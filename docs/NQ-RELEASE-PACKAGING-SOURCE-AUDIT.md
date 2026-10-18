# N-Questie — read-only 3.3.5a packaging and distribution source audit

**Status:** DRAFT source inventory, 18 October 2026. No **official/tagged release ZIP** was built or published by this investigation; **existing PR CI has previously uploaded downloadable QA test-build artifacts** (see §2A), which must be distinguished from tagged releases and from unbuilt local source audits. No release tag, file removal, private export or addon installation was performed by this investigation; no legal determination or release permission is implied.

**Frozen inspected baseline:** protected `335` at `2be0f6f3001a20242c2fe81cb1915ff18602a4c8`. Everything below describes the *source paths present at that commit*, not an observed release artefact. The existing [living master checklist](NQ-LIVING-PROJECT-MASTER-CHECKLIST.md) controls completion gates, and [Grok's single CS02 queue](https://github.com/CosmicCuddle/N-Questie/pull/42#issuecomment-6248354348) contains CS02-32 for independent source/packaging review.

## 1. Two materially different addon entry points

| Question | 3.3.5a N-Questie source on `335` | Inherited upstream/retail Classic paths |
| --- | --- | --- |
| Client / display identity | `Questie-335.toc`: `## Interface: 30300`, display title **N-Questie**, version **9.5.1.1**, inherited author line | `Questie-WOTLKC.toc`: `## Interface: 30403`, display title **Questie** v9.5.1; `Questie-Classic.toc`: `11502`; `Questie.toc`: unsupported-client fallback `00000` |
| Loader include | `Questie-335.toc` line 23 includes **`Compat\\embeds.xml`**; lines 88–93 list curated `Compat\\NQuestie...` Lua files | `Questie-WOTLKC.toc` and `Questie-Classic.toc` include root **`embeds.xml`** |
| Krowi Lua include | In `Compat/embeds.xml`, the Krowi `<Script>` directive is **XML-commented out** | In root `embeds.xml`, the Krowi `<Script file="Libs\\Krowi_WorldMapButtons\\Krowi_WorldMapButtons-1.4.lua"/>` directive is **active** |
| Implication | A manually selected **3.3.5a** manifest differs materially from the upstream classic manifests | Do **not** assume root `embeds.xml` is the actual 3.3.5a loader; equally, do **not** assume the inactive 3.3.5a Krowi include makes the file absent from any ZIP |

**Source locations:** [Questie-335.toc](../Questie-335.toc), [Questie-WOTLKC.toc](../Questie-WOTLKC.toc), [Questie-Classic.toc](../Questie-Classic.toc), [Questie.toc](../Questie.toc), [Compat/embeds.xml](../Compat/embeds.xml), [root embeds.xml](../embeds.xml). Exact 335 content was read before this draft.

## 2. CRITICAL: the inherited build script is not a validated N-Questie/3.3.5a packaging path

The source [`build.py`](../build.py) sets:

- `addonDir = 'Questie'`. A generated archive contains a **Questie** folder, whereas the current 3.3.5a QA/readme uses an installed **Questie-335** folder.
- `directoriesToInclude = ['Database', 'Icons', 'Libs', 'Localization', 'Modules']`. That is a **broad directory copy**, not a manifest-only subset. It does **not** list `Compat`, which contains the N-Questie loader and curated quest data/correction files.
- `filesToInclude = ['embeds.xml', 'Questie.lua', 'Questie.toc']`. It does **not** list `Questie-335.toc` or `Compat/embeds.xml`; this root `embeds.xml` has a different Krowi inclusion than the 335 compatibility loader.
- `tocs = ['', 'Questie-Classic.toc', 'Questie-BCC.toc', 'Questie-WOTLKC.toc']`. Default expansion selection is Classic and retail Wrath; the 3.3.5a `30300` manifest is never added.
- The copying loop walks the **root** first and copies the named directories wholesale, excluding patterns such as `*.test.lua`, rather than calculating exactly which runtime files the 335 TOC references.

**Source-derived result:** Invoking the present `python build.py -r` does **not produce an evidenced valid N-Questie 3.3.5a package**. Its intended directory, TOC and root loader are for a different client/build. **Do not run it to build, tag or distribute N-Questie without an explicitly reviewed replacement/adaptation and tests.** The source comparison alone does not assert that the old script fails to build its original upstream Questie flavour.

### Distribution trigger that needs an explicit guard

The inherited [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) defines a **`publish` job** conditional on `startsWith(github.ref, 'refs/tags/v')`. The job runs `python build.py -r` and then contains steps to **create a GitHub release, upload to CurseForge and upload to WAGO**. Whether external uploads succeed depends on permissions/tokens/services; **the workflow instructions themselves are present**. Merely merging a draft does not meet that tag condition.

**Safety gate:** Do not create/push a `v*` release tag as a test. A future 3.3.5a-specific, fail-closed, human-approved release plan should specify the correct folder, `30300` TOC, complete `Compat` files, missing-file refusal, inclusion allowlist, third-party licence/credit review, test logs and explicit publisher control. This is a **proposal only**, not implementation authorisation. The inherited [`release.py`](../release.py) also targets upstream Classic/WOTLKC TOCs and creates a tag; do not invoke it for N-Questie.

## 2A. Confirmed historic PR-only QA build uploads — separate from tagged releases

**Correction to the initial read-only audit:** the existing [3.3.5a overlay workflow](../.github/workflows/nquestie-overlay.yml) also contains two **`pull_request`-only** steps: `Assemble PR-only WoW 3.3.5a addon package` and `Upload temporary N-Questie PR test build`. These directly `cp -R Compat Database Icons Libs Localization Modules` into a temporary `qa-package/Questie-335` folder, copy the 335 TOC and root `embeds.xml`, and use GitHub `actions/upload-artifact@v4` with 14-day retention. The workflow is **not** the old release-tag `build.py` path; nevertheless, it creates a **downloadable QA test build** which can contain the broadly copied rights-unclear icons/Krowi files. The uploaded artifact is not necessarily an addon already installed or a marketplace release.

**Observed existing artifact:** GitHub [overlay run `39153149060`](https://github.com/CosmicCuddle/N-Questie/actions/runs/39153149060) exposed artifact `N-Questie-335-PR-TestBuild`, ID `12145947337`, **35,107,043 bytes** and not expired when inspected on 18 October. This is live workflow evidence, **not merely a guess from YAML**. Existing previous-run artifacts are not deleted or retroactively made safe by a new draft branch; retention policy and repository access determine future availability. No artifact download, removal, re-upload, or public distribution action was performed in this audit.

**Isolated safety proof:** [DRAFT PR #102](https://github.com/CosmicCuddle/N-Questie/pull/102) current initial head `cd594fabc82d43c05e6df6914efef68ad873ebfe` makes two changes **only on its own branch**: adds nine test-only/read-only 3.3.5a manifest preflight unittests and sets the two inherited automatic PR artifact steps to `if: ${{ false }}` during review. Its [dedicated overlay run `39157421599`](https://github.com/CosmicCuddle/N-Questie/actions/runs/39157421599) **PASS** showed `Ran 9 tests / OK`, both assembly/upload **SKIPPED**, and GitHub artifacts list returned `total_count=0`. Full six-workflow CI and independent CS02 review must be checked separately. **This branch-only hold is NOT a global fix**; other old PRs can continue using inherited upload steps until a separately reviewed approved policy change is integrated.

**Required maintainer gate:** decide how (or whether) to make private QA builds available to collaborators before third-party file rights are verified, and whether future CI should require explicit owner review/authorization for artifact upload. Do **not** create `v*` tags, publish market releases, or delete source artwork simply to silence this warning. A rigorous future staged-file check must also assess **any included root `embeds.xml` and its active Krowi reference**, even when the selected 335 `Compat/embeds.xml` comments it out.

## 3. Asset inclusion, source licences and remaining evidence

| Component | Source-tree evidence | Inclusion in **legacy `build.py`** | Inclusion in a **future reviewed 335 ZIP** | Source-rights action before public distribution |
| --- | --- | --- | --- | --- |
| `Libs/Krowi_WorldMapButtons/**` | [Krowi licence](../Libs/Krowi_WorldMapButtons/LICENSE.md) says changes for private use, permits upload to GitHub as a narrow exception, restricts publishing elsewhere, and requires notice. The library is not included by the active 335 `Compat/embeds.xml` directive; it **is** included by root `embeds.xml`. | **Yes, copy path:** entire `Libs` directory is copied; the root loader also has an active Krowi reference. (This is a code-path inference, **not an inspected ZIP**.) | **NOT DECIDED:** actual 335 package inclusion must be inventoried and permission verified; a commented-out 335 loader is not a legal permission or proof of ZIP omission. | Independent reviewer/maintainer to verify source permissions, desired inclusion, any required rightsholder consent and original notice. **Do not silently drop a dependency.** |
| `Icons/**` | [Icons/LICENSE.md](../Icons/LICENSE.md) explicitly lists individual MIT-covered assets; for other icons it states licensing is unclear and they should be treated as all rights reserved. [Icons/MIT.txt](../Icons/MIT.txt) contains copyright and notice conditions. | **Yes, copy path:** entire `Icons` directory is included except script test ignore patterns. This is **not** proof that all files are MIT. | **NOT DECIDED:** build an explicit file-level whitelist/rights and runtime-reference inventory for included icons. | Review each asset actually shipped, preserve required notices, and obtain rights clarification where needed. |
| Other `Libs/**` | [Libs/LICENSE.txt](../Libs/LICENSE.txt) contains another redistributable-with-conditions notice; individual embedded libraries may have their own licences. | **Yes, copy path** via the entire `Libs` folder. | **NOT DECIDED:** capture exact dependency inclusion and individual terms. | Retain notices; review any more restrictive component-specific licence; no blanket relicense inference. |
| Upstream source/TOC | [README](../README.md) attributes `divial28/Questie-335`; `Questie-335.toc` has upstream author list. No top-level `LICENSE`/`NOTICE` file appeared in the inspected 1,065-path tree. | Upstream builder produces different `Questie` identity and TOC selections. | **NOT DECIDED:** approved 335 manifest and credits are part of release QA. | Verify upstream and individual rights/credits independently; root-licence absence is **not** a legal conclusion. |
| `ExternalScripts(DONOTINCLUDEINRELEASE)/**` | Separate development/tool files, excluded from `build.py` by omission; `.gitattributes` also has export-ignore rules for Git archives. | **Not in `directoriesToInclude`.** | **Exclude unless separately authorised**. | No source or private generated data should be bundled accidentally. |
| `Compat/**` | Contains the **actual current 3.3.5a N-Questie loader and curated source files**. | **No**, missing from legacy builder's directory allowlist. | **Required by the 335 TOC**, subject to reviewed field-level package manifest. | Check every referenced file exists and all compiled source/lua syntax checks pass for the 3.3.5a release candidate. |

### Frozen file-level counts for rights triage (not legal clearance)

Read-only inspection of protected `335` Git tree found **909 tracked files across 1,065 tree entries**. `build.py`'s broad-copy source directory groups contain **53 `Icons/` files (51 image files plus two licence texts)** and **102 `Libs/` files**, including **7 files under `Libs/Krowi_WorldMapButtons/`**. These are tracked **source inventories**, not a claim that a ZIP has been generated.

Within `Icons/`, the existing `Icons/LICENSE.md` lists **18 individual MIT-covered image filenames**, and all 18 appear in the protected tree. The other **33 image files** are **not on that licence's named MIT list** (29 `.blp` and 4 `.tga`). The same document directs readers to treat unspecified assets as all rights reserved/unclear. **Do not infer that any of those 33 files are available for redistribution under MIT**. They need independently sourced permission/licence and an **actual proposed package inclusion** check; do not remove them without checking their references and obtaining approval.

The inherited broad-copy code can include all 53 `Icons/` files and the Krowi subtree even though the **3.3.5a runtime's** Krowi include is XML-commented out. **This reinforces the difference between a file being referenced at runtime and being copied into a release artifact.** Licence files' presence or absence in a source tree alone is not a legal clearance finding.

**Important distinction:** `.gitattributes` includes `export-ignore` rules for Git archive operations; it does **not** override the Python `build.py` explicit `shutil.copytree` selection. Likewise, a source file existing in GitHub does not establish that an approved release will contain it.

## 4. Source file-reference completeness baseline — verified read-only, not a package test

An additional static path-inventory pass on the same protected `335` commit parsed the **enabled** file paths from `Questie-335.toc` and from all of its directly/nested-reachable XML include files. It removed XML comments first, resolved backslash paths and `../` references relative to the declaring XML file, then compared exact case-sensitive paths with GitHub's **1,065-entry** repository Git tree.

| Reference group | Active file references seen | Missing exact paths from `335` |
| --- | ---: | ---: |
| `Questie-335.toc` (including 6 XML entry files) | **143** | **0** |
| `Compat/embeds.xml` direct enabled `Script/Include` references | **26** | **0** |
| Five directly loaded localisation/lookup XMLs (44 translation and 9 in each of four WotLK lookup files) | **80** | **0** |
| Fifteen active library XML files referenced from `Compat/embeds.xml` | **43** | **0** |
| **Total reference occurrences (not distinct files)** | **292** | **0** |

A total of **21 XML files** in that statically reachable set were inspected: `Compat/embeds.xml`, five localisation/lookup XMLs and fifteen library XMLs. No nested XML children were found in those fifteen library files, and all of their 43 declared script targets resolved to actual paths. This is a source **presence/relative-path/case** survey on `335`; it does **not** execute Lua, prove addon load order semantics, inspect dynamically computed asset names, certify legal rights or produce a ZIP.

This result reinforces the core packaging distinction: **the correct `335` source tree has all 292 directly declared reference occurrences resolvable**, while `build.py`'s **different selection of directories and TOC** would omit the essential `Compat/` subtree and 335 TOC. It does **not** validate an as-yet-unbuilt release. Any future package preflight must re-resolve this graph against the **actual staged package root** (not just Git) and fail closed on a missing target or case mismatch.

### Package preflight design requirements (proposal only)

- Parse the *selected* `Questie-335.toc`, not an arbitrary upstream TOC; require the expected `30300` interface and owner-approved folder identity.
- Strip comments from XML before following `Script` and `Include` references; resolve nested paths relative to each declaring XML, reject references leaving package root, and track visited XML files to reject dangerous cycles.
- For each enabled source reference, check its exact path in the **would-be package manifest**; report missing, duplicate, case-mismatched, and selected-but-unreferenced files as separate categories. Some Lua, textures, libraries and data are referenced dynamically; **unreferenced does not mean safe to delete**.
- Build a separate **non-executable, source-backed** licence/notice inventory for file-level inclusion, including `Icons/`, `Libs/` and original copyright/attribution. Do not equate “not loaded by the selected TOC” with “not copied into a zip”.
- Do not use the inherited `build.py -r` or `release.py` for a proof-run. No `v*` tag, GitHub release, CurseForge/WAGO upload or local addon overwrite is authorised by these source checks.

## 5. Proposed 335 package acceptance tests — partial test-only preflight on draft #102

1. **Manifest:** The package root folder is the owner-approved `Questie-335` name, with one `Questie-335.toc` indicating interface `30300`; no simultaneous duplicate Questie installation. Do not substitute `Questie-WOTLKC.toc` (`30403`).
2. **Required paths:** Every enabled `Questie-335.toc` and embedded XML `Script`/`Include` source resolves inside the package, including the N-Questie `Compat/` data and cache-revision components; prohibit path escapes, unreadable files and accidental case/path changes.
3. **No unintended extras:** Compare a recorded exact file manifest with an allowlist; exclude world DB exports, private reports, SavedVariables, debug scripts, test fixtures, unrelated expansion assets, and rights-unverified resources. **Do not assume excluding an icon is safe without usage review.**
4. **Licence/credits:** Record precisely which files will ship and which notices/permissions apply. Preserve upstream authors. Do not label a source asset MIT merely because a different icon in its folder is MIT.
5. **Nonpublication:** A proof/check must **not** create a release tag, run upload scripts, alter the installed addon or server, or upload a ZIP. CI dry validation should output only safe aggregate/pass-fail data.
6. **In-game acceptance after approval:** Back up both the current addon folder and Questie account/per-character SavedVariables, install only one approved QA build, verify original quest-2001 basic lifecycle **already recorded as passed on 14 Oct** plus remaining objective/minimap/cache/phase/IP axes, and confirm a rollback.

The **read-only manifest path/XML subset** is now covered by [draft #102](https://github.com/CosmicCuddle/N-Questie/pull/102) nine synthetic tests and a source-file reference-count assertion. **Full staging ZIP provenance, dynamic image references, third-party permissions, deployment/install, auto-upload policy, and user-side game QA remain OPEN.** Neither the tests nor a skipped artifact upload constitute a licence clearance or a distributable addon.

## 6. Review task and handoff

- **CosmicScript01 source-audit state:** paths and conditions above confirmed by reading frozen `335` source; no packaging command executed.
- **CosmicScript02 task CS02-32:** independently verify the exact inclusion paths, especially **root versus Compat XML and legacy Python builder**, and distinguish source licensing from the actual compiled ZIP. Record PASS / OWNER OR RIGHTSHOLDER CHECK / NOT TESTED. Reviewer may request corrections but no autonomous release/packaging modification.
- **Maintainer decisions later:** first release scope; any third-party rights or substitutions; client QA authorization and backups; separate protection against accidental `v*` auto-publishing; final integration and release. No decisions presumed.
