import * as admin from "firebase-admin";
import { FieldPath, FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import * as functions from "firebase-functions/v1";

// Initialize Firebase Admin
admin.initializeApp();

const db = getFirestore();
const messaging = admin.messaging();
const interactiveRuntime = functions.runWith({
  memory: "256MB",
  timeoutSeconds: 120,
  maxInstances: 40,
});
const eventSyncRuntime = functions.runWith({
  memory: "256MB",
  timeoutSeconds: 180,
  maxInstances: 20,
});
const maintenanceRuntime = functions.runWith({
  memory: "512MB",
  timeoutSeconds: 540,
  maxInstances: 1,
});

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

function chunkArray<T>(items: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

async function getUsersDataMap(userIds: string[]): Promise<Map<string, UserData>> {
  const result = new Map<string, UserData>();
  const uniqueIds = [...new Set(userIds)].filter((userId) => userId.length > 0);
  if (uniqueIds.length == 0) return result;

  for (const idChunk of chunkArray(uniqueIds, 30)) {
    const snapshot = await db.collection("users")
      .where(FieldPath.documentId(), "in", idChunk)
      .get();

    for (const doc of snapshot.docs) {
      result.set(doc.id, doc.data() as UserData);
    }
  }

  return result;
}

function stringifyPayload(
  data: Record<string, unknown>
): Record<string, string> {
  const payload: Record<string, string> = {};
  Object.entries(data).forEach(([key, value]) => {
    if (value == null) return;
    payload[key] = typeof value == "string" ? value : JSON.stringify(value);
  });
  return payload;
}

interface NotificationWriteInput {
  userId: string;
  type: string;
  title: string;
  message: string;
  relatedId: string;
  metadata?: Record<string, unknown>;
  deterministicId?: string;
  merge?: boolean;
}

async function createNotificationDocumentsBatch(
  notifications: NotificationWriteInput[]
): Promise<void> {
  if (notifications.length == 0) return;

  for (const notificationChunk of chunkArray(notifications, 350)) {
    const batch = db.batch();
    for (const notification of notificationChunk) {
      const ref = notification.deterministicId ?
        db.collection("notifications").doc(notification.deterministicId) :
        db.collection("notifications").doc();
      const payload = {
        userId: notification.userId,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        timestamp: FieldValue.serverTimestamp(),
        isRead: false,
        relatedId: notification.relatedId,
        metadata: notification.metadata ?? {},
      };
      if (notification.merge) {
        batch.set(ref, payload, { merge: true });
      } else {
        batch.set(ref, payload);
      }
    }
    await batch.commit();
  }
}

async function sendBulkPushNotification(
  usersById: Map<string, UserData>,
  userIds: string[],
  title: string,
  body: string,
  data: Record<string, unknown>
): Promise<void> {
  const tokens = [...new Set(
    userIds
      .flatMap((userId) => usersById.get(userId)?.fcmTokens ?? [])
      .filter((token) => token.length > 0)
  )];

  if (tokens.length == 0) return;

  for (const tokenChunk of chunkArray(tokens, 500)) {
    await messaging.sendEachForMulticast({
      tokens: tokenChunk,
      notification: {
        title,
        body,
      },
      data: stringifyPayload(data),
    });
  }
}

function computeParticipantState(
  currentParticipants: number,
  maxParticipants: number
): string {
  if (maxParticipants <= 0) return "has_space";
  if (currentParticipants >= maxParticipants) return "full";
  if ((currentParticipants / maxParticipants) >= 0.8) return "almost_full";
  return "has_space";
}

/*
function buildMeetupSearchKeywords(
  meetupData: FirebaseFirestore.DocumentData
): string[] {
  const joined = [
    meetupData.title,
    meetupData.description,
    meetupData.locationName,
    meetupData.locationAddress,
    meetupData.organizerName,
    meetupData.type,
  ].filter(Boolean).join(" ");

  return [...new Set(
    joined
      .toLowerCase()
      .replace(/[^a-z0-9Ã§ÄŸÄ±Ã¶ÅŸÃ¼\s]/g, " ")
      .split(/\s+/)
      .map((token) => token.trim())
      .filter((token) => token.length >= 2)
  )].sort();
}

*/

function normalizeSearchText(input: string): string {
  let normalized = input.toLowerCase();
  const replacements: Record<string, string> = {
    "ç": "c",
    "ğ": "g",
    "ı": "i",
    "i̇": "i",
    "ö": "o",
    "ş": "s",
    "ü": "u",
  };

  Object.entries(replacements).forEach(([from, to]) => {
    normalized = normalized.split(from).join(to);
  });

  return normalized.replace(/[^a-z0-9\s]/g, " ");
}

function buildMeetupSearchKeywords(
  meetupData: FirebaseFirestore.DocumentData
): string[] {
  const joined = [
    meetupData.title,
    meetupData.description,
    meetupData.locationName,
    meetupData.locationAddress,
    meetupData.organizerName,
    meetupData.type,
  ].filter(Boolean).join(" ");

  return [...new Set(
    normalizeSearchText(joined)
      .split(/\s+/)
      .map((token) => token.trim())
      .filter((token) => token.length >= 2)
  )].sort();
}

function buildMeetupDerivedFields(
  meetupData: FirebaseFirestore.DocumentData
): Record<string, unknown> {
  const participantIds = (meetupData.participantIds as string[] | undefined) ?? [];
  const currentParticipants = Number(
    meetupData.currentParticipants ?? participantIds.length
  );
  const maxParticipants = Number(meetupData.maxParticipants ?? 0);

  return {
    participantState: computeParticipantState(
      currentParticipants,
      maxParticipants
    ),
    availableSpots: Math.max(0, maxParticipants - currentParticipants),
    searchKeywords: buildMeetupSearchKeywords(meetupData),
  };
}

function sameStringArray(
  left: string[] | undefined,
  right: string[] | undefined
): boolean {
  const leftValue = [...(left ?? [])].sort();
  const rightValue = [...(right ?? [])].sort();
  if (leftValue.length != rightValue.length) return false;
  return leftValue.every((item, index) => item === rightValue[index]);
}

function needsMeetupDerivedFieldSync(
  meetupData: FirebaseFirestore.DocumentData,
  derivedFields: Record<string, unknown>
): boolean {
  return meetupData.participantState !== derivedFields.participantState ||
    meetupData.availableSpots !== derivedFields.availableSpots ||
    !sameStringArray(
      meetupData.searchKeywords as string[] | undefined,
      derivedFields.searchKeywords as string[] | undefined
    );
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
    timestamp: FieldValue.serverTimestamp(),
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

function buildMeetupChatShell(
  meetupId: string,
  meetupData: FirebaseFirestore.DocumentData
): Record<string, unknown> {
  const participantIds = ((meetupData.participantIds as string[]) || [])
    .filter((id) => typeof id === "string");
  const derivedFields = buildMeetupDerivedFields(meetupData);

  const chatShell: Record<string, unknown> = {
    type: "meetup",
    participants: participantIds,
    title: meetupData.title || "Etkinlik",
    description: meetupData.description || "",
    rules: meetupData.rules || "",
    imageUrl: meetupData.imageUrl || "",
    meetupType: meetupData.type || "other",
    organizerId: meetupData.organizerId || "",
    organizerName: meetupData.organizerName || "Unknown",
    organizerImageUrl: meetupData.organizerImageUrl || null,
    locationName: meetupData.locationName || "",
    locationAddress: meetupData.locationAddress || "",
    currentParticipants: meetupData.currentParticipants || participantIds.length,
    maxParticipants: meetupData.maxParticipants || 0,
    waitlistUserIds: (meetupData.waitlistUserIds as string[]) || [],
    latitude: meetupData.latitude ?? null,
    longitude: meetupData.longitude ?? null,
    hideFromFeedUntilAccepted: meetupData.hideFromFeedUntilAccepted === true,
    isFull: meetupData.isFull === true,
    participantState: derivedFields.participantState,
    availableSpots: derivedFields.availableSpots,
    searchKeywords: derivedFields.searchKeywords,
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (meetupData.date) {
    chatShell.meetupDate = meetupData.date;
  }
  if (meetupData.endDate) {
    chatShell.endDate = meetupData.endDate;
  }
  if (meetupData.createdAt) {
    chatShell.createdAt = meetupData.createdAt;
  }

  return chatShell;
}

async function syncMeetupChatShell(
  meetupId: string,
  meetupData: FirebaseFirestore.DocumentData | undefined
): Promise<void> {
  if (!meetupId || !meetupData) return;
  await db.collection("chats").doc(meetupId).set(
    buildMeetupChatShell(meetupId, meetupData),
    { merge: true }
  );
}

async function upsertMeetupChatSummaries(
  meetupId: string,
  meetupData: FirebaseFirestore.DocumentData,
  participantIds: string[],
  chatData?: FirebaseFirestore.DocumentData | null
): Promise<void> {
  if (participantIds.length === 0) return;

  const effectiveChatData = chatData ?? (
    await db.collection("chats").doc(meetupId).get()
  ).data();
  const unreadCounts = (effectiveChatData?.unreadCounts as Record<string, unknown> | undefined) ?? {};
  const batch = db.batch();

  for (const userId of participantIds) {
    const summaryRef = db
      .collection("users")
      .doc(userId)
      .collection("chat_summaries")
      .doc(meetupId);

    const unreadCountRaw = unreadCounts[userId];
    let unreadCount = Number(unreadCountRaw || 0);
    if (typeof unreadCountRaw === "number") {
      unreadCount = unreadCountRaw;
    }

    batch.set(summaryRef, {
      userId,
      chatId: meetupId,
      meetupId,
      title: meetupData.title || "",
      description: meetupData.description || "",
      rules: meetupData.rules || "",
      imageUrl: meetupData.imageUrl || "",
      meetupType: meetupData.type || "other",
      meetupDate: meetupData.date || null,
      endDate: meetupData.endDate || null,
      meetupEndDate: meetupData.endDate || null,
      effectiveEndDate: meetupData.endDate || meetupData.date || null,
      meetupCreatedAt: meetupData.createdAt || FieldValue.serverTimestamp(),
      createdAt: meetupData.createdAt || FieldValue.serverTimestamp(),
      locationName: meetupData.locationName || "",
      locationAddress: meetupData.locationAddress || "",
      organizerId: meetupData.organizerId || "",
      organizerName: meetupData.organizerName || "",
      organizerImageUrl: meetupData.organizerImageUrl || null,
      currentParticipants: meetupData.currentParticipants || 0,
      maxParticipants: meetupData.maxParticipants || 0,
      participants: meetupData.participantIds || [],
      participantIds: meetupData.participantIds || [],
      waitlistUserIds: meetupData.waitlistUserIds || [],
      latitude: meetupData.latitude || null,
      longitude: meetupData.longitude || null,
      hideFromFeedUntilAccepted: meetupData.hideFromFeedUntilAccepted === true,
      isFull: meetupData.isFull === true,
      lastMessage: effectiveChatData?.lastMessage || null,
      lastMessageTime: effectiveChatData?.lastMessageTime || null,
      lastMessageSenderId: effectiveChatData?.lastMessageSenderId || null,
      lastMessageSenderName: effectiveChatData?.lastMessageSenderName || null,
      unreadCount,
      isOrganizerOnlyMode: effectiveChatData?.isOrganizerOnlyMode === true,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  await batch.commit();
}

async function deleteMeetupChatSummaries(
  meetupId: string,
  participantIds: string[]
): Promise<void> {
  if (participantIds.length === 0) return;

  const batch = db.batch();
  for (const userId of participantIds) {
    const summaryRef = db
      .collection("users")
      .doc(userId)
      .collection("chat_summaries")
      .doc(meetupId);
    batch.delete(summaryRef);
  }
  await batch.commit();
}

// ==========================================
// CLOUD FUNCTIONS
// ==========================================

// 1. Chat Message Notification
// Uses deterministic document ID to prevent race conditions
// Supports both meetup chats and DM chats
export const onChatMessage = interactiveRuntime.firestore
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

    const chatRef = db.collection("chats").doc(chatId);
    const summaryUpdate: Record<string, unknown> = {
      lastMessage: messageData.text || "",
      lastMessageTime:
        messageData.timestamp || FieldValue.serverTimestamp(),
      lastMessageSenderId: senderId,
      lastMessageSenderName: messageData.senderName || "Birisi",
      updatedAt: FieldValue.serverTimestamp(),
      [`unreadCounts.${senderId}`]: 0,
    };

    for (const userId of participantIds) {
      if (userId !== senderId) {
        summaryUpdate[`unreadCounts.${userId}`] =
          FieldValue.increment(1);
      }
    }

    await chatRef.set(summaryUpdate, { merge: true });

    const recipientIds = participantIds.filter((id) => id !== senderId);
    const usersById = await getUsersDataMap(recipientIds);
    const eligibleRecipientIds = recipientIds.filter((userId) => {
      const userData = usersById.get(userId);
      return !!userData &&
        shouldSendNotification(userData.notificationPreferences, "chat_message", chatId);
    });

    await createNotificationDocumentsBatch(
      eligibleRecipientIds.map((userId) => ({
        userId,
        type: "chat_message",
        title: chatTitle,
        message: "Yeni mesajlar var",
        relatedId: chatId,
        metadata: {
          chatTitle,
          unreadCount: FieldValue.increment(1),
        },
        deterministicId: `chat_${userId}_${chatId}`,
        merge: true,
      }))
    );
    await sendBulkPushNotification(
      usersById,
      eligibleRecipientIds,
      chatTitle,
      "Yeni mesaj geldi",
      {
        type: "chat_message",
        relatedId: chatId,
      }
    );
    if (!isDmChat) {
      const meetupDoc = await db.collection("meetups").doc(chatId).get();
      if (meetupDoc.exists) {
        await syncMeetupChatShell(chatId, meetupDoc.data());
      }
    }
    console.log(`Chat notification processed for message in ${chatId}`);
    return null;
  });

export const onChatMetadataWrite = eventSyncRuntime.firestore
  .document("chats/{chatId}")
  .onWrite(async (change, context) => {
    const { chatId } = context.params;
    if (chatId.startsWith("dm_") || !change.after.exists) return null;

    const meetupDoc = await db.collection("meetups").doc(chatId).get();
    if (!meetupDoc.exists) return null;

    const meetupData = meetupDoc.data() || {};
    const participantIds = (meetupData.participantIds as string[]) || [];
    await upsertMeetupChatSummaries(chatId, meetupData, participantIds, change.after.data());
    return null;
  });

// 2. Meetup registration sync for organizer (create-time participant)
export const onMeetupCreated = eventSyncRuntime.firestore
  .document("meetups/{meetupId}")
  .onCreate(async (snap, context) => {
    const { meetupId } = context.params;
    const meetupData = snap.data() || {};
    const derivedFields = buildMeetupDerivedFields(meetupData);
    const organizerId = meetupData.organizerId as string | undefined;
    if (!organizerId) return null;

    try {
      await snap.ref.set(derivedFields, { merge: true });
      await adjustRegisteredCounter(organizerId, 1);
      await syncMeetupChatShell(meetupId, { ...meetupData, ...derivedFields });
      await upsertMeetupChatSummaries(
        meetupId,
        { ...meetupData, ...derivedFields },
        (meetupData.participantIds as string[]) || []
      );
    } catch (error) {
      console.error(`Organizer registration sync failed for ${organizerId}:`, error);
    }
    return null;
  });

// 3. Meetup Update Notification
export const onMeetupUpdate = eventSyncRuntime.firestore
  .document("meetups/{meetupId}")
  .onUpdate(async (change, context) => {
    const { meetupId } = context.params;
    const before = change.before.data();
    let effectiveAfter = change.after.data();
    const derivedFields = buildMeetupDerivedFields(effectiveAfter);
    if (needsMeetupDerivedFieldSync(effectiveAfter, derivedFields)) {
      await change.after.ref.set(derivedFields, { merge: true });
      effectiveAfter = { ...effectiveAfter, ...derivedFields };
    }

    const beforeParticipantIds = (before.participantIds as string[]) || [];
    const participantIds = (effectiveAfter.participantIds as string[]) || [];
    const removedParticipantIds = beforeParticipantIds.filter(
      (userId) => !participantIds.includes(userId)
    );

    await upsertMeetupChatSummaries(meetupId, effectiveAfter, participantIds);
    if (removedParticipantIds.length > 0) {
      await deleteMeetupChatSummaries(meetupId, removedParticipantIds);
    }

    // Check what changed
    const changes: string[] = [];

    if (before.date?.toDate?.()?.getTime() !== effectiveAfter.date?.toDate?.()?.getTime()) {
      changes.push("tarih");
    }
    if (
      before.locationName !== effectiveAfter.locationName ||
      before.locationAddress !== effectiveAfter.locationAddress
    ) {
      changes.push("konum");
    }
    if (before.title !== effectiveAfter.title || before.description !== effectiveAfter.description) {
      changes.push("detaylar");
    }

    // Check if meetup was cancelled (you might have a 'cancelled' field)
    const wasCancelled = !before.cancelled && effectiveAfter.cancelled;

    if (changes.length === 0 && !wasCancelled) {
      // No significant changes
      return null;
    }

    const organizerId = effectiveAfter.organizerId as string;
    const chatTitle = effectiveAfter.title as string;

    let notificationType = "meetup_update";
    let title = `${chatTitle} gÃ¼ncellendi`;
    let message = `DeÄŸiÅŸiklikler: ${changes.join(", ")}`;

    if (wasCancelled) {
      notificationType = "meetup_cancelled";
      title = `${chatTitle} iptal edildi`;
      message = "Etkinlik organizatÃ¶r tarafÄ±ndan iptal edildi.";
    }

    // Notify all participants except organizer (they made the change)
    const recipientIds = participantIds.filter((id) => id !== organizerId);
    const usersById = await getUsersDataMap(recipientIds);
    const eligibleRecipientIds = recipientIds.filter((userId) => {
      const userData = usersById.get(userId);
      return !!userData &&
        shouldSendNotification(userData.notificationPreferences, notificationType);
    });

    await createNotificationDocumentsBatch(
      eligibleRecipientIds.map((userId) => ({
        userId,
        type: notificationType,
        title,
        message,
        relatedId: meetupId,
        metadata: { chatTitle, changes },
      }))
    );
    await sendBulkPushNotification(
      usersById,
      eligibleRecipientIds,
      title,
      message,
      { type: notificationType, relatedId: meetupId }
    );
    await syncMeetupChatShell(meetupId, effectiveAfter);
    await upsertMeetupChatSummaries(meetupId, effectiveAfter, participantIds);
    console.log(`Meetup update notification sent for ${meetupId}`);
    return null;
  });

// 4. New Participant Notification (to organizer)
export const onNewParticipant = eventSyncRuntime.firestore
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
        `${chatTitle} - Yeni KatÄ±lÄ±mcÄ±`,
        `${participantName} etkinliÄŸinize katÄ±ldÄ±!`,
        meetupId,
        { participantId, participantName }
      );

      if (organizerData.fcmTokens && organizerData.fcmTokens.length > 0) {
        await sendPushNotification(
          organizerData.fcmTokens,
          `${chatTitle} - Yeni KatÄ±lÄ±mcÄ±`,
          `${participantName} etkinliÄŸinize katÄ±ldÄ±!`,
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
          "EtkinliÄŸiniz maksimum kapasiteye ulaÅŸtÄ±.",
          meetupId,
          {}
        );

        if (organizerData.fcmTokens && organizerData.fcmTokens.length > 0) {
          await sendPushNotification(
            organizerData.fcmTokens,
            `${chatTitle} - Kontenjan Doldu!`,
            "EtkinliÄŸiniz maksimum kapasiteye ulaÅŸtÄ±.",
            { type: "capacity_reached", relatedId: meetupId }
          );
        }
      }
    }

    await syncMeetupChatShell(meetupId, meetupData || {});
    await upsertMeetupChatSummaries(meetupId, meetupData || {}, [participantId]);
    console.log(`New participant notification sent for ${meetupId}`);
    return null;
  });

// 5. Participant Removed - Update counters + Notify waitlisted users
export const onParticipantRemoved = eventSyncRuntime.firestore
  .document("meetups/{meetupId}/participants/{participantId}")
  .onDelete(async (snap, context) => {
    const { meetupId, participantId } = context.params;

    const meetupDoc = await db.collection("meetups").doc(meetupId).get();
    if (!meetupDoc.exists) return null;

    const meetupData = meetupDoc.data();
    if (!meetupData) return null;

    const chatTitle = meetupData.title as string;
    const currentParticipants = meetupData.currentParticipants as number || 0;
    const maxParticipants = meetupData.maxParticipants as number || 0;
    const waitlistUserIds = (meetupData.waitlistUserIds as string[]) || [];

    const dateTs = meetupData.date as Timestamp | undefined;
    const endTs = meetupData.endDate as Timestamp | undefined;
    const effectiveEnd = (endTs ?? dateTs)?.toDate();
    if (effectiveEnd && effectiveEnd.getTime() > Date.now()) {
      try {
        await adjustRegisteredCounter(participantId, -1);
      } catch (error) {
        console.error(`Participant unregister sync failed for ${participantId}:`, error);
      }
    }

    if (currentParticipants >= maxParticipants || waitlistUserIds.length === 0) {
      await syncMeetupChatShell(meetupId, meetupData);
      await deleteMeetupChatSummaries(meetupId, [participantId]);
      console.log(`No waitlist notifications needed for ${meetupId}`);
      return null;
    }

    console.log(`Spot available in ${meetupId}, notifying ${waitlistUserIds.length} waitlisted users`);

    const meetupDate = meetupData.date.toDate() as Date;
    const hours = meetupDate.getHours().toString().padStart(2, "0");
    const mins = meetupDate.getMinutes().toString().padStart(2, "0");
    const timeStr = `${hours}:${mins}`;

    const usersById = await getUsersDataMap(waitlistUserIds);
    const eligibleRecipientIds = waitlistUserIds.filter((userId) => {
      const userData = usersById.get(userId);
      return !!userData &&
        shouldSendNotification(userData.notificationPreferences, "spot_available");
    });

    if (eligibleRecipientIds.length > 0) {
      await createNotificationDocumentsBatch(
        eligibleRecipientIds.map((userId) => ({
          userId,
          deterministicId: `spot_available_${userId}_${meetupId}`,
          type: "spot_available",
          title: `${chatTitle} - Kontenjan Acildi!`,
          message: `Etkinlikte yer acildi! ${timeStr}'de baslayacak.`,
          relatedId: meetupId,
          metadata: { chatTitle, time: timeStr },
        }))
      );

      await sendBulkPushNotification(
        usersById,
        eligibleRecipientIds,
        `${chatTitle} - Kontenjan Acildi!`,
        "Etkinlikte yer acildi! Hemen katilabilirsiniz.",
        { type: "spot_available", relatedId: meetupId }
      );
    }

    await syncMeetupChatShell(meetupId, meetupData);
    await deleteMeetupChatSummaries(meetupId, [participantId]);
    console.log(`Waitlist notifications sent for ${meetupId}`);
    return null;
  });

// 6. Meetup deleted - unregister all participants if meetup not finished yet
export const onMeetupDeleted = eventSyncRuntime.firestore
  .document("meetups/{meetupId}")
  .onDelete(async (snap, context) => {
    const { meetupId } = context.params;
    const meetupData = snap.data() || {};

    const participantIds = (meetupData.participantIds as string[]) || [];
    if (participantIds.length === 0) return null;

    const dateTs = meetupData.date as Timestamp | undefined;
    const endTs = meetupData.endDate as Timestamp | undefined;
    const effectiveEnd = (endTs ?? dateTs)?.toDate();
    if (!effectiveEnd || effectiveEnd.getTime() <= Date.now()) {
      try {
        await db.collection("chats").doc(meetupId).delete();
      } catch (error) {
        console.error(`Meetup chat shell delete failed for ${meetupId}:`, error);
      }
      await deleteMeetupChatSummaries(meetupId, participantIds);
      return null;
    }

    const updates = participantIds.map(async (userId) => {
      try {
        await adjustRegisteredCounter(userId, -1);
      } catch (error) {
        console.error(`Meetup delete unregister failed for meetup ${meetupId}, user ${userId}:`, error);
      }
    });
    await Promise.all(updates);
    try {
      await db.collection("chats").doc(meetupId).delete();
    } catch (error) {
      console.error(`Meetup chat shell delete failed for ${meetupId}:`, error);
    }
    await deleteMeetupChatSummaries(meetupId, participantIds);
    return null;
  });

export const backfillMeetupChatSummaries = maintenanceRuntime.pubsub
  .schedule("every 6 hours")
  .timeZone("Europe/Istanbul")
  .onRun(async () => {
    const now = new Date();
    const lookback = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const horizon = new Date(now.getTime() + 60 * 24 * 60 * 60 * 1000);
    const pageSize = 150;
    let scannedMeetups = 0;
    let writtenSummaries = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;
    let hasMoreMeetups = true;

    while (hasMoreMeetups) {
      let query = db.collection("meetups")
        .where("date", ">=", Timestamp.fromDate(lookback))
        .where("date", "<=", Timestamp.fromDate(horizon))
        .orderBy("date")
        .limit(pageSize);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const meetupsSnapshot = await query.get();
      if (meetupsSnapshot.empty) break;

      scannedMeetups += meetupsSnapshot.size;

      for (const meetupDoc of meetupsSnapshot.docs) {
        let meetupData = meetupDoc.data() || {};
        const derivedFields = buildMeetupDerivedFields(meetupData);
        if (needsMeetupDerivedFieldSync(meetupData, derivedFields)) {
          await meetupDoc.ref.set(derivedFields, { merge: true });
          meetupData = { ...meetupData, ...derivedFields };
        }

        const participantIds = (meetupData.participantIds as string[]) || [];
        if (participantIds.length === 0) {
          continue;
        }

        await syncMeetupChatShell(meetupDoc.id, meetupData);
        await upsertMeetupChatSummaries(meetupDoc.id, meetupData, participantIds);
        writtenSummaries += participantIds.length;
      }

      lastDoc = meetupsSnapshot.docs[meetupsSnapshot.docs.length - 1];
      hasMoreMeetups = meetupsSnapshot.size === pageSize;
    }

    console.log(
      `Meetup chat summary backfill done. Scanned ${scannedMeetups} meetups, upserted ${writtenSummaries} summaries.`
    );
    return null;
  });

// 7. Meetup Reminder (Scheduled - runs every 15 minutes)
export const meetupReminder = maintenanceRuntime.pubsub
  .schedule("every 15 minutes")
  .timeZone("Europe/Istanbul")
  .onRun(async () => {
    const now = new Date();
    const oneHourLater = new Date(now.getTime() + 60 * 60 * 1000);
    const fifteenMinutesLater = new Date(now.getTime() + 15 * 60 * 1000);
    const pageSize = 100;
    let scannedMeetups = 0;
    let sentReminders = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    let hasMoreMeetups = true;
    while (hasMoreMeetups) {
      let query = db.collection("meetups")
        .where("date", ">=", Timestamp.fromDate(fifteenMinutesLater))
        .where("date", "<=", Timestamp.fromDate(oneHourLater))
        .orderBy("date")
        .limit(pageSize);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const meetupsSnapshot = await query.get();
      if (meetupsSnapshot.empty) break;

      scannedMeetups += meetupsSnapshot.size;

      for (const meetupDoc of meetupsSnapshot.docs) {
        const meetupId = meetupDoc.id;
        const meetupData = meetupDoc.data();

        if (meetupData.reminderSent) {
          continue;
        }

        const chatTitle = meetupData.title as string;
        const meetupDate = meetupData.date.toDate() as Date;
        const participantIds = (meetupData.participantIds as string[]) || [];
        const locationName = meetupData.locationName as string;

        const hours = meetupDate.getHours().toString().padStart(2, "0");
        const mins = meetupDate.getMinutes().toString().padStart(2, "0");
        const timeStr = `${hours}:${mins}`;

        const usersById = await getUsersDataMap(participantIds);
        const eligibleRecipientIds = participantIds.filter((userId) => {
          const userData = usersById.get(userId);
          if (!userData) return false;
          return shouldSendNotification(userData.notificationPreferences, "meetup_reminder");
        });

        if (eligibleRecipientIds.length > 0) {
          const reminderTitle = `${chatTitle} - 1 Saat Kaldi!`;
          const reminderBody = `Etkinlik ${timeStr}de ${locationName} konumunda baslayacak.`;

          await createNotificationDocumentsBatch(
            eligibleRecipientIds.map((userId) => ({
              userId,
              type: "meetup_reminder",
              title: reminderTitle,
              message: reminderBody,
              relatedId: meetupId,
              metadata: { chatTitle, time: timeStr, location: locationName },
              deterministicId: `reminder_${userId}_${meetupId}`,
            }))
          );

          await sendBulkPushNotification(
            usersById,
            eligibleRecipientIds,
            reminderTitle,
            reminderBody,
            { type: "meetup_reminder", relatedId: meetupId }
          );
        }

        await meetupDoc.ref.update({ reminderSent: true });
        sentReminders++;
      }

      lastDoc = meetupsSnapshot.docs[meetupsSnapshot.docs.length - 1];
      hasMoreMeetups = meetupsSnapshot.size === pageSize;
    }

    console.log(`Meetup reminder scan done. Scanned ${scannedMeetups} meetups, sent ${sentReminders} reminders.`);
    return null;
  });

// 8. Cleanup Old Notifications (Scheduled - runs daily)
export const cleanupOldNotifications = maintenanceRuntime.pubsub
  .schedule("every 24 hours")
  .timeZone("Europe/Istanbul")
  .onRun(async () => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const pageSize = 500;
    let deletedCount = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    let hasMoreNotifications = true;
    while (hasMoreNotifications) {
      let query = db.collection("notifications")
        .where("timestamp", "<", Timestamp.fromDate(thirtyDaysAgo))
        .orderBy("timestamp")
        .limit(pageSize);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const oldNotifications = await query.get();
      if (oldNotifications.empty) break;

      const batch = db.batch();
      oldNotifications.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      deletedCount += oldNotifications.size;
      lastDoc = oldNotifications.docs[oldNotifications.docs.length - 1];
      hasMoreNotifications = oldNotifications.size === pageSize;
    }

    console.log(`Deleted ${deletedCount} old notifications`);

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
      "Sporsal'a HoÅŸ Geldin! ğŸ‰",
      `Merhaba ${username}! Spor arkadaÅŸlarÄ±nla tanÄ±ÅŸmaya hazÄ±r mÄ±sÄ±n?`,
      "",
      {}
    );

    console.log(`Welcome notification created for user ${userId}`);
    return null;
  });

// 10. GPS Proximity Attendance Record Reliability Sync
// Reliability formula uses ALL registered meetups in denominator.
export const onAttendanceRecordCreated = interactiveRuntime.firestore
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
export const processAttendanceCutoffs = maintenanceRuntime.pubsub
  .schedule("every 30 minutes")
  .timeZone("Europe/Istanbul")
  .onRun(async () => {
    const now = new Date();
    const lookback = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const pageSize = 250;
    let createdCount = 0;
    let scannedMeetups = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    let hasMoreCutoffMeetups = true;
    while (hasMoreCutoffMeetups) {
      let query = db.collection("meetups")
        .where("date", ">=", Timestamp.fromDate(lookback))
        .where("date", "<=", Timestamp.fromDate(now))
        .orderBy("date")
        .limit(pageSize);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const meetupsSnapshot = await query.get();
      if (meetupsSnapshot.empty) break;

      scannedMeetups += meetupsSnapshot.size;

      for (const meetupDoc of meetupsSnapshot.docs) {
        const meetupData = meetupDoc.data();
        const participantIds = (meetupData.participantIds as string[]) || [];
        if (participantIds.length < 2) continue;

        const startTs = meetupData.date as Timestamp | undefined;
        if (!startTs) continue;
        const startDate = startTs.toDate();

        const endTs = meetupData.endDate as Timestamp | undefined;
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

      lastDoc = meetupsSnapshot.docs[meetupsSnapshot.docs.length - 1];
      hasMoreCutoffMeetups = meetupsSnapshot.size === pageSize;
    }

    console.log(
      `Attendance cutoff processor done. Scanned ${scannedMeetups} meetups, created records: ${createdCount}`
    );
    return null;
  });


