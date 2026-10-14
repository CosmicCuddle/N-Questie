-- SYNTHETIC M2.3 private report example (DRAFT; no engine exists). Public
-- Questie IDs are used as labels only (900007 is invented); every status,
-- outcome, M1 class list and evidence value is invented to exercise the
-- format. Not a real comparison and not private data.
local full = { killCredit = "complete", conditions = "complete", scripts = "complete", ip = "complete", objectiveData = "complete" }
return {
    schema = "nq-m2-3-report", schemaVersion = 1, private = true,
    selected = { 1203, 2001, 498, 10503, 11142, 25199, 999999, 900007 },
    rows = {
        { questId = 1203, exportStatus = "EXPORTED", m1Supported = true, m1Classes = { "EXPECTED_REPRESENTATION_DIFF" },
          representationDiff = true, evidence = full, outcome = "EXPECTED_REPRESENTATION_DIFF" },
        { questId = 2001, exportStatus = "EXPORTED", m1Supported = true, m1Classes = {}, evidence = full,
          outcome = "CONFIRMED_MATCH" },
        { questId = 498, exportStatus = "EXPORTED", m1Supported = true, m1Classes = {},
          evidence = { killCredit = "unknown", conditions = "complete", scripts = "complete", ip = "complete", objectiveData = "complete" },
          outcome = "NEEDS_MANUAL_REVIEW" },
        { questId = 10503, exportStatus = "UNSUPPORTED_BY_SCHEMA_VERSION", reasons = { "KILLCREDIT_FIRST_REORDER" } },
        { questId = 11142, exportStatus = "UNSUPPORTED_BY_SCHEMA_VERSION", reasons = { "DUPLICATE_OBJECT", "EXTRA_CREATURE_REF" } },
        { questId = 25199, exportStatus = "EXPORTED", m1Supported = false, outcome = "M1_UNSUPPORTED_BY_RULES" },
        { questId = 999999, exportStatus = "ABSENT_FROM_EFFECTIVE_DB" },
        { questId = 900007, exportStatus = "EXPORTED", m1Supported = true, m1Classes = { "CONFIRMED_MISMATCH" }, evidence = full,
          outcome = "CONFIRMED_MISMATCH" },
    },
}
