# N-Questie — Draft PR Consolidation and Integration Gates

**Status:** review-only planning, 14 October 2026. No merge, rebase, release, installation or live server change authorised.  
**Tested reference:** #38 head `d58a4b89d247b2c2b43a85fa7cafc3600e23f823`. This is a **planning snapshot**; recheck heads and CI before any future integration.

## 1. Why the merge plan matters

A green workflow on one draft PR is not approval to merge it or all of its ancestors. A GitHub PR's **base branch** may point at an older branch in a stack, while its **head commits** may already include the feature being proposed in another PR. Older CI-only PRs can therefore be redundant or divergent.

The objective is to test **one exact combined source commit** with all intended public changes and no private data. Never merge every open PR indiscriminately or use force-push to try to make an old stack linear.

## 2. Current verified ancestry (GitHub compare, 14 October)

Comparisons made from each older head to **#38** show the following (the words `ahead` and `behind` describe **commit ancestry, not whether matching code exists**):

| Older PR head | Relationship to #38 head | Practical implication |
| --- | --- | --- |
| #6 / #7 / #8 / #13 / #16 | #38 is ahead, behind 0 | Quest 1203 and the 28-reviewed-level progression have an ancestral path through the main integration history; don't replay each patch blindly. |
| #20 / #21 / #24 / #25 / #29 / #33 / #34 / #36 / #37 | #38 is ahead, behind 0 | Their specific checked head commits are ancestors of #38. |
| #35 (CI activation) | #38 is ahead 9, behind 0 | #35's checked head is **already ancestral** to #38. Do not merge #35 separately to "activate" the same workflow a second time. |
| #4 (standalone Busted fixture repair) | diverged: #38 ahead 208, behind 2 | **Not** a commit ancestor. #16 copied an integration-specific fix; verify the resulting files and test outcomes, do not assume merging the old #4 head is safe or necessary. |
| #18 (fail-closed M1 rules) | diverged: #38 ahead 113, behind 14 | **Not** a commit ancestor. An M1 integration exists through #20; review exact source/rule equivalence and tests if someone proposes merging the old #18 head. |
| #32 (early CI activation proposal) | diverged: #38 ahead 18, behind 1 | **Not** a commit ancestor. The canonical workflow was integrated through #35/#38. Check the actual workflow file before replaying this old PR. |

These figures were measured on the specified #38 reference, not on whatever each branch may contain in a future session. A head being an ancestor does **not** prove its current PR branch is safe to click-merge into `335`, nor that all older independent PRs should be closed or merged.

## 3. Parallel draft branches after #38

| PR | Head at this checkpoint | Base | Role |
| --- | --- | --- | --- |
| [#39](https://github.com/CosmicCuddle/N-Questie/pull/39) | `2912fd20db7d2601057a33fbd52ed37a770af770` | #38 branch | Grok's **v2 design only**; +4 commits against #38, draft Lua validator/fixtures and docs, no production v2 exporter or M2.3 engine. |
| [#40](https://github.com/CosmicCuddle/N-Questie/pull/40) | `13ed7709b44f6f38d0b37c198584c531709a16ed` at initial comparison | #38 branch | Lead's private 1203 and in-game QA runbook; +1 documentation-only commit against #38. This consolidation document adds a subsequent commit to that PR. |

At the comparison checkpoint, #39 versus #40 was **diverged** (+1 for #40, -4 from #39): they are **siblings**, not a single linear chain. This is expected. No developer should reset, rebase or force-push either branch to reconcile that display.

The safe future review candidate is a **new temporary integration branch**, based on the then-latest reviewed #39 commit, which brings over the approved documentation from #40 without changing either contributor's original branch. Such a branch is not authorisation to merge into `335`.

## 4. Acceptance gates before the temporary combined candidate

1. **Freeze checked heads for review.** Record full commit SHA for #38, #39 and #40 and list their changed paths. If Grok updates #39, restart the diff/CI check on the new head; no green CI from an older SHA carries forward.
2. **No duplicate workflow activation.** Compare the one canonical active `.github/workflows/nquestie-m2-effective-export.yml` with any pending #30/#31/#32/#35 proposals. Keep only the currently reviewed workflow. Do not overwrite CI configuration from an old branch.
3. **Objective protection.** Ensure the 28 reviewed quest level corrections and specific item fix for 1203 remain narrowly scoped; quest 2001 NPC quest associations must not erase existing reverse indexes.
4. **Privacy protection.** No tracked `private/`, SQL archives, private input exports, private provenance fingerprints, full private discrepancy reports, credentials or SavedVariables.
5. **Version contract.** Keep `nq-m2-effective` v1 frozen and fail-closed; #39's v2 remains a design/draft validator, not a production exporter.
6. **One-source CI.** Run M0, M1, M2, overlay, inherited CI and revision guard on **one identical integration commit**. Run the full 232 M0 checks / 28 reviewed-level checks / 82,431 compiled-field read-back and negative fixtures on that same candidate.
7. **No premature approval.** A document-only PR or a complete CI pass does not approve release, deployment, production M2.3, a v2 exporter or automatic quest-data correction.

## 5. Future clean-room integration procedure (not executed)

When Grok marks #39 ready for review and the maintainer approves a **temporary, draft-only integration**, the reviewer may:

1. Create a **new named temporary branch** from the exact chosen #39 head SHA; do not edit #39, #40 or `335`.
2. Integrate only the reviewed #40 documentation diff, verifying its base and checking for path conflicts. Reapply it in a fresh review commit if copying is safer than merging branch ancestry. No force-push.
3. Run full CI on the new integration commit. Require all six workflows successful; do not combine green checks from different commits.
4. Review diff against the chosen #39 head: additions should be **only** the intended #40 docs. Verify no addon-runtime, database, workflow, TOC, revision, private or SavedVariables content appeared unexpectedly.
5. Keep the combined candidate as a **draft PR** for inspection, separate from the earlier PRs. If the branch introduces new code changes, perform new scoped technical review before claiming it is documentation-only.

Any eventual merge/release into `335` requires a **new explicit maintainer decision** based on the current integration diff, CI, backups and QA. Nothing here authorises closing or merging the legacy PRs.

## 6. Evidence snapshot and unfinished gates

| Item | Evidence | Status |
| --- | --- | --- |
| #38 full CI | Six successful workflows on `d58a4b89d247b2c2b43a85fa7cafc3600e23f823` | PASS for #38 only |
| #39 full CI | Six successful workflows on `2912fd20db7d2601057a33fbd52ed37a770af770`; see PR #39 lead follow-up | PASS for that head only |
| #40 initial CI | Six successful workflows on `13ed7709b44f6f38d0b37c198584c531709a16ed` | PASS for that earlier doc-only head; new commits must re-run |
| Lead's genuine private 1203 M2.1 Lua 5.1 input | Public CI does not validate it; see `NQ-PRIVATE-1203-PILOT-AND-INGAME-QA.md` | NOT DONE |
| Production v2 exporter / M2.3 | Require individual approval and new implementation/testing | NOT AUTHORISED |
| Combined #39 + #40 candidate | No branch, no merge, no combined CI yet | NOT CREATED |
| N-Questie public release or installation | Requires maintainer approval, in-game QA/backups | NOT AUTHORISED |

## 7. Division of responsibilities

- **Grok:** complete the #39 handover/CI bookkeeping and the separately assigned synthetic/design preparation without production implementation.
- **Lead / ChatGPT:** maintain the safe integration inventory and the real server-input/quest QA procedures without publishing private records.
- **Maintainer:** decide if/when a combined candidate may be built, review private 1203 validation status, authorise installation and eventually approve a release.

**This document is a snapshot, not a release checklist signed off as complete.** Re-measure ancestry and GitHub Actions on the exact latest heads before acting.
