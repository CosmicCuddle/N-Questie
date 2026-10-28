# Part43 Gate08 — original 335 DB consumer compatibility versus shadow generation publication

**28 October 2026 · protected source review · PUBLIC SAFE · no implementation, ZIP, install, merge or release**

## Original source independently inspected

Original protected `335` is `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070` and protected. The original Git blob for `Database/QuestieDB.lua` is `5784cb65160175e1dce30fe20e8baada0af7e480`. The original public source at **lines 220–311** defines `QuestieDB:Initialize()`.

- Lines 246–266 directly read the **eight individual** fields `npcBin/npcPtrs`, `questBin/questPtrs`, `objBin/objPtrs`, `itemBin/itemPtrs` from either `Questie.db.global.sod` or `Questie.db.global`. The 335 non-SoD path is lines 258–265. There is NO reference here to a single alternative `published` generation object.
- Lines 268–271 immediately make four `QuestieDBCompiler:GetDBHandle(...)` calls with those eight values, assembling NPC, quest, object and item handles individually. Bad or mixed fields can therefore propagate to consumer handles.
- Lines 273–296 publish the query wrappers and pointer handles. Lines 298–303 clear five related caches, and lines 305–310 initialize memoized checks and hidden-quest data. An alternate generation layout must account for these post-compile consumers and caches, not only the compiler.
- Original `Database/compiler.lua` at lines 952–959 assigns each per-kind Bin then Ptrs directly to global/SoD; its outer `:Compile()` at lines 1027–1060 follows four kinds with separate global metadata. Original `Modules/QuestieInit.lua` Stage1 at lines 211–215 calls that outer compiler and then separately assigns `nQuestieDataRevision`, without verifying a result status.

## New test-only shadow proof (NOT a candidate production patch)

New [DRAFT test #304](https://github.com/CosmicCuddle/N-Questie/pull/304), exact original `8ce2dfb7c76afd64949b02341d5b5732bdb64fdf`, child frozen [#302](https://github.com/CosmicCuddle/N-Questie/pull/302), adds only shadow Lua model/CI/research. It authenticates pinned original Stage1 and compiler source hash/anchors and tests **45 assertions on each Lua 5.1.5/5.4.6**. Independently inspected dedicated [run 40716909482](https://github.com/CosmicCuddle/N-Questie/actions/runs/40716909482), job `122916971759`, **SUCCESS: 45/45 PASS each VM, clean checkout, 0 artifacts**. Whole original-head #304 CI was **17/21 SUCCESS, four pending, zero failed** at its dated first audit; refresh before stating overall green. Prior #302 real-source witness original-head **20/20 success** and doc #303 original-head **8/8 success, 0/8 artifacts**.

The shadow model returns explicit `SUCCESS/BUSY/RETRY/ERROR`, stages all four kinds privately, validates source owner/epoch/revision and does a no-yield **one-pointer in-memory model publication**, setting metadata and new revision with the eight values. It rejects invented writer errors, partial/invalid results, ABA change and an active concurrent compile. Importantly, it DOES NOT run actual `QuestieDB` readers or per-kind writers/QuestieStream; **production uses a different data layout**.

## Consequences: a separate real-reader adapter gate is necessary

One-pointer shadow generation is a helpful design experiment, but **NOT a drop-in fix** for the direct-field consumers above. A realistic future production adapter would need, at minimum:

1. A single validated generation selection per reader/validator epoch, not eight unrelated global reads. Every query handle must refer to the **same generation**; running readers must not be repointed underfoot while active.
2. A measured and reversible compatibility/migration plan for existing `Questie.db.global.*` SavedVariables from preexisting 335 installs (and SoD isolation where applicable); no silent overwrite/retagging of a cached old generation as newly compiled.
3. An independently authenticated source writer fence (E01–E08 plus unknown external writers), global pooled `QuestieStream` lease/quarantine and ABA epoch handling, coherent all-kind Bin/Ptrs **plus** metadata publication, native data validations and read-side handle lifecycle.
4. Native 3.3.5a + Individual Progression tests and actual SavedVariables disk/relog/crash rollback, with original installed addon and both SavedVariables sets backed up **after separate owner approval** for packaging and installation.

These are design acceptance criteria, NOT an authorized production change. No direct field rewrite, Lua addon runtime edit, package/ZIP, client install, merge, tag or release performed in this work. Protected `335` unchanged. Gate08 **MAJOR RED**; full project **3 COMPLETE, 6 UNDERWAY, 3 TECHNICALLY PENDING**, 439 RAW quests unapproved, eligible denominator unknown, pilots 1207–1209 **0/3**.
