# N-Questie — Test Plan

**Baseline:** fork's `335` branch, WoW 3.3.5a (`30300`).  
**Status:** scenarios defined, not executed in-game for N-Questie.

## Prior to all installed tests

1. Close World of Warcraft.
2. Back up the existing **Questie-335** addon folder (or exact installed Questie folder) outside the AddOns directory.
3. Back up `QuestieConfig` (account-wide) and `QuestieConfigCharacter` (character-specific) SavedVariables from the applicable `WTF` account/realm/character paths. Verify which files actually exist before altering them.
4. Do not install two copies of Questie at once; preserve upstream addon identity until deliberate compatibility testing.
5. Use a dedicated test character if practical. Do not alter quest completion, server DB rows, GM flags or progression merely to make an icon visible.

## Baseline behavior

| ID | Check | Expected result |
| --- | --- | --- |
| B01 | Start the existing Questie-335 addon without N-Questie changes | Normal loading and familiar quest markers |
| B02 | Open world map and minimap | Existing quest start and turn-in pins appear normally |
| B03 | Accept and abandon a harmless available ordinary quest only if appropriate | Objective/turn-in state remains correct; no requirement to abandon an important quest |
| B04 | Reload UI / log out and in | Saved Questie settings and marker state remain consistent |
| B05 | Inspect / reload on the custom Naxxramas client | No Lua errors, unknown-map errors or duplicate addon loading |

## First custom quest

| ID | Check | Expected result |
| --- | --- | --- |
| C01 | Inspect validated read-only quest and NPC/object spawn records | Quest, giver/ender IDs, map and location source are known |
| C02 | Load one overlay quest whose prerequisites are truly met | Starter marker appears on the correct map |
| C03 | Visit giver and accept the quest if gameplay permits | Marker state updates appropriately |
| C04 | Reach real ender or objective | Turn-in/objective marker matches actual server location |
| C05 | Re-run the validated build after a source update | Corrected pin location, no unrelated map changes |
| C06 | Check not-yet-available/phase-locked quest | No incorrectly advertised availability; behavior explicitly recorded if not predictable |
| C07 | Reload and, if necessary, use supported Questie database recompile procedure | Generated overlay persists/rebuilds correctly without wiping user settings |

## Regression and release gates

| ID | Check | Expected result |
| --- | --- | --- |
| R01 | Parse new Lua with Lua 5.1 | No syntax errors or 3.3.5a-only API mismatches |
| R02 | Verify TOC file load order | Overlay initialisation occurs after all dependencies and before compiled lookup/marker generation |
| R03 | Inspect conflict with existing base quest/NPC/object IDs | Only intentionally specified fields change; no broad deletion |
| R04 | Validate manifest and generated data (once implemented) | Missing IDs, impossible map conversions and duplicate conflicts fail clearly |
| R05 | Compare world map and minimap | No duplicates, false zones, missing baseline quest pins or unreadable tooltips |
| R06 | Confirm SavedVariables schema/compatibility | Existing settings retained; rollback does not require deleting SavedVariables |
| R07 | Licence and upstream credit review | Original authors/assets credited and redistribution terms followed |

**Never mark tests PASS based on reading source or the existence of a PR.** Record the observed screenshot, tester, client version and candidate commit.

## Rollback

Close WoW; restore the backed-up addon directory. Restore SavedVariables **only if essential**, because replacing a newer saved file can discard changes made since the backup. No server data needs rollback when testing remains read-only.
