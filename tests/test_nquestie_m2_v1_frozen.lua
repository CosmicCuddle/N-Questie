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
-- Current Stage A2 compatibility candidate: use only the frozen base, not
-- a moving Grok development branch. This ensures these pins are tested
-- together on the same exact candidate tree, without future in-flight edits.
-- The v1 exporter, schema and Coverage implementation remain BYTE-IDENTICAL
-- to the six-green integration baseline. Their original SHA-256 pins NEVER
-- change to accommodate the independent safety fixes in this test-only stack.
--
-- Shared InputSchema, SafeWrite and ExportProvenance are intentionally hardened
-- by PRs #52/#53/#54. Requiring their original hashes would contradict the
-- explicitly scoped safety fixes; pin the exact REVIEWED replacement Git blob
-- objects separately, without pretending those helpers were left untouched.
local FROZEN_V1_SHA256 = {
    ["tools/validation/EffectiveExport.lua"] = "849ddb20648d545990f404fb2c6caa61c06274b9d66c804eb2008413ac01c489",
    ["tools/validation/EffectiveSchema.lua"] = "bcac0e53d9b0286dfe89714b67bf186143333dac3c7235a28dab5717ccb06696",
    ["tools/validation/Coverage.lua"] = "6010f6b37c9f74b97ee19c08144feab1cb99b3dae3d1d7091ca9673de2c6d7c3",
}
local APPROVED_SHARED_BLOBS = {
    -- Exact Git blob identities on independent six-green safety PR heads.
    ["tools/validation/InputSchema.lua"] = "af1a212fa68f0a6c073e27faa6b56ee3ff3db9ee", -- #52
    ["tools/validation/SafeWrite.lua"] = "71b61777c61d044caea496013c11f1077fe451d5", -- #53
    ["tools/validation/ExportProvenance.lua"] = "71ba299cc06b6c9083b952fcb36beb65a0f779f5", -- #54
}
local function sortedKeys(t)
    local names = {}
    for k in pairs(t) do names[#names + 1] = k end
    table.sort(names)
    return names
end
local function capturedHash(cmd)
    local h = io.popen(cmd .. " 2>/dev/null")
    if not h then return nil end
    local out = h:read("*a")
    h:close()
    -- sha256sum appends the filename; git hash-object prints just a digest.
    -- Both tools print the digest first, separated by whitespace.
    return out and out:match("^(%x+)%s")
end
for _, file in ipairs(sortedKeys(FROZEN_V1_SHA256)) do
    local got = capturedHash("sha256sum -- '" .. file .. "'")
    if got ~= FROZEN_V1_SHA256[file] then
        print("FAIL: frozen v1 module changed from the original baseline: " .. file)
        os.exit(1)
    end
end
for _, file in ipairs(sortedKeys(APPROVED_SHARED_BLOBS)) do
    local got = capturedHash("git hash-object -- '" .. file .. "'")
    if got ~= APPROVED_SHARED_BLOBS[file] then
        print("FAIL: hardened shared helper differs from its independently tested blob: " .. file)
        os.exit(1)
    end
end
print("PASS: frozen v1 golden (" .. #golden .. " bytes), " ..
    #sortedKeys(FROZEN_V1_SHA256) .. " original-module pins and " ..
    #sortedKeys(APPROVED_SHARED_BLOBS) .. " separately approved safety-helper blob pins")
