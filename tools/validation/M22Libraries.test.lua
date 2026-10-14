-- busted wrapper: runs the M2.2 standalone library tests so the existing
-- M1 workflow (busted -p ".test.lua" tools/validation) executes them.
describe("N-Questie M2.2 libraries", function()
    local function runs(script)
        local r = os.execute("lua5.1 " .. script .. " >/dev/null 2>&1")
        return r == 0 or r == true
    end
    it("EffectiveExport snapshot tests pass", function()
        assert.is_true(runs("tests/test_nquestie_m2_effective_export.lua"))
    end)
    it("SafeWrite tests pass", function()
        assert.is_true(runs("tests/test_nquestie_m2_safe_write.lua"))
    end)
    it("effective schema standalone tests pass", function()
        assert.is_true(runs("tests/test_nquestie_m2_effective_schema.lua"))
    end)
end)
