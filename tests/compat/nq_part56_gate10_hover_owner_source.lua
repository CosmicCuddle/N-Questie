-- Executes the actual Gate10 custom data and loader in a stubbed Questie 3.3.5a contract.
-- REVIEW-ONLY: no client, SQL, SavedVariables, download or package generation.
local function testCase(label, mutate, expectFull)
    local callbacks = {}
    QuestieCompat = {
        Is335 = true,
        RegisterCorrection = function(kind, callback)
            assert(type(kind) == "string" and type(callback) == "function")
            callbacks[kind] = callback
        end,
    }
    local keys = {
        name = 1, startedBy = 2, finishedBy = 3, requiredLevel = 4,
        questLevel = 5, requiredRaces = 6, requiredClasses = 7,
        objectivesText = 8, objectives = 10, sourceItemId = 11,
        preQuestSingle = 13, preQuestGroup = 12, childQuests = 14,
        exclusiveTo = 16, zoneOrSort = 17, nextQuestInChain = 22,
        questFlags = 23, specialFlags = 24, parentQuest = 25,
    }
    QuestieDB = {
        questKeys = keys,
        questData = {[2001] = {name = "previous public 2001"}},
        npcData = {[2121] = {}, [1868] = {}, [1869] = {}, [3393] = {}},
        npcKeys = {
            name = 1, minLevel = 2, maxLevel = 3, rank = 4,
            factionID = 5, npcFlags = 6, zoneID = 7, spawns = 8,
            questStarts = 9, questEnds = 10,
        },
        objectData = {},
        objectKeys = {
            name = 1, zoneID = 2, spawns = 3,
            questStarts = 4, questEnds = 5,
        },
        itemData = {},
        itemKeys = {
            name = 1, class = 2, subClass = 3, npcDrops = 4, objectDrops = 5,
        },
    }
    QuestieLoader = {
        ImportModule = function(_, name)
            assert(name == "QuestieDB")
            return QuestieDB
        end
    }
    NQuestieCustomQuestData = nil
    dofile("Compat/NQuestieCustomQuestData.lua")
    assert(NQuestieCustomQuestData.revision == 11, "new revision required")
    if mutate then mutate(NQuestieCustomQuestData) end
    dofile("Compat/NQuestieCustomQuestLoader.lua")
    assert(callbacks.questData, "original quest correction registered")
    local rows = callbacks.questData()
    assert(rows[2001], "protected public 2001 regression")
    if expectFull then
        local expected = {
            [1207] = {text = "Collect 20 Kirin Tor Signet rings from mages inside Northwatch Hold and return to Thugg in Ratchet", items = {166}},
            [1208] = {text = "Collect 15 War Documents from Northwatch Hold and return to Thugg in Ratchet", items = {167}},
            [1209] = {text = "Slay and collect the heads of Captain Fairmount and her allies Duncan Stonefist and Cassia Frostveil inside Northwatch Hold and return to Thugg in Ratchet", items = {160, 161, 162}},
        }
        for id, row in pairs(expected) do
            local got = assert(rows[id], "custom quest missing: " .. tostring(id))
            local desc = assert(got[keys.objectivesText], "description missing: " .. tostring(id))
            assert(#desc == 1 and desc[1] == row.text, "description mismatch: " .. tostring(id))
            local objectives = assert(got[keys.objectives], "objectives missing")
            local itemObjectives = assert(objectives[3], "item objective slot changed")
            assert(#itemObjectives == #row.items, "item count changed")
            for i, itemId in ipairs(row.items) do
                assert(itemObjectives[i][1] == itemId, "objective mapping changed")
            end
            assert(got[keys.requiredLevel] == 18 and got[keys.questLevel] == 21, "quest levels changed")
            assert(got[keys.startedBy][1][1] == 1209, "quest giver changed")
        end
        assert(rows[2001][keys.objectivesText] == nil, "2001 must remain unchanged")
        assert(QuestieDB.itemData[166] and QuestieDB.objectData[2013] and QuestieDB.npcData[3677], "source batch disappeared")
    else
        for _, id in ipairs({1207, 1208, 1209}) do
            assert(rows[id] == nil, "invalid custom batch must be rejected: " .. tostring(id))
        end
        assert(QuestieDB.itemData[166] == nil and QuestieDB.objectData[2013] == nil, "failed batch must rollback")
    end
    print("PASS " .. label)
end

testCase("three source-verified descriptions plus unchanged objective identity", nil, true)
testCase("reject non-array description", function(data) data.quests[1207].objectivesText = "invalid" end, false)
testCase("reject empty description", function(data) data.quests[1208].objectivesText = {} end, false)
testCase("reject multiple descriptions", function(data) data.quests[1209].objectivesText = {"text", "extra"} end, false)
testCase("reject sparse description", function(data) data.quests[1208].objectivesText = {[2] = "gap"} end, false)
testCase("reject overlong description", function(data) data.quests[1208].objectivesText = {string.rep("A", 65536)} end, false)
testCase("reject compiler sentinel nil text", function(data) data.quests[1207].objectivesText = {"nil"} end, false)
testCase("reject absent objectivesText schema mapping", function(data)
    QuestieDB.questKeys.objectivesText = nil
end, false)
testCase("reject shifted objectivesText schema mapping", function(data)
    QuestieDB.questKeys.objectivesText = 9
end, false)
print("PASS all 9 original-loader owner-hover source cases")
