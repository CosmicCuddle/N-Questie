-- Stage A1: the frozen v1 exporter's output is byte-identical to the golden
-- file produced by the base commit's EffectiveExport.lua (780e89cbe) on the
-- same synthetic compiled-shaped input: accepted records serialised, and the
-- exact refusal messages for quests v1 cannot hold. Lua 5.1.
local V1 = dofile("tools/validation/EffectiveExport.lua")
local S = dofile("tests/fixtures/m2_v2_builder/compiled_synthetic.lua")
local Q = function(id, key) return S.quests[id] and S.quests[id][key] end
local exists = function(id) return S.quests[id] ~= nil end
local ctx = { killCreditFirst = S.killCreditFirst }
local function render()
    local out = {}
    local recs, errs = V1.Snapshot(Q, exists, { 910002, 910005, 910006, 910014 }, ctx)
    out[#out + 1] = recs and V1.Serialize(V1.BuildDocument(recs, { note = "synthetic" }), "v1 frozen check") or ("ERR " .. table.concat(errs, "\n"))
    for _, id in ipairs({ 910001, 910003, 910004, 910007, 910008, 910009, 910010, 910011, 910012, 910013, 910015 }) do
        local r, e = V1.Snapshot(Q, exists, { id }, ctx)
        out[#out + 1] = r and ("ACCEPTED " .. id .. "\n" .. V1.Serialize(r)) or ("REFUSED " .. id .. "\n" .. table.concat(e, "\n") .. "\n")
    end
    return table.concat(out)
end
if arg and arg[1] == "--write-golden" then io.write(render()); os.exit(0) end
local f = assert(io.open("tests/fixtures/m2_v2_builder/v1_golden.txt", "rb"))
local golden = f:read("*a"); f:close()
local now = render()
if now ~= golden then print("FAIL: v1 exporter output differs from the base-commit golden file"); os.exit(1) end
-- Stage A2: the frozen v1 sources and the shared v1-era helpers are
-- byte-identical to integration base 780e89cbe (sha256 of the blobs there).
local PINS = {
    ["tools/validation/EffectiveExport.lua"] = "849ddb20648d545990f404fb2c6caa61c06274b9d66c804eb2008413ac01c489",
    ["tools/validation/EffectiveSchema.lua"] = "bcac0e53d9b0286dfe89714b67bf186143333dac3c7235a28dab5717ccb06696",
    ["tools/validation/InputSchema.lua"] = "ae7eab552152f9de58309cf5b8677e52141b172c08a56db2128c66c1fd822ce4",
    ["tools/validation/SafeWrite.lua"] = "7e9630ebccc132e4dec8e03c15b7c0929bbc1629667da47c7ea8cd7f4783be0e",
    ["tools/validation/ExportProvenance.lua"] = "79c1209a3fc4bafd0a029853ee87a55de298eedb508b48e2736bc75c1dd6a0ba",
    ["tools/validation/Coverage.lua"] = "6010f6b37c9f74b97ee19c08144feab1cb99b3dae3d1d7091ca9673de2c6d7c3",
}
local names = {}
for k in pairs(PINS) do names[#names + 1] = k end
table.sort(names)
for _, file in ipairs(names) do
    local h = io.popen("sha256sum -- '" .. file .. "' 2>/dev/null")
    local got = h and h:read("*a"):match("^(%x+)") or nil
    if h then h:close() end
    if got ~= PINS[file] then print("FAIL: " .. file .. " differs from the frozen base (sha256)"); os.exit(1) end
end
print("PASS: frozen v1 exporter byte-identical to the base-commit golden (" .. #golden .. " bytes); " .. #names .. " v1 sources pinned")
