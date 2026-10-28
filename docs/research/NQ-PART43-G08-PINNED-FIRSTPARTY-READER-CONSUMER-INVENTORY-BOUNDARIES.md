# Part 43 G08 — protected 335 first-party query consumer static census

**28 October 2026 · DRAFT · TEST-ONLY · NO actual addon changes, ZIP, install, merge or release**

## Motivation

[Source-backed original Journey Search test #311](https://github.com/CosmicCuddle/N-Questie/pull/311), exact original `246ab3a029cf3be2d448027495eb47f9e7d21048`, independently passed **52/52 original `QuestieSearch.lua` assertions on Lua 5.1.5 and Lua 5.4.6**, dedicated [run 40723477873](https://github.com/CosmicCuddle/N-Questie/actions/runs/40723477873), 0 artifacts. It revealed OLD/NEW query-pointer pairing and direct `:Search` retained-ID concerns with synthetic data. Three known files are **NOT** a complete account of first-party consumers; we now need a conservative reproducible inventory for proposed future generation-aware producer/readers.

## What this isolated test does

The test-only `nq_part43_g08_pinned_firstparty_reader_consumer_inventory.py` runs **read-only** against exactly original public protected `335` commit `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. It uses Git's original `ls-tree`, `rev-parse`, `show` to inspect first-party `Modules/**/*.lua` and selected core `Database/QuestieDB.lua`, `Database/compiler.lua`, Corrections and Compat loaders, excluding `*.test.lua`. It verifies exact known original source blobs for Journey Search, Journey SearchResults, AvailableQuests, QuestieDB and compiler. It does **not** checkout or repackage original addon; reads original Git tree directly.

An explicit conservative regular-expression scan records with source path and line number: `QuestieDB.QueryNPC/Quest/Item/Object` and their `Single` variants, exported `_Query*`, four `*Pointers` maps, direct `Questie.db.global[.sod].*Bin/*Ptrs` fields, `QuestieDB:Initialize()` and real `GetDBHandle()` construction. It classifies likely local/field query **assignments** and callback **pass-by-value** sites without treating a call expression as an assignment. Required source anchors fail closed if the protected original source, consumer paths or known interfaces disappear.

The read-only Python3 GitHub CI requires **25/25 exact scoped invariants** before success. It prints a compact inventory census, 20 busiest direct consumer paths, 20 callback sites and 20 likely retained-function assignment sites, **only in job logs**. No JSON/archive/upload artifact, ZIP, build, client action or saved files are produced. The actual reference counts must be derived from the dedicated CI output, **not invented in advance**.

## Important boundaries and how not to overclaim

This is a lexical inventory of selected **first-party Lua source only**, not a complete Lua parser, runtime call graph, alias-ownership proof, dynamic-index discovery, live addon/plugin/QuestieStream hook census or snapshot of all unknown external writers. Matches inside comments may overcount and dynamic computed field access may be missed. `Modules/` and selected core/Compat files are included; vendor Libs, Localization, giant static DB rows, XML/TOC and private addon/realm files are excluded. Any future migration must separately inspect other direct `QuestieDB.Get*` wrappers, cached query pointers, global aliases, original event consumers, and actual reader generation pointer lifecycle. A successful static audit is **not** evidence the future writer and reader adapter is safe.

**Real engineering target:** use the output to create explicit consumer-interface migration requirements (callback aliases and source generation binding, cache invalidation, existing 335/SoD SavedVariables layout). Cross-check against genuine real-source compiler writer and global QuestieStream lease/quarantine, E01–E08 and unknown writer capture, coherent all-eight Bin+Ptrs and metadata publication, and actual disk/relog + native 3.3.5a/Individual Progression before *any* production patch proposal or build.

Protected `335` remains protected/unchanged. Gate08 **MAJOR RED**, overall **3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING**; 439 RAW research entries unapproved, eligible denominator unknown and pilots 1207–1209 0/3 implemented. The owner has not authorized protected merge, production edits, ZIP/build, installation, tag/release, or sharing private player/account/realm data. A later separately approved native test requires backups and documented rollback for `Interface/AddOns/Questie-335` plus both SavedVariables sets.
