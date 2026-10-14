-- DRAFT acceptance checks for the v2 exporter SPEC (no exporter exists).
-- Validates the synthetic acceptance fixture against the draft v2 validator
-- and checks that the two fixtures together cover every acceptance category
-- in docs/NQ-VALIDATION-M2-V2-EXPORTER-SPEC.md section 9. Lua 5.1, no I/O
-- beyond reading fixtures.
local D = dofile("tools/validation/draft/EffectiveSchemaV2Draft.lua")
local OPT = { allowDraft = true }
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end
local function copy(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = copy(v) end return o end
local function has(errs, s) for _, e in ipairs(errs or {}) do if e:find(s, 1, true) then return true end end return false end
local A = dofile("tests/fixtures/m2_effective_v2_draft/v2_acceptance_synthetic.lua")
local C = dofile("tests/fixtures/m2_effective_v2_draft/v2_categories.lua")
local function q(d, id) for _, x in ipairs(d.quests) do if x.ID == id then return x end end end

local r, e = D.Validate(A, OPT)
ok(r, "acceptance fixture valid: " .. table.concat(e or {}, "; "))
for _, x in ipairs(A.quests) do ok(x.ID >= 900001 and x.ID <= 900999, "synthetic ID range " .. x.ID) end

-- Coverage of acceptance categories across both fixtures
local seen = {}
for _, doc in ipairs({ A, C }) do
    for _, x in ipairs(doc.quests) do
        if #x.objectives == 0 then seen.noObjectives = true end
        if x.killCreditFirst then seen.kcf = true end
        if #x.requiredSourceItems > 0 then seen.rsi = true end
        if x.sourceItemId > 0 then seen.sourceItem = true end
        if x.hasTriggerEnd then seen.trigger = true end
        local kinds, kc = {}, 0
        for _, o in ipairs(x.objectives) do
            kinds[o.kind] = true
            if (o.occurrence or 1) > 1 then seen.repeated = true end
            if o.kind == "reputation" and o.requiredValue == 0 then seen.repZero = true end
            if o.kind == "spell" and o.itemSourceId then seen.spellSource = true end
            if o.kind == "killCredit" then kc = kc + 1; if #o.ids > 1 then seen.kcMulti = true end end
        end
        if x.killCreditFirst and kc > 1 then seen.kcReversed = true end
        local nk = 0 for _ in pairs(kinds) do nk = nk + 1 end
        if nk == 6 then seen.allKinds = true end
        for _, ex in ipairs(x.extraObjectives) do
            if ex.objectiveIndex == 0 then seen.idx0 = true end
            if ex.objectiveIndex == #x.objectives and ex.objectiveIndex > 0 then seen.idxMax = true end
            if #ex.refs == 0 then seen.spawnOnly = true end
            for _, rf in ipairs(ex.refs) do seen["ref_" .. rf.type] = true end
        end
    end
end
for _, k in ipairs({ "noObjectives", "kcf", "kcReversed", "kcMulti", "rsi", "sourceItem", "trigger", "repeated",
    "repZero", "spellSource", "allKinds", "idx0", "idxMax", "spawnOnly", "ref_monster", "ref_object" }) do
    ok(seen[k], "acceptance category covered: " .. k)
end

-- Negative acceptance: the exporter must never produce these
local function mut(f) local d = copy(A); f(d); return D.Validate(d, OPT) end
r = mut(function(d) local o = q(d, 900003).objectives; o[1], o[3] = o[3], o[1]; o[1].position, o[3].position = 1, 3 end)
ok(not r, "kill-credit not reversed under killCreditFirst rejected")
r = mut(function(d) q(d, 900001).objectives[4].requiredValue = nil end)
ok(not r, "reputation zero dropped to nil rejected")
r = mut(function(d) q(d, 900001).extraObjectives[1].objectiveIndex = 7 end)
ok(not r, "objectiveIndex beyond objective count rejected")
r, e = mut(function(d) table.remove(d.quests, 5) end)
ok(not r and has(e, "questCount"), "silently dropped quest (questCount mismatch) rejected")
r = mut(function(d) q(d, 900001).objectives[6].text = "Cast it" end)
ok(not r, "display text in structural-only export rejected")
r = mut(function(d) d.schemaVersion = 3 end)
ok(not r, "unknown schema version rejected")

-- Reproducible equivalence despite run timestamps (lead review #44 point 3)
local a1, a2 = copy(A), copy(A)
a2.provenance.exportedAt = "2027-01-01T00:00:00Z"
ok(D.Canonical(a1, nil, OPT) ~= D.Canonical(a2, nil, OPT), "raw canonical forms differ when only exportedAt differs")
ok(D.Canonical(a1, { "exportedAt" }, OPT) == D.Canonical(a2, { "exportedAt" }, OPT), "exportedAt excluded explicitly: equal")
local a3 = copy(A); q(a3, 900002).questLevel = 13
ok(D.Canonical(a1, { "exportedAt" }, OPT) ~= D.Canonical(a3, { "exportedAt" }, OPT), "record difference still detected after exclusion")
local a4 = copy(A); a4.provenance.correctionCount = 27
ok(D.Canonical(a1, { "exportedAt" }, OPT) ~= D.Canonical(a4, { "exportedAt" }, OPT), "non-run provenance difference still detected")
ok(not pcall(D.Canonical, a1, { "correctionCount" }, OPT), "excluding a non-run field is refused")
ok(not pcall(D.Canonical, a1, { "exportedAt" }), "Canonical needs allowDraft")
local V1 = dofile("tools/validation/EffectiveSchema.lua")
local v1a = dofile("tests/fixtures/m2_effective/effective_selected_quests.lua")
local v1b = copy(v1a); v1b.provenance.exportedAt = "2030-05-05T05:05:05Z"
ok(V1.Validate(v1a) and V1.Validate(v1b), "v1 golden fixture valid with both timestamps (v1 unchanged)")
ok(D.Canonical(v1a, { "exportedAt" }, OPT) == D.Canonical(v1b, { "exportedAt" }, OPT), "v1 golden equivalence reproducible")
local rev = {} for k, v in pairs(copy(A)) do rev[k] = v end
ok(D.Canonical(rev, nil, OPT) == D.Canonical(a1, nil, OPT), "key insertion order does not change the output")

if fails > 0 then print(("FAIL: %d of %d checks failed"):format(fails, n)); os.exit(1) end
print(("PASS: M2 v2 exporter acceptance DRAFT (%d checks)"):format(n))
