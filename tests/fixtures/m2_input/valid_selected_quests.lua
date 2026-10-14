-- Synthetic M2.1 input example (schema nq-m2-input, version 1).
-- Not exported from any server. Quest 1203 mirrors the public, already
-- reviewed objective (item 3853 x1); every other ID is 9xxxxx synthetic.
return {
    schema = "nq-m2-input",
    schemaVersion = 1,
    provenance = {
        exporter = "nq-synthetic-fixture",
        exporterVersion = "1.0.0",
        sourceLabel = "synthetic",
        sourceFingerprint = "sha256:0000000000000000000000000000000000000000000000000000000000000000",
        exportedAt = "2026-10-14T12:00:00Z",
        selection = "explicit",
        questCount = 4,
    },
    quests = {
        {   -- 1203 Jarl Needs a Blade: one required item, nothing else
            ID = 1203, StartItem = 0, ItemDrop1 = 0, ItemDrop2 = 0, ItemDrop3 = 0, ItemDrop4 = 0,
            RequiredNpcOrGo1 = 0, RequiredNpcOrGoCount1 = 0, RequiredNpcOrGo2 = 0, RequiredNpcOrGoCount2 = 0,
            RequiredNpcOrGo3 = 0, RequiredNpcOrGoCount3 = 0, RequiredNpcOrGo4 = 0, RequiredNpcOrGoCount4 = 0,
            RequiredItemId1 = 3853, RequiredItemCount1 = 1, RequiredItemId2 = 0, RequiredItemCount2 = 0,
            RequiredItemId3 = 0, RequiredItemCount3 = 0, RequiredItemId4 = 0, RequiredItemCount4 = 0,
            RequiredItemId5 = 0, RequiredItemCount5 = 0, RequiredItemId6 = 0, RequiredItemCount6 = 0,
            KillCredit = {}, killCreditComplete = false,
            hasConditions = "unknown", ipGated = "unknown", scriptedCredit = "unknown",
        },
        {   -- two creatures, complete KillCredit rows ({0, 0} = verified none)
            ID = 900101, StartItem = 0, ItemDrop1 = 0, ItemDrop2 = 0, ItemDrop3 = 0, ItemDrop4 = 0,
            RequiredNpcOrGo1 = 900140, RequiredNpcOrGoCount1 = 8, RequiredNpcOrGo2 = 900141, RequiredNpcOrGoCount2 = 8,
            RequiredNpcOrGo3 = 0, RequiredNpcOrGoCount3 = 0, RequiredNpcOrGo4 = 0, RequiredNpcOrGoCount4 = 0,
            RequiredItemId1 = 0, RequiredItemCount1 = 0, RequiredItemId2 = 0, RequiredItemCount2 = 0,
            RequiredItemId3 = 0, RequiredItemCount3 = 0, RequiredItemId4 = 0, RequiredItemCount4 = 0,
            RequiredItemId5 = 0, RequiredItemCount5 = 0, RequiredItemId6 = 0, RequiredItemCount6 = 0,
            KillCredit = { [900140] = { 0, 0 }, [900141] = { 900142, 0 } }, killCreditComplete = true,
            hasConditions = false, ipGated = false, scriptedCredit = false,
        },
        {   -- gameobject objective (negative ID) with a start item and item drop
            ID = 900102, StartItem = 900500, ItemDrop1 = 900501, ItemDrop2 = 0, ItemDrop3 = 0, ItemDrop4 = 0,
            RequiredNpcOrGo1 = -900200, RequiredNpcOrGoCount1 = 1, RequiredNpcOrGo2 = 0, RequiredNpcOrGoCount2 = 0,
            RequiredNpcOrGo3 = 0, RequiredNpcOrGoCount3 = 0, RequiredNpcOrGo4 = 0, RequiredNpcOrGoCount4 = 0,
            RequiredItemId1 = 900501, RequiredItemCount1 = 3, RequiredItemId2 = 0, RequiredItemCount2 = 0,
            RequiredItemId3 = 0, RequiredItemCount3 = 0, RequiredItemId4 = 0, RequiredItemCount4 = 0,
            RequiredItemId5 = 0, RequiredItemCount5 = 0, RequiredItemId6 = 0, RequiredItemCount6 = 0,
            KillCredit = {}, killCreditComplete = true, -- no creature targets, so trivially complete
            hasConditions = true, ipGated = "unknown", scriptedCredit = false,
        },
        {   -- creature with only some KillCredit rows; completeness not claimed
            ID = 900103, StartItem = 0, ItemDrop1 = 0, ItemDrop2 = 0, ItemDrop3 = 0, ItemDrop4 = 0,
            RequiredNpcOrGo1 = 900150, RequiredNpcOrGoCount1 = 1, RequiredNpcOrGo2 = 900151, RequiredNpcOrGoCount2 = 1,
            RequiredNpcOrGo3 = 0, RequiredNpcOrGoCount3 = 0, RequiredNpcOrGo4 = 0, RequiredNpcOrGoCount4 = 0,
            RequiredItemId1 = 0, RequiredItemCount1 = 0, RequiredItemId2 = 0, RequiredItemCount2 = 0,
            RequiredItemId3 = 0, RequiredItemCount3 = 0, RequiredItemId4 = 0, RequiredItemCount4 = 0,
            RequiredItemId5 = 0, RequiredItemCount5 = 0, RequiredItemId6 = 0, RequiredItemCount6 = 0,
            KillCredit = { [900150] = { 0, 0 } }, killCreditComplete = false,
            hasConditions = "unknown", ipGated = true, scriptedCredit = "unknown",
        },
    },
}
