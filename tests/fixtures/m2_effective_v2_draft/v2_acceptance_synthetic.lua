-- SYNTHETIC nq-m2-effective v2 acceptance fixture (DRAFT; no exporter exists).
-- Quest IDs 900001-900006 are invented and are not real quests. Covers shapes
-- the category fixture lacks: spell objective with item source, required
-- source items, multi-id kill credit, three kill-credit entries reversed,
-- objectiveIndex at the maximum, trigger end, all six kinds in order.
local P = dofile("tests/fixtures/m2_effective_v2_draft/v2_categories.lua").provenance
local prov = {}
for k, v in pairs(P) do prov[k] = v end
prov.questCount = 6
return {
    schema = "nq-m2-effective", schemaVersion = 2, displayScope = "structural-only", provenance = prov,
    quests = {
        -- all six kinds in Questie order
        { ID = 900001, requiredLevel = 20, questLevel = 22, sourceItemId = 0, requiredSourceItems = {},
          objectives = {
            { position = 1, kind = "creature", slotIndex = 1, id = 101, occurrence = 1 },
            { position = 2, kind = "object", slotIndex = 1, id = 201, occurrence = 1 },
            { position = 3, kind = "item", slotIndex = 1, id = 301, occurrence = 1 },
            { position = 4, kind = "reputation", slotIndex = 1, factionId = 72, requiredValue = 0 },
            { position = 5, kind = "killCredit", slotIndex = 1, ids = { 401, 402, 403 }, rootId = 401 },
            { position = 6, kind = "spell", slotIndex = 1, id = 501, occurrence = 1, itemSourceId = 601 } },
          killCreditFirst = false, hasTriggerEnd = true,
          extraObjectives = { { position = 1, icon = 2, hasText = true, spawnZones = {}, objectiveIndex = 6,
              refs = { { type = "object", id = 202, refIndex = 1 } } } },
          m1Status = "UNSUPPORTED_BY_RULES", m1Reasons = { "EXTRA_OBJECT_REF", "REPUTATION_OBJECTIVE" } },
        -- required source items and a source item, item objective repeated id elsewhere
        { ID = 900002, requiredLevel = 10, questLevel = 12, sourceItemId = 701, requiredSourceItems = { 701, 702 },
          objectives = { { position = 1, kind = "item", slotIndex = 1, id = 301, occurrence = 1 } },
          killCreditFirst = false, hasTriggerEnd = false, extraObjectives = {},
          m1Status = "SUPPORTED", m1Reasons = {} },
        -- three kill-credit entries with killCreditFirst: reversed slot order
        { ID = 900003, requiredLevel = 70, questLevel = 72, sourceItemId = 0, requiredSourceItems = {},
          objectives = {
            { position = 1, kind = "killCredit", slotIndex = 3, ids = { 803 }, rootId = 803 },
            { position = 2, kind = "killCredit", slotIndex = 2, ids = { 802 }, rootId = 802 },
            { position = 3, kind = "killCredit", slotIndex = 1, ids = { 801 }, rootId = 801 } },
          killCreditFirst = true, hasTriggerEnd = false, extraObjectives = {},
          m1Status = "UNSUPPORTED_BY_RULES", m1Reasons = { "KILLCREDIT_FIRST_REORDER" } },
        -- killCreditFirst with a creature: killCredit moves before it
        { ID = 900004, requiredLevel = 70, questLevel = 72, sourceItemId = 0, requiredSourceItems = {},
          objectives = {
            { position = 1, kind = "killCredit", slotIndex = 1, ids = { 811, 812 }, rootId = 811 },
            { position = 2, kind = "creature", slotIndex = 1, id = 813, occurrence = 1 } },
          killCreditFirst = true, hasTriggerEnd = false, extraObjectives = {},
          m1Status = "UNSUPPORTED_BY_RULES", m1Reasons = { "KILLCREDIT_FIRST_REORDER" } },
        -- no objectives at all (talk-to / delivery quest): still exported, never dropped
        { ID = 900005, requiredLevel = 1, questLevel = 5, sourceItemId = 0, requiredSourceItems = {},
          objectives = {}, killCreditFirst = false, hasTriggerEnd = false, extraObjectives = {},
          m1Status = "SUPPORTED", m1Reasons = {} },
        -- spawn-only extra (no refs) linked to objective 0
        { ID = 900006, requiredLevel = 1, questLevel = 5, sourceItemId = 0, requiredSourceItems = {},
          objectives = { { position = 1, kind = "creature", slotIndex = 1, id = 901, occurrence = 1 } },
          killCreditFirst = false, hasTriggerEnd = false,
          extraObjectives = { { position = 1, icon = 3, hasText = true, spawnZones = { 1, 12 }, objectiveIndex = 0, refs = {} } },
          m1Status = "SUPPORTED", m1Reasons = {} },
    },
}
