-- SYNTHETIC nq-m2-markers v1 records (DRAFT; no exporter exists). Every ID,
-- zone and coordinate is INVENTED for format testing (IDs 9100xx-9199xx,
-- coordinates chosen by hand). No real Questie or server spawn is copied.
return {
    -- M-A1: spawn-only custom event, two distinct pins in one zone, objectiveIndex 0
    { ID = 910001, starters = { { type = "monster", id = 911001 } }, finishers = { { type = "monster", id = 911001 } },
      objectives = {},
      extraObjectives = { { position = 1, objectiveIndex = 0, icon = 3, refs = {},
          customSpawns = { { zone = 9001, pins = { { x = 41.37, y = 22.05, pinIndex = 1 }, { x = 41.38, y = 22.05, pinIndex = 2 } } } } } },
      points = { { origin = "custom_extra", extraPosition = 1, zone = 9001, x = 41.37, y = 22.05, pinIndex = 1 },
                 { origin = "custom_extra", extraPosition = 1, zone = 9001, x = 41.38, y = 22.05, pinIndex = 2 } },
      waypoints = {} },
    -- M-A2: custom pins plus monster and object refs; displayRef = first ref only
    { ID = 910002, starters = {}, finishers = {},
      objectives = { { position = 1, kind = "creature", targets = { { type = "monster", id = 912001, via = "direct" } } } },
      extraObjectives = { { position = 1, objectiveIndex = 1, icon = 5,
          refs = { { type = "monster", id = 912002, refIndex = 1 }, { type = "object", id = 912003, refIndex = 2 } },
          displayRef = { type = "monster", id = 912002 },
          customSpawns = { { zone = 9002, pins = { { x = 10.5, y = 80.25, pinIndex = 1 } } } } } },
      points = { { origin = "db_npc", ownerId = 912001, zone = 9002, x = 50.0, y = 50.0, pinIndex = 1 },
                 { origin = "db_npc", ownerId = 912002, zone = 9002, x = 12.0, y = 70.0, pinIndex = 1 },
                 { origin = "db_object", ownerId = 912003, zone = 9002, x = 13.0, y = 71.0, pinIndex = 1 },
                 { origin = "custom_extra", extraPosition = 1, zone = 9002, x = 10.5, y = 80.25, pinIndex = 1 } },
      waypoints = {} },
    -- M-A3: NPC in two zones with a patrol path; waypoints never counted as spawns
    { ID = 910003, starters = {}, finishers = {},
      objectives = { { position = 1, kind = "creature", targets = { { type = "monster", id = 913001, via = "direct" } } } },
      extraObjectives = {},
      points = { { origin = "db_npc", ownerId = 913001, zone = 9003, x = 20.0, y = 20.0, pinIndex = 1 },
                 { origin = "db_npc", ownerId = 913001, zone = 9004, x = 60.0, y = 40.0, pinIndex = 1 } },
      waypoints = { { npcId = 913001, zone = 9003, path = { { 20.0, 20.0 }, { 25.0, 22.0 }, { 30.0, 24.0 } } } } },
    -- M-A4: item objective with all four source categories, kept apart
    { ID = 910004, starters = {}, finishers = {},
      objectives = { { position = 1, kind = "item", targets = {
          { type = "monster", id = 914001, via = "itemSource", sourceKind = "npcDrop", path = { 914100, 914001 } },
          { type = "object", id = 914002, via = "itemSource", sourceKind = "objectDrop", path = { 914100, 914002 } },
          { type = "monster", id = 914003, via = "itemSource", sourceKind = "vendor", path = { 914100, 914003 } },
          { type = "item", id = 914004, via = "itemSource", sourceKind = "itemDrop", path = { 914100, 914004 } } } } },
      extraObjectives = {},
      points = { { origin = "db_npc", ownerId = 914001, zone = 9005, x = 30.0, y = 30.0, pinIndex = 1 },
                 { origin = "db_object", ownerId = 914002, zone = 9005, x = 31.0, y = 31.0, pinIndex = 1 },
                 { origin = "db_npc", ownerId = 914003, zone = 9006, x = 70.0, y = 10.0, pinIndex = 1 } },
      waypoints = {} },
}
