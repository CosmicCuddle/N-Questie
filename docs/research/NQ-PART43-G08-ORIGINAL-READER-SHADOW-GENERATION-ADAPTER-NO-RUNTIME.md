# Part43 G08 — original 335 reader with isolated shadow generation adapter (TEST ONLY)

**28 October 2026 · PUBLIC SAFE · no protected/runtime modifications, ZIP, build, installation, merge, tag or release**

## Purpose and precedence

Prior frozen [#302](https://github.com/CosmicCuddle/N-Questie/pull/302) demonstrated a source-backed **KNOWN UNSAFE** original Stage1/outer compiler handshake with fictional per-kind serializers (silent BUSY and partial writes). [#304](https://github.com/CosmicCuddle/N-Questie/pull/304) then passed a **shadow-only** `SUCCESS/BUSY/RETRY/ERROR` staging/one-pointer design experiment, but a pointer swap is meaningless to the current addon’s individual global fields. [#306](https://github.com/CosmicCuddle/N-Questie/pull/306) subsequently executed the *unchanged original* `QuestieDB:Initialize()` in fictional hosts, proving it reads eight separate global fields and binds four query handles.

This new **test-only** child connects the unchanged **real reader function** to an **invented dispatcher/generation coordinator** to determine whether a complete private reader set can be prepared and swapped as one in-memory pointer without changing what an already-active query handle sees. It does **not** implement that dispatcher in N-Questie.

## Source provenance

- Protected immutable original `335` commit: `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.
- Authentic `Database/QuestieDB.lua` Git blob: `5784cb65160175e1dce30fe20e8baada0af7e480`.
- CI verifies the source blob before staging one original file under ephemeral runner storage. Test extracts and runs the **entire unmodified `QuestieDB:Initialize()`** from its real start to the next original `GetObject` function boundary.
- Original `QuestieDBCompiler:GetDBHandle` and all binary serialization are **STUBBED** with fabricated strings; no real decoder, stream pool, actual client, SQL, saved character/account data or native IP.

## Proposed adapter experiment and acceptance

A new synthetic `host.current` points to an entire `readerSet` containing generation identity, the four original-source-created reader closures/Ptr handles, and the original source cache reset result. `host.legacy` begins from an invented old-style direct-field snapshot. The *experimental* caller privately stages all NPC/Quest/Object/Item Bin+Ptrs, checks matching revision/metadata and source owner identity plus monotonic epoch (including A→B→A), executes real `QuestieDB:Initialize()` inside a **new private environment**, and publishes a new `readerSet` pointer **only** after its fourth fabricated `GetDBHandle` succeeds. Explicit `SUCCESS`, `BUSY`, `RETRY` or `ERROR` drives downstream initialization; only SUCCESS permits it.

The test asserts **48 controls per Lua 5.1.5 and Lua 5.4.6** if verified by dedicated CI:
- old reader closure stays on old values across staging and later swap; complete four-kind new reader set selected together;
- busy duplicate request cannot certify revision or initialize downstream;
- injected failure at last *writer* or fourth *reader factory* preserves old live reader and releases test lock;
- mismatched pointer string prevents publication; A→B→A source epoch and changed revision discard staged readers;
- previous direct-field `legacy` object is not overwritten during new shadow generation construction;
- a fabricated external write to legacy object can still corrupt the old source record (unfenced original external writer), though already-created synthetic reader closure remains pinned.

The model’s `host.current` is **not** the original `QuestieDB.Query*` global API, which original startup overwrites individually. This test cannot establish atomicity of actual exported query functions, memory visibility of real AceDB, SavedVariables atomic disk flush, 3.3.5a game APIs, QuestieStream lease/quarantine, E01–E08 or unknown writers, unsafe aliases, cancellation, crash recovery or production migration. **Passing means the proposed abstraction is self-consistent under invented fixtures, NOT that Gate08 is fixed.**

## Readiness remains withheld

No protected `335`, addon runtime, build script or actual compiler changes; workflow is `contents:read`, runs Lua scripts only and explicitly blocks addon folders/ZIPs. This experimental adapter does **not** authorize a production rewrite or alpha package. Before implementation proposals, independently audit consumers and mutation aliases of `QuestieDB.Query*`, `_Query*`, pointer caches and existing SavedVariables, plus all participating source-writer/stream epochs; then obtain explicit owner scope approval. Native 3.3.5a + Individual Progression and disk relog/crash rollback remain owner-gated. Make full backups of installed Questie-335 and both SavedVariables sets before any later separately approved native test.

**Project status unchanged:** Gate08 MAJOR RED; 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING. 439 RAW research quests not approved, eligible denominator unknown, 1207–1209 pilot 0/3 implemented. Do not run legacy `build.py` (wrong addon folder/TOC/Compat) or `release.py` (may commit/tag).
