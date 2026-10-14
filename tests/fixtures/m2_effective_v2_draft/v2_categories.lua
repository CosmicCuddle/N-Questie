-- SYNTHETIC nq-m2-effective v2 DRAFT example. Hand-written; not produced by any
-- exporter (no v2 exporter exists). Hashes are placeholders. Objective and
-- extraObjective values mirror the PUBLIC compiled 3.3.5a Questie records of
-- the named quests (read 2026-10-14) so the design is tested on real shapes.
-- Display text and spawn coordinates are excluded by design (hasText /
-- spawnZones only).
return {
    schema = "nq-m2-effective",
    schemaVersion = 2,
    provenance = {
        harness = "validate-335", harnessVersion = "1.1.0", dataKind = "effective",
        sourceCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        sourceTree = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
        sourceDirty = false, tocInterface = 30300, flavour = "wotlk-335",
        nQuestieDataRevision = 5, correctionCount = 28,
        correctionFingerprint = "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
        correctionModules = { "NQuestieExistingQuestCorrections.lua" },
        m0Checks = 232, exportedAt = "2026-10-14T17:00:00Z", questCount = 8,
    },
    quests = {
        -- 1203: plain item objective (v1-representable; M1 SUPPORTED)
        { ID = 1203, requiredLevel = 30, questLevel = 35, sourceItemId = 0, requiredSourceItems = {},
          objectives = { { position = 1, kind = "item", slotIndex = 1, id = 3853, occurrence = 1 } },
          killCreditFirst = false, hasTriggerEnd = false, extraObjectives = {},
          m1Status = "SUPPORTED", m1Reasons = {} },
        -- 1367 Magram Alliance: reputation (faction 93, 3000) + creature extra with 9 refs
        { ID = 1367, requiredLevel = 30, questLevel = 33, sourceItemId = 0, requiredSourceItems = {},
          objectives = { { position = 1, kind = "reputation", slotIndex = 1, factionId = 93, requiredValue = 3000 } },
          killCreditFirst = false, hasTriggerEnd = false,
          extraObjectives = { { position = 1, icon = 1, hasText = true, spawnZones = {}, refs = {
              { type = "monster", id = 4653, refIndex = 1 }, { type = "monster", id = 4647, refIndex = 2 },
              { type = "monster", id = 4646, refIndex = 3 }, { type = "monster", id = 4661, refIndex = 4 },
              { type = "monster", id = 5602, refIndex = 5 }, { type = "monster", id = 4648, refIndex = 6 },
              { type = "monster", id = 4649, refIndex = 7 }, { type = "monster", id = 4651, refIndex = 8 },
              { type = "monster", id = 4652, refIndex = 9 } } } },
          m1Status = "UNSUPPORTED", m1Reasons = { "EXTRA_CREATURE_REF", "REPUTATION_OBJECTIVE" } },
        -- 735: three items + object extra linked to objective 2 (objectiveIndex)
        { ID = 735, requiredLevel = 30, questLevel = 44, sourceItemId = 0, requiredSourceItems = {},
          objectives = { { position = 1, kind = "item", slotIndex = 1, id = 4646, occurrence = 1 },
                         { position = 2, kind = "item", slotIndex = 2, id = 4641, occurrence = 1 },
                         { position = 3, kind = "item", slotIndex = 3, id = 4644, occurrence = 1 } },
          killCreditFirst = false, hasTriggerEnd = false,
          extraObjectives = { { position = 1, icon = 3, hasText = true, spawnZones = {}, objectiveIndex = 2,
              refs = { { type = "object", id = 2871, refIndex = 1 } } } },
          m1Status = "UNSUPPORTED", m1Reasons = { "EXTRA_OBJECT_REF" } },
        -- 25199 Basic Orders: the same creature four times = four log lines (occurrence 1..4)
        { ID = 25199, requiredLevel = 1, questLevel = -1, sourceItemId = 0, requiredSourceItems = {},
          objectives = { { position = 1, kind = "creature", slotIndex = 1, id = 39368, occurrence = 1 },
                         { position = 2, kind = "creature", slotIndex = 2, id = 39368, occurrence = 2 },
                         { position = 3, kind = "creature", slotIndex = 3, id = 39368, occurrence = 3 },
                         { position = 4, kind = "creature", slotIndex = 4, id = 39368, occurrence = 4 } },
          killCreditFirst = false, hasTriggerEnd = false, extraObjectives = {},
          m1Status = "UNSUPPORTED", m1Reasons = { "DUPLICATE_CREATURE" } },
        -- 11142: duplicate object 500007 + creature extra 23704, plus a spawn-only extra
        { ID = 11142, requiredLevel = 32, questLevel = 37, sourceItemId = 0, requiredSourceItems = {},
          objectives = { { position = 1, kind = "object", slotIndex = 1, id = 500007, occurrence = 1 },
                         { position = 2, kind = "object", slotIndex = 2, id = 500007, occurrence = 2 } },
          killCreditFirst = false, hasTriggerEnd = true,
          extraObjectives = { { position = 1, icon = 3, hasText = true, spawnZones = { 15 }, refs = {} },
                              { position = 2, icon = 5, hasText = true, spawnZones = {},
                                refs = { { type = "monster", id = 23704, refIndex = 1 } } } },
          m1Status = "UNSUPPORTED", m1Reasons = { "DUPLICATE_OBJECT", "EXTRA_CREATURE_REF" } },
        -- 8470: reputation with faction only (no required value in Questie data); never defaulted
        { ID = 8470, requiredLevel = 45, questLevel = 55, sourceItemId = 0, requiredSourceItems = {},
          objectives = { { position = 1, kind = "reputation", slotIndex = 1, factionId = 576 } },
          killCreditFirst = false, hasTriggerEnd = false, extraObjectives = {},
          m1Status = "UNSUPPORTED", m1Reasons = { "REPUTATION_OBJECTIVE" } },
        -- 9666: creature + kill credit (v1-representable shape)
        { ID = 9666, requiredLevel = 10, questLevel = 13, sourceItemId = 24084, requiredSourceItems = {},
          objectives = { { position = 1, kind = "creature", slotIndex = 1, id = 17701, occurrence = 1 },
                         { position = 2, kind = "killCredit", slotIndex = 1, ids = { 17701 }, rootId = 17701 } },
          killCreditFirst = false, hasTriggerEnd = false, extraObjectives = {},
          m1Status = "SUPPORTED", m1Reasons = {} },
        -- 1369: item + reputation together (Questie order: item before reputation)
        { ID = 1369, requiredLevel = 30, questLevel = 33, sourceItemId = 0, requiredSourceItems = {},
          objectives = { { position = 1, kind = "item", slotIndex = 1, id = 6083, occurrence = 1 },
                         { position = 2, kind = "reputation", slotIndex = 1, factionId = 93, requiredValue = 3000 } },
          killCreditFirst = false, hasTriggerEnd = false, extraObjectives = {},
          m1Status = "UNSUPPORTED", m1Reasons = { "REPUTATION_OBJECTIVE" } },
    },
}
