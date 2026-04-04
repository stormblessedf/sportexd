"use strict";

const {
  assertSafeEnvironment,
  initFirestore,
  parseArgs,
} = require("./loadtest_lib");

function parseOptions() {
  const args = parseArgs(process.argv.slice(2));
  return {
    runId: args.runId ? String(args.runId) : null,
    prefix: args.prefix ? String(args.prefix) : null,
    projectId:
      args.projectId ||
      process.env.GCLOUD_PROJECT ||
      process.env.GOOGLE_CLOUD_PROJECT ||
      "sportexd-1bb0e",
  };
}

function help() {
  console.log(`Usage:
  node scripts/loadtest_verify_chat_summaries.js [options]

Options:
  --runId=<id>      Verify a single seeded run.
  --prefix=<prefix> Verify all seeded docs with the prefix.
  --projectId=<id>  Firestore project id. Default: env project or sportexd-1bb0e
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

function arraysEqual(left, right) {
  if (!Array.isArray(left) || !Array.isArray(right) || left.length !== right.length) {
    return false;
  }
  return left.every((value, index) => value === right[index]);
}

async function fetchDocs(db, collectionName, fieldName, fieldValue) {
  const snapshot = await db.collection(collectionName).where(fieldName, "==", fieldValue).get();
  return snapshot.docs;
}

async function fetchGroupDocs(db, collectionName, fieldName, fieldValue) {
  const snapshot = await db.collectionGroup(collectionName).where(fieldName, "==", fieldValue).get();
  return snapshot.docs;
}

async function verifyLoadTest() {
  if (process.argv.includes("--help") || process.argv.includes("-h")) {
    help();
    return;
  }

  const options = parseOptions();
  if (!options.runId && !options.prefix) {
    throw new Error("Provide --runId or --prefix.");
  }

  assertSafeEnvironment("verify");
  const db = initFirestore(options.projectId);
  const fieldName = options.runId ? "loadTestRunId" : "loadTestPrefix";
  const fieldValue = options.runId || options.prefix;

  const [meetupDocs, chatDocs, summaryDocs, messageDocs, userDocs] = await Promise.all([
    fetchDocs(db, "meetups", fieldName, fieldValue),
    fetchDocs(db, "chats", fieldName, fieldValue),
    fetchGroupDocs(db, "chat_summaries", fieldName, fieldValue),
    fetchGroupDocs(db, "messages", fieldName, fieldValue),
    fetchDocs(db, "users", fieldName, fieldValue),
  ]);

  const chatById = new Map(chatDocs.map((doc) => [doc.id, doc.data()]));
  const summaryCounts = new Map();
  const summaryByParticipantAndChat = new Map();
  const messageCounts = new Map();
  const errors = [];

  for (const summaryDoc of summaryDocs) {
    const data = summaryDoc.data();
    const chatId = data.chatId || summaryDoc.id;
    const participantId = summaryDoc.ref.parent.parent.id;
    summaryCounts.set(chatId, (summaryCounts.get(chatId) || 0) + 1);
    summaryByParticipantAndChat.set(`${participantId}:${chatId}`, data);
  }

  for (const messageDoc of messageDocs) {
    const chatId = messageDoc.ref.parent.parent.id;
    messageCounts.set(chatId, (messageCounts.get(chatId) || 0) + 1);
  }

  for (const meetupDoc of meetupDocs) {
    const meetup = meetupDoc.data();
    const participantIds = meetup.participantIds || [];
    const expectedParticipantState = computeParticipantState(
      meetup.currentParticipants || 0,
      meetup.maxParticipants || 0,
    );
    const expectedAvailableSpots = Math.max(
      0,
      (meetup.maxParticipants || 0) - (meetup.currentParticipants || 0),
    );
    const expectedKeywords = buildSearchKeywords(meetup);
    const chat = chatById.get(meetupDoc.id);

    if (!chat) {
      errors.push({ type: "missing_chat", meetupId: meetupDoc.id });
      continue;
    }

    if ((summaryCounts.get(meetupDoc.id) || 0) !== participantIds.length) {
      errors.push({
        type: "summary_count_mismatch",
        meetupId: meetupDoc.id,
        expected: participantIds.length,
        actual: summaryCounts.get(meetupDoc.id) || 0,
      });
    }

    if ((messageCounts.get(meetupDoc.id) || 0) === 0) {
      errors.push({ type: "missing_messages", meetupId: meetupDoc.id });
    }

    if (meetup.participantState !== expectedParticipantState) {
      errors.push({ type: "meetup_participant_state_mismatch", meetupId: meetupDoc.id });
    }

    if (meetup.availableSpots !== expectedAvailableSpots) {
      errors.push({ type: "meetup_available_spots_mismatch", meetupId: meetupDoc.id });
    }

    if (!arraysEqual(meetup.searchKeywords || [], expectedKeywords)) {
      errors.push({ type: "meetup_search_keywords_mismatch", meetupId: meetupDoc.id });
    }

    if (!arraysEqual(chat.participantIds || [], participantIds)) {
      errors.push({ type: "chat_participants_mismatch", meetupId: meetupDoc.id });
    }

    if (chat.participantState !== meetup.participantState) {
      errors.push({ type: "chat_participant_state_mismatch", meetupId: meetupDoc.id });
    }

    if (chat.availableSpots !== meetup.availableSpots) {
      errors.push({ type: "chat_available_spots_mismatch", meetupId: meetupDoc.id });
    }

    if (!arraysEqual(chat.searchKeywords || [], meetup.searchKeywords || [])) {
      errors.push({ type: "chat_search_keywords_mismatch", meetupId: meetupDoc.id });
    }

    for (const participantId of participantIds) {
      const unreadCounts = chat.unreadCounts || {};
      if (typeof unreadCounts[participantId] !== "number") {
        errors.push({ type: "missing_unread_count", meetupId: meetupDoc.id, participantId });
      }

      const summary = summaryByParticipantAndChat.get(`${participantId}:${meetupDoc.id}`);
      if (!summary) {
        errors.push({ type: "missing_chat_summary", meetupId: meetupDoc.id, participantId });
        continue;
      }

      if (summary.unreadCount !== unreadCounts[participantId]) {
        errors.push({ type: "summary_unread_mismatch", meetupId: meetupDoc.id, participantId });
      }
    }
  }

  console.log(
    JSON.stringify(
      {
        runId: options.runId,
        prefix: options.prefix,
        users: userDocs.length,
        meetups: meetupDocs.length,
        chats: chatDocs.length,
        chatSummaries: summaryDocs.length,
        messages: messageDocs.length,
        errors,
      },
      null,
      2,
    ),
  );

  if (errors.length > 0) {
    process.exitCode = 2;
  }
}

if (require.main === module) {
  verifyLoadTest().catch((error) => {
    console.error("Verify failed:", error);
    process.exitCode = 1;
  });
}

module.exports = { verifyLoadTest };
