# N-Questie — Stage A2 Integration Decision Package

**Prepared:** 15 October 2026. **Status: REVIEW ONLY — NOT AUTHORISED TO MERGE, RELEASE OR INSTALL.**

This package is the lead developer's L5 handover following the independent cross-review of the Stage A2 / safety stack. It is a **decision aid**, not an instruction to fast-forward `335`, merge old draft PRs, run private exports or implement Stage A3/M2.3. It is intentionally written on a **new documentation-only draft branch** so the exact seven-green source snapshot stays frozen.

## 1. Exact frozen references and evidence

| Item | Exact reviewed head | Verified evidence |
| --- | --- | --- |
| Current protected source branch `335` | `13c958005c0e3b27e3ef0ea3472998fa522a11a5` | Unchanged at this review; no production merge performed |
| Base integration PR #48 | `780e89cbe2957e8c65c33a95b4ebe61c50f33587` | 6/6 workflows successful |
| Stage A1 PR #51 | `dadebefc0e458af01efc3e0a7e5ce94c7441f52b` | 6/6 workflows successful |
| Grok Stage A2 PR #56 | `11f58f687eb07febdf1c9a84208d29ae5f499407` | 6/6 workflows successful; revised `CheckoutState` requires `realpath` exit code 0 |
| Final test-only combined PR #63 | `3f2a430c7142c036ec5517d04f59bec4a012b2aa` | **7/7 workflows successful**; includes dedicated full M2 F1–F8 rehearsal |

Git ancestry, verified with exact-commit comparisons: #48 → #51: 3 ahead / 0 behind; #51 → #56: 11 ahead / 0 behind; #56 → #63: 1 ahead / 0 behind (**20 changed paths**). Relative to #48, #63 is 15 commits ahead and modifies 46 paths. Relative to current `335`, #63 is **304 commits ahead / 0 behind, across 186 changed paths**; that broad inherited integration scope requires its **own complete source diff review**, not just Stage A2's checks. These counts apply only to the pinned heads.

## 2. Technical acceptance already passed

- On #63's exact head: 169 Busted successes / 0 failures / 0 errors / 0 pending; M0 232 checks and 82,431 compiled fields; 40 SafeWrite checks; 124 v2 exporter synthetic checks; 31 checkout-state checks; 9 verify-CLI checks.
- The mutation runner reports **73 passed / 0 failed / 0 skipped** (72 mutants plus the unmutated control, per Grok's independent report). This is **not** evidence of mutation coverage for the *new* #61/#62 paths, which Grok identified separately.
- Complete F1–F8 integration on the real **public** compiled quest data: 111 passed / 0 failed; 9,159 compiled quest IDs; 8,401 v1-representable and 758 unsupported; zero structural round-trip differences and zero v1-equivalence differences.
- Original `EffectiveExport.lua`, `EffectiveSchema.lua`, `Coverage.lua`, and the 5,647-byte v1 output golden remain pinned/tested. The shared `InputSchema`, `SafeWrite` and `ExportProvenance` helpers are **deliberately changed**: v1 is preserved by tests, but the entire v1 dependency tree is **not byte-identical**.
- No private server export, live worldserver, client installation, SavedVariables or database rows were used or modified for the #63 public CI.

Primary evidence: [combined draft #63](https://github.com/CosmicCuddle/N-Questie/pull/63), M2 run `38729475847`, full rehearsal `38729475706`, and Grok's independent read-only review comment (15 October 2026).

## 3. Consolidation — what must NOT be replayed

The tested source lineage is #48 → #51 → #56 → #63. It does **not** follow that the historical review PRs should each be merged again. In the final tree:

| Draft source | Disposition in #63 |
| --- | --- |
| #49 and #50 | Documentation and canonical-path private-1203 test/helper blobs are exact copies of reviewed sources |
| #52, #54, #55 | Input resolver, provenance and NoWriteGuard helpers/tests are exact reviewed blobs |
| #53 | SafeWrite is **superseded** by the later #61/#62 post-publication protections. Do not restore the older #53 SafeWrite blob |
| #57 | A2 export preflight fix is **adapted** to newest Grok CLI/integration tests. Do not overwrite with the older #57 files |
| #61 and #62 | Final v2 post-install human-review handling and failed temporary hard-link unlink detection are included as reviewed exact blobs |
| #58, #59, #60 | Historical test-only rehearsals, not additional features to merge independently |
| #63 | Frozen combined verification snapshot, **not a direct production merge instruction** |

Grok confirmed that `CheckoutState.lua`, 31-check verification tests, verify CLI and the 72-mutant shell script from #56 have identical Git blob identities in #63. A complete future integration also needs to preserve the earlier 28 reviewed quest-level fixes, custom quest 2001, cache revision protection, M0/M1 strictness and relevant copyright/attribution.

## 4. Grok cross-review observations and decisions

**Observation 1 — hard integration exclusion:** `.github/workflows/nquestie-a2-fullsuite-review-2026-10-15.yml` is a **temporary test-only workflow** with an unrestricted `pull_request` trigger. It must **not** be integrated unchanged into `335` or the long-lived integration line; otherwise it would run on every PR. Preserve the evidence from #63, and if full-suite CI is desired permanently, first propose and review a deliberately scoped replacement workflow. Never quietly import the review workflow.

**Observation 2 — optional additional regression strength:** Grok saw no reproduced bug, but the final published-status mapping and status-marker capture are not covered by mutants. Suggested narrow synthetic mutation tests: bypass `writerState.published == true`; remove the third return result on failed temp unlink; accept a non-zero `NQ_SAFEWRITE_EXIT`. Existing positive/negative unit tests are green. Decide explicitly whether these additional mutants are required before release. A separate draft test-only PR is preferred; do not silently rewrite the frozen #63 head.

**Observation 3 — documentation reconciliation:** After #54, `ExportProvenance` and frozen `CheckoutState` use different text for top-level/root verification failures. Both reject the error, but a results-doc assertion that they use the **same message codes** is no longer literally accurate. Correct this claim in a separate scoped documentation diff before production integration; do **not** change working error behavior merely to make the wording identical.

Grok's G2 review was **acknowledgment of the preserved logic, not permission to merge**. Its three observations are recommendations/limitations rather than reported runtime regressions.

## 5. Proposed integration sequence (NONE of the actions below has been executed)

### Gate I0 — Maintainer scope approval

Maintainer approves the **scope of a future test-only clean-room integration candidate**. Freeze source branch, `335`, and approved PR heads. Decide how the review-only workflow is excluded, which optional mutations to require, and whether the inherited #48 scope is still desired in full. No merge, release, rebase or force-push.

### Gate I1 — Clean-room candidate, after I0

On a **new dedicated branch** anchored to the current verified `335` head, stage only approved combined source files, docs and production workflows. Do **not** click-merge 63 separate old PRs, reset their branches, or import the A2 full-suite **review-only** workflow. Keep source blobs/identity manifest for security-critical files and document the exact final file list. Confirm no private archives, SQL, generated per-quest reports, source fingerprints, secrets or SavedVariables are tracked. Verify changes to TOC, cache revision, addon runtime loader, existing quest overlays and attribution independently. Stop on any unexpected diff.

### Gate I2 — Prove the actual proposed production source tree

Run all **six standard GitHub workflows** on the precise new candidate head: M0, M1, M2, overlay, revision guard and CI. Re-run the full public/synthetic M2 acceptance (`bash tests/run_m2_suite.sh`, including F1–F8) in a temporary independent review checkout **whose executable source files match the candidate's exact tree**, and retain immutable test identity/evidence. If a temporary CI workflow is used, isolate it to a separate test-only branch/PR; do not include it in the production tree. Check 9,159 IDs, 8,401/758, zero structural and v1 differences, 169 Busted tests, 0600/0700, no-clobber and postpublication review behavior. Re-run all checks on *any* changed head. Resolve any failures without weakening M0/M1, v1 golden or privacy boundaries.

### Gate I3 — Private server-source authenticity (separate local step)

On a trusted Linux **development checkout**, not the live AzerothCore worldserver, a human locally validates only the real **quest 1203** `nq-m2-input` document with Lua 5.1 using the read-only `cli/check-private-1203.lua` gate. Its immediate parent directory must be owned mode 0700; the input regular file owned mode 0600; the input must resolve **outside** the public checkout. Optionally hash-check the **exact original** offline archive with the `--archive` option; check the exporter's actual source selection and snapshot time separately. Report only PASS/FAIL/MATCH/NOT VERIFIED summaries. Never post private filenames, rows, paths, fingerprints or the archive. A format PASS is **not** an M2.3 match and not proof of live-world freshness.

### Gate I4 — Approved human game-client QA

Only after separately approved backup/testing permission: protect the installed N-Questie addon and SavedVariables, verify rollback, test quest 2001 starter/ender marker lifecycle, the 28 reviewed levels, the known quest 1203 display, and **objectiveIndex quest IDs 10985, 13429, 12124, 13418, 13419** at their appropriate IP stages and client locales. Check map/minimap objective and completion lifecycle, no false location markers and unrelated native-quest behavior. Keep screenshots/logs private unless explicitly reviewed for disclosure. If QA fails, prepare a new narrow draft correction; do not patch the live environment to force a passing report.

### Gate I5 — Final merge and release decision (new authorisation required)

Present the exact source-to-`335` diff, cross-review acknowledgments, all test links, private-1203 status, five-quest manual QA, backup/rollback plan, licence/attribution status, known remaining SafeWrite path races and **no fsync / no power-loss durability guarantee**. Only the maintainer can approve a final controlled merge. Installation, release/tag creation and Addon Collection update are **distinct later approvals**, not side-effects of green CI. Re-verify after each approved change.

## 6. Workstream ownership and next checkpoint

| Workstream | Next responsibility |
| --- | --- |
| Lead / ChatGPT | Maintain the frozen evidence register, give the maintainer an explicit decision matrix, make any scope-approved *new* integration test candidate; privately guide quest-1203 and in-game QA without server access or uploads |
| Grok | G2 review is complete; provide G3 Stage A2 limitations/technical handover and identify optional missing safety mutants or doc inaccuracies. M2.3 remains **design review only** |
| Maintainer | Decide when to authorise I0, any private developer-machine run, any client QA/backups, a later merge or release. No permission can be inferred from this package |

**Decision recommendation:** The Stage A2 **public/synthetic validation and compatibility** checkpoint is technically successful; the software is **not yet approved for `335` integration, production installation, automatic corrections or release**. Preserve #63 unchanged. Progress only through the explicit gates above.
