-- Synthetic nq-m2-effective v1 example (stock). Not produced by a real export.
-- Hashes are placeholders; quest 1203's item objective mirrors public data
-- (stock Questie item 33110, before any correction); level values are placeholders for schema testing only.
return {
    schema = "nq-m2-effective",
    schemaVersion = 1,
    provenance = {
        harness = "validate-335",
        harnessVersion = "0.1.0",
        dataKind = "stock",
        sourceCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        sourceTree = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        sourceDirty = false,
        tocInterface = 30300,
        flavour = "wotlk-335",
        nQuestieDataRevision = 0,
        correctionCount = 0,
        correctionFingerprint = "none",
        correctionModules = {  },
        m0Checks = 0,
        exportedAt = "2026-10-14T15:00:00Z",
        questCount = 1,
    },
    quests = {
        {
            ID = 1203, requiredLevel = 0, questLevel = 1, sourceItemId = 0,
            requiredSourceItems = {  },
            objectives = {
                creatures = {  }, objects = {  }, items = { 33110 },
                killCredit = {  }, spells = {  },
            },
            hasTriggerEnd = false, hasExtraObjectives = false, extraObjectiveItems = {  },
        },
    },
}
