import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ==========================================
// HELPER FUNCTIONS
// ==========================================

interface NotificationPreferences {
  meetupReminders: boolean;
  meetupUpdates: boolean;
  chatMessages: boolean;
  newParticipants: boolean;
  systemNotifications: boolean;
  muteAll: boolean;
  quietHoursStart: string | null;
  quietHoursEnd: string | null;
  mutedChats: string[];
}

interface UserData {
  fcmTokens?: string[];
  notificationPreferences?: NotificationPreferences;
  username?: string;
}

async function getUserData(userId: string): Promise<UserData | null> {
  const doc = await db.collection("users").doc(userId).get();
  if (!doc.exists) return null;
  return doc.data() as UserData;
}

function isInQuietHours(prefs: NotificationPreferences): boolean {
  if (!prefs.quietHoursStart || !prefs.quietHoursEnd) return false;

  const now = new Date();
  const currentMinutes = now.getHours() * 60 + now.getMinutes();

  const [startHour, startMin] = prefs.quietHoursStart.split(":").map(Number);
  const [endHour, endMin] = prefs.quietHoursEnd.split(":").map(Number);

  const startMinutes = startHour * 60 + startMin;
  const endMinutes = endHour * 60 + endMin;

  // Handle overnight quiet hours
  if (startMinutes > endMinutes) {
    return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
  }
  return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
}

function shouldSendNotification(
  prefs: NotificationPreferences | undefined,
  notificationType: string,
  chatId?: string
): boolean {
  if (!prefs) return true; // Default to sending if no preferences

  if (prefs.muteAll) return false;
  if (isInQuietHours(prefs)) return false;

  switch (notificationType) {
  case "meetup_reminder":
    return prefs.meetupReminders !== false;
  case "meetup_update":
  case "meetup_cancelled":
    return prefs.meetupUpdates !== false;
  case "chat_message":
    if (chatId && prefs.mutedChats?.includes(chatId)) return false;
    return prefs.chatMessages !== false;
  case "new_participant":
  case "capacity_reached":
    return prefs.newParticipants !== false;
  case "system":
    return prefs.systemNotifications !== false;
  default:
    return true;
  }
}

async function createNotificationDocument(
  userId: string,
  type: string,
  title: string,
  message: string,
  relatedId: string,
  metadata: Record<string, unknown> = {}
): Promise<string> {
  const docRef = await db.collection("notifications").add({
    userId,
    type,
    title,
    message,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
    relatedId,
    metadata,
  });
  return docRef.id;
}

async function sendPushNotification(
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  if (tokens.length === 0) return;

  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: {
      title,
      body,
    },
    data,
    android: {
      priority: "high",
      notification: {
        channelId: "sporsal_notifications",
        priority: "high",
        defaultSound: true,
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
    webpush: {
      notification: {
        icon: "/icons/icon-192x192.png",
        badge: "/icons/badge-72x72.png",
      },
    },
  };

  try {
    const response = await messaging.sendEachForMulticast(message);
    console.log(`Successfully sent ${response.successCount} messages`);

    // Remove invalid tokens
    if (response.failureCount > 0) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
        }
      });
      console.log("Failed tokens:", failedTokens);
    }
  } catch (error) {
    console.error("Error sending push notification:", error);
  }
}

// ==========================================
// CLOUD FUNCTIONS
// ==========================================

// 1. Chat Message Notification
// Uses deterministic document ID to prevent race conditions
export const onChatMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const { chatId } = context.params;
    const messageData = snap.data();

    const senderId = messageData.senderId as string;

    // Get meetup to find participants
    const meetupDoc = await db.collection("meetups").doc(chatId).get();
    if (!meetupDoc.exists) {
      console.log("Meetup not found for chat:", chatId);
      return null;
    }

    const meetupData = meetupDoc.data();
    const participantIds = (meetupData?.participantIds as string[]) || [];
    const meetupTitle = meetupData?.title as string || "Etkinlik";

    // Send notification to all participants except sender
    const notifications = participantIds
      .filter((id) => id !== senderId)
      .map(async (userId) => {
        const userData = await getUserData(userId);
        if (!userData) return;

        // Check notification preferences
        if (!shouldSendNotification(userData.notificationPreferences, "chat_message", chatId)) {
          console.log(`User ${userId} has chat notifications disabled`);
          return;
        }

        // Use deterministic document ID: chat_userId_chatId
        // This prevents race conditions by always targeting the same document
        const notificationId = `chat_${userId}_${chatId}`;
        const notifRef = db.collection("notifications").doc(notificationId);

        // Use transaction to safely update or create
        await db.runTransaction(async (transaction) => {
          const notifDoc = await transaction.get(notifRef);

          if (notifDoc.exists && notifDoc.data()?.isRead === false) {
            // Update existing unread notification - increment count
            const currentCount = (notifDoc.data()?.metadata?.unreadCount as number) || 1;
            const newCount = currentCount + 1;

            transaction.update(notifRef, {
              "message": `${newCount} yeni mesaj`,
              "timestamp": admin.firestore.FieldValue.serverTimestamp(),
              "metadata.unreadCount": newCount,
            });

            console.log(`Updated chat notification ${notificationId}, count: ${newCount}`);
          } else {
            // Create or replace notification (if it was read before)
            transaction.set(notifRef, {
              userId,
              type: "chat_message",
              title: meetupTitle,
              message: "1 yeni mesaj",
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              isRead: false,
              relatedId: chatId,
              metadata: {
                meetupTitle,
                unreadCount: 1,
              },
            });

            console.log(`Created chat notification ${notificationId}`);
          }
        });

        // Send push notification
        if (userData.fcmTokens && userData.fcmTokens.length > 0) {
          await sendPushNotification(
            userData.fcmTokens,
            meetupTitle,
            "Yeni mesaj geldi",
            {
              type: "chat_message",
              relatedId: chatId,
            }
          );
        }
      });

    await Promise.all(notifications);
    console.log(`Chat notification processed for message in ${chatId}`);
    return null;
  });

// 2. Meetup Update Notification
export const onMeetupUpdate = functions.firestore
  .document("meetups/{meetupId}")
  .onUpdate(async (change, context) => {
    const { meetupId } = context.params;
    const before = change.before.data();
    const after = change.after.data();

    // Check what changed
    const changes: string[] = [];

    if (before.date?.toDate?.()?.getTime() !== after.date?.toDate?.()?.getTime()) {
      changes.push("tarih");
    }
    if (before.locationName !== after.locationName || before.locationAddress !== after.locationAddress) {
      changes.push("konum");
    }
    if (before.title !== after.title || before.description !== after.description) {
      changes.push("detaylar");
    }

    // Check if meetup was cancelled (you might have a 'cancelled' field)
    const wasCancelled = !before.cancelled && after.cancelled;

    if (changes.length === 0 && !wasCancelled) {
      // No significant changes
      return null;
    }

    const participantIds = (after.participantIds as string[]) || [];
    const organizerId = after.organizerId as string;
    const meetupTitle = after.title as string;

    let notificationType = "meetup_update";
    let title = `${meetupTitle} güncellendi`;
    let message = `Değişiklikler: ${changes.join(", ")}`;

    if (wasCancelled) {
      notificationType = "meetup_cancelled";
      title = `${meetupTitle} iptal edildi`;
      message = "Etkinlik organizatör tarafından iptal edildi.";
    }

    // Notify all participants except organizer (they made the change)
    const notifications = participantIds
      .filter((id) => id !== organizerId)
      .map(async (userId) => {
        const userData = await getUserData(userId);
        if (!userData) return;

        if (!shouldSendNotification(userData.notificationPreferences, notificationType)) {
          return;
        }

        await createNotificationDocument(
          userId,
          notificationType,
          title,
          message,
          meetupId,
          { meetupTitle, changes }
        );

        if (userData.fcmTokens && userData.fcmTokens.length > 0) {
          await sendPushNotification(
            userData.fcmTokens,
            title,
            message,
            { type: notificationType, relatedId: meetupId }
          );
        }
      });

    await Promise.all(notifications);
    console.log(`Meetup update notification sent for ${meetupId}`);
    return null;
  });

// 3. New Participant Notification (to organizer)
export const onNewParticipant = functions.firestore
  .document("meetups/{meetupId}/participants/{participantId}")
  .onCreate(async (snap, context) => {
    const { meetupId, participantId } = context.params;

    // Get meetup details
    const meetupDoc = await db.collection("meetups").doc(meetupId).get();
    if (!meetupDoc.exists) return null;

    const meetupData = meetupDoc.data();
    const organizerId = meetupData?.organizerId as string;
    const meetupTitle = meetupData?.title as string;
    const currentParticipants = meetupData?.currentParticipants as number || 0;
    const maxParticipants = meetupData?.maxParticipants as number || 0;

    // Don't notify if participant is the organizer
    if (participantId === organizerId) return null;

    // Get participant name
    const participantDoc = await db.collection("users").doc(participantId).get();
    const participantName = participantDoc.data()?.username as string || "Birisi";

    // Get organizer data
    const organizerData = await getUserData(organizerId);
    if (!organizerData) return null;

    // Send new participant notification
    if (shouldSendNotification(organizerData.notificationPreferences, "new_participant")) {
      await createNotificationDocument(
        organizerId,
        "new_participant",
        `${meetupTitle} - Yeni Katılımcı`,
        `${participantName} etkinliğinize katıldı!`,
        meetupId,
        { participantId, participantName }
      );

      if (organizerData.fcmTokens && organizerData.fcmTokens.length > 0) {
        await sendPushNotification(
          organizerData.fcmTokens,
          `${meetupTitle} - Yeni Katılımcı`,
          `${participantName} etkinliğinize katıldı!`,
          { type: "new_participant", relatedId: meetupId }
        );
      }
    }

    // Check if capacity is reached
    if (currentParticipants + 1 >= maxParticipants) {
      if (shouldSendNotification(organizerData.notificationPreferences, "capacity_reached")) {
        await createNotificationDocument(
          organizerId,
          "capacity_reached",
          `${meetupTitle} - Kontenjan Doldu!`,
          "Etkinliğiniz maksimum kapasiteye ulaştı.",
          meetupId,
          {}
        );

        if (organizerData.fcmTokens && organizerData.fcmTokens.length > 0) {
          await sendPushNotification(
            organizerData.fcmTokens,
            `${meetupTitle} - Kontenjan Doldu!`,
            "Etkinliğiniz maksimum kapasiteye ulaştı.",
            { type: "capacity_reached", relatedId: meetupId }
          );
        }
      }
    }

    console.log(`New participant notification sent for ${meetupId}`);
    return null;
  });

// 4. Participant Removed - Notify Waitlisted Users
export const onParticipantRemoved = functions.firestore
  .document("meetups/{meetupId}/participants/{participantId}")
  .onDelete(async (snap, context) => {
    const { meetupId } = context.params;

    // Get meetup details
    const meetupDoc = await db.collection("meetups").doc(meetupId).get();
    if (!meetupDoc.exists) return null;

    const meetupData = meetupDoc.data();
    if (!meetupData) return null;

    const meetupTitle = meetupData.title as string;
    const currentParticipants = meetupData.currentParticipants as number || 0;
    const maxParticipants = meetupData.maxParticipants as number || 0;
    const waitlistUserIds = (meetupData.waitlistUserIds as string[]) || [];

    // Check if spot is now available (current < max)
    if (currentParticipants >= maxParticipants || waitlistUserIds.length === 0) {
      console.log(`No waitlist notifications needed for ${meetupId}`);
      return null;
    }

    console.log(`Spot available in ${meetupId}, notifying ${waitlistUserIds.length} waitlisted users`);

    const meetupDate = meetupData.date.toDate() as Date;
    const hours = meetupDate.getHours().toString().padStart(2, "0");
    const mins = meetupDate.getMinutes().toString().padStart(2, "0");
    const timeStr = `${hours}:${mins}`;

    // Notify all waitlisted users
    const notifications = waitlistUserIds.map(async (userId) => {
      const userData = await getUserData(userId);
      if (!userData) return;

      if (!shouldSendNotification(userData.notificationPreferences, "spot_available")) {
        return;
      }

      await createNotificationDocument(
        userId,
        "spot_available",
        `${meetupTitle} - Kontenjan Açıldı!`,
        `Etkinlikte yer açıldı! ${timeStr}'de başlayacak.`,
        meetupId,
        { meetupTitle, time: timeStr }
      );

      if (userData.fcmTokens && userData.fcmTokens.length > 0) {
        await sendPushNotification(
          userData.fcmTokens,
          `${meetupTitle} - Kontenjan Açıldı!`,
          "Etkinlikte yer açıldı! Hemen katılabilirsiniz.",
          { type: "spot_available", relatedId: meetupId }
        );
      }
    });

    await Promise.all(notifications);
    console.log(`Waitlist notifications sent for ${meetupId}`);
    return null;
  });

// 5. Meetup Reminder (Scheduled - runs every 15 minutes)
export const meetupReminder = functions.pubsub
  .schedule("every 15 minutes")
  .timeZone("Europe/Istanbul")
  .onRun(async () => {
    const now = new Date();
    const oneHourLater = new Date(now.getTime() + 60 * 60 * 1000);
    const fifteenMinutesLater = new Date(now.getTime() + 15 * 60 * 1000);

    // Query meetups starting in approximately 1 hour
    const meetupsSnapshot = await db.collection("meetups")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(fifteenMinutesLater))
      .where("date", "<=", admin.firestore.Timestamp.fromDate(oneHourLater))
      .get();

    console.log(`Found ${meetupsSnapshot.size} meetups starting soon`);

    for (const meetupDoc of meetupsSnapshot.docs) {
      const meetupId = meetupDoc.id;
      const meetupData = meetupDoc.data();

      // Check if reminder was already sent
      if (meetupData.reminderSent) {
        console.log(`Reminder already sent for ${meetupId}`);
        continue;
      }

      const meetupTitle = meetupData.title as string;
      const meetupDate = meetupData.date.toDate() as Date;
      const participantIds = (meetupData.participantIds as string[]) || [];
      const locationName = meetupData.locationName as string;

      const hours = meetupDate.getHours().toString().padStart(2, "0");
      const mins = meetupDate.getMinutes().toString().padStart(2, "0");
      const timeStr = `${hours}:${mins}`;

      // Send reminder to all participants
      const notifications = participantIds.map(async (userId) => {
        const userData = await getUserData(userId);
        if (!userData) return;

        if (!shouldSendNotification(userData.notificationPreferences, "meetup_reminder")) {
          return;
        }

        await createNotificationDocument(
          userId,
          "meetup_reminder",
          `${meetupTitle} - 1 Saat Kaldı!`,
          `Etkinlik ${timeStr}'de ${locationName} konumunda başlayacak.`,
          meetupId,
          { meetupTitle, time: timeStr, location: locationName }
        );

        if (userData.fcmTokens && userData.fcmTokens.length > 0) {
          await sendPushNotification(
            userData.fcmTokens,
            `${meetupTitle} - 1 Saat Kaldı!`,
            `Etkinlik ${timeStr}'de ${locationName} konumunda başlayacak.`,
            { type: "meetup_reminder", relatedId: meetupId }
          );
        }
      });

      await Promise.all(notifications);

      // Mark reminder as sent
      await meetupDoc.ref.update({ reminderSent: true });
      console.log(`Reminder sent for meetup ${meetupId}`);
    }

    return null;
  });

// 5. Cleanup Old Notifications (Scheduled - runs daily)
export const cleanupOldNotifications = functions.pubsub
  .schedule("every 24 hours")
  .timeZone("Europe/Istanbul")
  .onRun(async () => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const oldNotifications = await db.collection("notifications")
      .where("timestamp", "<", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
      .limit(500)
      .get();

    if (oldNotifications.empty) {
      console.log("No old notifications to delete");
      return null;
    }

    const batch = db.batch();
    oldNotifications.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${oldNotifications.size} old notifications`);

    return null;
  });

// 6. Welcome Notification (when user signs up)
export const onUserCreated = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const userData = snap.data();
    const username = userData.username as string || "Sporcu";

    await createNotificationDocument(
      userId,
      "system",
      "Sporsal'a Hoş Geldin! 🎉",
      `Merhaba ${username}! Spor arkadaşlarınla tanışmaya hazır mısın?`,
      "",
      {}
    );

    console.log(`Welcome notification created for user ${userId}`);
    return null;
  });
