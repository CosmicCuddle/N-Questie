# Gate08 — owned source generation: observed feasibility and hard decision gate

**Date:** 27 October 2026. **Status:** PUBLIC-SAFE ENGINEERING DESIGN / RESEARCH ONLY.
**No implementation acceptance, integration approval, merge, install, package or release.**
Protected `335` remains `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.

## Decision in one paragraph

An already-complete, privately owned copy of Questie's four base source kinds **and both effective faction views** can isolate the real compiler and reader from subsequent edits to the public Lua source tables in a *tiny, fictional, test-owned generation*. But **creating that copy is not inherently atomic**. An unregistered writer between copying NPC and quest can create an impossible combination of old NPC plus new quest fields. A deep copy alone cannot satisfy Gate08 E01–E08 or authorize Stage1. Choose a source ownership/exclusion mechanism first; measure full WoW 3.3.5a client RAM/frame/GC cost before deciding to use a snapshot in production.

## Evidence and exact isolated PR ancestry

- [#187](https://github.com/CosmicCuddle/N-Questie/pull/187) optional scratch-authentication guards: real 73/73 Lua5.1+5.4, full CI green, no source-table fencing.
- [#189](https://github.com/CosmicCuddle/N-Questie/pull/189) optional staged *scalar-only* numeric bounds: real 94/94, legacy untouched. Compound numeric writers unguarded.
- [#191](https://github.com/CosmicCuddle/N-Questie/pull/191) test-only M1/M10 regressions: real 98/98, full 9/9 CI success / 0 artifacts; independent CS02 kill re-test still pending.
- [#192](https://github.com/CosmicCuddle/N-Questie/pull/192) real-source E01/E02/E03/E06/E07 and narrow E08 characterization: **six known weaknesses reproduced**, full 10/10 exact-head CI success / 0 artifacts. *Not* E01–E08 accepted.
- [#194](https://github.com/CosmicCuddle/N-Questie/pull/194) real correction merge and reader with **fictional** faction-selected loader records, 11/11 expected unprotected source scenarios on Lua5.1+5.4. First test head failed for a missing invented WotLK object-fix stub; corrected head `42c4ce89da5b449f08d06a04248c1cbd01f0ab02` dedicated green, final **10/10** original CI success and **0 artifacts across all ten runs**. Actual client faction APIs/IP owner precedence **not** tested.
- [#196](https://github.com/CosmicCuddle/N-Questie/pull/196) standalone, **test-only** owned-copy feasibility experiment `6449f59ad439fc16ed99a36b72112bf481df77a6`, two new test/workflow paths, no compiler change. Dedicated [run 40510601199](https://github.com/CosmicCuddle/N-Questie/actions/runs/40510601199) **SUCCESS**: actual Lua5.1 and Lua5.4 **11/11**; full original-branch CI **pending** at initial checkpoint. Public invented source only. Passing is **bounded feasibility, NOT an accepted production snapshot**.

## Actual public source-writer surfaces and limits

| Writer/source | Public Questie entry point | What a complete source generation must cover |
|---|---|---|
| All four base kinds | `Database/Corrections/QuestieCorrections.lua::_LoadCorrections` and `Initialize` | New rows, replacing existing row fields, nested relation arrays, additions/removals, 3.3.5 compatibility correction callback |
| Derived quest requirements | `QuestieCorrections:Initialize` direct `quest[requiredRaces]` assignment | Changes after correction lookup, including relation-dependent derived fields |
| Yielding NPC waypoint preprocessing | `QuestieCorrections:PreCompile` | Writes to `npcData[id][waypointKey]` and coroutine yields; needs consistent capture or excluded writers |
| Runtime faction overrides, all four kinds | `QuestieCorrections:MinimalInit` local `addOverride` | New override-only record and in-place nested override fields; both effective faction inputs |
| Other built-in paths | `QuestieQuestFixes:LoadMissingQuests`, DB node deletion/compatibility hooks and addon transforms | Explicit audit of root and nested source data writes; no generic root `__newindex` proof |
| Unknown addons or delayed corrections | Writable exported `QuestieDB.*Data`, `*DataOverrides`, nested record tables | Fail-closed when exclusive writer ownership/certification cannot be established |

**Do not assume** that a Lua table root metatable catches changes to existing keys, nested arrays, or transient A→B→A. Equality of final bytes/values also cannot prove that no intermediate writer ran.

## What #196 proves — and does not

The prototype uses **the real** `DBCompiler:CompileTableCoroutine`, `GetDBHandle`, `QuestieStream` and `Begin/VerifyNQStagedGeneration`. It copies tiny invented four-kind input sources plus A/H override view tables before compilation, then mutates **different live tables** during each coroutine's yield.

**Observed bounded isolation:** late scalar and nested NPC edits, item edits by an unregistered function, source A→B→A, new rows, both effective faction-view edits and an override-only change do **not** alter already-captured bytes/readback. It does not publish SavedVariables or bump the revision.

**Observed fatal capture race:** write to the live NPC and quest tables **between the two copies**. The owned generation then reads NPC=A, quest=B, while the live sources both equal B. The copied result is stable but **inconsistent**. Its scratch receipts still verify because receipts authenticate the *scratch fields*, not the moment at which the source generation was captured.

**Prototype limitations:** copying tiny owned tables in a fixture is not evidence that production database copies are affordable, that all actual readers consume only the private copy, that a third-party addon cannot reach it, or that the complete source graph includes every base/derived/faction layer. No real player faction detection or Individual Progression precedence used. No native client memory or performance measurement. No crash/relog recovery. The prototype clone explicitly rejects table-valued keys and does not preserve metatables: it is **not** a drop-in general Lua deep copier.

## Required solution classes; neither approved

### A. Fully instrumented source-writer epoch and exclusion

1. Enumerate and own *all* sanctioned mutators, including nested references, both effective faction views and delayed callbacks.
2. Define a monotonic private epoch incremented **before each mutation**. A transient A→B→A must still increment it.
3. Block or queue writers while making the complete source generation and across any compiler/reader interval that relies on live inputs; alternatively fail/restart at every coroutine boundary and precommit when an epoch changed.
4. Fail closed for uncontrolled addon writers or otherwise prove they cannot mutate in-scope data. An unknowable mutation means **NO PUBLICATION**, even if all scratch receipts pass.
5. Test all E01–E08 plus no-yield transaction and client quotas before Stage1 consideration.

**Open:** how to establish a truthful exclusive writer policy in real WoW 3.3.5a addon load/update order, including third-party addons and saved state. Merely adding counters to `_LoadCorrections` is incomplete.

### B. Atomic capture into an owned read-only/effective generation

1. Establish a source ownership boundary *before first copy*; all relevant writers must be excluded, version-journalled or captured through a verifiable immutable generation until after the **last** base/override read.
2. Include all four base kinds, nested relationships and **both** effective faction views/approved ownership policy in one coherently versioned capture.
3. Ensure all staged compiler and validation reader paths use that owned generation, without falling back to public root/override tables.
4. Remove public aliases to owned source, preserve required schema/metatable/identity semantics and enforce an approved no-mutation contract.
5. Measure peak additional Lua heap, garbage collector pressure, frame budget, and actual login/relog behaviour in the **WoW 3.3.5a/IP client** using the real source corpus before selecting or integrating this approach.

**Open:** capturing an in-memory table graph is not atomic by default. Even in Lua's cooperative scheduler, a yield, callback or reentrant method during any capture operation may invalidate the source; unknown writers remain a risk. Copying all data may be too expensive on the actual client.

## Acceptance contract — still RED / unimplemented

| Acceptance case | Must demonstrate | Current state |
|---|---|---|
| E01 persistent source edit | Deny/retry or safely compile a coherent owned generation with explicit provenance | Only unsafe witness + tiny copy isolation |
| E02 transient A→B→A | Detect epoch movement or prove copy completed under exclusive ownership | Not proven |
| E03 nested mutation | Own or quarantine direct indexed-array changes | Not proven |
| E04 override-only/in-place merge | Cover actual late `MinimalInit/addOverride` outcomes | Vulnerable witness; no lock |
| E05 opposite-faction | Certify both real effective views and cached-login precedence | Synthetic view only; client unknown |
| E06 unrelated writer | Document and test non-interference or conservative invalidation policy | Policy unresolved |
| E07 unknown writer | Reject if writer provenance/exclusion cannot be established | Not implemented |
| E08 legacy compatibility | Byte/semantics identity for normal Stage1, SoD and 3.3.5a/IP | Narrow invented fixture only |
| TX01–TX18 / global stream | Driver lifetime, stream quarantine, atomic eight fields + metadata and crash recovery | BLOCKED |

**Next engineering action:** independently review #196's observed capture race; choose a falsifiable source-writer contract *in design and tests* before adding compiler source production code. The decision must record quantified 3.3.5a memory/frame figures, and distinguish owner-private evidence from public invented fixtures.

Full N-Questie programme remains **3 complete / 6 underway / 3 technically pending**; Gate10 covers **439 raw research records**, initial 1207–1209 pilot 0/3. No private server SQL, real NPC/GO/item/loot/IP mapping on public GitHub.
