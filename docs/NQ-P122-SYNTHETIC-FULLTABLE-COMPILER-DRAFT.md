# Part 122 — synthetic whole-table compiler harness (DRAFT)

This note describes `tests/compat/nq_custom_fulltable_compiler.lua`. It is a compiler-only check. It is **not** a WoW 3.3.5a client PASS, a SavedVariables rebuild, a real Questie database compile, or permission to import quests.

The harness loads the real `Database/questDB.lua` schema, the real `Database/compiler.lua` (`CompileTable`, `CompileTableCoroutine`, `BuildSkipMap`, `GetDBHandle`) and the real `Modules/QuestieStream.lua`. `CompileTable` requests stream mode `raw`. `CompileTableCoroutine` requests `raw_assert` when `Questie.db.profile.debugEnabled` is set, and `raw` otherwise. Ten invented quests, ids `920241`–`920250`, are compiled and reopened. Quest 2001 is not in the table. No production loader, compiler, stream, canonical quest, or data revision file is modified.

Local runs recorded below used Lua 5.1.5 and Lua 5.4.6. CI runs the same file on Lua 5.1 only, under `timeout --signal=TERM --kill-after=5s 120s`. Lua 5.4 is not in that workflow step.

## What the harness runs

Three production compiles of the same table:

1. `CompileTable` (`raw`). This walks `pairs(order)` and `pairs(tbl)`.
2. `CompileTableCoroutine` with debug enabled (`raw_assert`). This walks `1..#order` and numeric quest ids. With ten entries the debug batch finishes after one yield.
3. `CompileTableCoroutine` with debug disabled and `entriesPerTick = 0` (`raw`). This yields once per entry plus the terminal index (11 yields).

Each binary is reopened with `BuildSkipMap` + `GetDBHandle` (the handle uses `raw` and yields four times, including pointer-map decode).

## Verdicts

### VERIFIED

- One-kind GameObject objectives and one-kind item objectives, each at list lengths 1, 2 and 255, reopen in input order. Nil objective text reopens as Lua nil. The order-probe text `Use synthetic object` reopens unchanged. No fixture puts two objective kinds on one quest.
- The field written immediately after `objectives` (`reputationReward`) reopens as that quest's sentinel for lengths 1, 2 and 255. The same values come back when `reputationReward` is queried before `objectives` and when it is queried after. `extraObjectives` after that field reopens as Lua nil on the capacity quests and as the probe description `extra-probe` on quest `920250`. `BuildSkipMap` gives `objectives`, `reputationReward` and `extraObjectives` no direct skip; `name` is the first dynamic field and is direct-skipped. `QueryValidator` completed its skipper/reader walk for every quest, including the 255-length lists.
- Equal-length capacity names make the compiled entry grow only with the objective list: length 2 is 4 bytes larger than length 1, and length 255 is 1016 bytes larger (`254 * 4`), on all three compile paths, for both GameObject and item lists.
- A Lua nil `name` (quest `920243`) reopens as Lua nil. That is the existing `u8string` writer inserting the sentinel string `nil`.
- The ordinary control name on quest `920241`, `Synthetic control name`, reopens as that string on every path. Its `questLevel` of `-1` also reopens as `-1`. `zoneOrSort` in the fixture is `130`.
- On Lua 5.1.5 and Lua 5.4.6, the top-level writer call sequence for `pairs(order)` matched indexed `1..#order` for every entry. The coroutine paths also matched `1..#order`. This is an observation of these two interpreters on the dense production array, not a language rule that `pairs` and `1..#order` are the same.
- Entry order did **not** match across paths. `CompileTable` followed `pairs(tbl)`. That order was `920247,920248,920241,920249,920242,920250,920243,920244,920245,920246` on Lua 5.1.5 and `920250,920241,920242,920243,920244,920245,920246,920247,920248,920249` on Lua 5.4.6. Both coroutine paths used numeric order `920241` through `920250` on both interpreters. Pointer-map reopen still returned every id. The two production loops are not interchangeable in entry order.
- The existing loader suite remained **56/56** on Lua 5.1.5 and **56/56** on Lua 5.4.6. The existing codec/stream suite remained **19/19** on both. This harness itself reported **473/473** on both. Those 473 include the schema, ordering, capacity, reopen and labelled finding assertions printed by the script.

### POTENTIAL ISSUE

Confirmed current behaviour, not a desired result, and not fixed on this branch.

Quest `920242` is compiled with `name` set to the Lua string `"nil"` (three characters) and a one-kind item objective. After every compile path, `QuerySingle(920242, "name")` returns **Lua nil**. The row is present: `QuerySingle(920242, "requiredLevel")` returns **11**. The control quest's name does not collapse.

Cause, from the unchanged compiler: `writers["u8string"]` writes `value or "nil"`, and `readers["u8string"]` turns a decoded string equal to `"nil"` into Lua nil. A quest that is actually named `nil` is therefore indistinguishable from a missing name after `GetDBHandle`.

The harness asserts this current result on purpose (`CONFIRMED FINDING ... reopens as Lua nil`). A later compiler change that preserves the string will fail that assertion until the finding is retired. No loader or compiler edit is included.

Minimal synthetic reproduction: one table entry, invented id `920242`, `questKeys.name` = `"nil"`, any other fields inside the normal codec ranges, then `CompileTable` or `CompileTableCoroutine` and `GetDBHandle` `QuerySingle(id, "name")`.

Separate work, not done here: a fail-closed loader rejection `q.name ~= "nil"`, a negative loader test, peer review, preservation of public quest 2001, a data-revision bump and an updated pinned loader blob. Loader acceptance of the string `"nil"` was **not** executed by this harness.

### UNKNOWN

- Whether some other Lua implementation would walk `pairs(order)` in a different order than `1..#order`. That did not happen on Lua 5.1.5 or Lua 5.4.6. If it did, `CompileTable` bytes would disagree with `BuildSkipMap`, which is built from `1..#order`. The coroutine path would stay aligned with the skip map.

### NOT TESTED

- Live WoW 3.3.5a client, SavedVariables, and a compile of the real quest database.
- Mixed-kind objectives. None are in the fixture. The harness does not assert that the compiler accepts or rejects them.
- `zoneOrSort = -32768` and `questLevel = -32768`. Both are excluded. This branch does not re-run that boundary. It stays a separate finding and is not fixed here.
- Quest 2001's compiled form. The record is absent from this table. The loader suite still checks the public 2001 input shape.
- Loader acceptance of a quest named `"nil"`.
- Exact numeric reopen of the order-probe trigger coordinates. `QueryValidator` walked that field; the decoded coordinates are not compared.
- Packaging, assembly, upload, release and tags. The workflow steps that assemble and upload a PR package are `if: ${{ false }}`.

## Counts from this working tree

| Suite | Lua 5.1.5 | Lua 5.4.6 |
|---|---|---|
| `run_nq_custom_loader_safety.py` | 56/56 | 56/56 |
| `nq_custom_compiler_codec.lua` | 19/19 | 19/19 |
| `nq_custom_fulltable_compiler.lua` | 473/473 | 473/473 |

CI on pull requests runs the first two and the new harness under Lua 5.1 with a 120-second timeout. It does not run Lua 5.4.
