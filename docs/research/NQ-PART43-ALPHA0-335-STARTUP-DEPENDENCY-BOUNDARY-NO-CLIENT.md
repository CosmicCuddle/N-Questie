# N-Questie Alpha 0 — original 3.3.5a startup dependency boundary (NO client/ZIP)

**28 October 2026 · original protected source inspection · PUBLIC SAFE · no game test or packaging authorization**

## Why this matters

The owner prioritises a first private **playable** Alpha 0 test sooner than full release, without authorising a ZIP, installation, merge, tag or release. Passing isolated filename and XML-order tests is necessary but **not sufficient**. We independently read these original exact-commit `335` files at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`:
- `Questie.lua`, specifically `Questie:OnInitialize` and the file's final game-cache bootstrap call;
- `Modules/QuestieInit.lua`, particularly `loadFullDatabase`, `QuestieInit.Stages[1..3]` and `QuestieInit:Init`;
- `Modules/QuestieCompat.lua` for `GetBuildInfo()` 30300 compatibility;
- `Modules/Migration.lua` for profile migration writes.

## Actual startup dependency — pinned source, not a hypothetical bypass

1. In `Questie.lua`, `Questie:OnInitialize` immediately creates AceDB under `QuestieConfig`, registers profile callbacks and early events. This is **not a read-only operation** from the SavedVariables perspective. An Alpha 0 in-game run needs the owner's separate backup/restore plan for both account and character SavedVariables.
2. `QuestieInit:Init` schedules the three-stage start coroutine with `ThreadLib.ThreadError` and handles tracker/WatchFrame visibility. It does **not** itself certify the compiler's source ownership.
3. **Stage 1** sets up options, icons, locale, zones, migration and professions. Its real recompilation condition at original `QuestieInit.lua` around lines 188–221 checks existing compiled flags, addon version, locale, expansion and N-Questie data revision. On a clean/no-valid-cache first start, it enters `loadFullDatabase()`: source table deserialisation, `QuestieCorrections:Initialize()`, townfolk, locale, gathering removal and `QuestieCorrections:PreCompile()` across actual coroutine yields; then it calls `QuestieDBCompiler:Compile()`. A matching pre-existing cache may follow the alternative `MinimalInit` route. **The owner-requested first clean Alpha 0 test cannot be deemed compiler-free.**
4. Original `skipValidation` is an optional **debug validation** branch around Stage1 lines 237–245, after compilation, and **is not** a switch that prevents the compiler/corrections from running. Likewise disabling tracker UI does not prove compilation was disabled.
5. Stage 2 initialises journey/player and waits for game cache (with a timeout), and Stage 3 registers late events, map/tracker/quest handlers, sets `Questie.started`, then draws available quests. A mere TOC/XML load is **not equivalent** to a working map/quest/tracker smoke test.

## Consequences for the first owner-approved private test

- **DO NOT label an ordinary cold-login normal-startup build 'safe' solely because 32/32 payload checks and 28/28 load-order checks pass.** True Gate08 is still MAJOR RED: source writers E01–E08, A→B→A, actual QuestieStream lease, checked all-four-kind eight-field+metadata publication, on-disk recovery and native IP tests unresolved.
- A purely inert loader-only diagnostic (if later explicitly designed and approved) could test file loading without full quest functionality. It must not be marketed as a *playable quest/map/tracker* Alpha 0. It would still require separate packaging/install consent and SavedVariables review.
- A meaningful playable Alpha 0 must either establish a controlled fail-closed Stage1 compiler/runtime boundary on its **own isolated experimental code** with native test acceptance, or wait for the applicable Gate08 protections. A shortcut that skips correction/compile without establishing that downstream DB consumers are coherent can create a false positive and is **not approved**.
- Before any separate owner-authorised ZIP: freeze immutable branch/head and feature exclusions, verify file bytes and licenses, ensure true `Questie-335` directory/TOC/Compat closure, full asset references, and absence of accidental private content. Back up existing `Interface/AddOns/Questie-335`, account `QuestieConfig` and character `QuestieConfigCharacter` data before a separately authorised install. Rollback and sanitised error capture must be documented before game launch.

## Current parallel evidence

- Frozen [#293](https://github.com/CosmicCuddle/N-Questie/pull/293) original head `e3ebb1d241fb15214886f0627592621613e3acda`: dedicated **28/28**, now independent full **18/18 Actions SUCCESS**, **0/18 independently checked workflow artifacts**.
- Frozen docs [#292](https://github.com/CosmicCuddle/N-Questie/pull/292) original head `b56f374c8f01d189e94b8063538946cf5ed1f4f6`: independently rechecked **9/9 Actions SUCCESS, 0/9 artifacts**.
- Docs [#294](https://github.com/CosmicCuddle/N-Questie/pull/294) head `77ed775e716a63e04665811375a26cf1dd711823` was **7/8 Actions SUCCESS, last M2 running** at this writing, 0/7 independently audited completed artifacts; not called fully green.
- New [TEST-ONLY #295](https://github.com/CosmicCuddle/N-Questie/pull/295) head `e34c8dd398f0db7af47fd417df5ecb5a5e3721fa`: exact original 335 **546 candidate runtime file references**, static allowlist/TOC/XML/deterministic Git blob model. Dedicated exact-head [run 40707459303](https://github.com/CosmicCuddle/N-Questie/actions/runs/40707459303) and job `122883303683` independently confirmed **32/32 PASS, clean checkout, zero artifacts**. Broad original-head CI remains underway at this dated checkpoint. 546 is **not** an approved distribution file list; script never generated files.
- `build.py` still has wrong `Questie` output folder, wrong `Questie-WOTLKC.toc` Wrath manifest, and omitted `Compat`. `release.py` can commit/tag and must not run.

## Whole-project bounds

3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING; Gate08 MAJOR RED; 439 RAW investigation entries not approved, eligible count unknown, pilots 1207–1209 still 0/3 implemented. No actual native client, live SavedVariables crash/relog, private SQL/realm data, package/ZIP, install, merge, tag or release. This is a source-backed decision brief, **not** a request to relax owner's approval gates.
