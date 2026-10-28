# Part 43 Alpha 0 — 335 runtime payload eligibility audit (NO build/package)

**28 October 2026 · PUBLIC-SAFE TEST ONLY · DRAFT · unmerged**

## Practical need

The owner prioritises a first **private, reversible, explicitly approved** Alpha 0 client smoke test. Previous [#288](https://github.com/CosmicCuddle/N-Questie/pull/288) and [#290](https://github.com/CosmicCuddle/N-Questie/pull/290) proved main TOC and recursive active XML filename closure; new [#293](https://github.com/CosmicCuddle/N-Questie/pull/293) additionally established deterministic TOC/XML encounter-order diagnostics. None produces a playable addon.

GitHub's original pinned protected `335` tree (`8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`) contains **920 blob-or-gitlink entries** across production files, tooling, documentation and test data. Blindly copying the repository is inappropriate for Alpha 0. Independently inspected tree extensions before this draft: `Compat` contains two CSV extractor inputs, and `Icons`/`Libs` contain non-runtime documentation and licensing resources. The previous old `build.py` still has known incorrect folder/TOC/Compat choices.

## What this isolated test checks

The Python standard-library test reads an **immutable Git tree** with `git ls-tree -r -z`, `git show`, never writing a candidate or copying files. Its **fictional, in-memory-only** *potential runtime-eligible* file selection is:
- Original **`Questie-335.toc` and `Questie.lua`** root blobs;
- regular Git blobs under only six source runtime subtrees: `Compat/`, `Database/`, `Icons/`, `Libs/`, `Localization/`, `Modules/`;
- filename extension allowed for Lua, XML, library TOC, relevant graphical/font/audio assets; excludes extraction CSV and text/changelog/license metadata from this *diagnostic* file set, **not** a decision to omit required third-party notices from any future authorized distribution.

For the pinned original Git tree, this model expects **544 runtime-tree files + two root files = 546** potential file references. This is **not** a ZIP's contents or byte-size and is **not** approved as a final shipping manifest. The test verifies every eligible path is an original regular Git blob (no symlinks/gitlinks), casefold-unique, under the approved roots, and that the actual 335 TOC plus recursively found active XML `Script`/`Include` filenames are all represented. It separately excludes tools/tests/docs/source-private and disallowed suffixes, checks a known real CSV exclusion, asserts a hypothetical truncated selection fails closure and detects the existing builder's three known mismatches.

A SHA-256 is calculated **only in memory** over canonical sorted candidate Git path names, modes, types and object IDs; this is NOT a built payload hash, ZIP hash or a guarantee all runtime resources have been included. An isolated workflow checks a clean checkout and that no output folder/ZIP was created. The 32 assertions are source-pinned; they do not run an addon builder.

## Critical nonclaims and owner gates

This script is a conservative **eligibility classification**, not a Warcraft XML engine, not full Lua/asset reference discovery, not third-party license compliance approval, not byte-content secret screening, not client compatibility, not complete native API coverage, and not an Alpha 0 candidate package. A file that is unreferenced by static TOC/XML but used dynamically may still be needed; an eligible source file may not be safe to ship. Any future actual package requires separate explicit owner approval, production-scoped feature exclusions, source pin/hash, independent file-by-file content and license review, asset/API tests, verified correct 335 output root and TOC, and no private server/account data.

Before separately authorized native installation: back up `Interface/AddOns/Questie-335` and both account `QuestieConfig` and character `QuestieConfigCharacter` SavedVariables; document rollback/recovery, then sanitized 3.3.5a login, map/tracker/quest and relog tests. Never run legacy `build.py`/`release.py` for Alpha0 and never merge test-only PRs as production fixes.

**Gate08 MAJOR RED; 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**; 439 RAW investigation records are not approved quests, eligible denominator UNKNOWN, pilots 1207–1209 are 0/3 implemented. No protected changes, packaging, installs, tags, releases, private SQL/NPC/GO/item/loot/IP/SavedVariables or unauthorized data exports.

**Dedicated 32/32 and whole-CI verdicts must be independently verified after workflow execution.** Do not mark green from merely committing this document.
