# Part 43 Gate08 — shadow fail-closed generation transaction (TEST ONLY)

**28 October 2026 · PUBLIC SAFE · no packaging, build, install, merge, tag or release**

## Decision and source evidence

Frozen [#302](https://github.com/CosmicCuddle/N-Questie/pull/302) authenticated original protected `335` functions and demonstrated with synthetic serializers that the real outer `QuestieDBCompiler:Compile()` can return silently when already busy, while the unchanged Stage1 writes `nQuestieDataRevision` as though compilation succeeded. A later-kind exception can also leave earlier per-kind output written before the final cache metadata. Those are real control-flow weaknesses under *constructed scheduling*, NOT native-client reproduction.

This new isolated draft tests **one possible replacement protocol** in an entirely separate **shadow Lua model**. It DOES NOT patch `Modules/QuestieInit.lua`, `Database/compiler.lua`, `Modules/QuestieStream.lua` or AceDB. In CI, the test confirms authentic original pinned public protected source commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, blob IDs `22fffa1b1bbeb81ba067f34151949c0938a316c1` (Stage1) and `abba0249f44d14711dbdd46bbde969ccffbc2963` (compiler), and checks exact original hazard anchors for caller revision update, compiler BUSY guard and both per-kind Bin/Ptrs writes. It does **not** execute the real compiler here; original real function execution belongs to #302.

## Proposed handshake contract (experimental, not approved)

- `SUCCESS`: only after all four kinds (NPC, object, quest, item), each Bin and Ptrs, and compatible version/language/expansion, compiled count and N-Questie data revision are complete **as a single in-memory generation object**. Only then may the caller advance to downstream DB initialization.
- `BUSY`: an active compiler request must **not** be interpreted as completed; the caller stops without changing cache revision or initializing downstream.
- `RETRY`: an unavailable or changed source owner, source revision, or **monotonic epoch** invalidates the staged work; this covers a deliberately constructed source A→B→A identity restoration where the epoch still advances. No generation is published.
- `ERROR`: a throwing per-kind writer or invalid Bin/Ptrs values discards staging and releases the model's lock. No downstream initialization.
- All writes to the new candidate generation take place privately. Existing readers remain pinned to the previous generation across coroutine yields. Exactly **one pointer swap**, with no yield, makes the new in-memory generation visible when the source fingerprint is unchanged.

The self-contained Lua fixture uses invented tiny `OLD_BIN_...` and `NEW_BIN_...` strings, one owner identity, one monotonic epoch and fictional per-kind serializer functions; it preserves a previous source generation. It tests duplicate BUSY during yield, success, 8+metadata coherence, re-use after successful cleanup, mid-write object/item failures and recovery, bad output shape, owner change, revision drift, source removal, pre-existing BUSY and A→B→A. It should report **45 checks each** under real Lua 5.1.5 and Lua 5.4.6 only after CI is independently verified.

## Crucial technical limits

This is **not** a drop-in patch: the current addon and AceDB readers directly use separate `Questie.db.global.npcBin`, `npcPtrs`, `objBin`, `objPtrs`, `questBin`, `questPtrs`, `itemBin`, `itemPtrs` fields. A model's single `host.published = candidate` pointer swap proves only that the **new proposed structure** can avoid *cooperative-Lua* yields during an in-memory publication; it does NOT prove existing readers would observe it, any SavedVariables persistence is atomic, or that production can change layout without migrations.

An invented monotonic epoch works only if **every** mutating source writer participates. Actual E01–E08 and unknown external addon writers, local/global QuestieStream leases, ownership across coroutine yields, quarantine on error, third-party source aliases, full clone timing, buffer/ptr validity, native IP and SavedVariables torn flush/relog remain unproven. A stalled or reentrant writer must not be allowed to write into a committed candidate; this shadow model never gives writers a live reference. It also does not validate a full source fingerprint or freeze a real legacy API.

**Next step** is not to merge this model. Independently review the contract for hidden consumers of direct `Questie.db.global.*` fields and for untracked writers; design a separate gated real-source adapter only when evidence supports it and under explicit scope approval. Gate08 stays **MAJOR RED**, project gates **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**. 439 RAW research entries are not approved quests, eligible denominator unknown and pilots 1207–1209 remain 0/3 implemented. Owner separately approves any later playable package and native install, after correct `Questie-335` folder/TOC/Compat, file contents and licensing, and full addons/account/character SavedVariables backups with rollback.
