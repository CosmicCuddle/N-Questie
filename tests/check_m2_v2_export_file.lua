-- Stage A2 helper for tests/test_nquestie_m2_v2_export_integration.sh.
-- Reads written v2 files (read-only) and prints facts for the shell test.
--   ids FILE            sorted quest IDs, one per line (for the sha256 pin)
--   counts FILE         key=value counts from the records themselves
--   coverage FILE MAN   per-quest status/reasons equal the coverage manifest
--   canon A B           provenance fields that differ, and whether the two
--                       documents are equal after Canonical(doc, {exportedAt})
--   tamper IN OUT       copy IN to OUT (new file in a private temp dir) with
--                       one creature id changed, for the verify-mode negative
-- Lua 5.1.
local X = dofile("tools/validation/ExportV2.lua")
local Schema = dofile("tools/validation/EffectiveSchemaV2.lua")
local Input = dofile("tools/validation/InputSchema.lua")
local function read(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end
local function load(p) local d, e = X.ParseAndValidate(read(p)); if not d then io.stderr:write(table.concat(e, "\n") .. "\n"); os.exit(2) end return d end
local mode = arg[1]
if mode == "ids" then
    local d = load(arg[2])
    for _, q in ipairs(d.quests) do io.write(q.ID, "\n") end
elseif mode == "counts" then
    local d = load(arg[2])
    local c = { quests = #d.quests, supported = 0, unsupported = 0, refs = 0, monster = 0, object = 0, item = 0,
        reputation = 0, reputationZero = 0, killCreditFirst = 0, duplicates = 0, extraEntries = 0, spawnOnly = 0,
        idx0 = 0, idxPast = 0, sorted = 1, questCount = d.provenance.questCount }
    local reasons = {}
    local prev = 0
    for _, q in ipairs(d.quests) do
        if q.ID <= prev then c.sorted = 0 end
        prev = q.ID
        if q.m1Status == "SUPPORTED" then c.supported = c.supported + 1 else c.unsupported = c.unsupported + 1 end
        for _, r in ipairs(q.m1Reasons) do reasons[r] = (reasons[r] or 0) + 1 end
        if q.killCreditFirst then c.killCreditFirst = c.killCreditFirst + 1 end
        for _, o in ipairs(q.objectives) do
            if o.kind == "reputation" then
                c.reputation = c.reputation + 1
                if o.requiredValue == 0 then c.reputationZero = c.reputationZero + 1 end
            end
            if (o.occurrence or 1) > 1 then c.duplicates = c.duplicates + 1 end
        end
        for _, e in ipairs(q.extraObjectives) do
            c.extraEntries = c.extraEntries + 1
            if #e.refs == 0 then c.spawnOnly = c.spawnOnly + 1 end
            if e.objectiveIndex == 0 then c.idx0 = c.idx0 + 1 end
            if e.objectiveIndex > #q.objectives then c.idxPast = c.idxPast + 1 end
            for _, r in ipairs(e.refs) do c.refs = c.refs + 1; c[r.type] = c[r.type] + 1 end
        end
    end
    local keys = {}
    for k in pairs(c) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do io.write(k, "=", c[k], "\n") end
    local rk = {}
    for k in pairs(reasons) do rk[#rk + 1] = k end
    table.sort(rk)
    for _, k in ipairs(rk) do io.write("reason.", k, "=", reasons[k], "\n") end
elseif mode == "coverage" then
    local d = load(arg[2])
    local m = assert(Input.ParseString(read(arg[3])), "manifest parse")
    local by = {}
    for _, q in ipairs(m.quests) do
        local r = {}
        for i, x in ipairs(q.reasons) do r[i] = x end
        table.sort(r)
        by[q.ID] = (q.status == "REPRESENTABLE" and "SUPPORTED" or "UNSUPPORTED_BY_RULES") .. ":" .. table.concat(r, "+")
    end
    local diff, n = 0, 0
    for _, q in ipairs(d.quests) do
        n = n + 1
        if by[q.ID] ~= q.m1Status .. ":" .. table.concat(q.m1Reasons, "+") then diff = diff + 1 end
        by[q.ID] = nil
    end
    local left = 0
    for _ in pairs(by) do left = left + 1 end
    io.write("compared=", n, "\ndiffering=", diff, "\nmanifestOnly=", left, "\n")
elseif mode == "canon" then
    local a, b = load(arg[2]), load(arg[3])
    local fields = {}
    for k, v in pairs(a.provenance) do
        if Schema.Canonical({ v }, {}) ~= Schema.Canonical({ b.provenance[k] }, {}) then fields[#fields + 1] = k end
    end
    for k in pairs(b.provenance) do if a.provenance[k] == nil then fields[#fields + 1] = k end end
    table.sort(fields)
    io.write("provenanceDiffering=", table.concat(fields, ","), "\n")
    io.write("canonicalEqualExcludingExportedAt=", tostring(Schema.Canonical(a, { "exportedAt" }) == Schema.Canonical(b, { "exportedAt" })), "\n")
    io.write("canonicalEqualIncludingAll=", tostring(Schema.Canonical(a, {}) == Schema.Canonical(b, {})), "\n")
elseif mode == "tamper" then
    local s = read(arg[2])
    local t, k = s:gsub('kind="creature",slotIndex=1,id=(%d+),', function(id) return 'kind="creature",slotIndex=1,id=' .. (tonumber(id) + 1) .. ',' end, 1)
    assert(k == 1)
    local f = assert(io.open(arg[3], "wb")); f:write(t); f:close()
else
    io.stderr:write("usage: ids|counts|coverage|canon|tamper\n"); os.exit(2)
end
