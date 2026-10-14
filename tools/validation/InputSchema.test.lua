-- busted spec for the M2.1 input schema (synthetic fixtures only).
-- Picked up by the existing M1 workflow: busted -p ".test.lua" tools/validation
describe("N-Questie M2.1 input schema", function()
    local Schema = dofile("tools/validation/InputSchema.lua")
    local cases = dofile("tools/validation/fixtures/input_cases.lua")
    local parseCases = dofile("tools/validation/fixtures/input_parse_cases.lua")

    local function deepCopy(t)
        if type(t) ~= "table" then return t end
        local c = {}
        for k, v in pairs(t) do c[deepCopy(k)] = deepCopy(v) end
        return c
    end

    local f = assert(io.open("tests/fixtures/m2_input/valid_selected_quests.lua", "rb"))
    local src = f:read("*a"); f:close()
    local base = assert(Schema.ParseString(src))

    it("accepts the valid selected-quests fixture", function()
        local ok, errs = Schema.Validate(base)
        assert.is_true(ok, table.concat(errs or {}, "; "))
        assert.are.equal(4, #base.quests)
        assert.are.equal(1203, base.quests[1].ID)
    end)

    it("does not mutate its input", function()
        local copy = deepCopy(base)
        Schema.Validate(copy)
        assert.are.same(base, copy)
    end)

    for _, case in ipairs(cases) do
        it("rejects: " .. case.name, function()
            local copy = deepCopy(base)
            case.mutate(copy)
            local ok, errs = Schema.Validate(copy)
            assert.is_false(ok)
            local text = table.concat(errs, " | ")
            assert.is_truthy(text:find(case.expect, 1, true), "expected '" .. case.expect .. "', got: " .. text)
        end)
    end

    for _, case in ipairs(parseCases) do
        it("parse rejects: " .. case.name, function()
            local got, errs = Schema.ParseString(case.src)
            assert.is_nil(got)
            local text = table.concat(errs, " | ")
            assert.is_truthy(text:find(case.expect, 1, true), "expected '" .. case.expect .. "', got: " .. text)
        end)
    end

    it("LoadFile accepts the fixture under tests/fixtures/m2_input/", function()
        local root = assert(io.popen("pwd"):read("*l"))
        local doc, errs = Schema.LoadFile(root .. "/tests/fixtures/m2_input/valid_selected_quests.lua", root)
        assert.is_truthy(doc, table.concat(errs or {}, "; "))
        assert.are.equal(4, #doc.quests)
    end)

    it("LoadFile refuses a tracked public path", function()
        local root = assert(io.popen("pwd"):read("*l"))
        local doc, errs = Schema.LoadFile(root .. "/cli/validate-335.lua", root)
        assert.is_nil(doc)
        assert.is_truthy(errs[1]:find("public checkout", 1, true))
    end)
end)
