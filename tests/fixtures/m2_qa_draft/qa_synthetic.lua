-- SYNTHETIC correction-regression and text-QA observations (DRAFT). Values
-- are invented; 1203's 3853 vs 33110 are the public compiled/stock item IDs.
-- No in-game observation is claimed by this file.
return {
    regression = {
        { questId = 1203, fields = { objectives = { expectedInherited = 33110, approved = 3853, compiled = 3853 } },
          unrelatedDiffs = 0, m23Outcome = "EXPECTED_REPRESENTATION_DIFF" },
        { questId = 900101, fields = { questLevel = { expectedInherited = 20, approved = 22, compiled = 22 } },
          unrelatedDiffs = 0, m23Outcome = "NEEDS_MANUAL_REVIEW", reviewNote = "ip evidence unknown in M2.1" },
        { questId = 900102, fields = { questLevel = { expectedInherited = 30, approved = 31, compiled = 31 } }, unrelatedDiffs = 0 },
    },
    text = {
        { questId = 2001, surface = "questLogCount", stage = "accepted", clientLocale = "enUS", availability = "verified",
          observed = true, textSource = "client", result = "PASS" },
        { questId = 1203, surface = "questLogLine", stage = "accepted", clientLocale = "deDE", availability = "unknown",
          observed = false, result = "UNKNOWN" },
        { questId = 11142, surface = "objectiveMarkerTooltip", stage = "progress", clientLocale = "enUS", availability = "verified",
          observed = true, textSource = "addon", result = "DIFFERENCE_TO_REVIEW", autoRewrite = false },
    },
}
