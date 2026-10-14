# N-Questie integration plan (335 -> validation stack)

Status: plan only. Nothing here has been merged, rebased or pushed to 335.
Written 14 Oct 2026 (Europe/London).

## 1. Why this document is on #44

#44 already carries the design audit and the M2 roadmap, and the
test-inventory script below has to see every test that the stack adds. A
separate docs-only PR would have to be based on #44 anyway, so it would add a
sixth layer to review with no gain. Keeping it on #44 means one review covers
the plan and the tool it relies on.

## 2. Ancestry from 335

335 is at 13c958005 ("Fix missing module reference (Issue #21)"). Every open
and historical PR branch contains 335 (0 commits behind), so 335 itself needs
no catch-up merge.

Already contained in #38 and in the #44 tip (no action needed): #1, #3,
#5-#8, #13, #16, #20-#29, #33-#38. #39 and #41-#44 form the design stack on
top of #38 (#39 <- #41 <- #42 <- #43 <- #44).

#4 has 2 commits that are patch-equivalent to commits in #38 and no path
differences, so it is effectively included.

Diverged from #38 (not to be merged blindly, each needs its own review):

| PR | Commits not in #38 | Paths still different |
|---|---|---|
| #2 | 9 | 4 |
| #9 | 4 | 6 |
| #10 | 4 | 7 |
| #11 | 6 | 6 |
| #12 | 1 | 2 |
| #14 | 1 | 2 |
| #15 | 9 | 10 |
| #17 | 9 | 11 |
| #18 | 11 | 8 |
| #19 | 2 | 1 |
| #30 | 1 | 1 |
| #31 | 10 | 3 |
| #32 | 1 | 1 |

#18 and #32 (and #4 above) are the historical divergent PRs named in the
brief. Most of these are older versions of work that later landed in another
form. The recommendation is to close them with a note once the integration
lands, not to merge them.

Parallel PRs on #38 (merge base d58a4b89d), owned by others or separate:

| PR | Head | Commits | Paths |
|---|---|---|---|
| #40 | 830cea3fb | 6 | 5 docs |
| #45 | 81643eea8 | 6 | 4 |
| #46 | 8c95bdc8e | 1 | 7 |

## 3. Throwaway integration result

A local throwaway branch (`local/throwaway-integration-do-not-push`, never
pushed) was built from the #44 tip 7b25eb9dd by merge only:

1. merge #40: clean (5 docs).
2. merge #45: clean (pilot preflight test, run-m2-pilot.sh,
   M22PilotPreflight.test.lua).
3. merge #46: 2 conflicts, committed as 810ee4004.

| File | Conflict | Resolution |
|---|---|---|
| docs/DEVELOPMENT-LOG.md | both sides appended entries at the same place | union, both entries kept in date order |
| tools/validation/M22Libraries.test.lua | both sides added a suite entry at the end of the list | union, qa_draft and harness pin entries both kept |

tests/run_m2_suite.sh merged automatically and has the harness pin, the
correction/text QA draft and the pilot preflight steps.

Recommended real order: #39 -> #41 -> #42 -> #43 -> #44 (already stacked),
then #46, then #45, then #40. #46 first because it is the only one with
conflicts and it changes the harness version; the other two then merge
cleanly. The same union resolution applies.

## 4. Test-preservation check

`tools/validation/integration/test_inventory.sh <target> <source>...` lists,
for each ref, the test files, run_m2_suite.sh steps, busted wrapper entries
and workflow commands, and fails if anything in a source is missing in the
target. It only reads git objects.

Result on the throwaway commit 810ee4004:

| Ref | Test files | Suite steps | Busted entries | Workflow commands |
|---|---|---|---|---|
| integration 810ee4004 | 36 | 22 | 10 | 53 |
| #44 tip 7b25eb9dd | 33 | 20 | 9 | 53 |
| #40 830cea3fb | 29 | 16 | 4 | 53 |
| #45 81643eea8 | 31 | 17 | 4 | 53 |
| #46 8c95bdc8e | 30 | 17 | 5 | 53 |
| #38 d58a4b89d | 29 | 16 | 4 | 53 |

PASS: nothing is lost. 36 = 33 + harness pin test (#46) + 2 pilot preflight
files (#45).

## 5. CI on one exact integration commit

1. Build the integration branch by merges only, in the order in section 3.
2. Run test_inventory.sh against every source head; it must pass.
3. Run tests/run_m2_suite.sh and busted locally on a clean tree.
4. Push that branch (after approval) and open it as a draft PR against 335.
5. Record the exact head SHA. All six workflows must pass on that SHA; any
   new commit restarts this step.
6. The lead runs the private 1203 Lua 5.1 validation on the same SHA.
7. Only then ask for approval to merge, with a merge commit (no squash, no
   rebase) so the SHA tested is the SHA in history.

## 6. Preserving 335

335 is not touched until Michael approves step 7. Before any merge, tag the
current tip (for example `pre-integration-335` on 13c958005) so it can be
restored. No force-push to 335 at any stage.
