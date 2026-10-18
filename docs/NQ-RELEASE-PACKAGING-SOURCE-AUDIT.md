# N-Questie — read-only 3.3.5a packaging and distribution source audit

**Status:** DRAFT source inventory, 18 October 2026. **No ZIP built, no tag created, no file removed, no private export or addon installation, no legal determination and no permission to release.**

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

## 3. Asset inclusion, source licences and remaining evidence

| Component | Source-tree evidence | Inclusion in **legacy `build.py`** | Inclusion in a **future reviewed 335 ZIP** | Source-rights action before public distribution |
| --- | --- | --- | --- | --- |
| `Libs/Krowi_WorldMapButtons/**` | [Krowi licence](../Libs/Krowi_WorldMapButtons/LICENSE.md) says changes for private use, permits upload to GitHub as a narrow exception, restricts publishing elsewhere, and requires notice. The library is not included by the active 335 `Compat/embeds.xml` directive; it **is** included by root `embeds.xml`. | **Yes, copy path:** entire `Libs` directory is copied; the root loader also has an active Krowi reference. (This is a code-path inference, **not an inspected ZIP**.) | **NOT DECIDED:** actual 335 package inclusion must be inventoried and permission verified; a commented-out 335 loader is not a legal permission or proof of ZIP omission. | Independent reviewer/maintainer to verify source permissions, desired inclusion, any required rightsholder consent and original notice. **Do not silently drop a dependency.** |
| `Icons/**` | [Icons/LICENSE.md](../Icons/LICENSE.md) explicitly lists individual MIT-covered assets; for other icons it states licensing is unclear and they should be treated as all rights reserved. [Icons/MIT.txt](../Icons/MIT.txt) contains copyright and notice conditions. | **Yes, copy path:** entire `Icons` directory is included except script test ignore patterns. This is **not** proof that all files are MIT. | **NOT DECIDED:** build an explicit file-level whitelist/rights and runtime-reference inventory for included icons. | Review each asset actually shipped, preserve required notices, and obtain rights clarification where needed. |
| Other `Libs/**` | [Libs/LICENSE.txt](../Libs/LICENSE.txt) contains another redistributable-with-conditions notice; individual embedded libraries may have their own licences. | **Yes, copy path** via the entire `Libs` folder. | **NOT DECIDED:** capture exact dependency inclusion and individual terms. | Retain notices; review any more restrictive component-specific licence; no blanket relicense inference. |
| Upstream source/TOC | [README](../README.md) attributes `divial28/Questie-335`; `Questie-335.toc` has upstream author list. No top-level `LICENSE`/`NOTICE` file appeared in the inspected 1,065-path tree. | Upstream builder produces different `Questie` identity and TOC selections. | **NOT DECIDED:** approved 335 manifest and credits are part of release QA. | Verify upstream and individual rights/credits independently; root-licence absence is **not** a legal conclusion. |
| `ExternalScripts(DONOTINCLUDEINRELEASE)/**` | Separate development/tool files, excluded from `build.py` by omission; `.gitattributes` also has export-ignore rules for Git archives. | **Not in `directoriesToInclude`.** | **Exclude unless separately authorised**. | No source or private generated data should be bundled accidentally. |
| `Compat/**` | Contains the **actual current 3.3.5a N-Questie loader and curated source files**. | **No**, missing from legacy builder's directory allowlist. | **Required by the 335 TOC**, subject to reviewed field-level package manifest. | Check every referenced file exists and all compiled source/lua syntax checks pass for the 3.3.5a release candidate. |

**Important distinction:** `.gitattributes` includes `export-ignore` rules for Git archive operations; it does **not** override the Python `build.py` explicit `shutil.copytree` selection. Likewise, a source file existing in GitHub does not establish that an approved release will contain it.

## 4. Proposed 335 packaging acceptance tests — NOT implemented

1. **Manifest:** The package root folder is the owner-approved `Questie-335` name, with one `Questie-335.toc` indicating interface `30300`; no simultaneous duplicate Questie installation. Do not substitute `Questie-WOTLKC.toc` (`30403`).
2. **Required paths:** Every enabled `Questie-335.toc` and embedded XML `Script`/`Include` source resolves inside the package, including the N-Questie `Compat/` data and cache-revision components; prohibit path escapes, unreadable files and accidental case/path changes.
3. **No unintended extras:** Compare a recorded exact file manifest with an allowlist; exclude world DB exports, private reports, SavedVariables, debug scripts, test fixtures, unrelated expansion assets, and rights-unverified resources. **Do not assume excluding an icon is safe without usage review.**
4. **Licence/credits:** Record precisely which files will ship and which notices/permissions apply. Preserve upstream authors. Do not label a source asset MIT merely because a different icon in its folder is MIT.
5. **Nonpublication:** A proof/check must **not** create a release tag, run upload scripts, alter the installed addon or server, or upload a ZIP. CI dry validation should output only safe aggregate/pass-fail data.
6. **In-game acceptance after approval:** Back up both the current addon folder and Questie account/per-character SavedVariables, install only one approved QA build, verify original quest-2001 basic lifecycle **already recorded as passed on 14 Oct** plus remaining objective/minimap/cache/phase/IP axes, and confirm a rollback.

Until a maintainer explicitly selects a release scope and approves the packaging implementation, **all of these are OPEN release-readiness tests**, not verified features or proof of lawful distribution.

## 5. Review task and handoff

- **CosmicScript01 source-audit state:** paths and conditions above confirmed by reading frozen `335` source; no packaging command executed.
- **CosmicScript02 task CS02-32:** independently verify the exact inclusion paths, especially **root versus Compat XML and legacy Python builder**, and distinguish source licensing from the actual compiled ZIP. Record PASS / OWNER OR RIGHTSHOLDER CHECK / NOT TESTED. Reviewer may request corrections but no autonomous release/packaging modification.
- **Maintainer decisions later:** first release scope; any third-party rights or substitutions; client QA authorization and backups; separate protection against accidental `v*` auto-publishing; final integration and release. No decisions presumed.
