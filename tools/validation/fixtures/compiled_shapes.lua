-- Compiled Questie query results (QuestieDB.QueryQuestSingle) copied from the
-- public 3.3.5a N-Questie database on 2026-10-14 by running the M0 harness.
-- Public Questie data only. Used to unit-test EffectiveExport without the
-- ~20-90 s harness run; the harness integration test checks the same IDs live.
-- Objective, source-item, triggerEnd and extraObjectives values are copied;
-- levels are real for 1203, 2001, 2784, 30, 25 and 28; the refused quests
-- (1036, 1367, 11142, 11706) use placeholder levels 1/1.
return {
    [1203] = { requiredLevel = 30, questLevel = 35, objectives = { nil, nil, { { 3853 } } } },
    [2001] = { requiredLevel = 12, questLevel = 16, objectives = { { { 1868 }, { 1869 } } } },
    [2784] = { requiredLevel = 45, questLevel = 50, sourceItemId = 0,
               objectives = { nil, nil, nil, nil, { { { 7572 }, 7572, "The Tale of Sorrow" } } } },
    [30]   = { requiredLevel = 16, questLevel = -1, sourceItemId = 0, objectives = { nil, nil, { { 15885 } } },
               requiredSourceItems = { 15883, 15882 },
               extraObjectives = { { { [493] = { { 36.479217603912, 41.687041564792 } } }, 3,
                                     "Combine the Pendant halves at the Shrine of Remulos.", 0 } } },
    [25]   = { requiredLevel = 23, questLevel = 25, sourceItemId = 0, objectives = { { { 3917 } } },
               triggerEnd = { "Scout the gazebo on Mystral Lake that overlooks the nearby Alliance outpost.",
                              { [331] = { { 48.899755501222, 69.559902200489 } } } } },
    [28]   = { requiredLevel = 16, questLevel = -1, sourceItemId = 0, objectives = {}, requiredSourceItems = { 15877 },
               triggerEnd = { "Complete the Trial of the Lake.", { [493] = { { 36.161369193154, 41.662591687042 } } } } },
    -- not representable in v1 (must be refused, never trimmed)
    [1036] = { requiredLevel = 1, questLevel = 1, objectives = { nil, nil, nil, { 87, 3000 } } },
    [1367] = { requiredLevel = 1, questLevel = 1, objectives = { nil, nil, nil, { 93, 3000 } },
               extraObjectives = { { nil, 1, "Slay Gelkis centaur to increase your reputation with the Magram Clan", 0,
                                     { { "monster", 4653 }, { "monster", 4647 } } } } },
    [11142] = { requiredLevel = 1, questLevel = 1, objectives = { nil, { { 500007 }, { 500007 } } } },
    [11706] = { requiredLevel = 1, questLevel = 1, sourceItemId = 34968,
                objectives = { { { 25768 }, { 25768, "Nerubian tunnels collapsed" } } },
                extraObjectives = { { nil, 3, "Use The Horn of Elemental Fury near the southern sinkhole", 0,
                                      { { "monster", 25664 } } } } },
}
