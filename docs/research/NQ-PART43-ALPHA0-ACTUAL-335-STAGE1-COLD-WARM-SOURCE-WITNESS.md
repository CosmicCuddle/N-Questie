# Part 43 Alpha 0 — actual protected 335 Stage 1 cold/warm execution (test only)

**28 October 2026 · PUBLIC SAFE · isolated draft · absolutely NO client, package, ZIP, install, merge, tag, release or private data**

## Purpose

We need to know if a limited first private *playable* N-Questie Alpha 0 could avoid the still-unproven Gate 08 compiler writer/stream/atomicity hazards simply by changing interface settings or using a warm cache. The actual original 335 startup source matters: a filename-valid addon is not automatically startup-safe.

**Unchanged protected source:** `Modules/QuestieInit.lua` original `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`, Git blob `22fffa1b1bbeb81ba067f34151949c0938a316c1`. The dedicated CI verifies both the commit tree reference and staged blob hash before Lua execution.

The new test **extracts and executes literal, unchanged complete function bodies** from that authentic source: `local function loadFullDatabase()`, `local function runValidator()` and `QuestieInit.Stages[1]` through the original Stage 2 boundary. It does not rewrite the Stage1 conditional. It runs the functions as coroutines inside a **fictional host** where all real Blizzard APIs, full database, QuestieCorrections, compiler, AceDB, locale, loader and character state are explicitly stubbed with invented values. It does **not** execute real `QuestieCorrections` or `DBCompiler` internals, cannot show real source ownership, and must never be called native gameplay or disk QA.

## Negative/positive coverage

The dedicated Lua 5.1.5 and Lua 5.4.6 test asserts **35 distinct source-backed controls**:
- A clean/invalid-cache cold Stage1 calls base DB, correction writer, PreCompile and compiler, in real Stage1 order and with real coroutine yields, then DB initialize and cleanup.
- Exact matching version/locale/expansion/N-Questie data revision on a fictional valid warm cache calls `QuestieCorrections:MinimalInit` rather than recompiling.
- False compiled flag and mismatch of cached version, locale, expansion or N-Questie data revision each force a recompile. A missing fictional custom data table uses actual `revision=0` fallback.
- `skipValidation=true` with debug enabled still runs real Stage1 compilation, but not the optional *debug validator*; when debug validation is enabled, real Stage1 schedules four validation function calls **after** compile.
- A deliberately failing fictional compiler causes actual Stage1 to stop before downstream DB initialization/cleanup and before recording a new `nQuestieDataRevision`. A stale revision fails closed in this limited test; the exercise does not establish real SavedVariables atomicity, full four-kind publication or crash-safe rollback.

All source data and failure payloads are fabricated. Each fixture gets its own environment and coroutine. Dedicated workflow has `contents:read`, stages only the **original source file in ephemeral runner temporary storage**, checks exact output markers in both Lua VMs, clean Git checkout, and absence of build/ZIP/addon directories. No test harness code is used at production runtime.

## Why a first private test is still owner-gated

This analysis demonstrates that on normal original source with a cold cache, compilation is on the necessary path to a fully initialized quest/map/tracker UI. Even a warm cache triggers `MinimalInit`, and using it assumes a previously valid cache; simply skipping UI/debug validation is not a safe workaround for Gate08. New bounded *loader-only* functionality would not be a playable quest/map/tracker Alpha0, and neither is approved for implementation here.

Before an actual package or native install, separate explicit owner approval is mandatory, including bounded source scope, frozen commit, true 335 folder/TOC/Compat/dependencies, independent content/assets/licenses/secret review, backup of `Interface/AddOns/Questie-335` and both Questie SavedVariables sets, and rollback/native client acceptance. Original `build.py` is wrong for 335 and `release.py` may tag/commit. Neither was invoked.

**No project gate advanced:** Gate08 MAJOR RED (E01–E08 writers, global QuestieStream lease/quarantine, coherent four-kind eight-field metadata publication, disk relog/recovery, native 3.3.5a/IP). 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING. 439 RAW not approved quests, eligible denominator UNKNOWN, pilots 1207–1209 0/3.

**CI claims must be updated only after verifying the original-head workflow and real job logs.**
