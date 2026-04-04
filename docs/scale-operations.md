# Scale Operations

This repo now has three production-hardening layers for the 10k-user target:

1. Feed queries push more filtering into Firestore instead of client-side filtering.
2. Chat list reads use per-user meetup summaries at `users/{userId}/chat_summaries/{chatId}` with legacy fallback still in place.
3. High-volume Functions use controlled runtime limits, scheduled maintenance jobs paginate, and chat summary backfill runs automatically every 6 hours.

## Runtime Baseline

- Cloud Functions runtime: Node.js 22
- Firebase Admin SDK: current 13.x line
- Firebase Functions SDK: current 7.x line using the v1 trigger API surface for low-risk compatibility

## Phase 4 Part 1 Scope

This prep layer is complete when all of the following are true:

- one canonical seed script exists
- one canonical verify script exists
- one canonical cleanup script exists
- package scripts and docs point to the same files
- seeded meetups include the same derived fields used by production queries
- verification checks summary coverage, unread consistency, and derived-field consistency
- scripts refuse to touch non-emulator Firestore unless `ALLOW_PROD=true` is set deliberately

## Emulator Load Test

Prerequisites:

- Run commands from the repo root.
- Install Functions dependencies once with `npm --prefix functions install`.
- Use the canonical `npm --prefix functions run loadtest:*` commands below. They point to `functions/scripts/loadtest_*.js`.
- On Windows, Phase 4 uses the dedicated `firebase.phase4.json` config and `start_phase4_emulator.cmd` launcher so the load-test emulator can run on alternate ports with JDK 21.

Start emulators in one terminal:

```powershell
cmd /c start_phase4_emulator.cmd
```

Alternative manual command:

```powershell
cmd /c "set JAVA_HOME=C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot && set PATH=C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot\bin;%PATH% && firebase emulators:start --only firestore,functions --config firebase.phase4.json"
```

Seed synthetic data in another terminal:

```powershell
$env:FIRESTORE_EMULATOR_HOST="127.0.0.1:28080"
npm --prefix functions run loadtest:seed -- --runId scale_smoke --prefix scale --users 200 --meetups 60 --messagesPerChat 12
```

Verify dataset integrity:

```powershell
$env:FIRESTORE_EMULATOR_HOST="127.0.0.1:28080"
npm --prefix functions run loadtest:verify -- --runId scale_smoke
```

Clean up:

```powershell
$env:FIRESTORE_EMULATOR_HOST="127.0.0.1:28080"
npm --prefix functions run loadtest:cleanup -- --runId scale_smoke
```

## What To Check

- Active chats page loads from summary docs without opening one stream per chat card.
- Past chats page still renders correctly when summaries exist.
- New chat messages update `chats/{chatId}` preview fields and fan out unread counts without per-user transactions.
- `users/{userId}/chat_summaries/{chatId}` count matches meetup participant count.
- Seeded meetups contain `participantState`, `availableSpots`, and `searchKeywords`.
- Seeded chat shells mirror meetup-derived fields used by production feed and summary logic.
- Cleanup dry-runs include side-effect notifications written by Functions triggers for seeded users.
- Scheduled jobs do not attempt full-collection scans in a single run.

## Canonical Scripts

- Seed: `functions/scripts/loadtest_seed.js`
- Verify: `functions/scripts/loadtest_verify_chat_summaries.js`
- Cleanup: `functions/scripts/loadtest_cleanup.js`
- Windows launcher: `start_phase4_emulator.cmd`
- Alternate-port emulator config: `firebase.phase4.json`

## Production Rollout Checklist

1. Deploy Functions and Firestore rules/indexes together.
2. Wait for the scheduled `backfillMeetupChatSummaries` run or trigger an equivalent manual backfill if the backlog is large.
3. Smoke test:
   - open active chats
   - open past chats
   - send a meetup chat message
   - confirm notification unread badge clears after opening the chat
   - confirm feed search/filter still returns seeded meetups by title or location token
4. Watch Functions logs for:
   - `onChatMessage`
   - `onChatMetadataWrite`
   - `backfillMeetupChatSummaries`
   - `processAttendanceCutoffs`

## Safety Notes

- The load-test scripts refuse to run outside the Firestore emulator unless `ALLOW_PROD=true` is set explicitly.
- Seeded documents are tagged with `loadTestRunId` so they can be verified and removed safely.
- Seeded documents also carry `loadTestPrefix` so a batch of runs can be cleaned together if needed.
- `loadtest:cleanup:dry` prints matching document counts without deleting them.
