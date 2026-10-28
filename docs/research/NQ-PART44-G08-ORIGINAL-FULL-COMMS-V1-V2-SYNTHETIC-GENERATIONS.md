# Part 44 Gate08 — full authentic 335 QuestieComms V1/V2 broadcast lifetime

**28 October 2026 · PUBLIC-SAFE TEST-ONLY · NO ACTUAL MESSAGES, ZIP, CLIENT, RELEASE, MERGE OR PRODUCTION CODE EDITS**

## Exact original source and provenance

Immutable protected public `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, genuine original `Modules/Network/QuestieComms.lua`, Git blob `400dbfaec895517cea7cd283e6ec20404f46a7b7`. A dedicated read-only CI authenticates the original commit/blob. The Lua test loads the **entire original unmodified 1,099-line file**, then invokes the **real complete** `_QuestieComms:BroadcastQuestLog` (V1), `_QuestieComms:BroadcastQuestLogV2` (V2), `QuestieComms:CreateQuestDataPacket`, `QuestieComms:PopulateQuestDataPacketV2_noclass_renameme`, `_QuestieComms:CreatePacket`, `_QuestieComms:Broadcast`, and real delayed-timer closures.

Full module loading does **not** mean every original network function or the native addon executed: the host `QuestieLoader`, `QuestieDB`, `QuestiePlayer`, `QuestLogCache`, `ZoneDB`, `HereBeDragons`, `QuestieSerializer`, `C_Timer` and `Questie` are all invented. The fake `Questie:SendCommMessage` only appends a record to an in-memory Lua table. The test **cannot send a real message**, contacts no remote service/realm/player, does not register the network subsystem and does not access SavedVariables.

## Real source boundary

Both V1 and V2 independently:
1. Read `QuestLogCache.questLog_DO_NOT_MODIFY`, test `QuestieDB.QuestPointers[questId]` (V1 at lines 530–536; V2 at 647–653), then separately query `QuestieDB.QueryQuestSingle(questId, "zoneOrSort")` (V1 line 541; V2 line 658) and numerically test `entry.zoneOrSort > 0` (545, 662).
2. Construct sorted quest entries, then packet data using the **real** original quest packet builders and `QuestieSerializer:Serialize` interface (fake codec).
3. Delay actual `CreatePacket` / `packet:write()` / `Broadcast` through `C_Timer.After` then `C_Timer.NewTicker` (fake scheduler, actual source callbacks).
4. Hold packet blocks in callback closures across the deliberate delay. There is no visible read-generation/epoch lease or later `QuestieDB` revalidation before original `packet:write()`.

## Expected controls (not green until original-head CI independently inspected)

The fixture proposes **46 checks per real Lua 5.1.5/5.4.6 interpreter**, including:
- Exact original source anchors; full file loaded, V1+V2 functions exist.
- Coherent fictional OLD V1: original membership, numeric zone/HBD distance, objective packet assembly, delayed original packet write, party dispatch through fake captured `SendCommMessage`, completion clears broadcast flag.
- Coherent fictional NEW V2: original objective packet offset/array representation and count, whisper target/mode, delayed send and completion.
- Deliberately mixed OLD pointer/NEW zone and NEW pointer/OLD zone: each real original V1/V2 function can throw on `nil > 0` **before** scheduling an outbound timer. This is a *constructed mixed input* witness, not native race or proof production interleaving occurs between adjacent synchronous reads.
- Missing quest pointer: existing warning and skip. No party: no broadcast. Raid solo filters; raid dungeon included.
- Queue one V1 broadcast while another is pending, switch fictional source generation before original first packet timer fires: original **already encoded OLD** packet reaches the **fake** outbound sink after NEW is selected; queued second request is rebuilt under NEW source. A separate V2 OLD block can similarly fire after NEW has become active. This is a *possible future migration output-lifetime risk*, not necessarily a current gameplay bug.
- Safe transport invariant: zero actual network emission, no writes to addon data, no artifact creation, no original decoder, no private data.

## Consequences for future design — NOT authorised production modifications

Reader coherency must cover the **source membership, associated `QueryQuestSingle`, quest-builder `QuestieDB.GetQuest`, objective cache, payload queue and delayed outbound network lifetime**, not only the sorted-query loop. A future generation policy must decide whether to permit a consistent OLD snapshot to finish sending after NEW publication, or abort/drain/rebuild the unsent payload under NEW; test both choices against packet type, quest progress semantics, group state and genuine timer/transport. Partial direct query rebinding is unsafe in fictional mismatch tests. No actual code adapter or permission for native testing is implied.

Remaining Gate08 **MAJOR RED**: real E01–E08 and unknown source writers, shared QuestieStream lifetime/ABA/quarantine, atomic 4-kind eight Bin+Ptrs and metadata publication, actual reader/cache integration, Comms event scheduling, third-party API lifetime, SavedVariables interrupted write/relog recovery, WoW3.3.5a + Individual Progression acceptance. Protected `335` unchanged; overall **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**; 439 RAW quest candidates not approved, denominator unknown, pilots 1207–1209 0/3. No package/install/merge/tag/release without separate owner authorization and future full `Questie-335` and account/character SavedVariables backups plus rollback.
