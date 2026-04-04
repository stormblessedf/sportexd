"use strict";

const admin = require("firebase-admin");

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--")) {
      continue;
    }

    const eqIndex = token.indexOf("=");
    if (eqIndex >= 0) {
      const key = token.slice(2, eqIndex);
      const value = token.slice(eqIndex + 1);
      args[key] = value === "" ? true : value;
      continue;
    }

    const key = token.slice(2);
    const next = argv[i + 1];
    if (next && !next.startsWith("--")) {
      args[key] = next;
      i += 1;
    } else {
      args[key] = true;
    }
  }
  return args;
}

function normalizeSegment(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function parseIntArg(value, fallback) {
  if (value === undefined || value === null || value === true) {
    return fallback;
  }
  const parsed = Number.parseInt(String(value), 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function parseBoolArg(value, fallback) {
  if (value === undefined) {
    return fallback;
  }
  if (value === true) {
    return true;
  }
  const normalized = String(value).toLowerCase();
  return normalized === "1" || normalized === "true" || normalized === "yes";
}

function hashString(value) {
  let hash = 2166136261;
  for (let i = 0; i < value.length; i += 1) {
    hash ^= value.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function createRng(seedText) {
  let seed = hashString(seedText) || 1;
  return function rng() {
    seed |= 0;
    seed = (seed + 0x6D2B79F5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t ^= t + Math.imul(t ^ (t >>> 7), 61 | t);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function pick(rng, values) {
  return values[Math.floor(rng() * values.length)];
}

function pickMany(rng, values, count, exclude = new Set()) {
  const pool = values.filter((value) => !exclude.has(value));
  const chosen = [];
  while (pool.length > 0 && chosen.length < count) {
    const index = Math.floor(rng() * pool.length);
    chosen.push(pool.splice(index, 1)[0]);
  }
  return chosen;
}

function ts(date) {
  return admin.firestore.Timestamp.fromDate(date);
}

function assertSafeEnvironment(actionLabel) {
  if (process.env.ALLOW_PROD === "true" || process.env.FIRESTORE_EMULATOR_HOST) {
    return;
  }

  throw new Error(
    `Refusing to ${actionLabel} Firestore outside the emulator. Set FIRESTORE_EMULATOR_HOST or ALLOW_PROD=true.`,
  );
}

function initFirestore(projectId) {
  if (admin.apps.length === 0) {
    admin.initializeApp({ projectId });
  }
  const db = admin.firestore();
  db.settings({ ignoreUndefinedProperties: true });
  return db;
}

function buildDatasetKey(prefix, runId) {
  return `${normalizeSegment(prefix)}_${normalizeSegment(runId)}`;
}

function createWriteBuffer(db, maxOps = 400) {
  const writes = [];

  async function flush() {
    if (writes.length === 0) {
      return 0;
    }

    let committed = 0;
    for (let i = 0; i < writes.length; i += maxOps) {
      const batch = db.batch();
      const slice = writes.slice(i, i + maxOps);
      for (const item of slice) {
        if (item.type === "delete") {
          batch.delete(item.ref);
          continue;
        }

        if (item.merge) {
          batch.set(item.ref, item.data, { merge: true });
        } else {
          batch.set(item.ref, item.data);
        }
      }
      await batch.commit();
      committed += slice.length;
    }

    writes.length = 0;
    return committed;
  }

  return {
    set(ref, data, merge = false) {
      writes.push({ ref, data, merge, type: "set" });
    },
    delete(ref) {
      writes.push({ ref, type: "delete" });
    },
    async flush() {
      return flush();
    },
  };
}

async function deleteInChunks(docs, db, maxOps = 400) {
  if (docs.length === 0) {
    return 0;
  }

  let deleted = 0;
  for (let i = 0; i < docs.length; i += maxOps) {
    const batch = db.batch();
    const slice = docs.slice(i, i + maxOps);
    for (const doc of slice) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += slice.length;
  }

  return deleted;
}

function formatDocPath(doc) {
  return doc.ref.path;
}

module.exports = {
  assertSafeEnvironment,
  buildDatasetKey,
  createRng,
  createWriteBuffer,
  deleteInChunks,
  formatDocPath,
  initFirestore,
  parseArgs,
  parseBoolArg,
  parseIntArg,
  pick,
  pickMany,
  ts,
};
