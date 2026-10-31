-- N-Questie server-specific quest records. Derived from a read-only world export.
-- Public curated quest metadata only; never include a raw database dump here.
-- Increase revision whenever a record or loader behaviour changes to rebuild the compiled DB.
NQuestieCustomQuestData = {
    revision = 10,
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
        [1207] = {
            name = "The Kirin Tor Aid",
            requiredLevel = 18, questLevel = 21, zoneOrSort = 17, -- The Barrens
            requiredRaces = 690, questFlags = 0,
            startedByNpcs = {1209}, finishedByNpcs = {1209},
            itemObjectives = {166},
        },
        [1208] = {
            name = "Northwatch Intel",
            requiredLevel = 18, questLevel = 21, zoneOrSort = 17,
            requiredRaces = 690, questFlags = 0,
            startedByNpcs = {1209}, finishedByNpcs = {1209},
            itemObjectives = {167},
        },
        [1209] = {
            name = "WANTED: The Northwatch Guard",
            requiredLevel = 18, questLevel = 21, zoneOrSort = 17,
            requiredRaces = 690, questFlags = 0,
            startedByNpcs = {1209}, finishedByNpcs = {1209},
            itemObjectives = {160, 161, 162},
        },
    },
    -- Gate10 (quests 1207-1209): source records these quests need that are
    -- absent from the inherited Questie database. Player-visible fields only.
    -- Spawns are Barrens (zone 17) map percentages. Provisioned all-or-nothing
    -- by NQuestieCustomQuestLoader before the quest list is first built.
    -- POTENTIAL ISSUE / NOT TESTED in-game: spawn map percentages were
    -- converted from world coordinates with the Barrens map bounds.
    sources = {
        npcs = {
            [1209] = {
                name = "Thugg", minLevel = 35, maxLevel = 35,
                factionID = 85, npcFlags = 2, zoneID = 17,
                spawns = {[17] = {{62.2, 39.25}}},
            },
            [3506] = {
                name = "Captain Duncan Stonefist", minLevel = 20, maxLevel = 20,
                factionID = 1077, npcFlags = 0, zoneID = 17,
                spawns = {[17] = {{60.54, 55.07}}},
            },
            [3526] = {
                name = "Arcanist Cassia Frostveil", minLevel = 20, maxLevel = 20,
                factionID = 24, npcFlags = 0, zoneID = 17,
                spawns = {[17] = {{62.95, 56.7}}},
            },
            [3677] = {
                name = "Theramore Mage", minLevel = 17, maxLevel = 19, rank = 1,
                factionID = 1077, npcFlags = 0, zoneID = 17,
                spawns = {[17] = {{61.92, 54.79}, {61.87, 54.98}, {63.14, 56.65}, {62.18, 56.52}, {61.61, 56.07}, {62.42, 56.01}, {62.2, 56.09}, {61.02, 55.83}, {61.07, 55.85}, {61.74, 54.67}, {61.93, 54.62}, {61.8, 55.12}, {61.8, 53.48}, {61.39, 53.07}, {61.23, 53.49}, {61.03, 53.75}, {61.24, 53.98}, {61.26, 54.03}, {61.37, 54.78}, {61.95, 55.77}, {61.38, 55.62}, {60.92, 55.48}, {60.45, 55.5}, {60.9, 54.93}}},
            },
        },
        objects = {
            [2013] = {
                name = "War Documents", zoneID = 17,
                spawns = {[17] = {{61.88, 54.96}, {61.89, 55.09}, {62.0, 54.72}, {61.71, 54.85}, {61.72, 54.65}, {61.85, 55.16}, {61.51, 53.66}, {61.88, 53.51}, {61.96, 53.52}, {62.18, 53.63}, {62.08, 53.5}, {61.03, 53.63}, {62.0, 55.34}, {62.29, 56.54}, {62.84, 56.5}, {63.17, 56.67}, {63.18, 56.57}, {61.58, 56.03}, {61.29, 55.59}, {61.25, 55.61}, {60.71, 55.09}, {60.5, 55.38}, {60.38, 54.8}, {61.6, 53.25}}},
            },
        },
        items = {
            [160] = {name = "The Head of Duncan Stonefist", class = 12, subClass = 0, npcDrops = {3506}},
            [161] = {name = "Head of Cassia Frostveil", class = 12, subClass = 0, npcDrops = {3526}},
            [162] = {name = "Head of Captain Fairmount", class = 12, subClass = 0, npcDrops = {3393}},
            [166] = {name = "Kirin Tor Signet", class = 12, subClass = 0, npcDrops = {3677}},
            [167] = {name = "War Documents", class = 12, subClass = 0, objectDrops = {2013}},
        },
    },
}
