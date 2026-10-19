# N-Questie 3.3.5a — Release rights and package-source preflight

**Status: GUARDED RESEARCH / NOT A RELEASE APPROVAL.** Source reference: protected `335` at `2be0f6f3001a20242c2fe81cb1915ff18602a4c8` (checked 19 October 2026). This note is evidence for a future maintainer decision, not a legal determination, licence grant, installable package, or permission to publish anything.

## 1. Two separate source-to-package pathways exist

| Path | Actual source observations | Decision before use |
| --- | --- | --- |
| `.github/workflows/nquestie-overlay.yml` on `335` | PR-only **Assemble** at lines 61–81 copies `Questie.lua`, `Questie-335.toc`, `embeds.xml`, and entire `Compat/`, `Database/`, `Icons/`, `Libs/`, `Localization/`, `Modules/` trees into `qa-package/Questie-335/`. PR-only **Upload** at lines 82–90 invokes `actions/upload-artifact@v4`, retention 14 days. Both steps are conditioned on `github.event_name == 'pull_request'` on production `335`, not disabled. | A PR QA artifact may contain third-party copyrighted assets. **Do not issue/download/redistribute a QA ZIP on the assumption that test-only packaging is authorised.** Obtain rights and intended audience decisions first; preserve existing workflow until separately approved. |
| Guarded development `nquestie-overlay.yml` | On peer-reviewed draft #143 (`151b8b1a70c1d46776999891bb86acd26640acb3`), both Assemble and Upload are byte-held by `if: ${{ false }}`; six-run zero-artifact evidence exists for that draft. | **Do not infer** this branch-local protection exists on `335`. Keep holds in every development draft unless the maintainer separately permits a narrowly defined package. |
| Inherited `.github/workflows/ci.yml` on `335` | `push` covers all tags; `publish` job at lines 160–200 uses `startsWith(github.ref, 'refs/tags/v')`, runs `python build.py -r`, attempts GitHub release creation, then CurseForge and WAGO uploads. | **Do not create or push a `v*` tag** without an approved and reviewed release-specific workflow/build route and content-rights/credentials review. A PR-only safe overlay does not disable inherited tagged publishing. |
| Inherited `build.py` on `335` | `directoriesToInclude = ['Database','Icons','Libs','Localization','Modules']`; `filesToInclude = ['embeds.xml','Questie.lua','Questie.toc']` at lines 151–152. The explicit list does **not** include `Compat/` or the N-Questie `Questie-335.toc`. | Inherited upstream builder is **not an approved N-Questie 3.3.5a package manifest**. This is a source-list mismatch; **not** a claim that its output was executed/tested. Do not use `build.py -r` as a N-Questie release path as-is. |

## 2. Distribution-rights evidence, specific files

| Source | Source text / SHA | Conservative conclusion |
| --- | --- | --- |
| `Icons/LICENSE.md` | Git blob `d4dcaef9a5235e275f3511b214017fd892d08de7`. The document names **19** `pfQuest`-derived images made available under MIT with permission, and states **other files in the directory have unclear licensing; consider them “all rights reserved.”** | Do **not** assume MIT covers every `Icons/` asset. Make a filename-by-filename licence/permission inventory before distribution. |
| `Icons/MIT.txt` | Blob `814bef05214ea042df6fbf0cf6e7358a216967fc`; Shagu MIT copyright notice must accompany covered works. | Retain the permission notice for every item confirmed to be under these terms. |
| `Libs/Krowi_WorldMapButtons/LICENSE.md` | Blob `3a204362419bf105b75bd7ea9841cf5706fb7710`: modified private use permitted, publicizing portions restricted **except an express GitHub website exception**; library/folder name must not change; notice retained. | The GitHub exception **does not automatically grant unrestricted packaged redistribution**. The production QA copy copies the entire `Libs/` tree, including this directory. Require explicit rights determination, source provenance/changes inspection and, if needed, holder permission or a separately reviewed lawful alternative. |
| `Libs/LICENSE.txt` | Blob `866fc34ea592d49b1dc0b1b3827c24e7be138858`; Ace3 notice allows conditions for source/binary redistribution but says stand-alone redistribution requires advance authorisation; forbids implied endorsement. | Keep relevant notices and independently inspect **each embedded library's own terms**. This umbrella file is not proof that all `Libs/` assets share one licence. |
| Root `LICENSE` | No root file named `LICENSE` exists in the checked top-level tree; per-directory notices do exist. | Missing a root licence file is **not proof that the whole fork is unlicensed**, but the effective package rights cannot be concluded from a single repository-root licence. |

**Caution:** File presence on GitHub and private access do not establish permission to distribute all contained assets. This is a source-review flag, not legal advice or a finding of infringement.

## 3. Real client requirements and currently proven tests

- `Questie-335.toc` on protected `335`: `## Interface: 30300`, `## Version: 9.5.1.1`, account SavedVariables `QuestieConfig`, per-character `QuestieConfigCharacter`. These identities must be preserved in any approved WoW 3.3.5a QA trial.
- `tools/test_nquestie_335_manifest_preflight.py` has a read-only `check_manifest` that verifies the reachable active TOC/XML dependency graph, including spelling, traversal and missing file guards. The existing source self-test expects **143 active TOC paths, 149 XML references, 292 total references, 21 XML documents** on its reviewed test head. This is **not** a real staged package pass and **not** rights clearance.
- The 14 October Quest 2001 in-game test verified initial marker/objective/turn-in/remove lifecycle **only**. Its distinct intermediate counters, minimap, active-spawn/phase/IP eligibility and reload regression remain open.
- Real private M2.1 selected-input validation for quest 1203 and real quest-log/item-3853 credit/turn-in have **not** been verified. Keep server exports/provenance private.

## 4. Release-readiness checklist (all unchecked until separately evidenced)

- [ ] **Select first-release scope:** list exactly which `335` runtime features are already there and what genuinely new changes would be merged; do not blindly merge divergent historical #2/#3/#13 branches.
- [ ] **Clear file-level rights** for each included `Icons/`, `Libs/`, any other third-party assets and required notices; record any permissions/attributions offline.
- [ ] **Approve a safe package manifest** specific to `Questie-335.toc` and `Compat/`; independently verify the complete staged TOC/XML dependency graph in a **non-published, explicitly authorised** QA context.
- [ ] **Decide PR-artifact policy for production `335`** and protect the inherited tag-triggered `ci.yml` release job before protected-branch integration or creating tags.
- [ ] **Back up before any approved QA install:** close WoW; back up existing `Interface/AddOns/Questie-335/` and account/character `QuestieConfig` / `QuestieConfigCharacter`; verify restore path; do not overwrite live settings for an unapproved test.
- [ ] **Run owner-approved in-game acceptance** against exact recorded source SHA, for Quest 2001 remaining checks, Quest 1203 private/real-client gates if in scope, and selected GO/KillCredit examples as appropriate.
- [ ] **Require reciprocal review, exact-head CI, written maintainer decision, and rollback plan** for any later merge, build, version/tag, public release or deployment.

## 5. Safety stop conditions

Immediately STOP and escalate if a proposed package adds `private/`, raw world SQL/ZIP, credentials, SavedVariables, unexpected third-party assets, a tag publish path, missing notices, or a changed protected `335` SHA. Do not paper over licence uncertainty by simply deleting required runtime dependencies; such an edit needs fresh feature tests, exact-head review and a separate owner scope decision.

**No files were copied into a package, no ZIP was created, no rights were granted, and no production/test workflow or server settings were changed by this research note.**
