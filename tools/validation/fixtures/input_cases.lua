-- M2.1 input schema negative cases. Each case mutates a deep copy of the
-- valid synthetic fixture (tests/fixtures/m2_input/valid_selected_quests.lua)
-- and must be rejected with an error matching `expect` (plain substring).
local function q(doc, id)
    for _, r in ipairs(doc.quests) do if r.ID == id then return r end end
end

return {
    -- top level / versioning
    { name = "wrong schema name", expect = "schema: must be", mutate = function(d) d.schema = "other" end },
    { name = "unsupported schema version", expect = "schemaVersion: unsupported", mutate = function(d) d.schemaVersion = 2 end },
    { name = "unknown top-level field", expect = "unknown top-level field", mutate = function(d) d.extra = 1 end },
    { name = "quests missing", expect = "quests: missing", mutate = function(d) d.quests = nil end },
    { name = "quests empty", expect = "quests: empty", mutate = function(d) d.quests = {}; d.provenance.questCount = 1 end },
    { name = "quests keyed by ID instead of a list", expect = "list has holes or non-list keys",
      mutate = function(d) d.quests = { [1203] = d.quests[1] }; d.provenance.questCount = 1 end },
    -- provenance
    { name = "provenance missing", expect = "provenance: missing", mutate = function(d) d.provenance = nil end },
    { name = "exporter missing", expect = "provenance.exporter", mutate = function(d) d.provenance.exporter = nil end },
    { name = "exporter version not semver", expect = "provenance.exporterVersion", mutate = function(d) d.provenance.exporterVersion = "v1" end },
    { name = "source label is a path", expect = "provenance.sourceLabel",
      mutate = function(d) d.provenance.sourceLabel = "/home/user/acore_world.zip" end },
    { name = "fingerprint not sha256", expect = "provenance.sourceFingerprint", mutate = function(d) d.provenance.sourceFingerprint = "md5:abc" end },
    { name = "export time not UTC ISO", expect = "provenance.exportedAt", mutate = function(d) d.provenance.exportedAt = "2026-10-14 12:00" end },
    { name = "export time impossible date", expect = "not a valid date", mutate = function(d) d.provenance.exportedAt = "2026-13-14T12:00:00Z" end },
    { name = "selection not explicit", expect = "provenance.selection", mutate = function(d) d.provenance.selection = "all" end },
    { name = "questCount mismatch", expect = "does not match", mutate = function(d) d.provenance.questCount = 3 end },
    { name = "unknown provenance field (e.g. a path)", expect = "provenance.path: unknown field",
      mutate = function(d) d.provenance.path = "/tmp/x" end },
    -- records
    { name = "duplicate quest ID", expect = "duplicate quest ID 1203",
      mutate = function(d) d.quests[2].ID = 1203 end },
    { name = "record is not a table", expect = "record is not a table", mutate = function(d) d.quests[2] = 5 end },
    { name = "missing objective field", expect = "RequiredItemCount1: missing", mutate = function(d) q(d, 1203).RequiredItemCount1 = nil end },
    { name = "non-integer field", expect = "must be an integer", mutate = function(d) q(d, 1203).RequiredItemCount1 = 1.5 end },
    { name = "string in numeric field", expect = "must be an integer", mutate = function(d) q(d, 1203).StartItem = "0" end },
    { name = "negative item id", expect = "RequiredItemId1: must be between", mutate = function(d) q(d, 1203).RequiredItemId1 = -3853 end },
    { name = "zero quest ID", expect = ".ID: must be positive", mutate = function(d) q(d, 1203).ID = 0 end },
    { name = "unknown record field", expect = "RequiredItemId7: unknown field", mutate = function(d) q(d, 1203).RequiredItemId7 = 0 end },
    { name = "item set with zero count", expect = "RequiredItemCount1: must be > 0", mutate = function(d) q(d, 1203).RequiredItemCount1 = 0 end },
    { name = "empty item slot with count", expect = "RequiredItemCount2: must be 0", mutate = function(d) q(d, 1203).RequiredItemCount2 = 2 end },
    { name = "gameobject target with zero count", expect = "RequiredNpcOrGoCount1: must be > 0",
      mutate = function(d) q(d, 900102).RequiredNpcOrGoCount1 = 0 end },
    { name = "NpcOrGo out of range", expect = "RequiredNpcOrGo1: out of range",
      mutate = function(d) q(d, 900102).RequiredNpcOrGo1 = -3000000000 end },
    -- tri-state flags
    { name = "hasConditions absent", expect = "hasConditions: missing", mutate = function(d) q(d, 1203).hasConditions = nil end },
    { name = "ipGated absent", expect = "ipGated: missing", mutate = function(d) q(d, 1203).ipGated = nil end },
    { name = "scriptedCredit absent", expect = "scriptedCredit: missing", mutate = function(d) q(d, 1203).scriptedCredit = nil end },
    { name = "flag with invalid value", expect = "ipGated: must be true, false or", mutate = function(d) q(d, 1203).ipGated = "maybe" end },
    { name = "flag as number", expect = "scriptedCredit: must be true, false or", mutate = function(d) q(d, 1203).scriptedCredit = 0 end },
    { name = "killCreditComplete absent", expect = "killCreditComplete: missing", mutate = function(d) q(d, 1203).killCreditComplete = nil end },
    { name = "killCreditComplete as string", expect = "killCreditComplete: missing or not a boolean",
      mutate = function(d) q(d, 1203).killCreditComplete = "true" end },
    -- KillCredit
    { name = "KillCredit absent", expect = "KillCredit: missing", mutate = function(d) q(d, 1203).KillCredit = nil end },
    { name = "KillCredit keyed by gameobject (negative)", expect = "gameobjects have no KillCredit",
      mutate = function(d) q(d, 900102).KillCredit = { [-900200] = { 0, 0 } } end },
    { name = "KillCredit row with one value", expect = "[2]: must be an integer",
      mutate = function(d) q(d, 900101).KillCredit[900140] = { 0 } end },
    { name = "KillCredit row negative", expect = "[1]: must be an integer",
      mutate = function(d) q(d, 900101).KillCredit[900140] = { -1, 0 } end },
    { name = "KillCredit row extra values", expect = "only {credit1, credit2}",
      mutate = function(d) q(d, 900101).KillCredit[900140] = { 0, 0, 0 } end },
    { name = "KillCredit row not a table", expect = "must be {credit1, credit2}",
      mutate = function(d) q(d, 900101).KillCredit[900140] = 0 end },
    { name = "complete claimed but a creature row is missing", expect = "no row for creature 900141",
      mutate = function(d) q(d, 900101).KillCredit[900141] = nil end },
    { name = "complete claimed with no rows at all", expect = "no row for creature 900151",
      mutate = function(d) q(d, 900103).killCreditComplete = true end },
}
