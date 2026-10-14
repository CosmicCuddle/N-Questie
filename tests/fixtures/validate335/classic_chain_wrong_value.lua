-- EXPECT: PR #13 quest 225 requiredLevel 28
-- Synthetic fault: the registered Classic-chain correction sets the correct
-- 225 minimum to 28, then this later callback changes it to 29.
-- The 3.3.5a M0 check must reject the incorrect final effective DB value.
local ctx = ...
ctx.registerNQuestie("questData", function()
    return { [225] = { [ctx.QK.requiredLevel] = 29 } }
end)
