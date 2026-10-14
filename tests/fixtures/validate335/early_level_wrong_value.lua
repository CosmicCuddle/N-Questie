-- EXPECT: PR #8 quest 169 requiredLevel 15
-- Synthetic fault: a later correction sets an allow-listed field to a wrong
-- value (quest 169 minimum level 16 instead of 15). Only meaningful when the
-- PR #8 early-level module is in the TOC; otherwise the harness fails earlier
-- with "not allow-listed", which is also a rejection.
local ctx = ...
ctx.registerNQuestie("questData", function()
    return { [169] = { [ctx.QK.requiredLevel] = 16 } }
end)
