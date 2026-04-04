"use strict";

const {
  assertSafeEnvironment,
  deleteInChunks,
  formatDocPath,
  initFirestore,
  parseArgs,
  parseBoolArg,
  parseIntArg,
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
    dryRun: parseBoolArg(args.dryRun, false),
    batchSize: parseIntArg(args.batchSize, 400),
  };
}

function help() {
  console.log(`Usage:
  node scripts/loadtest_cleanup.js [options]

Options:
  --runId=<id>        Remove a single seeded run.
  --prefix=<prefix>   Remove all seeded docs with the prefix.
  --projectId=<id>    Firestore project id. Default: env project or sportexd-1bb0e
  --dryRun            Print counts without deleting.
  --batchSize=<n>     Batch size for deletes. Default: 400
`);
}

async function fetchDocsByField(db, collectionName, fieldName, value) {
  const snapshot = await db.collection(collectionName).where(fieldName, "==", value).get();
  return snapshot.docs;
}

async function fetchGroupDocsByField(db, collectionName, fieldName, value) {
  const snapshot = await db.collectionGroup(collectionName).where(fieldName, "==", value).get();
  return snapshot.docs;
}

function chunkArray(values, size) {
  const chunks = [];
  for (let index = 0; index < values.length; index += size) {
    chunks.push(values.slice(index, index + size));
  }
  return chunks;
}

async function fetchDocsByValues(db, collectionName, fieldName, values) {
  const uniqueValues = [...new Set(values)].filter(Boolean);
  if (uniqueValues.length === 0) {
    return [];
  }

  const docs = [];
  for (const valueChunk of chunkArray(uniqueValues, 30)) {
    const snapshot = await db
      .collection(collectionName)
      .where(fieldName, "in", valueChunk)
      .get();
    docs.push(...snapshot.docs);
  }

  const deduped = new Map();
  for (const doc of docs) {
    deduped.set(doc.id, doc);
  }
  return [...deduped.values()];
}

async function cleanupLoadTest() {
  if (process.argv.includes("--help") || process.argv.includes("-h")) {
    help();
    return;
  }

  const options = parseOptions();
  if (!options.runId && !options.prefix) {
    throw new Error("Provide --runId or --prefix.");
  }

  assertSafeEnvironment("delete");
  const db = initFirestore(options.projectId);
  const fieldName = options.runId ? "loadTestRunId" : "loadTestPrefix";
  const fieldValue = options.runId || options.prefix;

  const userDocs = await fetchDocsByField(db, "users", fieldName, fieldValue);
  const userIds = userDocs.map((doc) => doc.id);

  const groups = [
    { name: "messages", docs: await fetchGroupDocsByField(db, "messages", fieldName, fieldValue) },
    {
      name: "chat_summaries",
      docs: await fetchGroupDocsByField(db, "chat_summaries", fieldName, fieldValue),
    },
  ];

  const roots = [
    { name: "users", docs: userDocs },
    { name: "meetups", docs: await fetchDocsByField(db, "meetups", fieldName, fieldValue) },
    { name: "chats", docs: await fetchDocsByField(db, "chats", fieldName, fieldValue) },
    { name: "swipe_invites", docs: await fetchDocsByField(db, "swipe_invites", fieldName, fieldValue) },
    { name: "swipe_actions", docs: await fetchDocsByField(db, "swipe_actions", fieldName, fieldValue) },
    {
      name: "notifications",
      docs: await fetchDocsByValues(db, "notifications", "userId", userIds),
    },
    { name: "partners", docs: await fetchDocsByField(db, "partners", fieldName, fieldValue) },
  ];

  const summary = [...groups, ...roots].map((entry) => ({
    name: entry.name,
    count: entry.docs.length,
    samples: entry.docs.slice(0, 3).map(formatDocPath),
  }));

  console.log(
    JSON.stringify(
      {
        runId: options.runId,
        prefix: options.prefix,
        dryRun: options.dryRun,
        summary,
      },
      null,
      2,
    ),
  );

  if (options.dryRun) {
    return;
  }

  const deletedCounts = [];
  for (const entry of groups) {
    deletedCounts.push({
      name: entry.name,
      deleted: await deleteInChunks(entry.docs, db, options.batchSize),
    });
  }

  for (const entry of roots) {
    deletedCounts.push({
      name: entry.name,
      deleted: await deleteInChunks(entry.docs, db, options.batchSize),
    });
  }

  console.log(
    JSON.stringify(
      {
        runId: options.runId,
        prefix: options.prefix,
        deletedCounts,
      },
      null,
      2,
    ),
  );
}

if (require.main === module) {
  cleanupLoadTest().catch((error) => {
    console.error("Cleanup failed:", error);
    process.exitCode = 1;
  });
}

module.exports = { cleanupLoadTest };
