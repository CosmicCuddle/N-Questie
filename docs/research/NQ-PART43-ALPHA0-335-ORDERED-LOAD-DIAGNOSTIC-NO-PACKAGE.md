# Part 43 Alpha 0 — exact 3.3.5a TOC and XML encounter-order diagnostic

**2026-10-28 | PUBLIC-SAFE TEST ONLY | no ZIP/build, install, release, merge or private files.**

## Why this draft exists

The owner prioritises a first **private, separately approved** Alpha 0 WoW 3.3.5a smoke test. Frozen test drafts [#288](https://github.com/CosmicCuddle/N-Questie/pull/288) and [#290](https://github.com/CosmicCuddle/N-Questie/pull/290) establish direct and nested XML filename closure (27/27 and 39/39), but a filename **set** loses the authored order of the original 335 TOC and of nested XML Script/Include tags. This new draft tests that additional, distinct hazard without creating an addon directory or archive.

## Exact source and scope

- Immutable original public protected `335`: `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`. This is fetched through Git, verified by SHA and read using `git show` and `git ls-tree`.
- Original active `Questie-335.toc` lines are kept in order, not put into a set; `## Interface: 30300` and both SavedVariables names are checked.
- Every active `Script` / `Include` `file=` reference in the six original XML TOC roots is expanded depth-first in the lexical order of each XML file. Repeated references remain repeated in the diagnostic ordered encounter list. Circular includes are rejected by the model. Exact-case existence is checked against the immutable Git tree.
- The *minimal referenced-file selection* is only a **Python in-memory set** consisting of the original 335 TOC and these observed referenced files. There is no output directory, copy operation, zip, installer or modified production file.
- Fictional negative mutations prove wrong source-path case, missing source, ignored XML comments, preserved duplicate references, nested traversal, absolute / escaped paths, cycle failure, changed TOC order and deterministic reruns. No original Git data is altered.
- 28 labelled strict controls run under a new read-only GitHub Actions workflow. The workflow checks exact summary markers, a clean checkout and absence of generated archive/addon directories. It has `contents: read` only and does not upload artifacts.

**Important limitation:** The ordered recursion is deliberately an approximation for **active Script/Include file encounter order**, **not** proof of the Warcraft XML engine's complete parser or Lua execution order (including runtime code, conditional loading, assets, dynamic references, files loaded outside this TOC, and environment differences). The diagnostic is not a runnable package manifest or proof of in-game compatibility. Existing `build.py` still selects the wrong addon folder `Questie`, wrong Wrath `Questie-WOTLKC.toc`, and omits required `Compat` files. **Never run it or `release.py` for Alpha 0.**

## What remains before a first private playable test

Separate owner approval is still required to make **any build/ZIP**. Another explicit installation decision may be required. Before future authorised local client operations, agree on immutable candidate source and disabled risky scope, prepare a correct 335-only packager, verify every byte and file exclusion, back up the existing `Interface/AddOns/Questie-335` folder and both account and per-character Questie SavedVariables, document restore procedures, then perform reversible native game cold-login/map/tracker/quest/relog with sanitised logs.

**Gate08 remains MAJOR RED.** All-writer E01–E08 ownership, real QuestieStream pool lifecycle/quarantine, checked coherent four-kind eight-field plus metadata publication, game disk SavedVariables crash/relog recovery and Individual Progression tests remain unproven. Programme gates remain 3 complete / 6 underway / 3 technically pending. 439 RAW quest research records are not approved; eligible count unknown and 1207–1209 remain 0/3 implemented.

**No claim of CI pass until original-head run and job logs have been independently inspected.** No production, protected branch, private server data, merge, package, install, tag or release.
