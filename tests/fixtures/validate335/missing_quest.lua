-- EXPECT: quest 2001 missing after corrections
-- luacheck: globals NQuestieCustomQuestData
-- Synthetic fault: the curated custom quest 2001 is absent from the overlay
-- data. The harness must report quest 2001 as missing.
local _ = ...
NQuestieCustomQuestData.quests[2001] = nil
