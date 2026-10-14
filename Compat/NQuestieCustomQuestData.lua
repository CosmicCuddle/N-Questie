-- N-Questie server-specific quest records. Derived from a read-only world export.
-- Public curated quest metadata only; never include a raw database dump here.
-- Increase revision whenever any record changes to rebuild Questie's compiled DB.
NQuestieCustomQuestData = {
    revision = 2,
    quests = {
        [2001] = {
            name = "Ravenclaw Cleanup",
            requiredLevel = 12,
            questLevel = 16,
            zoneOrSort = 130, -- Silverpine Forest (AreaTable.dbc ID)
            requiredRaces = 690, -- world.quest_template.AllowableRaces
            questFlags = 8,
            preQuestSingle = {437}, -- world.quest_template_addon.PrevQuestID
            startedByNpcs = {2121}, -- Shadow Priest Allister
            finishedByNpcs = {2121},
            killNpcs = {1868, 1869}, -- Ravenclaw Servant/Champion; 8 of each
        },
    },
}
