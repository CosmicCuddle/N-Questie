-- SYNTHETIC compiled-shaped Questie quest values for the Stage A1 v2 builder
-- tests. Shapes copy QueryQuestSingle output (objectives slots 1-6 as
-- {id, text}, reputation {factionId, value}, killCredit {{ids}, rootId, text},
-- spells {id, text, itemSourceId}, extraObjectives {spawns, icon, text,
-- objectiveIndex, {{type, id}}}). Quest IDs 910001-910020 are invented;
-- every value is invented. No private data.
local S = {}
S.killCreditFirst = { [910003] = true, [910004] = true, [910013] = true }
S.quests = {
    -- all six kinds, compiled order, rep value 0, spell without item source
    [910001] = { requiredLevel = 20, questLevel = 22, sourceItemId = 0, requiredSourceItems = nil,
        objectives = { { { 101, "Kill" } }, { { 201 } }, { { 301, "Loot" } }, { 72, 0 },
            { { { 401, 402, 403 }, 401, "Credit" } }, { { 501, "Cast" } } },
        triggerEnd = { "Go there", { [1] = { { 10, 20 } } } },
        extraObjectives = { { nil, 2, "Use it", 6, { { "object", 202 } } } } },
    -- requiredSourceItems overlapping an item objective; sourceItemId set
    [910002] = { requiredLevel = 10, questLevel = 12, sourceItemId = 701, requiredSourceItems = { 701, 702 },
        objectives = { nil, nil, { { 701 } } } },
    -- three killCredit entries, killCreditFirst: reversed
    [910003] = { requiredLevel = 70, questLevel = 72, sourceItemId = nil,
        objectives = { nil, nil, nil, nil, { { { 801 }, 801 }, { { 802 }, 802 }, { { 803 }, 803 } } } },
    -- killCreditFirst with a creature before it
    [910004] = { requiredLevel = 70, questLevel = 72,
        objectives = { { { 813 } }, nil, nil, nil, { { { 811, 812 }, 811 } } } },
    -- no objectives at all (objectives = {} as in the compiled DB)
    [910005] = { requiredLevel = 1, questLevel = 5, objectives = {} },
    -- objectives absent (nil)
    [910006] = { requiredLevel = 1, questLevel = 5 },
    -- repeated creature id four times (shape of 25199) and an object twice
    [910007] = { requiredLevel = 60, questLevel = 62,
        objectives = { { { 901 }, { 902 }, { 901 }, { 901 }, { 901 } }, { { 903 }, { 903 } } } },
    -- spawn-only extra (no refs), zones given in non-sorted insertion order
    [910008] = { requiredLevel = 5, questLevel = 6, objectives = { { { 904 } } },
        extraObjectives = { { { [12] = { { 1, 2 }, { 3, 4 } }, [1] = { { 5, 6 } }, [440] = { { 7, 8 } } }, 3, "Look", 0 } } },
    -- multiple refs of every type in one extra entry, plus a second extra
    [910009] = { requiredLevel = 30, questLevel = 31, objectives = { { { 905 } }, nil, { { 906 } } },
        extraObjectives = { { nil, 5, nil, 2, { { "monster", 907 }, { "object", 908 }, { "item", 909 }, { "monster", 907 } } },
                            { nil, 1, "Talk", 1, { { "monster", 910 } } } } },
    -- extra linked one past the DB objectives: quest without DB objectives (client-only log line)
    [910010] = { requiredLevel = 68, questLevel = 70, objectives = {},
        extraObjectives = { { nil, 5, "Ride", 1, { { "monster", 911 } } } } },
    -- extra linked to the triggerEnd event line (objectives + 1)
    [910011] = { requiredLevel = 68, questLevel = 70, objectives = { { { 912 } } }, triggerEnd = { "Event", {} },
        extraObjectives = { { nil, 5, "Event", 2, { { "monster", 913 } } } } },
    -- scaling quest level and reputation with a negative value
    [910012] = { requiredLevel = 80, questLevel = -1, objectives = { nil, nil, nil, { 1098, -42000 } } },
    -- killCreditFirst flagged with a single killCredit and nothing else
    [910013] = { requiredLevel = 70, questLevel = 72, objectives = { nil, nil, nil, nil, { { { 821 }, 821 } } } },
    -- plain v1-representable quest with an item extra
    [910014] = { requiredLevel = 15, questLevel = 18, objectives = { { { 914, "Slay" } }, nil, { { 915 } } },
        extraObjectives = { { nil, 4, "Use", 0, { { "item", 916 } } } } },
}
-- Spec conflict cases (not in the real compiled DB, measured 0): v1 codes and
-- the v2 ExpectedM1 rule disagree, so the round trip must fail closed.
S.conflicts = {
    -- killCreditFirst flagged, a single killCredit and nothing else: v1 SUPPORTED,
    -- v2 ExpectedM1 UNSUPPORTED (KILLCREDIT_FIRST_REORDER)
    [910013] = true,
    -- repeated requiredSourceItems: v1 DUPLICATE_SOURCE_ITEM, v2 ExpectedM1 SUPPORTED
    [910015] = true,
}
S.quests[910015] = { requiredLevel = 10, questLevel = 12, sourceItemId = 701, requiredSourceItems = { 701, 702, 701 } }
return S
