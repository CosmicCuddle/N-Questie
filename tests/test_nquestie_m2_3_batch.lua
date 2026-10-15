-- M2.3 Part 2 PUBLIC/SYNTHETIC test; no server access, no private input.
-- The 9,159-row fixture is generated entirely in memory with invented records.
local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
local V1 = dofile("tools/validation/EffectiveSchema.lua")
local M1 = dofile("tools/validation/ObjectiveRules.lua")
local Adapter = dofile("tools/validation/M23QuestieAdapter.lua")
local Membership = dofile("tools/validation/M23Membership.lua")
local Batch = dofile("tools/validation/M23Batch.lua")
local c, fails = 0, 0
local function check(v, label)
    c = c + 1
    if not v then fails = fails + 1; print("FAIL: " .. label) end
end
local function clone(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = clone(v) end
    return out
end

local function makeData(n, unsupported)
    local prov = {
        harness = "validate-335", harnessVersion = "1.3.0",
        dataKind = "effective",
        sourceCommit = string.rep("a", 40), sourceTree = string.rep("b", 40),
        sourceDirty = false, tocInterface = 30300, flavour = "wotlk-335",
        nQuestieDataRevision = 5, correctionCount = 28,
        correctionFingerprint = "sha256:" .. string.rep("c", 64),
        correctionModules = { "NQuestieExistingQuestCorrections.lua" },
        m0Checks = 232, exportedAt = "2026-10-15T18:00:00Z",
        questCount = n,
    }
    local effective = { schema = "nq-m2-effective", schemaVersion = 2,
        displayScope = "structural-only", provenance = prov, quests = {} }
    local manifest = { kind = "nq-m2-coverage-manifest", version = 1,
        note = "Coverage report, not an export. Contains no effective records.",
        provenance = clone(prov), quests = {},
        aggregate = { kind = "nq-m2-coverage-aggregate", version = 1,
            total = n, representable = n - unsupported,
            unsupported = unsupported, reconciled = true,
            reasonQuests = unsupported > 0 and { REPUTATION_OBJECTIVE = unsupported } or {} } }
    for id = 1, n do
        local bad = id <= unsupported
        local objectives = bad and {
            { position = 1, kind = "reputation", slotIndex = 1, factionId = 72, requiredValue = 0 }
        } or {}
        local q = { ID = id, requiredLevel = 1, questLevel = 3,
            sourceItemId = 0, requiredSourceItems = {}, objectives = objectives,
            killCreditFirst = false, hasTriggerEnd = false, extraObjectives = {},
            m1Status = bad and "UNSUPPORTED_BY_RULES" or "SUPPORTED",
            m1Reasons = bad and { "REPUTATION_OBJECTIVE" } or {} }
        effective.quests[id] = q
        manifest.quests[id] = { ID = id, status = bad and "UNSUPPORTED" or "REPRESENTABLE",
            reasons = bad and { "REPUTATION_OBJECTIVE" } or {} }
    end
    return effective, manifest, { questCount = n,
        supportedCount = n - unsupported, unsupportedCount = unsupported }
end

local function serverRow(id, requiredItem, amount)
    local r = { ID = id, StartItem = 0, KillCredit = {},
        killCreditComplete = true, hasConditions = false, scriptedCredit = false,
        ipGated = false }
    for i = 1, 4 do
        r["RequiredNpcOrGo" .. i] = 0
        r["RequiredNpcOrGoCount" .. i] = 0
        r["ItemDrop" .. i] = 0
    end
    for i = 1, 6 do
        r["RequiredItemId" .. i] = i == 1 and (requiredItem or 0) or 0
        r["RequiredItemCount" .. i] = i == 1 and (amount or 0) or 0
    end
    return r
end
local serverProv = {
    exporter = "nquestie-private-objectives", exporterVersion = "3.0.0",
    sourceLabel = "synthetic-only", sourceFingerprint = "sha256:" .. string.rep("d", 64),
    exportedAt = "2026-10-15T18:00:00Z", selection = "explicit", questCount = 1
}
local function serverDoc(row)
    return { schema = "nq-m2-input", schemaVersion = 1,
        provenance = clone(serverProv), quests = { clone(row) } }
end

check(Membership.IdBytes({ 2, 10 }) == "2\n10\n", "canonical decimal LF, final LF")
check(Membership.IdBytes({ 10, 2 }) == nil, "refuse unsorted ID list")
check(Membership.IdBytes({ 2, 2 }) == nil, "refuse duplicate ID list")
check(Membership.IdBytes({}) == nil, "refuse empty ID list")
check(Membership.IdBytes({ [1] = 2, [3] = 3 }) == nil, "refuse sparse ID list")
local e, m, pins = makeData(3, 1)
check(V2.Validate(e), "synthetic v2 valid")
local idx, err = Membership.Check(e, m, pins)
check(idx ~= nil and err == nil, "valid paired synthetic manifest")
check(idx and idx.idBytes == "1\n2\n3\n", "membership emits canonical IDs")
check(idx and idx.supported == 2 and idx.unsupported == 1, "membership exact counts")
check(idx and idx.byId[3] == e.quests[3], "membership records are indexed")
local a = clone(m); a.quests[3].status = "UNSUPPORTED"
check(Membership.Check(e, a, pins) == nil, "mismatched support refused")
a = clone(m); a.quests[1].reasons = { "REPUTATION_OBJECTIVE", "REPUTATION_OBJECTIVE" }
local _, code = Membership.Check(e, a, pins)
check(code == "REJECTED_MALFORMED_INPUT", "duplicate reasons refused before status comparison")
a = clone(m); a.quests[1].reasons = { "REPUTATION_OBJECTIVE", "EXTRA_CREATURE_REF" }
_, code = Membership.Check(e, a, pins)
check(code == "REJECTED_MALFORMED_INPUT", "reordered reason list refused")
a = clone(m); a.quests[1].reasons = { "UNKNOWN_REASON" }
_, code = Membership.Check(e, a, pins)
check(code == "REJECTED_MALFORMED_INPUT", "unknown reason refused")
a = clone(m); a.quests[2].ID = 999
check(Membership.Check(e, a, pins) == nil, "manifest membership substitution refused")
a = clone(m); a.provenance.sourceCommit = string.rep("d", 40)
_, code = Membership.Check(e, a, pins)
check(code == "REJECTED_PAIRING", "paired provenance must match")
a = clone(m); a.aggregate.representable = 1
_, code = Membership.Check(e, a, pins)
check(code == "REJECTED_MANIFEST_INCOMPLETE", "invalid aggregate pins refused")
a = clone(m); a.aggregate.reasonQuests = { REPUTATION_OBJECTIVE = 2 }
_, code = Membership.Check(e, a, pins)
check(code == "REJECTED_MANIFEST_INCOMPLETE", "reasonQuests must reconcile")
check(Membership.Check(e, m, {questCount=3,supportedCount=3,unsupportedCount=0}) == nil,
    "untrusted mismatched counts refused")
a = clone(m); a.quests[2].status = "UNEXPECTED"
_, code = Membership.Check(e, a, pins)
check(code == "REJECTED_MALFORMED_INPUT", "unknown coverage status refused")
a = clone(e); a.quests[2].ID = 5
check(Membership.Check(a, m, pins) == nil, "invalid effective membership refused")

local emptyQ = clone(e.quests[3])
local projected, pErr = Adapter.ToQuestieRecordV2(emptyQ)
check(projected ~= nil and pErr == nil, "supported empty objective adapter")
check(projected and #projected[10][3] == 0, "supported empty items retained")
check(Adapter.ToQuestieRecordV2(e.quests[1]) == nil, "unsupported never projected")
local itemQ = clone(emptyQ)
itemQ.objectives = { {position=1,kind="item",slotIndex=1,id=50002,occurrence=1} }
projected = Adapter.ToQuestieRecordV2(itemQ)
check(projected and projected[10][3][1][1] == 50002, "item objective slot retained")
local secondItem = clone(itemQ)
secondItem.objectives[2] = { position=2,kind="item",slotIndex=2,id=50002,occurrence=2 }
secondItem.m1Status = "UNSUPPORTED_BY_RULES"
secondItem.m1Reasons = { "DUPLICATE_ITEM" }
check(Adapter.ToQuestieRecordV2(secondItem) == nil, "duplicate item is unsupported, no lossy projection")
local credit = clone(emptyQ)
credit.objectives = { {position=1,kind="killCredit",slotIndex=1,ids={40001,40002},rootId=40001} }
credit.killCreditFirst = true
projected = Adapter.ToQuestieRecordV2(credit)
check(projected and #projected[10][5] == 1 and projected[10][5][1][1][2] == 40002,
    "KillCredit IDs and slot retained")
check(projected and projected[10][5][1][2] == 40001, "KillCredit root retained")
local mutatedCredit = clone(credit)
mutatedCredit.objectives[1].ids[1] = 90009
check(projected[10][5][1][1][1] == 40001, "adapter never aliases input ids")
local extra = clone(emptyQ)
extra.extraObjectives = {{ position=1, icon=3, hasText=true, spawnZones={},
    objectiveIndex=0, refs={{type="item", id=72001, refIndex=1}} }}
projected = Adapter.ToQuestieRecordV2(extra)
check(projected and projected[27][1][5][1][2] == 72001, "extra source item retained")
local src = clone(emptyQ)
src.sourceItemId = 55; src.requiredSourceItems = { 56, 57 }; src.hasTriggerEnd = true
projected = Adapter.ToQuestieRecordV2(src)
check(projected and projected[11] == 55 and #projected[21] == 2 and projected[9] ~= nil,
    "source item / required source / trigger retained")
local gap = clone(itemQ); gap.objectives[1].slotIndex = 2
check(Adapter.ToQuestieRecordV2(gap) == nil, "sparse slot fails closed")

local legacy = { ID=3, requiredLevel=1, questLevel=3, sourceItemId=0,
    requiredSourceItems={}, hasTriggerEnd=false, hasExtraObjectives=false, extraObjectiveItems={},
    objectives={creatures={},objects={},items={50002},killCredit={},spells={}} }
local legacyM1 = V1.ToQuestieRecord(legacy)
projected = Adapter.ToQuestieRecordV2(itemQ)
local normal = M1.FromQuestTemplateRow(serverRow(3,50001,1))
local left, right = M1.Compare(normal,legacyM1), M1.Compare(normal,projected)
check(#left == #right, "v2 projection and frozen v1 produce same number M1 findings")
local equal = #left == #right
for i=1,#left do
    local l, r = left[i], right[i]
    if not r or l.class ~= r.class or l.kind ~= r.kind
        or table.concat(l.rules,",") ~= table.concat(r.rules,",")
        or l.explanation ~= r.explanation then equal = false end
end
check(equal, "v2 adapter = v1 adapter M1 finding class/rules/text parity")

local plain = serverDoc(serverRow(3))
local results = Batch.Run(plain,e,m,pins)
check(results ~= nil and results.rows[1].outcome == "NEEDS_MANUAL_REVIEW",
    "zero differences on v1 do not become CONFIRMED_MATCH")
check(results and results.rows[1].evidence.objectiveData == "unknown",
    "objectiveData always unknown with frozen v1")
check(results and results.rows[1].evidence.ip == "unknown",
    "explicit ip=false does not grant verified evidence")
check(results and results.authenticated == false and results.publishable == false,
    "pure result never reports authenticated or publishable")
local flagUnknown = serverDoc(serverRow(3))
flagUnknown.quests[1].ipGated = nil
results, code = Batch.Run(flagUnknown,e,m,pins)
check(results == nil and code == "REJECTED_MALFORMED_INPUT",
    "frozen M2.1 rejects a missing tri-state instead of implying false")
flagUnknown.quests[1].ipGated = "unknown"
results = Batch.Run(flagUnknown,e,m,pins)
check(results and results.rows[1].outcome == "NEEDS_MANUAL_REVIEW",
    "explicit unknown tri-state never implies false")
local unsupported = Batch.Run(serverDoc(serverRow(1)),e,m,pins)
check(unsupported and unsupported.rows[1].outcome == "M1_UNSUPPORTED_BY_RULES",
    "unsupported quest never run through M1")
check(unsupported and #unsupported.rows[1].m1Classes == 0,
    "unsupported has no M1 findings")
local mismatchE = clone(e)
mismatchE.quests[3] = clone(itemQ)
results = Batch.Run(serverDoc(serverRow(3,50001,1)),mismatchE,m,pins)
check(results and results.rows[1].outcome == "NEEDS_MANUAL_REVIEW",
    "M1 target disagreement is not a confirmed mismatch")
local hasClass = false
if results then
    for _, cl in ipairs(results.rows[1].m1Classes) do
        if cl == "CONFIRMED_MISMATCH" then hasClass = true end
    end
end
check(hasClass, "underlying M1 mismatch still preserved for future private review")
check(mismatchE.quests[3].objectives[1].id == 50002,
    "comparison never modifies effective input")
local expectedE = clone(e)
expectedE.quests[3] = clone(itemQ)
results = Batch.Run(serverDoc(serverRow(3,50002,1)),expectedE,m,pins)
check(results and results.rows[1].outcome == "EXPECTED_REPRESENTATION_DIFF",
    "M1's quantity representation difference is preserved")
local missing = Batch.Run(serverDoc(serverRow(900001)),e,m,pins)
check(missing == nil, "server ID not in full export rejects selection")
local malformed = serverDoc(serverRow(3)); malformed.quests[1].RequiredItemId1 = "invalid"
check(Batch.Run(malformed,e,m,pins) == nil, "invalid server document rejects batch")

-- Full public-shaped synthetic identity check: 9,159 invented IDs, of which
-- exactly 8,401 are supported and 758 are unsupported. No private database.
local fe, fm, fp = makeData(9159, 758)
local full, fullErr = Membership.Check(fe,fm,fp)
check(full ~= nil and fullErr == nil, "full 9159 / 8401 / 758 synthetic membership passes")
check(full and full.total == 9159 and full.supported == 8401
    and full.unsupported == 758, "full synthetic counts exact")
check(full and full.byId[2001] ~= nil, "custom-ID-shaped 2001 included in full synthetic set")
local changed = clone(fm)
changed.quests[700].status = "REPRESENTABLE"; changed.quests[700].reasons = {}
_, code = Membership.Check(fe,changed,fp)
check(code == "REJECTED_M1_STATUS_MISMATCH",
    "flip of UNSELECTED quest is caught across all 9159")
local fullRow = serverDoc(serverRow(2001))
local fullResult = Batch.Run(fullRow,fe,fm,fp)
check(fullResult and fullResult.rows[1].outcome == "NEEDS_MANUAL_REVIEW",
    "full synthetic batch never confirms with v1 evidence")
check(fullResult and #fullResult.allQuestIdsCanonicalBytes > 40000,
    "canonical all-9159 ID bytes returned for LATER trusted hashing")

if fails > 0 then
    print(string.format("FAIL: M2.3 Part 2 %d/%d",fails,c))
    os.exit(1)
end
print(string.format("PASS: M2.3 Part 2 (%d public/synthetic assertions; 9159 generated IDs)",c))
