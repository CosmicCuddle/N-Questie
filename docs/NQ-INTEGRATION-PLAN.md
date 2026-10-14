# N-Questie integration plan (335 -> validation stack)

Status: plan only. Nothing here has been merged, rebased or pushed to 335.
Written 14 Oct 2026, updated for round 4 the same night (Europe/London).

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
brief. Section 7 classifies each one with evidence. None is merged or closed before an approved integration.

Parallel PRs on #38 (merge base d58a4b89d), owned by others or separate:

| PR | Head | Commits | Paths |
|---|---|---|---|
| #40 | 830cea3fb | 6 | 5 docs |
| #45 | 81643eea8 | 6 | 4 |
| #46 | 8c95bdc8e | 1 | 7 |

## 3. Trial integration (round 4, local only)

Source heads verified live on 14 Oct 2026 in the evening (BST), before the trial. All
matched the requested SHAs:

| Source | Head |
|---|---|
| stack #39 -> #41 -> #42 -> #43 -> #44 | #44 at 3c14b8c16 (contains #39 da7f67fed, #41 9afbb6fbb, #42 63836c216, #43 35699cc79) |
| #46 | 8c95bdc8e480a37fb8732721af5647c59123c0a8 |
| #45 | 6177a3f745e726e34ab9c603269cf6344bf8517b |
| #47 | 81c2c89deddbd6056fbced4a2be0cafbbd3311a4 |
| #40 | 830cea3fb6cea13d7e0473c0c790a5eb44fa89a2 |
| 335 | 13c958005c0e3b27e3ef0ea3472998fa522a11a5 |

The trial branch `local/trial-r4-do-not-push` was built by merges only and is
never pushed. **Trial SHA: c54dbf2ea** (merge chain 9f84834ce, d18cf5a90,
e21d8ac57, c54dbf2ea on top of 3c14b8c16). The later #44 commit that adds this
document changes docs and the two read-only scripts only.

| Step | Merge | Result |
|---|---|---|
| 1 | #46 | conflicts in docs/DEVELOPMENT-LOG.md and tools/validation/M22Libraries.test.lua |
| 2 | #45 | clean (tests/run_m2_suite.sh auto-merged) |
| 3 | #47 | clean (tests/run_m2_suite.sh auto-merged) |
| 4 | #40 | clean (docs only) |

| File | Conflict | Resolution |
|---|---|---|
| docs/DEVELOPMENT-LOG.md | both sides appended entries at the end | union: stack entries, then the #46 entry |
| tools/validation/M22Libraries.test.lua | stack adds five DRAFT suite entries, #46 adds the harness pin entry, at the same place | union: all six entries kept |

The other files named in the brief needed no manual resolution:
run_m2_suite.sh merged automatically and has every step from every source
(24 steps), and the busted wrappers from #45 (M22PilotPreflight.test.lua) and
#47 (M21Private1203Gate.test.lua) are separate files.

Order. A second trial in the order #47, #45, #40, #46 gave the same two
conflicts, both at #46, so the conflicts belong to #46 against the stack and
not to the order. Recommended order: **stack, #46, #45, #47, #40**.
- #46 first: it is the only source that conflicts, and it sets the harness pin
  (1.2.0) that the rest of the plan (Stage A1) relies on. Resolving it right
  after the stack keeps the resolution on one small merge.
- #45 then #47: both add suite steps and busted wrappers and merge cleanly in
  either order. #45 (pilot preflight) goes first because #47 (lead's
  single-quest 1203 gate) is the newest and builds on the same pilot flow.
- #40 last: docs only, no tests, so it cannot change any count.

## 4. Test and behaviour preservation

Three checks, all on the trial SHA.

**4.1 Inventory** (`tools/validation/integration/test_inventory.sh`):

| Ref | Test files | Suite steps | Busted entries | Workflow commands |
|---|---|---|---|---|
| trial c54dbf2ea | 38 | 24 | 10 | 53 |
| #44 3c14b8c16 | 33 | 20 | 9 | 53 |
| #46 8c95bdc8e | 30 | 17 | 5 | 53 |
| #45 6177a3f74 | 31 | 17 | 4 | 53 |
| #47 81c2c89de | 31 | 18 | 4 | 53 |
| #40 830cea3fb | 29 | 16 | 4 | 53 |

PASS: everything in every source is in the trial.

**4.2 Static assertion counts** (`tools/validation/integration/assertion_counts.sh`):
counts assertion calls per test file (Lua `ok`, `check`, `expect`, `eq`, `it`,
`assert*`; shell pass/fail/check helpers) on each source and on the trial and
fails if any file has fewer in the trial. Result: 38 test files, 566 assertion
calls, and every file in the trial has exactly the count of its newest source
(for example tests/check_m2_export_values.lua has 11 on #44 and 13 on #46 and
the trial). PASS: no assertion dropped.

**4.3 Executed counts.** tests/run_m2_suite.sh was run on a clean checkout of
each source head and of the trial (all exit 0). Pass counts per suite step
("ok" where the step prints no count; "-" where the source does not have it):

| Step | #44 | #46 | #45 | #47 | #40 | trial |
|---|---|---|---|---|---|---|
| GNU realpath available | ok | ok | ok | ok | ok | ok |
| Lua 5.1 syntax (M1, M2.1, M2.2 modules, fixtures, specs, tests) | ok | ok | ok | ok | ok | ok |
| private/ guard | ok | ok | ok | ok | ok | ok |
| private/ guard self-test | ok | ok | ok | ok | ok | ok |
| M1 objective rules | ok | ok | ok | ok | ok | ok |
| M2.1 input schema and parser | ok | ok | ok | ok | ok | ok |
| M2.1 path and symlink safety | ok | ok | ok | ok | ok | ok |
| M2.2 effective schema | 0,71 | 0,71 | 0,71 | 0,71 | 0,71 | 0,71 |
| M2.2 snapshot (compiled shapes) | 46 | 46 | 46 | 46 | 46 | 46 |
| M2.2 safe writer | 36 | 36 | 36 | 36 | 36 | 36 |
| M2.2 provenance | 22 | 22 | 22 | 22 | 22 | 22 |
| M2.2 coverage (synthetic) | 71 | 71 | 71 | 71 | 71 | 71 |
| M2.2 objective order (killCreditObjectiveFirst) | 23 | 23 | 23 | 23 | 23 | 23 |
| M2 v2 DRAFT prototype (design validation only) | 63 | 33 | 33 | 33 | 33 | 63 |
| M2 v2 exporter acceptance DRAFT (spec only) | 38 | - | - | - | - | 38 |
| M2.3 contract DRAFT (design only) | 185 | - | - | - | - | 185 |
| nq-m2-markers DRAFT (design only) | 39 | - | - | - | - | 39 |
| Correction regression and text QA DRAFT | 25 | - | - | - | - | 25 |
| pilot script syntax | ok | ok | ok | ok | ok | ok |
| busted tools/validation | 156 | 152 | 21,152 | 19,152 | 151 | 21,159 |
| M2.2 real-DB export integration (M0 + export) | 25,25 | 25,25 | 25,25 | 25,25 | 25,25 | 25,25 |
| M2.2 real-DB coverage integration | 0,26 | 0,26 | 0,26 | 0,26 | 0,26 | 0,26 |
| Harness version pin | - | 5 | - | - | - | 5 |
| pilot output path and no-clobber preflight | - | - | 21 | - | - | 21 |
| Single-quest 1203 gate syntax | - | - | - | ok | - | ok |
| Private-1203 gate (public synthetic cases only) | - | - | - | 19 | - | 19 |

Where a cell has two numbers, the first is a nested suite printed inside the step (pilot preflight 21 or 1203 gate 19) and the second the busted total. Every step passes on the trial with the same count as its source. busted:
151 on the #38 base, +5 stack wrappers, +1 each from #46, #45 and #47 gives
the 159 on the trial; the nested pilot preflight (21) and 1203 gate (19)
checks also run inside busted.

Outside the M2 suite, every other command in the six workflows was run on the
trial: overlay, quest 1203, the three reviewed-level tests, validate-335
fixtures (3 rejections), revision bump guard self-test, validate-objectives,
the four Python tool tests (4, 3, 3 tests and the generator run), and the full
repository busted run (177 successes, 0 failures). All passed; M0 passed all
232 checks inside the export integration step.

## 5. CI on one exact integration commit

1. Build the integration branch by merges only, in the order in section 3.
2. Run test_inventory.sh and assertion_counts.sh against every source head;
   both must pass.
3. Run tests/run_m2_suite.sh, the other workflow commands and busted locally
   on a clean tree; executed counts must match section 4.3 or be explained.
4. After approval, push that branch and open it as a draft PR against 335.
5. Record the exact head SHA. All six workflows must pass on that SHA; any new
   commit restarts at step 2.
6. The lead runs the private 1203 Lua 5.1 validation on the same SHA.
7. Only then ask for approval to merge, with a merge commit (no squash, no
   rebase) so the tested SHA is the SHA in history.

## 6. Preserving 335: pre-integration tag (proposal, not created)

335 verified live with `git ls-remote origin refs/heads/335` on 14 Oct 2026:
`13c958005c0e3b27e3ef0ea3472998fa522a11a5` ("Fix missing module reference
(Issue #21)"). Before the integration merge, and only after approval:

```
git fetch origin 335
test "$(git rev-parse origin/335)" = 13c958005c0e3b27e3ef0ea3472998fa522a11a5
git tag -a pre-integration-335 13c958005c0e3b27e3ef0ea3472998fa522a11a5 \
    -m "335 before the validation-stack integration (approved by Michael Board)"
git push origin refs/tags/pre-integration-335
```

Verification after the push:

```
git rev-parse pre-integration-335^{commit}        # 13c958005c0e...
git ls-remote origin refs/tags/pre-integration-335^{}   # 13c958005c0e...
git ls-remote origin refs/heads/335               # still 13c958005c0e... until the approved merge
```

If 335 has moved when this runs, stop and ask again; do not tag a different
commit. 335 itself is not touched until Michael approves step 7, and is never
force-pushed. The tag has not been created.

## 7. Old PR preservation

Checked against the #44 head 3c14b8c16 with `git merge-base --is-ancestor`,
`git cherry` and a per-path content diff. **No PR is closed until after an
approved integration has landed**; closing then needs its own approval.

| PR | Status | Evidence |
|---|---|---|
| #1, #3, #5-#8, #13, #16, #20-#29, #33-#38 | fully preserved (contained) | head is an ancestor of the #44 head |
| #4 | fully preserved (patch-equivalent) | both commits patch-equivalent (`git cherry` -), no path differs |
| #9, #10, #11 | deliberately superseded | older M0 harness and handover/roadmap text; validate-335.lua replaced by the #16/#20/#38 line (harness 1.1.0, then 1.2.0 in #46); `docs/proposed-workflows/nquestie-validate-335.yml` replaced by the active `.github/workflows/nquestie-validate-335.yml` |
| #12, #14 | deliberately superseded | only differences: executable bit on check-revision-bump.sh, 2 lines in its self-test, and the proposed workflow now active as `.github/workflows/nquestie-revision-guard.yml` |
| #15, #17 | deliberately superseded | older M1 ObjectiveRules (36 lines) replaced by #18's fail-closed rules, which equal the head; proposed workflows now active |
| #18 | superseded except for its rules, which are preserved | ObjectiveRules.lua and fixtures identical to the head; remaining differences are older handover/roadmap text and proposed-workflow copies |
| #30, #32 | deliberately superseded | single workflow file, replaced by the #35 activation contained in #38 |
| #31 | deliberately superseded | older objective-rules workflow and an earlier M2 roadmap (56 lines) rewritten in #33-#38 and #44 |
| #2 | **not fully preserved: decision needed** | 40 doc lines only on #2 (DEVELOPMENT-LOG, PROJECT-HANDOVER, QUEST-2001-SMOKE-TEST, ROADMAP); later docs cover the same ground, but the text is not carried |
| #19 | **not fully preserved: decision needed** | the "private intake hardening, version 2" section (12 lines) of docs/M2-PRIVATE-OBJECTIVE-INTAKE-HANDOVER.md exists only on #19 (lead's doc) |

Recommendation: before closing #2 and #19, either carry the missing text over
in a reviewed docs PR or record that it is superseded.

## 8. First production milestone

1. **Proposal A Stage A1** (#41 section 4): v2 record builder and in-memory
   round trip of all 9,159 quests, counts only, no writes, no private exports,
   harness stays **1.2.0**. First production PR.
2. **Stage A2** separately: opt-in v2 export through SafeWrite, harness
   **1.3.0**, its own approval.
3. **Proposal B** (M2.3 engine) stays gated on the round 4 publication
   corrections (#42: no durability claim, fail-closed `PublishBundle` with
   tamper digest) being accepted by the lead, then on its own approval.
