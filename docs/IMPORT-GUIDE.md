# N-Questie — Read-only server quest export

**Early prototype:** the exporter creates a limited, curated **JSON review file** from an offline HeidiSQL world-database export. It does **not** automatically edit Questie, import all quests or guarantee accurate pins.

## Extract a specific quest

1. Keep the original \`acore_world.sql\` or \`acore_world.zip\` **outside the public repository** and make a private backup.
2. From a machine with Python 3, run:

\`\`\`bash
python3 tools/export_world_quests.py --world /private/acore_world.zip --quest 2001 --output review-2001.json
\`\`\`

For several verified quest IDs, repeat \`--quest\`:

\`\`\`bash
python3 tools/export_world_quests.py --world /private/acore_world.zip --quest 2001 --quest 30000 --output review-quests.json
\`\`\`

3. Inspect the JSON locally. Verify NPC IDs, objectives and prerequisites against the live server's actual rules. The script fails on unsupported gameobject quest starters/enders or gameobject objectives, negative prerequisites and missing NPC links.
4. **Only after review**, copy the safe, validated fields into \`Compat/NQuestieCustomQuestData.lua\` and increment its \`revision\`. Commit the **small curated Lua data file**, never the SQL ZIP or full generated raw extract.
5. Run \`python3 -m unittest discover -s tools -p 'test_export_world_quests.py'\` and \`lua5.1 tests/test_nquestie_overlay.lua\` locally where available. These do not replace WoW client tests.
6. Back up the installed Questie folder and account/character SavedVariables before testing. The revision change asks Questie to rebuild its compiled DB without wiping player preferences.

## Scope of this first exporter

Supported: quest title, min/quest level, race mask, flags, zone/sort, positive prerequisite, NPC quest starters/enders, and direct NPC kill-credit IDs/counts. The selected quest's original server source is authoritative for **its recorded values**, but runtime availability needs separate testing.

**Not yet automated:** mapping all raw AzerothCore world-space creature/gameobject spawn positions to 3.3.5a UI-zone map percentages, custom NPC creation, item/gameobject objectives, POI/scripts and server Individual Progression gating. Do not fabricate map coordinates or imply unsupported objectives are complete.

Next milestone: validate actual spawn-coordinate conversions and produce **reviewable Lua directly from the curated manifest** so future quests need only one safe command rather than hand-editing the small data file.

**Privacy:** The repository is public. The user approved publishing only curated quest IDs, names, links and coordinates needed for functionality. Keep the SQL export, server connection strings and unrelated data private.


## Draft next stage — Generate a reviewed Lua overlay (PR #3)

The new offline generator is in a **separate draft development branch**. This does not update your installed addon and is not a release. Step 2's live quest 2001 markers still need testing.

1. Use the read-only extractor above to produce a **private** JSON review file. Keep it outside the public checkout.
2. Independently verify the quest is actually available and the relevant NPC IDs already have correct map locations in Questie's 3.3.5a database (or plan separately reviewed NPC spawn corrections). For quest 2001, the inherited records already have coordinates, but their accuracy against active server spawns still needs in-game verification.
3. Review which quest metadata is approved for publication. Then run the following command **locally**, substituting paths and the next new revision number:

```bash
python3 tools/generate_custom_quests.py \
  --review /private/review-2001.json \
  --approved-quest 2001 \
  --verified-npc 2121 --verified-npc 1868 --verified-npc 1869 \
  --revision 2 \
  --output /private/staging/NQuestieCustomQuestData.lua
```

4. Compare the staged Lua against the current curated data. After review and authorization, copy the generated Lua into `Compat/NQuestieCustomQuestData.lua` on a development branch; never commit the JSON review file, SQL/ZIP source, credentials or full export. Increment `revision` each time published curated Lua changes.
5. Run `python3 tools/test_generate_custom_quests.py` and the Lua 5.1 checks, and test the game markers before any release.

**Safety behavior:** the converter refuses unapproved quest IDs, missing or extra verified NPC IDs, malformed records, unsupported extra fields, duplicate IDs, unsafe quest names and overwriting an existing destination without explicit `--overwrite`. A successful conversion **does not prove** that quest availability, phases or spawn positions are correct. Kill counts in the source JSON are validated, but the addon objective records intentionally contain only NPC IDs; the WoW quest log supplies counts.

**Future extension:** validated gameobject/item/script objectives and server-specific NPC map-coordinate mapping will require separate verified data and code, not guessed locations.

### Protection against accidental loss of curated quests

The generator treats its JSON input as the **complete desired set** of curated quests in the generated output, not merely as a list of new additions. When updating an existing generated file with `--overwrite`, it compares the older and newer quest IDs and rejects *any* missing old quest.

If a quest genuinely should be removed, each missing ID must be explicitly approved with `--approve-removal-quest ID`. Extra removal approvals are rejected. A higher `--revision` is also required, and unrelated Lua files cannot be overwritten.

**Adding a quest safely:** regenerate from a reviewed manifest containing **all previously curated quests plus the additional quest**, explicitly approve every included quest and verify all referenced NPC positions. First stage the result privately and review the Git diff. Never import a single-quest JSON over a previous multi-quest generated file without carrying forward older records.

These safeguards operate on the *generated* Lua format. The existing original hand-curated `Compat/NQuestieCustomQuestData.lua` is intentionally not overwritten by the generator. Migration to generated data requires a separately reviewed staging/copy operation, including preservation of quest 2001 and the updated revision.
