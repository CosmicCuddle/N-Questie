# N-Questie — guarded integration candidate #137 and remaining QA gates

**Date:** 19 October 2026  
**Status:** DRAFT READ-ONLY HANDOFF. No authority to merge, install, package, upload, tag, release, access private records, or change production.  
**Integration candidate:** [draft PR #137](https://github.com/CosmicCuddle/N-Questie/pull/137), exact commit `3b5e3a90c2194b7d6b214e7d280b0a8248d0d5aa`.  
**Protected production branch:** `335` at `2be0f6f3001a20242c2fe81cb1915ff18602a4c8` when this handoff was written. Recheck it before any eventual owner-authorized action.

## 1. What is ready, and what is not

| Gate | Actual evidence as of this checkpoint | Decision |
|---|---|---|
| **Combined public CI** | Exactly six `pull_request` workflows SUCCESS on #137's **same SHA**, including M0, M1, M2, overlay, revision and general CI. | **PASS — CI only** |
| **No-upload CI** | All six exact-head artifact listings empty; overlay package assembly and artifact upload both SKIPPED. | **PASS — no new QA ZIP** |
| **Source provenance** | One integration commit changes exactly six test files relative to reviewed #135; all six file Git blob SHAs equal their respective reviewed #128/#129/#130/#131/#132/#134 sources. | **PASS — file identity only** |
| **Combined reciprocal review** | CosmicScript02 has been asked to inspect #137 **and run it in a fresh checkout**; separate earlier peer reviews do not automatically cover the combined head. | **PENDING** |
| **Four new Python suites in CI** | `test_generate_custom_quests_json_roots.py`, `test_generate_custom_quests_numeric_types.py`, `test_audit_world_quest_levels_counts.py`, `test_audit_world_quest_levels_columns.py` are in #137 but **not invoked** by its existing Actions workflow. | **NOT RUN IN CI** |
| **Real private M2.1 Quest 1203 input validation** | Existing pilot/runbook says the selected private input has not been validated by a genuine Lua 5.1 invocation on a trusted operator machine. | **NOT VERIFIED** |
| **Real-client Quest 1203** | Offline/synthetic correction for item 3853 passes, but real quest-log/objective/turn-in behavior on current server is not established. | **NOT VERIFIED** |
| **Real-client Quest 2001** | Maintainer already checked starter marker, initial **0/8** NPC-objective pins, completed turn-in marker, hand-in removal, normal Questie icons/settings on an earlier QA addon. | **PARTIAL IN-GAME PASS — not full QA** |
| **Package, third-party distribution rights, production integration** | `335` has a different artifact-producing workflow, and branch-local suppression in #137 is not a production rollout plan. Licensing, final contents, release and installation still need owner clearance. | **NOT AUTHORIZED** |

**Important:** The diff from #137 to production `335` contains tests, documentation and one branch-local guarded CI workflow only. **There are no new addon-runtime, TOC, compiled quest-data or gameplay changes in this particular combined candidate.** A fully green #137 alone cannot prove new in-game features or justify an immediate release. Earlier runtime functionality already present on `335` must be evaluated on its own merits.

## 2. Offline validation — independent reviewer / safe development checkout only

Run these **only in a trusted temporary development checkout** of the *exact* #137 SHA. Check `pwd`, `git rev-parse HEAD` and `git status --short` first. Do **not** run inside AzerothCore's live worldserver directory or an installed WoW addon. The commands below neither require nor should be given private SQL/ZIP files, real player data or secrets.

```bash
git rev-parse HEAD
git status --short
lua5.1 tests/test_nquestie_overlay.lua
lua5.1 tests/test_nquestie_existing_quest_1203.lua

# Four already-authored, synthetic stand-alone suites missing from Actions:
python3 tools/test_generate_custom_quests_json_roots.py
python3 tools/test_generate_custom_quests_numeric_types.py
python3 tools/test_audit_world_quest_levels_counts.py
python3 tools/test_audit_world_quest_levels_columns.py

# Optional cross-check of all offline Python test modules, WITHOUT -t .:
python3 -m unittest discover -s tools -p 'test_*.py' -v
git status --short
```

Record each command's exit code and test count. Record any intentionally skipped test as **SKIPPED**, not PASS: the audit counts suite contains an intentionally unresolved repeated-correction policy case. Do not infer CI execution from the fact that old generator/exporter/audit suites pass.

**Unapproved CI runner proposal:** CosmicScript02 proposed using `python3 -m unittest discover -s tools -p 'test_*.py' -v` in a **separate guarded draft** to cover new Python modules, with explicit module-count/name checks against quiet omissions. This proposal has **not changed #137 or `335`**. Before changing an Actions workflow, obtain the maintainer's explicit approval for the exact bounded scope; keep both Assemble/Upload `if: ${{ false }}` safety holds and all Lua M2 workflow ownership intact. A proposed discovery count from an author-local synthetic overlay is evidence to verify, not a permanent benchmark.

## 3. Outstanding in-game acceptance — only after a separately approved QA build

**Preflight and backup (required before any future installation):**

1. Obtain explicit maintainer approval for the exact build SHA, redistribution/package contents and a controlled in-game test. **No test ZIP or installation is supplied by this document.**
2. **Close WoW fully.** Copy the existing `Interface/AddOns/Questie-335` folder to a separate dated backup location. Independently back up the related account/character Questie **SavedVariables**. Verify the backup copies exist and are readable before changes.
3. Have a tested restore procedure for both the addon directory and SavedVariables. Do not erase live settings or use two copies of Questie simultaneously.
4. Test a legitimately eligible character only. Preserve server-authoritative faction, prerequisite, quest completion, phasing, and Individual Progression restrictions. **Do not grant quests, remove prerequisites, teleport to inaccessible phases, or change production SQL to force a PASS.**
5. Capture screenshots/observations privately. Avoid uploading player identifiers, private SQL, account information or character-specific exports to public GitHub.

**Quest 2001 — Ravenclaw Cleanup:** Do not repeat the previously verified entire basic lifecycle merely to rebuild evidence. Target still-open points: record an **intermediate** count update (for example 0/8 → 1/8) for both relevant objectives independently; verify **quest-specific minimap** pins separately from world-map pins; compare relevant NPC 2121 / 1868 / 1869 map locations against **active** server spawn/phase when approved; check proper prerequisite quest **437**, faction/IP-stage eligibility without bypasses; and perform a `/reload` persistence check. Record each as PASS / FAIL / NOT TESTED, with build SHA.

**Quest 1203 — Moonsteel Broadsword item objective:** First perform the genuine private M2.1 selected-input Lua 5.1 validation using the pre-existing trusted operator runbook, keeping files and results private. The intended offline effective objective uses **item 3853** rather than inherited **33110**, but static equivalence and synthetic Lua tests are not real server proof. On a separately approved QA build, compare the **actual current server quest-log text, required count, item credit and turn-in transition** with client display. Confirm unrelated objectives and ordinary Questie functionality still work. If there is a mismatch, collect evidence privately; **do not silently edit the correction or world database**.

**Other 16-quest M2.2 pilot records:** Public compiled representations have been checked previously, but server equivalence/in-game markers are mostly **NOT TESTED**. Follow `docs/NQ-PILOT-QUEST-QA-MATRIX.md`; prioritize explicit kinds (gameobject, item source, KillCredit, trigger) without reducing them to a single generic counter.

## 4. Action owners and stop conditions

- **CosmicScript01:** hold #137 source HEAD, maintain the master checklist and independent review trail; audit new build/CI evidence, report blockers without inferring approvals.
- **CosmicScript02:** independently review and execute the exact combined source; post separate PASS / CHANGES REQUESTED / NOT TESTED for #137, plus a bounded discovery-runner proposal in [coordination PR #42](https://github.com/CosmicCuddle/N-Questie/pull/42). No silent workflow changes or workstream overlap.
- **Maintainer:** approve any actual CI workflow expansion, private M2.1 run, QA addon build/install, packaging/licensing decision, production `335` merge, release or real-game acceptance.

**Stop immediately** on changed production SHA, unexpectedly produced/uploaded artifacts, private data in a proposed Git diff, a failing exact-head test, unplanned server writes, or an unavailable/incorrect backup. Report the evidence and ask for the appropriate owner decision; do not work around a guard.

**No release date or completion percentage is implied by this checklist.** This is a bounded, evidence-based path from a reviewed public test candidate to the remaining operator-held gates.
