-- EXPECT: 1203 item objective is 3853
-- Synthetic fault: an N-Questie correction writes a malformed objectives value
-- for quest 1203 and another returns a non-table. The harness must fail.
local ctx = ...
ctx.registerNQuestie("questData", function()
    return { [1203] = { [ctx.QK.objectives] = "corrupted" } }
end)
ctx.registerNQuestie("questData", function()
    return "not a table"
end)
