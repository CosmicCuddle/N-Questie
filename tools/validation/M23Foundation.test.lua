-- M2.3 Part 1 bridge into the existing PR-scoped M2 framework workflow.
-- Never reports PASSED when Lua 5.1 is unavailable.
describe("N-Questie M2.3 Part 1 safe-capture and empty allowlist", function()
    local result = os.execute("command -v lua5.1 >/dev/null 2>&1")
    if result == 0 or result == true then
        it("rejects failed commands and unapproved/malformed allowlist data", function()
            local status = os.execute("lua5.1 tests/test_nquestie_m2_3_foundation.lua >/dev/null 2>&1")
            assert.is_true(status == 0 or status == true)
        end)
    else
        pending("M2.3 Part 1 contract tests require Lua 5.1")
    end
end)
