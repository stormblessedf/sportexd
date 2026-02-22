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

interface AttendanceRecordData {
  userId?: string;
  status?: string; // "attended" or "not_attended"
  distanceMeters?: number;
  method?: string;
}

interface PartnershipData {
  userId?: string;
  partnerId?: string;
  status?: string; // "pending" | "accepted" | "rejected" | "blocked"
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

function calculateReliabilityScore(joined: number, registered: number): number {
  if (registered <= 0) return 100;
  const boundedJoined = Math.min(Math.max(0, joined), registered);
  const raw = (boundedJoined / registered) * 100;
  return Math.max(0, Math.min(100, raw));
}

async function adjustRegisteredCounter(userId: string, delta: number): Promise<void> {
  if (!userId || delta === 0) return;
  const userRef = db.collection("users").doc(userId);

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) return;

    const userData = userDoc.data() || {};
    const currentRegistered = Math.max(0, Number(userData.totalMeetupsRegistered || 0));
    const currentJoined = Math.max(0, Number(userData.totalMeetupsJoined || 0));

    const nextRegistered = Math.max(0, currentRegistered + delta);
    const boundedJoined = Math.min(currentJoined, nextRegistered);
    const score = calculateReliabilityScore(boundedJoined, nextRegistered);

    transaction.update(userRef, {
      totalMeetupsRegistered: nextRegistered,
      totalMeetupsJoined: boundedJoined,
      reliabilityScore: score,
    });
  });
}

// ==========================================
// CLOUD FUNCTIONS
// ==========================================

// 1. Chat Message Notification
// Uses deterministic document ID to prevent race conditions
// Supports both meetup chats and DM chats
export const onChatMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const { chatId } = context.params;
    const messageData = snap.data();

    const senderId = messageData.senderId as string;

    let participantIds: string[] = [];
    let chatTitle = "Mesaj";

    // Check if this is a DM chat (starts with "dm_")
    const isDmChat = chatId.startsWith("dm_");

    if (isDmChat) {
      // Get DM chat document to find participants
      const chatDoc = await db.collection("chats").doc(chatId).get();
      if (!chatDoc.exists) {
        console.log("DM chat not found:", chatId);
        return null;
      }

      const chatData = chatDoc.data();
      participantIds = (chatData?.participants as string[]) || [];

      // Get sender's name for DM title
      const senderDoc = await db.collection("users").doc(senderId).get();
      const senderName = senderDoc.data()?.username as string || "Birisi";
      chatTitle = senderName;
    } else {
      // Get meetup to find participants
      const meetupDoc = await db.collection("meetups").doc(chatId).get();
      if (!meetupDoc.exists) {
        console.log("Meetup not found for chat:", chatId);
        return null;
      }

      const meetupData = meetupDoc.data();
      participantIds = (meetupData?.participantIds as string[]) || [];
      chatTitle = meetupData?.title as string || "Etkinlik";
    }

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
              title: chatTitle,
              message: "1 yeni mesaj",
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              isRead: false,
              relatedId: chatId,
              metadata: {
                chatTitle,
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
            chatTitle,
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

// 2. Meetup registration sync for organizer (create-time participant)
export const onMeetupCreated = functions.firestore
  .document("meetups/{meetupId}")
  .onCreate(async (snap) => {
    const meetupData = snap.data() || {};
    const organizerId = meetupData.organizerId as string | undefined;
    if (!organizerId) return null;

    try {
      await adjustRegisteredCounter(organizerId, 1);
    } catch (error) {
      console.error(`Organizer registration sync failed for ${organizerId}:`, error);
    }
    return null;
  });

// 3. Meetup Update Notification
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
    const chatTitle = after.title as string;

    let notificationType = "meetup_update";
    let title = `${chatTitle} güncellendi`;
    let message = `Değişiklikler: ${changes.join(", ")}`;

    if (wasCancelled) {
      notificationType = "meetup_cancelled";
      title = `${chatTitle} iptal edildi`;
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
          { chatTitle, changes }
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

// 4. New Participant Notification (to organizer)
export const onNewParticipant = functions.firestore
  .document("meetups/{meetupId}/participants/{participantId}")
  .onCreate(async (snap, context) => {
    const { meetupId, participantId } = context.params;

    // Get meetup details
    const meetupDoc = await db.collection("meetups").doc(meetupId).get();
    if (!meetupDoc.exists) return null;

    const meetupData = meetupDoc.data();
    const organizerId = meetupData?.organizerId as string;
    const chatTitle = meetupData?.title as string;
    const currentParticipants = meetupData?.currentParticipants as number || 0;
    const maxParticipants = meetupData?.maxParticipants as number || 0;

    // Don't notify if participant is the organizer
    if (participantId === organizerId) return null;

    // Sync participant's registered counter (+1)
    try {
      await adjustRegisteredCounter(participantId, 1);
    } catch (error) {
      console.error(`Participant registration sync failed for ${participantId}:`, error);
    }

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
        `${chatTitle} - Yeni Katılımcı`,
        `${participantName} etkinliğinize katıldı!`,
        meetupId,
        { participantId, participantName }
      );

      if (organizerData.fcmTokens && organizerData.fcmTokens.length > 0) {
        await sendPushNotification(
          organizerData.fcmTokens,
          `${chatTitle} - Yeni Katılımcı`,
          `${participantName} etkinliğinize katıldı!`,
          { type: "new_participant", relatedId: meetupId }
        );
      }
    }

    // Check if capacity is reached (participant already added, so compare directly)
    if (currentParticipants >= maxParticipants) {
      if (shouldSendNotification(organizerData.notificationPreferences, "capacity_reached")) {
        await createNotificationDocument(
          organizerId,
          "capacity_reached",
          `${chatTitle} - Kontenjan Doldu!`,
          "Etkinliğiniz maksimum kapasiteye ulaştı.",
          meetupId,
          {}
        );

        if (organizerData.fcmTokens && organizerData.fcmTokens.length > 0) {
          await sendPushNotification(
            organizerData.fcmTokens,
            `${chatTitle} - Kontenjan Doldu!`,
            "Etkinliğiniz maksimum kapasiteye ulaştı.",
            { type: "capacity_reached", relatedId: meetupId }
          );
        }
      }
    }

    console.log(`New participant notification sent for ${meetupId}`);
    return null;
  });

// 5. Participant Removed - Update counters + Notify waitlisted users
export const onParticipantRemoved = functions.firestore
  .document("meetups/{meetupId}/participants/{participantId}")
  .onDelete(async (snap, context) => {
    const { meetupId, participantId } = context.params;

    // Get meetup details
    const meetupDoc = await db.collection("meetups").doc(meetupId).get();
    if (!meetupDoc.exists) return null;

    const meetupData = meetupDoc.data();
    if (!meetupData) return null;

    const chatTitle = meetupData.title as string;
    const currentParticipants = meetupData.currentParticipants as number || 0;
    const maxParticipants = meetupData.maxParticipants as number || 0;
    const waitlistUserIds = (meetupData.waitlistUserIds as string[]) || [];

    // Decrement registration only if meetup has not ended yet
    const dateTs = meetupData.date as admin.firestore.Timestamp | undefined;
    const endTs = meetupData.endDate as admin.firestore.Timestamp | undefined;
    const effectiveEnd = (endTs ?? dateTs)?.toDate();
    if (effectiveEnd && effectiveEnd.getTime() > Date.now()) {
      try {
        await adjustRegisteredCounter(participantId, -1);
      } catch (error) {
        console.error(`Participant unregister sync failed for ${participantId}:`, error);
      }
    }

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
        `${chatTitle} - Kontenjan Açıldı!`,
        `Etkinlikte yer açıldı! ${timeStr}'de başlayacak.`,
        meetupId,
        { chatTitle, time: timeStr }
      );

      if (userData.fcmTokens && userData.fcmTokens.length > 0) {
        await sendPushNotification(
          userData.fcmTokens,
          `${chatTitle} - Kontenjan Açıldı!`,
          "Etkinlikte yer açıldı! Hemen katılabilirsiniz.",
          { type: "spot_available", relatedId: meetupId }
        );
      }
    });

    await Promise.all(notifications);
    console.log(`Waitlist notifications sent for ${meetupId}`);
    return null;
  });

// 6. Meetup deleted - unregister all participants if meetup not finished yet
export const onMeetupDeleted = functions.firestore
  .document("meetups/{meetupId}")
  .onDelete(async (snap, context) => {
    const { meetupId } = context.params;
    const meetupData = snap.data() || {};

    const participantIds = (meetupData.participantIds as string[]) || [];
    if (participantIds.length === 0) return null;

    const dateTs = meetupData.date as admin.firestore.Timestamp | undefined;
    const endTs = meetupData.endDate as admin.firestore.Timestamp | undefined;
    const effectiveEnd = (endTs ?? dateTs)?.toDate();
    if (!effectiveEnd || effectiveEnd.getTime() <= Date.now()) return null;

    const updates = participantIds.map(async (userId) => {
      try {
        await adjustRegisteredCounter(userId, -1);
      } catch (error) {
        console.error(`Meetup delete unregister failed for meetup ${meetupId}, user ${userId}:`, error);
      }
    });
    await Promise.all(updates);
    return null;
  });

// 7. Meetup Reminder (Scheduled - runs every 15 minutes)
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

      const chatTitle = meetupData.title as string;
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
          `${chatTitle} - 1 Saat Kaldı!`,
          `Etkinlik ${timeStr}'de ${locationName} konumunda başlayacak.`,
          meetupId,
          { chatTitle, time: timeStr, location: locationName }
        );

        if (userData.fcmTokens && userData.fcmTokens.length > 0) {
          await sendPushNotification(
            userData.fcmTokens,
            `${chatTitle} - 1 Saat Kaldı!`,
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

// 8. Cleanup Old Notifications (Scheduled - runs daily)
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

// 9. Welcome Notification (when user signs up)
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

// 10. GPS Proximity Attendance Record Reliability Sync
// Reliability formula uses ALL registered meetups in denominator.
export const onAttendanceRecordCreated = functions.firestore
  .document("meetups/{meetupId}/attendance_records/{userId}")
  .onCreate(async (snap, context) => {
    const { meetupId, userId } = context.params;
    const recordData = (snap.data() || {}) as AttendanceRecordData;
    const status = recordData.status;

    if (recordData.userId && recordData.userId !== userId) {
      console.warn(`Attendance record userId mismatch. Path=${userId}, payload=${recordData.userId}`);
      return null;
    }
    if (status !== "attended" && status !== "not_attended") {
      console.warn(`Invalid attendance status for meetup ${meetupId}, user ${userId}: ${status}`);
      return null;
    }

    try {
      await db.runTransaction(async (transaction) => {
        const meetupRef = db.collection("meetups").doc(meetupId);
        const userRef = db.collection("users").doc(userId);
        const meetupDoc = await transaction.get(meetupRef);
        if (!meetupDoc.exists) {
          console.log(`Meetup not found for attendance sync: ${meetupId}`);
          return;
        }
        const participants = (meetupDoc.data()?.participantIds as string[]) || [];
        if (!participants.includes(userId)) {
          console.log(`User ${userId} is not participant of meetup ${meetupId}, skipping sync`);
          return;
        }

        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          console.log(`User not found for attendance record sync: ${userId}`);
          return;
        }

        const userData = userDoc.data() || {};
        const currentRegistered = Math.max(0, Number(userData.totalMeetupsRegistered || 0));
        const currentJoined = Math.max(0, Number(userData.totalMeetupsJoined || 0));

        const nextJoined = status === "attended" ? currentJoined + 1 : currentJoined;
        const boundedJoined =
          currentRegistered > 0 ? Math.min(nextJoined, currentRegistered) : nextJoined;
        const boundedScore = calculateReliabilityScore(boundedJoined, currentRegistered);

        const updateData: Record<string, unknown> = {
          totalMeetupsJoined: boundedJoined,
          reliabilityScore: boundedScore,
        };
        transaction.update(userRef, updateData);
      });

      console.log(`Attendance record sync completed for meetup ${meetupId}, user ${userId}`);
    } catch (error) {
      console.error(
        `Attendance record sync failed for meetup ${meetupId}, user ${userId}:`,
        error
      );
    }

    return null;
  });

// 11. Rating aggregate sync (server-side)
// Keeps users/{ratedUserId}.averageRating and totalRatings consistent.
export const onRatingCreated = functions.firestore
  .document("ratings/{ratingId}")
  .onCreate(async (snap) => {
    const data = snap.data() || {};
    const ratedUserId = data.ratedUserId as string | undefined;
    const ratingRaw = Number(data.rating || 0);

    if (!ratedUserId || !Number.isFinite(ratingRaw)) return null;
    const rating = Math.max(1, Math.min(5, ratingRaw));
    const userRef = db.collection("users").doc(ratedUserId);

    try {
      await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        const userData = userDoc.data() || {};
        const currentAverage = Math.max(0, Number(userData.averageRating || 0));
        const currentTotal = Math.max(0, Number(userData.totalRatings || 0));

        const newTotal = currentTotal + 1;
        const newAverage = ((currentAverage * currentTotal) + rating) / newTotal;
        const roundedAverage = Math.round(newAverage * 10) / 10;

        transaction.update(userRef, {
          averageRating: roundedAverage,
          totalRatings: newTotal,
        });
      });
    } catch (error) {
      console.error(`Rating aggregate sync failed for user ${ratedUserId}:`, error);
    }

    return null;
  });

// 12. Partnership users sync (server-side)
// Syncs users/{id}.partners and partnersCount when partnership state changes.
export const onPartnershipWrite = functions.firestore
  .document("partners/{partnershipId}")
  .onWrite(async (change) => {
    const before = change.before.exists ? (change.before.data() as PartnershipData) : null;
    const after = change.after.exists ? (change.after.data() as PartnershipData) : null;

    const wasAccepted = before?.status === "accepted";
    const isAccepted = after?.status === "accepted";
    if (wasAccepted === isAccepted) return null;

    const userId = (after?.userId ?? before?.userId) || "";
    const partnerId = (after?.partnerId ?? before?.partnerId) || "";
    if (!userId || !partnerId || userId === partnerId) return null;

    const userRef = db.collection("users").doc(userId);
    const partnerRef = db.collection("users").doc(partnerId);

    try {
      await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        const partnerDoc = await transaction.get(partnerRef);
        if (!userDoc.exists || !partnerDoc.exists) return;

        const currentUserPartners = ((userDoc.data()?.partners as string[]) || [])
          .filter((id) => typeof id === "string");
        const currentPartnerPartners = ((partnerDoc.data()?.partners as string[]) || [])
          .filter((id) => typeof id === "string");

        let nextUserPartners = currentUserPartners;
        let nextPartnerPartners = currentPartnerPartners;

        if (isAccepted) {
          if (!nextUserPartners.includes(partnerId)) {
            nextUserPartners = [...nextUserPartners, partnerId];
          }
          if (!nextPartnerPartners.includes(userId)) {
            nextPartnerPartners = [...nextPartnerPartners, userId];
          }
        } else {
          nextUserPartners = nextUserPartners.filter((id) => id !== partnerId);
          nextPartnerPartners = nextPartnerPartners.filter((id) => id !== userId);
        }

        transaction.update(userRef, {
          partners: nextUserPartners,
          partnersCount: nextUserPartners.length,
        });
        transaction.update(partnerRef, {
          partners: nextPartnerPartners,
          partnersCount: nextPartnerPartners.length,
        });
      });
    } catch (error) {
      console.error(`Partnership users sync failed for ${userId} <-> ${partnerId}:`, error);
    }

    return null;
  });

// 13. Attendance cutoff processor (scheduled)
// Auto-creates "not_attended" records for missing participants after cutoff.
export const processAttendanceCutoffs = functions.pubsub
  .schedule("every 30 minutes")
  .timeZone("Europe/Istanbul")
  .onRun(async () => {
    const now = new Date();
    const lookback = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    const meetupsSnapshot = await db.collection("meetups")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(lookback))
      .where("date", "<=", admin.firestore.Timestamp.fromDate(now))
      .limit(250)
      .get();

    let createdCount = 0;

    for (const meetupDoc of meetupsSnapshot.docs) {
      const meetupData = meetupDoc.data();
      const participantIds = (meetupData.participantIds as string[]) || [];
      if (participantIds.length < 2) continue;

      const startTs = meetupData.date as admin.firestore.Timestamp | undefined;
      if (!startTs) continue;
      const startDate = startTs.toDate();

      const endTs = meetupData.endDate as admin.firestore.Timestamp | undefined;
      const endDate = endTs ? endTs.toDate() : new Date(startDate.getTime() + 2 * 60 * 60 * 1000);
      const cutoff = new Date(startDate.getTime() + Math.floor((endDate.getTime() - startDate.getTime()) / 2));
      if (now < cutoff) continue;

      for (const participantId of participantIds) {
        const recordRef = meetupDoc.ref.collection("attendance_records").doc(participantId);
        try {
          await recordRef.create({
            userId: participantId,
            status: "not_attended",
            detectedAt: now.toISOString(),
            method: "cutoff_auto",
          });
          createdCount++;
        } catch (error) {
          // Ignore already-exists (record already created by GPS/client/previous run)
          const err = error as { code?: string | number };
          if (err?.code === 6 || err?.code === "already-exists") continue;
          console.error(`Cutoff record create failed for meetup ${meetupDoc.id}, user ${participantId}:`, error);
        }
      }
    }

    console.log(`Attendance cutoff processor done. Created records: ${createdCount}`);
    return null;
  });
