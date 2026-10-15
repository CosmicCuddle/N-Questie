-- Synthetic nq-m2-effective v1 example (effective). Not produced by a real export.
-- Hashes are placeholders; quest 1203's item objective mirrors public data
-- (3853 after the N-Questie correction); level values are placeholders for schema testing only.
return {
    schema = "nq-m2-effective",
    schemaVersion = 1,
    provenance = {
        harness = "validate-335",
        harnessVersion = "0.1.0",
        dataKind = "effective",
        sourceCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        sourceTree = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        sourceDirty = false,
        tocInterface = 30300,
        flavour = "wotlk-335",
        nQuestieDataRevision = 1,
        correctionCount = 28,
        correctionFingerprint = "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        correctionModules = { "NQuestieExistingQuestCorrections.lua", "NQuestieReviewedClassicChainLevels.lua", "NQuestieReviewedEarlyQuestLevels.lua", "NQuestieReviewedQuestLevelCorrections.lua" },
        m0Checks = 232,
        exportedAt = "2026-10-14T15:00:00Z",
        questCount = 4,
    },
    quests = {
        {
            ID = 1203, requiredLevel = 0, questLevel = 1, sourceItemId = 0,
            requiredSourceItems = {  },
            objectives = {
                creatures = {  }, objects = {  }, items = { 3853 },
                killCredit = {  }, spells = {  },
            },
            hasTriggerEnd = false, hasExtraObjectives = false, extraObjectiveItems = {  },
        },
        {
            ID = 900301, requiredLevel = 0, questLevel = 1, sourceItemId = 0,
            requiredSourceItems = {  },
            objectives = {
                creatures = { 900140, 900141 }, objects = {  }, items = {  },
                killCredit = { { ids = { 900142, 900143 }, rootId = 900140 } }, spells = {  },
            },
            hasTriggerEnd = false, hasExtraObjectives = false, extraObjectiveItems = {  },
        },
        {
            ID = 900302, requiredLevel = 0, questLevel = 1, sourceItemId = 900500,
            requiredSourceItems = { 900500 },
            objectives = {
                creatures = {  }, objects = { 900200 }, items = { 900501 },
                killCredit = {  }, spells = {  },
            },
            hasTriggerEnd = false, hasExtraObjectives = false, extraObjectiveItems = {  },
        },
        {
            ID = 900303, requiredLevel = 0, questLevel = -1, sourceItemId = 0,
            requiredSourceItems = {  },
            objectives = {
                creatures = {  }, objects = {  }, items = {  },
                killCredit = {  }, spells = {  },
            },
            hasTriggerEnd = true, hasExtraObjectives = true, extraObjectiveItems = { 900600 },
        },
    },
}
