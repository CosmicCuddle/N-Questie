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
print("PASS: frozen v1 exporter byte-identical to the base-commit golden (" .. #golden .. " bytes)")
