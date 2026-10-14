-- EXPECT: not allow-listed
-- Synthetic fault: a correction changes a field that is not allow-listed
-- (quest 1203 questLevel) and an unrelated quest (Dustwallow 1173). The
-- harness must fail with "not allow-listed".
local ctx = ...
ctx.registerNQuestie("questData", function()
    return {
        [1203] = { [ctx.QK.questLevel] = 36 },
        [1173] = { [ctx.QK.name] = "Synthetic unexpected rename" },
    }
end)
