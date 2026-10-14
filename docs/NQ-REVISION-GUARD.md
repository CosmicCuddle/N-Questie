# N-Questie — CI Revision Bump Guard

**Date:** 14 October 2026
**Status:** Draft, CI-only. Workflow proposed, not active. Runtime revision mechanism unchanged.
**Owner:** Grok Bot (validation workstream)
**Base:** PR #7 head `d1580bbf`
**Related:** `docs/NQ-VALIDATION-M0.md` §6 and §9.5 on the M0 branches (PR #9 / #11)

## 1. Problem

`Modules/QuestieInit.lua` (PR #2) recompiles the Questie database when `Questie.db.global.nQuestieDataRevision ~= NQuestieCustomQuestData.revision`. The number lives only in `Compat/NQuestieCustomQuestData.lua`. Editing any other N-Questie correction module without bumping it leaves installed clients on stale compiled data, and the TOC `## Version` stays the same.

## 2. What this branch adds

| File | Purpose |
|---|---|
| `cli/check-revision-bump.sh [<base-ref>]` | Finds the merge base with `<base-ref>` (default `origin/335`). If `Compat/NQuestie*.lua` changed, or a `Compat\NQuestie*` line in `Questie-335.toc` was added or removed, then `revision` at HEAD must be strictly greater than at the merge base. A missing data file at the base counts as 0. Exit codes: 0 OK, 1 bump missing or revision unreadable, 2 git error. |
| `tests/test_check_revision_bump.sh` | 7 synthetic cases in temporary git repos (never the working repo) |
| `docs/proposed-workflows/nquestie-revision-guard.yml` | Pull-request job with `fetch-depth: 0`: self-test, then the guard against `origin/<base_ref>` |

## 3. Why the base is PR #7, not PR #9

The guard is independent of the M0 harness. It only reads git history and `NQuestieCustomQuestData.lua`, which already exist on #7. Basing it on #7 keeps the diff to this feature alone and lets the lead developer adopt it without taking #9. It also avoids editing `docs/ROADMAP.md` and `docs/PROJECT-HANDOVER.md` here, because #9 and #11 append to the same sections and that would conflict. Those notes live on the M0 branches.

## 4. Test results (local, 14 Oct 2026)

| Case | Expected | Result |
|---|---|---|
| Correction changed, no bump | fail | PASS (exit 1) |
| Correction changed, bump 3→4 | pass | PASS (exit 0) |
| Unrelated file only | pass | PASS (exit 0) |
| New `Compat\NQuestie*` TOC line, no bump | fail | PASS (exit 1) |
| Revision decreased | fail | PASS (exit 1) |
| `revision` line removed | fail | PASS (exit 1) |
| Data file first introduced (base 0 → 1) | pass | PASS (exit 0) |

On the real branches, run read-only against their PR bases:

| Head | Base | Result |
|---|---|---|
| #2 | `335` | OK, 0 → 1 |
| #6 | #5 | OK, 1 → 2 |
| #7 | #6 | OK, 2 → 3 |
| #7 | `335` | OK, 0 → 3 |
| #8 | #7 | OK, 3 → 4 |
| #11 (M0 + #8) | #7 | OK, 3 → 4 |

## 5. Limitations and deferred work

- **Comment-only edits:** these also require a bump. That is deliberate; the cost is one extra recompile for players.
- **Parallel PRs:** two PRs from the same base can both bump to the same number, for example #8 and a future PR both going 3 → 4. Each passes alone, but after the first merges, the second must be re-checked against the new base. That happens automatically, because the check runs against the PR's current base on every push.
- **Content fingerprint (layer 2): deferred.** The plan is to compare the M0 harness's post-correction hashes with a committed manifest, which also catches semantic changes that arrive through inherited correction files. It needs agreement with the lead developer on the manifest format and ownership.
- **Workflow not active:** a maintainer must copy the proposed file into `.github/workflows/`.
- The guard cannot prove that players actually recompile. That still needs the login check described in the review (R4).
