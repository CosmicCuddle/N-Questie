-- busted wrapper: runs the M2.2 standalone library tests so the existing
-- M1 workflow (busted -p ".test.lua" tools/validation) executes them.
-- They need a lua5.1 binary and GNU coreutils. The inherited ci.yml busted
-- container has neither, so there the tests are reported as pending, not passed.
describe("N-Questie M2.2 libraries", function()
    local available = os.execute("command -v lua5.1 >/dev/null 2>&1 && realpath -e -- / >/dev/null 2>&1")
    available = available == 0 or available == true
    local function runs(script)
        local r = os.execute("lua5.1 " .. script .. " >/dev/null 2>&1")
        return r == 0 or r == true
    end
    for _, t in ipairs({
        { "EffectiveExport snapshot tests pass", "tests/test_nquestie_m2_effective_export.lua" },
        { "SafeWrite tests pass", "tests/test_nquestie_m2_safe_write.lua" },
        { "effective schema standalone tests pass", "tests/test_nquestie_m2_effective_schema.lua" },
    }) do
        if available then
            it(t[1], function() assert.is_true(runs(t[2])) end)
        else
            pending(t[1] .. " (lua5.1 or GNU realpath not available in this runner)")
        end
    end
end)
