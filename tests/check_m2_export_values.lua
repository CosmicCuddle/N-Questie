#!/usr/bin/env lua5.1
-- Asserts the values of a real effective export of quests
-- 1203,2001,2784,30,25,28,498,532,553,786 (public compiled 3.3.5a Questie DB,
-- read 2026-10-14). Also validates the schema, provenance and M1 shape.
-- Parsing and schema validity are not semantic correctness: these expected
-- values are what make the check meaningful.
local E = dofile("tools/validation/EffectiveSchema.lua")
local Rules = dofile("tools/validation/ObjectiveRules.lua")
local path = assert(arg[1], "usage: check_m2_export_values.lua /abs/export.lua")
local root = io.popen("pwd -P"):read("*l")
local doc, errs = E.LoadFile(path, root, { expectKind = "effective", expectCorrectionCount = 28 })
if not doc then io.stderr:write(table.concat(errs, "\n") .. "\n") os.exit(1) end
local fails = 0
local function check(c, m) if not c then fails = fails + 1; io.stderr:write("FAIL: " .. m .. "\n") end end
local function j(t) local o = {} for _, v in ipairs(t) do o[#o + 1] = type(v) == "table" and ("{" .. j(v.ids) .. "|" .. v.rootId .. "}") or tostring(v) end return table.concat(o, ",") end
local expect = {
    [1203] = "30 35 c= o= i=3853 kc= sp= src=0 rsi= te=false ex=false exi=",
    [2001] = "12 16 c=1868,1869 o= i= kc= sp= src=0 rsi= te=false ex=false exi=",
    [2784] = "45 50 c= o= i= kc={7572|7572} sp= src=0 rsi= te=false ex=false exi=",
    [30]   = "16 -1 c= o= i=15885 kc= sp= src=0 rsi=15883,15882 te=false ex=true exi=",
    [25]   = "23 25 c=3917 o= i= kc= sp= src=0 rsi= te=true ex=false exi=",
    [28]   = "16 -1 c= o= i= kc= sp= src=0 rsi=15877 te=true ex=false exi=",
    [498]  = "17 22 c= o=1721,1722 i= kc= sp= src=0 rsi=3467,3499 te=false ex=false exi=",
    [532]  = "19 26 c=2335,2387 o=1761 i=3657 kc= sp= src=0 rsi= te=false ex=false exi=",
    [553]  = "29 33 c= o=1768,1769,1770 i= kc= sp= src=3710 rsi= te=false ex=false exi=",
    [786]  = "5 8 c= o=3189,3190,3192 i= kc= sp= src=0 rsi= te=false ex=false exi=",
}
local order = { 1203, 2001, 2784, 30, 25, 28, 498, 532, 553, 786 }
check(#doc.quests == #order, "record count")
for i, r in ipairs(doc.quests) do
    local o = r.objectives
    local got = string.format("%d %d c=%s o=%s i=%s kc=%s sp=%s src=%d rsi=%s te=%s ex=%s exi=%s", r.requiredLevel, r.questLevel,
        j(o.creatures), j(o.objects), j(o.items), j(o.killCredit), j(o.spells), r.sourceItemId, j(r.requiredSourceItems),
        tostring(r.hasTriggerEnd), tostring(r.hasExtraObjectives), j(r.extraObjectiveItems))
    check(r.ID == order[i], "order at " .. i)
    check(got == expect[r.ID], "quest " .. r.ID .. ": got '" .. got .. "'")
end
local p = doc.provenance
check(p.harnessVersion == "1.2.0", "harnessVersion 1.2.0 (kill-credit ordering protection)")
check(p.harness == "validate-335", "harness validate-335")
check(p.m0Checks == 232, "m0Checks 232")
check(p.correctionCount == 28, "correctionCount 28")
check(p.nQuestieDataRevision >= 1, "revision")
check(p.sourceDirty == false and p.tocInterface == 30300, "clean, 30300")
local head = io.popen("git rev-parse HEAD"):read("*l")
check(p.sourceCommit == head, "sourceCommit equals HEAD")
local server = Rules.FromQuestTemplateRow({ ID = 1203, RequiredItemId1 = 3853, RequiredItemCount1 = 1 })
check(Rules.Worst(Rules.Compare(server, E.ToQuestieRecord(doc.quests[1]))) == "EXPECTED_REPRESENTATION_DIFF",
      "M1 on exported 1203: EXPECTED_REPRESENTATION_DIFF")
if fails > 0 then os.exit(1) end
print("PASS: export values, provenance and M1 shape")
