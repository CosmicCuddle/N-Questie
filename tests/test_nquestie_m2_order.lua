-- M2.2 objective-order regression: QuestieCorrections.killCreditObjectiveFirst.
-- Questie maps quest-log line N to ObjectiveData[N] (QuestieQuest.lua,
-- PopulateQuestLogInfo). For quests in killCreditObjectiveFirst, QuestieDB
-- inserts each killCredit entry at position 1. v1 has per-kind lists only, so
-- such quests must be refused (KILLCREDIT_FIRST_REORDER), never exported with
-- the default order implied. Shapes mirror the public compiled records of
-- 10503 and 11652. Lua 5.1, no I/O.
local Export = dofile("tools/validation/EffectiveExport.lua")
local Coverage = dofile("tools/validation/Coverage.lua")
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end
local KC10503 = { { { 19998, 20334, 20723, 20726, 20730, 20731, 20732, 21296, 21975, 19995 }, 19995, "Bladespire Ogres killed" } }
local DB = {
    [10503] = { objectives = { { { 20728 } }, nil, nil, nil, KC10503 } },              -- creature + kc, flagged
    [11652] = { objectives = { { { 25465 } }, nil, nil, nil, {
        { { 27106, 27107, 27108, 27110 }, 27106, "a" }, { { 25332, 25333, 25469 }, 25333, "b" } } }, triggerEnd = { "x" } },
    [1] = { objectives = { nil, nil, nil, nil, { { { 5 }, 5 } } } },                   -- flagged, single kc only: no reorder
    [2] = { objectives = { nil, nil, nil, nil, { { { 5 }, 5 }, { { 6 }, 6 } } } },     -- flagged, two kc only: reversed
    [3] = { objectives = { { { 7 } }, nil, nil, nil, { { { 5 }, 5 } } } },             -- NOT flagged: default order
    [4] = { objectives = { nil, nil, { { 8 } }, nil, { { { 5 }, 5 } } } },             -- flagged, item + kc
    [5] = { objectives = { nil, nil, nil, { 93, 3000 }, { { { 5 }, 5 } } } },          -- flagged, reputation + kc
    [6] = { objectives = { { { 7 } } } },                                               -- flagged, no kc: nothing moves
}
local function query(id, key)
    local r = DB[id]
    if key == "requiredLevel" then return 1 elseif key == "questLevel" then return 2 end
    return r[key]
end
local ctx = { killCreditFirst = { [10503] = true, [11652] = true, [1] = true, [2] = true, [4] = true, [5] = true, [6] = true } }
local function codes(id, c)
    local rec, errs, cs = Export.Record(query, id, c == nil and ctx or c)
    if rec then return "" end
    local u = Export.UniqueCodes(cs); table.sort(u)
    return table.concat(u, "+"), errs
end
ok(codes(10503) == "KILLCREDIT_FIRST_REORDER", "10503 shape refused")
local c11652, e11652 = codes(11652)
ok(c11652 == "KILLCREDIT_FIRST_REORDER" and e11652[1]:find("2 killCredit entries reversed", 1, true), "11652 shape refused, reversal named")
ok(codes(1) == "", "single killCredit only: position unchanged, representable")
ok(codes(2) == "KILLCREDIT_FIRST_REORDER", "two killCredit only: order reversed, refused")
ok(codes(3) == "", "not flagged: default order, representable")
ok(codes(4) == "KILLCREDIT_FIRST_REORDER", "item + killCredit refused")
ok(codes(5) == "KILLCREDIT_FIRST_REORDER+REPUTATION_OBJECTIVE", "all reasons kept (reputation + order)")
ok(codes(6) == "", "flagged without killCredit: representable")
ok(codes(10503, { killCreditFirst = {} }) == "", "same shape not flagged: representable (flag is what matters)")
ok(Export.REASONS.KILLCREDIT_FIRST_REORDER ~= nil, "reason documented")
ok(Coverage.Category("KILLCREDIT_FIRST_REORDER") == "order", "coverage category 'order'")
-- export refuses and names the reason; coverage gives the same codes
local recs, errs, refused = Export.Snapshot(query, function(id) return DB[id] ~= nil end, { 3, 10503 }, ctx)
ok(recs == nil and refused[1].id == 10503 and refused[1].codes[1] == "KILLCREDIT_FIRST_REORDER", "snapshot refused, nothing returned")
ok(errs[#errs] == "quest 10503: refused, reasons: KILLCREDIT_FIRST_REORDER", "summary line")
local res = Coverage.Run(Export, query, { 10503, 11652, 1, 2, 3, 4, 5, 6 }, ctx)
local a = Coverage.Aggregate(res)
ok(a.representable == 3 and a.unsupported == 5 and a.reasonQuests.KILLCREDIT_FIRST_REORDER == 5, "coverage counts")
ok(a.categoryQuests.order == 5 and a.unclassified == 0, "order category, nothing unclassified")
for _, r in ipairs(res) do
    ok(table.concat(r.codes, "+") == codes(r.id), "coverage/export parity " .. r.id)
end
if fails > 0 then print("FAILED: M2.2 order (" .. fails .. " of " .. n .. ")") os.exit(1) end
print("PASS: M2.2 objective order / killCreditObjectiveFirst (" .. n .. " checks)")
