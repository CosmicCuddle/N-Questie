-- SYNTHETIC M2.3 negative/positive batch matrix (DRAFT). Each case states the
-- input condition and the required engine result. "reject" means whole-batch
-- rejection: no report, no aggregate, no partial output. Used by the draft
-- test to check the matrix is complete and self-consistent; it is the
-- acceptance list for a future engine.
return {
    { id = "B01", input = "server", condition = "server file fails M2.1 validation (any provenance field missing)", result = "reject" },
    { id = "B02", input = "server", condition = "server provenance carries a git commit", result = "reject" },
    { id = "B03", input = "effective", condition = "unknown schemaVersion", result = "reject" },
    { id = "B04", input = "effective", condition = "v2 file fails v2 validation (kill credit not reversed)", result = "reject" },
    { id = "B05", input = "effective", condition = "sourceDirty true", result = "reject" },
    { id = "B06", input = "manifest", condition = "manifest aggregate does not reconcile", result = "reject" },
    { id = "B07", input = "pairing", condition = "manifest commit differs from export commit", result = "reject" },
    { id = "B08", input = "pairing", condition = "correction fingerprint or modules differ", result = "reject" },
    { id = "B09", input = "pairing", condition = "harness version differs", result = "reject" },
    { id = "B10", input = "membership", condition = "exported quest listed UNSUPPORTED in manifest", result = "reject" },
    { id = "B11", input = "membership", condition = "manifest REPRESENTABLE quest missing from v1 export", result = "reject" },
    { id = "B12", input = "membership", condition = "export and manifest quest counts differ", result = "reject" },
    { id = "B13", input = "server", condition = "duplicate quest ID in server file", result = "reject" },
    { id = "B14", input = "all", condition = "input changed during run (deep compare)", result = "reject" },
    { id = "B15", input = "output", condition = "output path unsafe or exists", result = "reject" },
    { id = "Q01", input = "quest", condition = "1203 v1 effective vs server", result = "EXPORTED/EXPECTED_REPRESENTATION_DIFF" },
    { id = "Q02", input = "quest", condition = "server quest not in effective DB", result = "ABSENT_FROM_EFFECTIVE_DB" },
    { id = "Q03", input = "quest", condition = "v1 export, quest unsupported (11142 duplicate)", result = "UNSUPPORTED_BY_SCHEMA_VERSION" },
    { id = "Q04", input = "quest", condition = "v1 export, kill-credit-first quest (10503)", result = "UNSUPPORTED_BY_SCHEMA_VERSION" },
    { id = "Q05", input = "quest", condition = "v2 export, M1-unsupported (25199 duplicates)", result = "EXPORTED/M1_UNSUPPORTED_BY_RULES" },
    { id = "Q06", input = "quest", condition = "server record malformed for one quest", result = "REJECTED_MALFORMED_INPUT" },
    { id = "Q07", input = "quest", condition = "no findings, KillCredit evidence unknown", result = "EXPORTED/NEEDS_MANUAL_REVIEW" },
    { id = "Q08", input = "quest", condition = "no findings, IP/conditions/scripts unknown", result = "EXPORTED/NEEDS_MANUAL_REVIEW" },
    { id = "Q09", input = "quest", condition = "no findings, all evidence complete", result = "EXPORTED/CONFIRMED_MATCH" },
    { id = "Q10", input = "quest", condition = "M1 finding, all evidence complete", result = "EXPORTED/CONFIRMED_MISMATCH" },
    { id = "Q11", input = "quest", condition = "v2, kill-credit-first order differs from server order", result = "EXPORTED/NEEDS_MANUAL_REVIEW" },
}
