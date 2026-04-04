"use strict";

const crypto = require("crypto");
const {
  assertSafeEnvironment,
  buildDatasetKey,
  createRng,
  createWriteBuffer,
  initFirestore,
  parseArgs,
  parseBoolArg,
  parseIntArg,
  pick,
  pickMany,
  ts,
} = require("./loadtest_lib");

const DEFAULTS = {
  users: 48,
  meetups: 18,
  messagesPerChat: 12,
  prefix: "loadtest",
};

const SPORT_TYPES = [
  { name: "football", title: "Futbol" },
  { name: "basketball", title: "Basketbol" },
  { name: "volleyball", title: "Voleybol" },
  { name: "tennis", title: "Tenis" },
  { name: "running", title: "Kosu" },
  { name: "cycling", title: "Bisiklet" },
  { name: "fitness", title: "Fitness" },
];

const FIRST_NAMES = [
  "Arda",
  "Berk",
  "Can",
  "Deniz",
  "Ece",
  "Firat",
  "Gizem",
  "Hakan",
  "Irem",
  "Jale",
  "Kaan",
  "Lara",
  "Mert",
  "Nehir",
  "Ozan",
  "Pelin",
  "Sena",
  "Tolga",
];

const CITIES = [
  "Kadikoy",
  "Besiktas",
  "Sisli",
  "Atasehir",
  "Uskudar",
  "Bakirkoy",
  "Mecidiyekoy",
  "Maltepe",
];

const LEVELS = ["beginner", "intermediate", "advanced"];
const TIMES = ["morning", "afternoon", "evening"];
const PLAY_STYLES = ["casual", "competitive", "social"];
const TEAM_PREFS = ["mixed", "male", "female", "any"];
const GENDERS = ["male", "female", "other"];

function makeRunId(prefix) {
  const stamp = new Date().toISOString().replace(/[:.]/g, "");
  const suffix = crypto.randomBytes(2).toString("hex");
  return `${prefix}_${stamp}_${suffix}`;
}

function parseOptions() {
  const args = parseArgs(process.argv.slice(2));
  const prefix = args.prefix ? String(args.prefix) : DEFAULTS.prefix;
  const runId = args.runId ? String(args.runId) : makeRunId(prefix);

  return {
    prefix,
    runId,
    projectId:
      args.projectId ||
      process.env.GCLOUD_PROJECT ||
      process.env.GOOGLE_CLOUD_PROJECT ||
      "sportexd-1bb0e",
    users: parseIntArg(args.users, DEFAULTS.users),
    meetups: parseIntArg(args.meetups, DEFAULTS.meetups),
    messagesPerChat: parseIntArg(args.messagesPerChat, DEFAULTS.messagesPerChat),
    materializeSummaries: parseBoolArg(args.materializeSummaries, true),
  };
}

function help() {
  console.log(`Usage:
  node scripts/loadtest_seed.js [options]

Options:
  --runId=<id>               Reuse a previous run id.
  --prefix=<prefix>          Prefix for generated ids. Default: ${DEFAULTS.prefix}
  --projectId=<id>           Firestore project id. Default: env project or sportexd-1bb0e
  --users=<count>            Number of synthetic users. Default: ${DEFAULTS.users}
  --meetups=<count>          Number of meetup chats. Default: ${DEFAULTS.meetups}
  --messagesPerChat=<count>  Messages per seeded chat. Default: ${DEFAULTS.messagesPerChat}
  --materializeSummaries     Write users/{userId}/chat_summaries docs directly. Default: true
`);
}

function normalizeSearchText(input) {
  return String(input)
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9\s]+/g, " ");
}

function computeParticipantState(currentParticipants, maxParticipants) {
  if (!Number.isFinite(maxParticipants) || maxParticipants <= 0) {
    return "has_space";
  }
  if (currentParticipants >= maxParticipants) {
    return "full";
  }
  if (currentParticipants / maxParticipants >= 0.8) {
    return "almost_full";
  }
  return "has_space";
}

function buildSearchKeywords(meetup) {
  return Array.from(
    new Set(
      normalizeSearchText(
        [
          meetup.title,
          meetup.description,
          meetup.locationName,
          meetup.locationAddress,
          meetup.organizerName,
          meetup.type,
        ].join(" "),
      )
        .split(/\s+/)
        .map((token) => token.trim())
        .filter((token) => token.length >= 2),
    ),
  ).sort();
}

function buildUsers({ count, datasetKey, prefix, runId, rng, now }) {
  const users = [];

  for (let i = 0; i < count; i += 1) {
    const first = pick(rng, FIRST_NAMES);
    const city = pick(rng, CITIES);
    const id = `${datasetKey}_user_${String(i + 1).padStart(2, "0")}`;
    const username = `${prefix}_${i + 1}`;
    const sportA = pick(rng, SPORT_TYPES).name;
    const sportB = pick(rng, SPORT_TYPES).name;

    users.push({
      id,
      username,
      email: `${username}@example.test`,
      profileImageUrl: "",
      bio: `${first} icin ${runId} load test profili.`,
      location: city,
      gender: pick(rng, GENDERS),
      birthDate: ts(new Date(Date.UTC(1990 + (i % 10), i % 12, 1))),
      height: 165 + (i % 20),
      weight: 58 + (i % 24),
      interestedSports: [sportA, sportB],
      level: pick(rng, LEVELS),
      preferredTimes: [pick(rng, TIMES)],
      playStyle: pick(rng, PLAY_STYLES),
      teamPreference: pick(rng, TEAM_PREFS),
      lastSeen: ts(new Date(now.getTime() - Math.floor(rng() * 45) * 60000)),
      isOnline: i % 3 !== 0,
      fcmTokens: [],
      notificationPreferences: {
        meetupReminders: true,
        meetupUpdates: true,
        chatMessages: true,
        newParticipants: true,
        systemNotifications: true,
        muteAll: false,
        quietHoursStart: null,
        quietHoursEnd: null,
        mutedChats: [],
      },
      processedAttendanceIds: [],
      isPremium: i % 11 === 0,
      premiumUntil: null,
      createdAt: ts(new Date(now.getTime() - (10 + i) * 24 * 60 * 60 * 1000)),
      loadTestRunId: runId,
      loadTestPrefix: prefix,
      seededBy: "load-test",
    });
  }

  return users;
}

function buildMeetups({
  count,
  datasetKey,
  prefix,
  runId,
  rng,
  now,
  users,
  messagesPerChat,
}) {
  const writes = [];

  for (let i = 0; i < count; i += 1) {
    const sport = pick(rng, SPORT_TYPES);
    const organizer = users[i % users.length];
    const inviteStyle = i % 6 === 0;
    const meetupId = `${datasetKey}_meetup_${String(i + 1).padStart(2, "0")}`;
    const meetupDate = new Date(now.getTime() + (i - 6) * 6 * 60 * 60 * 1000);
    const endDate = new Date(meetupDate.getTime() + 90 * 60 * 1000);
    const createdAt = new Date(meetupDate.getTime() - 2 * 24 * 60 * 60 * 1000);
    const maxParticipants = inviteStyle ? 2 : 8 + (i % 3);
    const participantTarget = inviteStyle ? 1 : 4 + (i % 4);
    const participantIds = [organizer.id];
    const extraParticipants = pickMany(
      rng,
      users.map((user) => user.id),
      Math.max(0, Math.min(participantTarget - 1, users.length - 1)),
      new Set([organizer.id]),
    );

    for (const participantId of extraParticipants) {
      participantIds.push(participantId);
    }

    const waitlistUserIds = [];
    if (!inviteStyle && participantIds.length >= maxParticipants) {
      waitlistUserIds.push(
        ...pickMany(rng, users.map((user) => user.id), 2, new Set(participantIds)),
      );
    }

    const currentParticipants = participantIds.length;
    const isFull = currentParticipants >= maxParticipants;
    const participantState = computeParticipantState(currentParticipants, maxParticipants);
    const availableSpots = Math.max(0, maxParticipants - currentParticipants);
    const hiddenUntilAccepted = inviteStyle;
    const messageCount = Math.max(1, messagesPerChat);
    const messages = [];
    const lastMessageTime = new Date(endDate.getTime() - 10 * 60 * 1000);

    for (let j = 0; j < messageCount; j += 1) {
      const senderId = participantIds[(j + i) % participantIds.length];
      const sender = users.find((user) => user.id === senderId) || organizer;
      const messageTime = new Date(
        lastMessageTime.getTime() - (messageCount - j - 1) * 6 * 60 * 1000,
      );

      messages.push({
        id: `${meetupId}_message_${String(j + 1).padStart(3, "0")}`,
        senderId: sender.id,
        senderName: sender.username,
        senderImageUrl: sender.profileImageUrl || "",
        text: `Run ${runId} | ${sport.title} meetup ${i + 1} | message ${j + 1}`,
        imageUrl: null,
        type: "text",
        timestamp: ts(messageTime),
        loadTestRunId: runId,
        loadTestPrefix: prefix,
      });
    }

    const finalMessage = messages[messages.length - 1];
    const unreadCounts = {};
    for (const participantId of participantIds) {
      unreadCounts[participantId] =
        participantId === finalMessage.senderId ? 0 : 1 + Math.floor(rng() * 4);
    }

    const meetup = {
      id: meetupId,
      title: `${sport.title} Toplantisi ${i + 1}`,
      description: `Run ${runId} icin ${sport.title.toLowerCase()} load test meetup'i.`,
      rules: "Zamaninda gel, saygili ol, no-show yapma.",
      imageUrl: "",
      type: sport.name,
      date: ts(meetupDate),
      endDate: ts(endDate),
      locationName: `${sport.title} Sahasi ${i + 1}`,
      locationAddress: `${10 + i} Test Sokak, ${organizer.location}`,
      organizerId: organizer.id,
      organizerName: organizer.username,
      organizerImageUrl: organizer.profileImageUrl || null,
      organizerRating: 4.4 + ((i % 5) * 0.1),
      currentParticipants,
      maxParticipants,
      hideFromFeedUntilAccepted: hiddenUntilAccepted,
      isFull,
      participantState,
      availableSpots,
      participantIds,
      waitlistUserIds,
      latitude: 41.0 + (i % 10) * 0.01,
      longitude: 29.0 + (i % 10) * 0.01,
      isOrganizerOnlyChat: false,
      createdAt: ts(createdAt),
      teamFormat: null,
      formation: null,
      teamASlots: null,
      teamBSlots: null,
      routeData: null,
      searchKeywords: [],
      loadTestRunId: runId,
      loadTestPrefix: prefix,
      seededBy: "load-test",
    };
    meetup.searchKeywords = buildSearchKeywords(meetup);

    const chat = {
      type: "meetup",
      participants: participantIds,
      participantIds,
      title: meetup.title,
      description: meetup.description,
      rules: meetup.rules,
      imageUrl: meetup.imageUrl,
      meetupType: meetup.type,
      organizerId: meetup.organizerId,
      organizerName: meetup.organizerName,
      organizerImageUrl: meetup.organizerImageUrl,
      locationName: meetup.locationName,
      locationAddress: meetup.locationAddress,
      currentParticipants,
      maxParticipants,
      waitlistUserIds,
      participantState,
      availableSpots,
      latitude: meetup.latitude,
      longitude: meetup.longitude,
      hideFromFeedUntilAccepted: hiddenUntilAccepted,
      isFull,
      searchKeywords: meetup.searchKeywords,
      meetupDate: meetup.date,
      endDate: meetup.endDate,
      createdAt: meetup.createdAt,
      lastMessage: finalMessage.text,
      lastMessageTime: finalMessage.timestamp,
      lastMessageSenderId: finalMessage.senderId,
      lastMessageSenderName: finalMessage.senderName,
      unreadCounts,
      updatedAt: finalMessage.timestamp,
      loadTestRunId: runId,
      loadTestPrefix: prefix,
      seededBy: "load-test",
    };

    const summaries = participantIds.map((participantId) => ({
      userId: participantId,
      data: {
        chatId: meetupId,
        title: meetup.title,
        imageUrl: meetup.imageUrl,
        meetupType: meetup.type,
        meetupDate: meetup.date,
        meetupEndDate: meetup.endDate,
        meetupCreatedAt: meetup.createdAt,
        lastMessage: finalMessage.text,
        lastMessageTime: finalMessage.timestamp,
        lastMessageSenderId: finalMessage.senderId,
        lastMessageSenderName: finalMessage.senderName,
        unreadCount: unreadCounts[participantId] || 0,
        isOrganizerOnlyMode: false,
        updatedAt: finalMessage.timestamp,
        loadTestRunId: runId,
        loadTestPrefix: prefix,
        seededBy: "load-test",
      },
    }));

    writes.push({ chatId: meetupId, meetup, chat, messages, summaries });
  }

  return writes;
}

async function seedLoadTest() {
  if (process.argv.includes("--help") || process.argv.includes("-h")) {
    help();
    return;
  }

  const options = parseOptions();
  assertSafeEnvironment("seed");
  const db = initFirestore(options.projectId);
  const rng = createRng(`${options.prefix}:${options.runId}`);
  const datasetKey = buildDatasetKey(options.prefix, options.runId);
  const now = new Date();
  const users = buildUsers({
    count: options.users,
    datasetKey,
    prefix: options.prefix,
    runId: options.runId,
    rng,
    now,
  });
  const writes = buildMeetups({
    count: options.meetups,
    datasetKey,
    prefix: options.prefix,
    runId: options.runId,
    rng,
    now,
    users,
    messagesPerChat: options.messagesPerChat,
  });

  const buffer = createWriteBuffer(db, 400);

  for (const user of users) {
    buffer.set(db.collection("users").doc(user.id), user);
  }

  for (const item of writes) {
    const meetupRef = db.collection("meetups").doc(item.meetup.id);
    const chatRef = db.collection("chats").doc(item.chatId);

    buffer.set(meetupRef, item.meetup);
    buffer.set(chatRef, item.chat);

    for (const participantId of item.meetup.participantIds) {
      buffer.set(meetupRef.collection("participants").doc(participantId), {
        userId: participantId,
        joinedAt: item.meetup.createdAt,
        loadTestRunId: options.runId,
        loadTestPrefix: options.prefix,
        seededBy: "load-test",
      });
    }

    for (const message of item.messages) {
      buffer.set(chatRef.collection("messages").doc(message.id), message);
    }

    if (options.materializeSummaries) {
      for (const summary of item.summaries) {
        buffer.set(
          db
            .collection("users")
            .doc(summary.userId)
            .collection("chat_summaries")
            .doc(item.chatId),
          summary.data,
        );
      }
    }
  }

  const written = await buffer.flush();
  console.log(
    JSON.stringify(
      {
        runId: options.runId,
        prefix: options.prefix,
        projectId: options.projectId,
        users: users.length,
        meetups: writes.length,
        messagesPerChat: options.messagesPerChat,
        summariesMaterialized: options.materializeSummaries,
        writes: written,
      },
      null,
      2,
    ),
  );
}

if (require.main === module) {
  seedLoadTest().catch((error) => {
    console.error("Seed failed:", error);
    process.exitCode = 1;
  });
}

module.exports = { seedLoadTest };
