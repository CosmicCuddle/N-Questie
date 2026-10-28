# Part 44 Gate 08 — actual original TrackerLinePool item button SetItem and reader generation

**28 October 2026 · PUBLIC-SAFE TEST-ONLY DRAFT · NO GAME CLIENT, BUILD, ZIP, INSTALL, MERGE OR RELEASE**

## Source and execution level

- Protected original `335` immutable `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, original `Modules/Tracker/TrackerLinePool.lua` Git blob `e7e9f6b8539080b3934def64779a49c0fc2a6b6b`.
- The read-only GitHub Action authenticates exact original Git commit + blob, then extracts the **unaltered entire `btn.SetItem = function(self, quest, buttonType, size)` source fragment** between original line 493 and the next `btn.OnEvent` definition at 607. The test compiles that original function **byte-for-byte**, supplying only fake surrounding lexical closure locals such as `btn`, `cooldown`, `LSM30`, `QuestieDB` and `QuestieCompat`.
- **Unlike full original #326 Comms or #324 ThreadLib/AvailableQuests tests, this does NOT load or run the complete 1,117-line TrackerLinePool module, `Initialize()`, real `CreateFrame`, combat security, native bag functions, true event scheduling or native 3.3.5a**. It executes the genuine original SetItem function body with synthetic bag, equipment, query, frame methods and disabled side effects.

## Exact original source boundary

- Actual `QueryItemSingle(...,"class") == 12` checks are made independently by the original SetItem body during bag scan at lines 500, 508, 516 and equipped-item scan at 531, 539, 547.
- Successful match applies `self.itemId`, `questID`, secure `item1`, button textures, charge and UI state at lines 557–598; unsuccessful match clears secure `item1` and hides button (599–604), **but does not explicitly clear existing `self.itemId` or `questID`**. This is a source-level stale-private-field boundary, not proof those hidden fields cause an observed native defect.
- A future producer that changes global QueryItemSingle while button assignments or cached UI state exist must clarify whether to pin source reader, invalidate old fields and rebuild under NEW, or cancel pending updates. Original frame visibility and consumer event paths still require separate native/source testing.

## Proposed synthetic acceptance — not verified until CI finishes

The dedicated job proposes **35 checks per actual Lua 5.1.5 / 5.4.6 interpreter**:

1. Authenticate original source, extract exact 493–605 SetItem closure and verify bag/inventory and direct QueryItemSingle source anchors.
2. OLD source item class=12 + bag slot produces actual original success, real secure item attribute, UI textures, charges and sizing; NEW matched source does likewise.
3. Force OLD item ID with a fake NEW item-class query: original function returns false, clears secure action and hides button, but previous private `itemId`/`questID` remain unchanged. Demonstrates the relevant synthetic derived state lifecycle.
4. Verify single required item, multiple required items with *secondary* button only, non-class-12 rejection, no action on wrong type, and real original equipped-item fallback.
5. Invoke a fake bag API hook that switches query generation before the original class call; then verify matched NEW rescan restores original secure action. This constructed reentrant hook is NOT evidence that native WoW changes source while the original item query executes.
6. CI checks actual Lua syntax and exact pass output, clean worktree and zero produced package/ZIP/build data.

No production code or UI API changes are authorised by this draft. No private account/realm/inventory state or SavedVariables are accessed. Source fragment/harness results are not native client or actual GetDBHandle evidence.

## Remaining safety gates

Gate08 **MAJOR RED**; overall **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**, 439 RAW unapproved, denominator UNKNOWN, pilot 1207–1209 **0/3 implemented**. Real E01–E08 and unknown writers, QuestieStream global pool/abort/ABA fencing, coherent eight Bin+Ptrs + metadata publication, real QuestieDB QueryItemSingle/caches and the whole tracker frame/event lifecycle, actual QuestieComms networking, SavedVariables disk/crash/relog and 3.3.5a Individual Progression native testing remain unproven. Separate owner authorization plus full `Questie-335` and account/character SavedVariables backups and rollback are required before any native install. No merge, ZIP, build, release or protected branch modifications.
