-- Stage A1 M1 parity (decision t54u): the v2 classification ExpectedM1(record)
-- must equal the frozen v1 EffectiveExport.Record classification, status AND
-- reason set, over a systematic matrix of compiled-shaped synthetic quests:
-- every reason alone, every pair and triple of features, all features
-- together, and edge cases. v1 is called directly here (not through the
-- builder), so the two sides are independent. Synthetic data only. Lua 5.1.
local V1 = dofile("tools/validation/EffectiveExport.lua")
local V2 = dofile("tools/validation/EffectiveExportV2.lua")
local D = dofile("tools/validation/draft/EffectiveSchemaV2Draft.lua")
local OPT = { allowDraft = true }
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end

-- Features mutate a compiled-shaped quest; they compose.
local function slot(q, k) q.objectives = q.objectives or {}; q.objectives[k] = q.objectives[k] or {}; return q.objectives[k] end
local function extra(q, idx, refs, spawns) q.extraObjectives = q.extraObjectives or {}; q.extraObjectives[#q.extraObjectives + 1] = { spawns, 4, "x", idx or 0, refs } end
local F = {
    creature      = function(q) table.insert(slot(q, 1), { 101, "c" }) end,
    dupCreature   = function(q) local s = slot(q, 1); s[#s + 1] = { 102 }; s[#s + 1] = { 102 } end,
    object        = function(q) table.insert(slot(q, 2), { 201 }) end,
    dupObject     = function(q) local s = slot(q, 2); s[#s + 1] = { 202 }; s[#s + 1] = { 202, "o" } end,
    item          = function(q) table.insert(slot(q, 3), { 301 }) end,
    dupItem       = function(q) local s = slot(q, 3); s[#s + 1] = { 302 }; s[#s + 1] = { 302 } end,
    reputation    = function(q) slot(q, 4); q.objectives[4] = { 72, 3000 } end,
    reputationZero = function(q) slot(q, 4); q.objectives[4] = { 73, 0 } end,
    killCredit    = function(q) table.insert(slot(q, 5), { { 401, 402 }, 401, "k" }) end,
    killCredit2   = function(q) table.insert(slot(q, 5), { { 411 }, 411 }) end,
    dupKcId       = function(q) table.insert(slot(q, 5), { { 421, 422, 421 }, 421 }) end,
    sameRootTwice = function(q) local s = slot(q, 5); s[#s + 1] = { { 431 }, 430 }; s[#s + 1] = { { 432 }, 430 } end,
    spell         = function(q) table.insert(slot(q, 6), { 501, "s" }) end,
    dupSpell      = function(q) local s = slot(q, 6); s[#s + 1] = { 502 }; s[#s + 1] = { 502 } end,
    spellItemSrc  = function(q) table.insert(slot(q, 6), { 503, "s", 601 }) end,
    sourceItems   = function(q) q.sourceItemId = 701; q.requiredSourceItems = { 701, 702 } end,
    dupSourceItem = function(q) q.requiredSourceItems = { 711, 712, 711 } end,
    extraMonster  = function(q) extra(q, 0, { { "monster", 801 } }) end,
    extraObject   = function(q) extra(q, 0, { { "object", 802 } }) end,
    extraItem     = function(q) extra(q, 0, { { "item", 803 } }) end,
    dupExtraItemSameEntry = function(q) extra(q, 0, { { "item", 804 }, { "item", 804 } }) end,
    dupExtraItemAcross    = function(q) extra(q, 0, { { "item", 805 } }); extra(q, 0, { { "item", 805 } }) end,
    spawnOnlyExtra = function(q) extra(q, 0, nil, { [12] = { { 40.5, 60.1 } } }) end,
    dupExtraMonster = function(q) extra(q, 0, { { "monster", 806 }, { "monster", 806 } }) end,
    triggerEnd    = function(q) q.triggerEnd = { "Event", {} } end,
    emptySlots    = function(q) slot(q, 1); slot(q, 2); slot(q, 3) end,
    flagged       = function(q) q.__flag = true end,  -- in the killCreditFirst set
}
local NAMES = {}
for k in pairs(F) do NAMES[#NAMES + 1] = k end
table.sort(NAMES)

local nextId, quests, flag = 950000, {}, { [949999] = true }
local function make(list)
    nextId = nextId + 1
    local q = { requiredLevel = 10, questLevel = 12 }
    for _, f in ipairs(list) do F[f](q) end
    if q.__flag then flag[nextId] = true; q.__flag = nil end
    quests[nextId] = q
    return nextId
end
local Q = function(id, key) return quests[id] and quests[id][key] end
local CTX = { killCreditFirst = flag }

local stats = { cases = 0, supported = 0, unsupported = 0, refusedBoth = 0, codes = {} }
local function v1Class(id)
    local rec, _, codes = V1.Record(Q, id, CTX)
    if rec then return "SUPPORTED", {} end
    local u = V1.UniqueCodes(codes); table.sort(u)
    return "UNSUPPORTED_BY_RULES", u
end
local function check(list, label)
    local id = make(list)
    local st1, rs1 = v1Class(id)
    local rec, errs = V2.BuildRecord(Q, id, CTX)
    stats.cases = stats.cases + 1
    if not rec then
        ok(false, label .. ": v2 builder refused: " .. table.concat(errs or {}, "; "))
        return
    end
    local st2, rs2 = D.ExpectedM1(rec)
    local a, b = table.concat(rs1, "+"), table.concat(rs2, "+")
    ok(st1 == st2 and a == b, label .. ": v1 " .. st1 .. " [" .. a .. "] vs v2 ExpectedM1 " .. st2 .. " [" .. b .. "]")
    ok(rec.m1Status == st2 and table.concat(rec.m1Reasons, "+") == b, label .. ": record m1 equals ExpectedM1")
    ok(D.ValidateQuest(rec, OPT), label .. ": record valid")
    if st1 == "SUPPORTED" then stats.supported = stats.supported + 1 else stats.unsupported = stats.unsupported + 1 end
    for _, c in ipairs(rs1) do stats.codes[c] = (stats.codes[c] or 0) + 1 end
    return st1, rs1, rec
end
local function expect(list, st, reasons, label)
    local s, r, rec = check(list, label)
    ok(s == st and table.concat(r or {}, "+") == table.concat(reasons, "+"),
       label .. ": expected " .. st .. " [" .. table.concat(reasons, "+") .. "], got " .. tostring(s) .. " [" .. table.concat(r or {}, "+") .. "]")
    return rec
end

-- 1. Each reason alone, with the exact established code
expect({}, "SUPPORTED", {}, "empty quest")
expect({ "creature", "object", "item", "killCredit", "spell", "sourceItems", "extraItem", "triggerEnd", "emptySlots", "spawnOnlyExtra" }, "SUPPORTED", {}, "every representable feature")
expect({ "dupCreature" }, "UNSUPPORTED_BY_RULES", { "DUPLICATE_CREATURE" }, "repeated creature")
expect({ "dupObject" }, "UNSUPPORTED_BY_RULES", { "DUPLICATE_OBJECT" }, "repeated object")
expect({ "dupItem" }, "UNSUPPORTED_BY_RULES", { "DUPLICATE_ITEM" }, "repeated item")
expect({ "dupSpell" }, "UNSUPPORTED_BY_RULES", { "DUPLICATE_SPELL" }, "repeated spell")
expect({ "dupKcId" }, "UNSUPPORTED_BY_RULES", { "DUPLICATE_KILLCREDIT_ID" }, "killCredit entry repeating an id")
local r15 = expect({ "dupSourceItem" }, "UNSUPPORTED_BY_RULES", { "DUPLICATE_SOURCE_ITEM" }, "repeated requiredSourceItems")
ok(r15 and #r15.requiredSourceItems == 3, "repeated requiredSourceItems: every occurrence kept in v2 (no dedupe)")
expect({ "reputation" }, "UNSUPPORTED_BY_RULES", { "REPUTATION_OBJECTIVE" }, "reputation")
expect({ "reputationZero" }, "UNSUPPORTED_BY_RULES", { "REPUTATION_OBJECTIVE" }, "reputation value 0")
expect({ "spellItemSrc" }, "UNSUPPORTED_BY_RULES", { "SHAPE_UNUSUAL" }, "spell with itemSourceId")
expect({ "extraMonster" }, "UNSUPPORTED_BY_RULES", { "EXTRA_CREATURE_REF" }, "extra monster ref")
expect({ "dupExtraMonster" }, "UNSUPPORTED_BY_RULES", { "EXTRA_CREATURE_REF" }, "repeated extra monster ref (no duplicate code in v1)")
expect({ "extraObject" }, "UNSUPPORTED_BY_RULES", { "EXTRA_OBJECT_REF" }, "extra object ref")
expect({ "dupExtraItemSameEntry" }, "UNSUPPORTED_BY_RULES", { "DUPLICATE_EXTRA_ITEM" }, "extra item repeated in one entry")
expect({ "dupExtraItemAcross" }, "UNSUPPORTED_BY_RULES", { "DUPLICATE_EXTRA_ITEM" }, "extra item repeated across entries")
expect({ "sameRootTwice" }, "SUPPORTED", {}, "two killCredit entries sharing a rootId (not a v1 refusal)")
expect({ "killCredit", "killCredit2" }, "SUPPORTED", {}, "two killCredit entries, not flagged")

-- 2. killCreditFirst decision (t54u)
local k1 = expect({ "flagged", "killCredit" }, "SUPPORTED", {}, "flagged, one killCredit alone (nothing reorders)")
ok(k1 and k1.killCreditFirst == true, "flag kept in v2 when nothing reorders")
expect({ "flagged", "killCredit", "triggerEnd" }, "SUPPORTED", {}, "flagged, one killCredit and triggerEnd only")
expect({ "flagged", "killCredit", "extraMonster" }, "UNSUPPORTED_BY_RULES", { "EXTRA_CREATURE_REF" }, "flagged, one killCredit and an extra (extras are not objectives)")
for _, other in ipairs({ "creature", "object", "item", "spell", "reputation", "reputationZero" }) do
    local want = { "KILLCREDIT_FIRST_REORDER" }
    if other == "reputation" or other == "reputationZero" then want = { "KILLCREDIT_FIRST_REORDER", "REPUTATION_OBJECTIVE" } end
    local rec = expect({ "flagged", "killCredit", other }, "UNSUPPORTED_BY_RULES", want, "flagged, killCredit moved before " .. other)
    ok(rec and rec.objectives[1].kind == "killCredit", "flagged + " .. other .. ": killCredit first in the v2 order")
end
local k2 = expect({ "flagged", "killCredit", "killCredit2" }, "UNSUPPORTED_BY_RULES", { "KILLCREDIT_FIRST_REORDER" }, "flagged, two killCredit entries reversed")
ok(k2 and k2.objectives[1].rootId == 411 and k2.objectives[2].rootId == 401, "two killCredit entries reversed in v2")
expect({ "flagged", "creature" }, "SUPPORTED", {}, "flagged without killCredit (no effect)")
expect({ "flagged" }, "SUPPORTED", {}, "flagged, no objectives")

-- 3. Every pair and every triple of features, and all features together
local function combos(k)
    local out = {}
    local function rec(start, acc)
        if #acc == k then local c = {} for i, v in ipairs(acc) do c[i] = v end out[#out + 1] = c return end
        for i = start, #NAMES do acc[#acc + 1] = NAMES[i]; rec(i + 1, acc); acc[#acc] = nil end
    end
    rec(1, {})
    return out
end
-- Some pairs cannot coexist in one compiled slot 4 (one reputation pair per quest).
local function compatible(c)
    local rep = 0
    for _, f in ipairs(c) do if f == "reputation" or f == "reputationZero" then rep = rep + 1 end end
    return rep <= 1
end
local pairsN, triplesN = 0, 0
for _, c in ipairs(combos(2)) do if compatible(c) then check(c, "pair " .. table.concat(c, "+")); pairsN = pairsN + 1 end end
for _, c in ipairs(combos(3)) do if compatible(c) then check(c, "triple " .. table.concat(c, "+")); triplesN = triplesN + 1 end end
local all = {}
for _, f in ipairs(NAMES) do if f ~= "reputationZero" then all[#all + 1] = f end end
check(all, "all features")

-- 4. Every established v1 code reachable from a valid v2 record occurred
for _, c in ipairs({ "DUPLICATE_SOURCE_ITEM", "DUPLICATE_CREATURE", "DUPLICATE_OBJECT", "DUPLICATE_ITEM", "DUPLICATE_SPELL",
    "DUPLICATE_KILLCREDIT_ID", "REPUTATION_OBJECTIVE", "SHAPE_UNUSUAL", "EXTRA_CREATURE_REF", "EXTRA_OBJECT_REF",
    "DUPLICATE_EXTRA_ITEM", "KILLCREDIT_FIRST_REORDER" }) do
    ok((stats.codes[c] or 0) > 0, "code " .. c .. " exercised")
end
-- No code outside the established v1 set is ever produced.
local KNOWN = {}
for k in pairs(V1.REASONS or {}) do KNOWN[k] = true end
local unknown = 0
for c in pairs(stats.codes) do if next(KNOWN) and not KNOWN[c] then unknown = unknown + 1; print("unknown code " .. c) end end
ok(unknown == 0, "only established v1 codes produced")
-- Generic codes from the old draft are gone.
for c in pairs(stats.codes) do ok(not c:find("OTHER", 1, true), "no generic code " .. c) end

print(string.format("parity matrix: %d cases (%d pairs, %d triples), %d SUPPORTED, %d UNSUPPORTED",
    stats.cases, pairsN, triplesN, stats.supported, stats.unsupported))
if fails > 0 then print("FAIL: " .. fails .. " of " .. n .. " checks failed"); os.exit(1) end
print("PASS: M2 v2 M1 parity with frozen v1 (" .. n .. " checks)")
