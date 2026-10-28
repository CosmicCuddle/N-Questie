# N-Questie Part 43 — Living Development Checklist

**Opened:** 28 October 2026. **Read first:** [Complete Part 42 → 43 Engineering Handover](HANDOVERS/2026-10-28_PART42_TO_PART43.md), [project master](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md), and [Part 42 checklist](NQ-PART42-LIVING-DEVELOPMENT-CHECKLIST.md).

## Priority 1 — Alpha 0 private smoke-test preparation (NO packaging approval)

- [x] Public protected 335 revision confirmed as `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.
- [x] Actual 335 TOC uses Interface 30300 and requires installed `Questie-335` directory.
- [x] Existing `build.py` is not 335-ready: wrong output folder, upstream Wrath TOC, omitted Compat dependencies.
- [x] Frozen [test draft #288](https://github.com/CosmicCuddle/N-Questie/pull/288) `6a217b98c6e45b8cffa7f90b76797a752aff8e4d`: original manifest static preflight **27/27**, latest full original CI 17/17 success, no archive produced.
- [x] Frozen [test draft #290](https://github.com/CosmicCuddle/N-Questie/pull/290) `3e8211d54d0d4c3b651ed37c6b96323996040057`: all six 335 TOC XML roots and recursive script/include closure **39/39** on dedicated source-pinned CI.
- [ ] Audit and close original-head #290 final M2 `40701161369` (16/17 passing at handover), checking any later runs and empty artifacts.
- [ ] Design and test isolated no-write, no-archive 335-aware candidate manifest including file order, exact case and negative mutation controls.
- [ ] Obtain a separate explicit owner decision before generating ANY package, building or distributing a ZIP.
- [ ] With distinct later authorization: verify candidate scope, correct folder and TOC, dependencies, hashes, restricted data exclusion, backups and restore; then reversible WoW 3.3.5a cold-start/quest/map/tracker/relog QA. None yet completed.
- [ ] Do not run the legacy `release.py`, which can commit and tag.

## Priority 2 — true Gate 08 safety blockers

- [x] Original real GetDBHandle/QuestieStream, real compiler, correction-writer A→B→A and initialization-source test evidence lives in frozen [#278](https://github.com/CosmicCuddle/N-Questie/pull/278), [#280](https://github.com/CosmicCuddle/N-Questie/pull/280), [#282](https://github.com/CosmicCuddle/N-Questie/pull/282), [#284](https://github.com/CosmicCuddle/N-Questie/pull/284), [#286](https://github.com/CosmicCuddle/N-Questie/pull/286). Passing tests remain test-only diagnostics.
- [ ] Actual E01–E08 complete source-writer and external-addon owner coverage, including nested A→B→A and both faction views.
- [ ] Actual exact-once global stream pool lease/abort quarantine.
- [ ] Checked full outer four-kind compiler with all eight binary/pointer fields and coherent metadata in one no-yield RAM publication.
- [ ] Actual native client SavedVariables on-disk interrupted-write, relog and recovery verification, plus Individual Progression QA.

## Priority 3 — documentation, CI and coordination

- [x] Frozen documentation [#291](https://github.com/CosmicCuddle/N-Questie/pull/291) exact head `064256d9cde256c6f68c5f81d88c7df79b9427a4`, original CI at handover 7/8 passing, M2 `40701649606` pending, all eight artifacts empty.
- [ ] Refresh final #290 and #291 Actions and all newly appeared artifacts; preserve dated pending evidence.
- [ ] Append subsequent verified checkpoints to this checklist and both authoritative Part42/master checklists on a NEW isolated docs-only child.
- [ ] CS02 prior reviews #267/#270/#272/#275/#278 completed; optional later #280/#282/#284/#286/#288/#290 independently reviewable comment-only, no falsely claimed completion.
- [ ] Continue [PR #42 coordination](https://github.com/CosmicCuddle/N-Questie/pull/42) with exact source heads, tested controls and unresolved blockers.
- [ ] Preserve historical failed #274 missing WoW `tremove` in bare Lua and its corrected follow-up.

## Whole-project release safety

- [ ] 12 gates remain **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**; Gate08 **MAJOR RED**.
- [ ] 439 RAW research records are not approved quest additions, eligible count UNKNOWN; pilots 1207–1209 still 0/3 implemented.
- [ ] No protected branch changes, merging, distribution, builds, installations, tags, releases or private server/account files without separately authorized approval.

## Part 43 work log (append dated verified updates)

**2026-10-28 initial handover:** First Alpha0 goal is a limited, private, reversible smoke test. No playable build yet. Review frozen exact heads and carry on public-safe engineering before asking approval for packaging.
