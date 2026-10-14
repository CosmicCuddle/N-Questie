-- SYNTHETIC M2.3 private report example (DRAFT; no engine exists). Quest IDs
-- are public Questie IDs used as labels only; every status, outcome and
-- evidence value is invented to exercise the format. Not a real comparison.
local full = { killCredit = "complete", conditions = "complete", scripts = "complete", ip = "complete", objectiveData = "complete" }
return {
    schema = "nq-m2-3-report", schemaVersion = 1, private = true,
    selected = { 1203, 2001, 498, 10503, 11142, 25199, 999999, 900007, 900005 },
    rows = {
        { questId = 1203, exportStatus = "EXPORTED", m1Supported = true, m1Findings = 1, representationDiff = true,
          evidence = full, outcome = "EXPECTED_REPRESENTATION_DIFF" },
        { questId = 2001, exportStatus = "EXPORTED", m1Supported = true, m1Findings = 0, evidence = full,
          outcome = "CONFIRMED_MATCH" },
        { questId = 498, exportStatus = "EXPORTED", m1Supported = true, m1Findings = 0,
          evidence = { killCredit = "unknown", conditions = "complete", scripts = "complete", ip = "complete", objectiveData = "complete" },
          outcome = "NEEDS_MANUAL_REVIEW" },
        { questId = 10503, exportStatus = "UNSUPPORTED_BY_SCHEMA_VERSION", reasons = { "KILLCREDIT_FIRST_REORDER" } },
        { questId = 11142, exportStatus = "UNSUPPORTED_BY_SCHEMA_VERSION", reasons = { "DUPLICATE_OBJECT", "EXTRA_CREATURE_REF" } },
        { questId = 25199, exportStatus = "EXPORTED", m1Supported = false, outcome = "M1_UNSUPPORTED_BY_RULES" },
        { questId = 999999, exportStatus = "ABSENT_FROM_EFFECTIVE_DB" },
        { questId = 900007, exportStatus = "EXPORTED", m1Supported = true, m1Findings = 2, evidence = full,
          outcome = "CONFIRMED_MISMATCH" },
        { questId = 900005, exportStatus = "REJECTED_MALFORMED_INPUT" },
    },
}
