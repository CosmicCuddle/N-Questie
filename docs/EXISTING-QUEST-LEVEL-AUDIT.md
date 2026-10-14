# N-Questie — Existing Quest Level Audit

**Status:** Offline read-only mismatch discovery, draft PR only. No quest overrides or in-game changes are applied.

## Why this exists

AzerothCore and server modules can modify existing WotLK quests. Questie's inherited WotLK record may retain older values and show the wrong quest level or colour.

**Quest level is not minimum required level:**
- \`quest_template.QuestLevel\` determines the quest's nominal level; Questie uses its own \`questLevel\` value when calculating colour relative to the character's level.
- \`quest_template.MinLevel\` represents the minimum required level, which Questie stores as \`requiredLevel\`.
- Colour uses \`QuestieLib:GetColoredQuestName\` → \`GetTbcLevel\` → \`PrintDifficultyColor\` and the character's actual level; it must not be artificially overridden just because an Individual Progression era is active.
- Individual Progression, conditions, scripts, and quest prerequisites may impose **additional restrictions**, even if these level values match. No static export can prove character-specific availability.

## First known report — Jarl Needs a Blade

- Quest ID **1203** — Jarl Needs a Blade, in Dustwallow Marsh.
- Stock WotLK Questie record: \`requiredLevel = 30\`, \`questLevel = 35\`.
- The checked Classic, TBC, and WotLK literal correction layers had no entry for ID 1203.
- **User reports that this quest is incorrect on the Naxxramas server.**
- **Server's actual QuestLevel/MinLevel values are not yet verified in the current chat.** We cannot claim a fix or prescribe a changed level before checking the private world export and in-game behaviour.

### Important second discrepancy to investigate

Quest 1203 changed its required item between pre-2.3 Classic and WotLK:
- **Original Classic:** Moonsteel Broadsword.
- **Later WotLK:** Razorspine's Sword (item 33110 in the inherited Questie quest record).

These are public historical variants; **do not infer which one the Naxxramas world database currently implements.** The first audit tool checks *level fields only*, not item objectives. Extend the audit later to server RequiredItemId/Count and Questie item objective slots, respecting correction layers and scripted/item-drop behavior. Do not automatically replace quest objectives from a public Classic website.

## Run the read-only audit

1. Keep your original offline HeidiSQL \`acore_world.zip\` or SQL file **outside** the publicly cloned N-Questie directory. Make a private backup first.
2. With Python 3 available, from your **reviewed development clone** run:

   \`python3 tools/audit_world_quest_levels.py --world /private/acore_world.zip --quest 1203 --output /private/jarl-level-review.json\`

3. After verifying the single quest, omit \`--quest 1203\` to scan all server quests and report the mismatches:

   \`python3 tools/audit_world_quest_levels.py --world /private/acore_world.zip --output /private/all-quest-level-mismatches.json\`

4. Review the private JSON and classify each difference. It contains:
   - Server values for \`MinLevel\` and \`QuestLevel\`.
   - Raw Questie \`requiredLevel\` and \`questLevel\`.
   - An **approximation** after literal numeric Classic → TBC → WotLK corrections.
   - A field-by-field mismatch list, notes on unresolved cases, and summary totals.

**Privacy enforced:** output inside the public addon repository is refused. Never push the full SQL archive, raw generated review JSON, server credentials, or uncontrolled quest metadata to the public repository.

**Safety enforced:** existing private output is not overwritten without \`--overwrite\`, and source SQL/ZIP is never overwritten. No database connection or mutation, quest state modification, or changes to the installed addon occur.

## Known limits (important)

- The supported HeidiSQL format uses explicit \`INSERT INTO\` column lists and one SQL tuple per line. Other export formats fail rather than silently give incorrect numbers.
- The current audit evaluates the generated 3.3.5a WotLK quest data and **literal numeric** corrections from the Classic, TBC and WotLK quest correction tables. It does not execute arbitrary Lua and cannot prove later dynamic or 3.3.5a compatibility-module modifications. Treat results as **candidate mismatches**, not guaranteed current runtime truth.
- If a correction assigns a nonliteral expression to a level, the quest is classified as \`needs_review\`, not silently guessed.
- \`questLevel = -1\` may mean scaling to the player; investigate, do not substitute a made-up static level.
- Missing quest IDs belong to the **new quest importer** and are excluded from the ordinary full-audit mismatch list; explicitly selected missing quests are still reported as missing.
- Exact map locations, NPC/GO relationships, item counts, scripts, conditional quest availability and IP phase locks are follow-on audits, not solved by comparing two integer levels.

## Approval path for actual corrections

1. Verify the relevant server record and current in-game quest-level/colour behaviour.
2. Check **effective runtime data** when an inherited static correction or dynamic code might apply.
3. Propose a small, reviewed **field-level** correction (e.g. \`[questKeys.questLevel] = verifiedValue\`) on a new draft PR. Never replace existing quest objectives, NPCs or quest chains just to change a level.
4. Run Lua 5.1 and scoped tests, then a backed-up QA addon in game. Review effects on quest filtering and tooltip colours.
5. **Do not merge, tag, release, update N-Addon-Collection, or alter the live world database without explicit maintainer approval.**

The private world export from the earlier chat may need to be reattached in the current conversation to perform the actual audit. Publishing the original archive to GitHub is prohibited.


## Private database verification — 14 October 2026

The maintainer re-uploaded the complete private \`acore_world.zip\` directly in chat. The archive was inspected **read-only**; it contains approximately 9,525 unique \`quest_template\` records. This private archive itself has **not** been placed in GitHub.

**Quest 1203 verified server values:**
- \`QuestLevel = 35\`; \`MinLevel = 30\`. These match stock Questie's nominal level and required level, so no quest-level correction is appropriate for this ID.
- \`RequiredItemId1 = 3853\`; \`RequiredItemCount1 = 1\`: Moonsteel Broadsword.
- Server objective text: "Bring a Moonsteel Broadsword to Jarl in Dustwallow Marsh."
- NPC giver and recipient 4792; prerequisite 1206, unchanged.

**Public source difference:** stock WotLK Questie item objective is \`33110\` (Razorspine's Sword), so this is an actual **item/objective text mismatch**, not a level mismatch.

A separate stacked draft correction changes only the existing quest 1203 item objective (to \`3853\`) and its objective text, preserving quest level, minimum level, NPC links and prerequisite. It verifies the expected original Questie objective ID and refuses to overwrite unexpected/updated records. **The in-game correction has not yet been tested.**

The original level scanner's full-database mismatch counts **have not yet been established** from the combined private archive and current Questie data; do not substitute its synthetic fixture results for a real comparison. The next audit stage needs item/NPC objective comparison and module/Individual Progression condition review.
