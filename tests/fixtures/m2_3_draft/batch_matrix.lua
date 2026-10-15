-- SYNTHETIC executable M2.3 protocol matrix (DRAFT). Every case with
-- `run` is executed by tests/test_nquestie_m2_3_report_draft.lua through a
-- draft validator; `expect` is the required result. Cases marked
-- designAssertion = true describe engine behaviour that cannot be executed
-- without an engine (they are counted separately and NOT claimed as tests).
-- Synthetic manifest: 6 quests, complete. Public IDs are labels only.
local manifest = { complete = true, expectedCount = 6, quests = {
    [1203] = { status = "REPRESENTABLE", reasons = {} },
    [2001] = { status = "REPRESENTABLE", reasons = {} },
    [498] = { status = "REPRESENTABLE", reasons = {} },
    [11142] = { status = "UNSUPPORTED", reasons = { "DUPLICATE_OBJECT", "EXTRA_CREATURE_REF" } },
    [10503] = { status = "UNSUPPORTED", reasons = { "KILLCREDIT_FIRST_REORDER" } },
    [25199] = { status = "UNSUPPORTED", reasons = { "DUPLICATE_CREATURE" } },
} }
local function m(f) local c = { complete = manifest.complete, expectedCount = manifest.expectedCount, quests = {} }
    for k, v in pairs(manifest.quests) do c.quests[k] = v end; if f then f(c) end; return c end
return {
    manifest = manifest,
    cases = {
        -- selection protocol (PlanSelection)
        { id = "S01", run = "plan", server = { 1203 }, manifest = m(), export = { schemaVersion = 1, ids = { 1203 } },
          expect = { { 1203, "EXPORTED" } } },
        { id = "S02", run = "plan", server = { 1203 }, manifest = m(), export = { schemaVersion = 1, ids = { 2001 } },
          expect = "REJECTED_SELECTION_MISMATCH", note = "1203 representable but selected export holds only 2001: not ABSENT" },
        { id = "S03", run = "plan", server = { 1203, 999999 }, manifest = m(), export = { schemaVersion = 1, ids = { 1203 } },
          expect = { { 1203, "EXPORTED" }, { 999999, "ABSENT_FROM_EFFECTIVE_DB" } }, note = "absent from the complete manifest" },
        { id = "S04", run = "plan", server = { 999999 }, manifest = m(function(c) c.complete = false end), export = { schemaVersion = 1, ids = {} },
          expect = "REJECTED_MANIFEST_INCOMPLETE", note = "absence not provable" },
        { id = "S05", run = "plan", server = { 999999 }, manifest = m(function(c) c.quests[498] = nil end), export = { schemaVersion = 1, ids = {} },
          expect = "REJECTED_MANIFEST_INCOMPLETE", note = "manifest count below its pinned size" },
        { id = "S06", run = "plan", server = { 1203, 11142 }, manifest = m(), export = { schemaVersion = 1, ids = { 1203 } },
          expect = { { 1203, "EXPORTED" }, { 11142, "UNSUPPORTED_BY_SCHEMA_VERSION" } }, note = "mixed selection, preflight split" },
        { id = "S07", run = "plan", server = { 1203, 11142 }, manifest = m(), export = { schemaVersion = 1, ids = { 1203, 11142 } },
          expect = "REJECTED_MEMBERSHIP", note = "v1 export claims an unsupported quest" },
        { id = "S08", run = "plan", server = { 1203 }, manifest = m(), export = { schemaVersion = 1, ids = { 1203, 2001 } },
          expect = "REJECTED_SELECTION_MISMATCH", note = "export holds more than the preflight request" },
        { id = "S09", run = "plan", server = { 1203, 1203 }, manifest = m(), export = { schemaVersion = 1, ids = { 1203 } },
          expect = "REJECTED_DUPLICATE_ID" },
        { id = "S10", run = "plan", server = { 1203, 0 }, manifest = m(), export = { schemaVersion = 1, ids = { 1203 } },
          expect = "REJECTED_DUPLICATE_ID", note = "invalid ID" },
        { id = "S11", run = "plan", server = { 1203 }, manifest = m(), export = { schemaVersion = 1, ids = { 1203, 1203 } },
          expect = "REJECTED_DUPLICATE_ID", note = "duplicate in export" },
        { id = "S12", run = "plan", server = { 1203 }, manifest = m(), export = { schemaVersion = 3, ids = { 1203 } },
          expect = "REJECTED_MALFORMED_INPUT", note = "unknown export version" },
        { id = "S13", run = "plan", server = { 1203 }, manifest = m(), export = { schemaVersion = 1, ids = { 777 } },
          expect = "REJECTED_MEMBERSHIP", note = "exported quest not in manifest" },
        { id = "S14", run = "plan", server = { 11142, 25199 }, manifest = m(),
          export = { schemaVersion = 2, ids = { 1203, 2001, 498, 11142, 10503, 25199 } },
          expect = { { 11142, "EXPORTED" }, { 25199, "EXPORTED" } }, note = "v2 holds unsupported quests (m1Supported false)" },
        { id = "S15", run = "plan", server = { 11142 }, manifest = m(), export = { schemaVersion = 2, ids = { 11142 } },
          expect = "REJECTED_SELECTION_MISMATCH", note = "v2 export must be complete" },
        { id = "S16", run = "plan", server = { 1203 }, manifest = m(function(c) c.quests[11142] = { status = "UNSUPPORTED", reasons = { "quest-11142-private-label" } } end),
          export = { schemaVersion = 1, ids = { 1203 } }, expect = "REJECTED_MALFORMED_INPUT", note = "manifest reason outside vocabulary" },
        { id = "S17", run = "plan", server = { [1] = 1203, [3] = 2001 }, manifest = m(), export = { schemaVersion = 1, ids = { 1203 } },
          expect = "REJECTED_DUPLICATE_ID", note = "sparse server selection" },
        { id = "S18", run = "plan", server = { 11142, 10503 }, manifest = m(), export = { schemaVersion = 1, ids = {} },
          expect = "REJECTED_V1_SELECTION_EMPTY_AFTER_PREFLIGHT", note = "unsupported-only selection cannot use v1 (v1 needs questCount > 0)" },
        { id = "S19", run = "plan", server = { 999999 }, manifest = m(), export = { schemaVersion = 1, ids = {} },
          expect = "REJECTED_V1_SELECTION_EMPTY_AFTER_PREFLIGHT", note = "absent-only selection: nothing for v1 either" },
        { id = "S20", run = "plan", server = { 11142, 10503 }, manifest = m(),
          export = { schemaVersion = 2, ids = { 1203, 2001, 498, 11142, 10503, 25199 } },
          expect = { { 11142, "EXPORTED" }, { 10503, "EXPORTED" } }, note = "the same selection with a full v2 export" },
        -- preflight split (mixed selection protocol)
        { id = "P01", run = "split", server = { 11142, 1203, 999999, 2001, 10503 }, manifest = m(),
          expect = { v1Request = { 1203, 2001 }, unsupported = { 10503, 11142 }, absent = { 999999 } } },
        -- engine-only behaviour, not executable here
        { id = "D01", designAssertion = true, condition = "an input changes during the run (deep compare)", expect = "REJECTED_INPUT_CHANGED" },
        { id = "D02", designAssertion = true, condition = "real filesystem: output path unsafe or already exists (simulated publish tested separately)", expect = "REJECTED_UNSAFE_OUTPUT" },
        { id = "D03", designAssertion = true, condition = "M1 results inside M2.3 equal direct M1 calls", expect = "equal" },
    },
}
