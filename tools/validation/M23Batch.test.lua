-- M2.3 Part 2: new pure schema/adapter/M1 test via existing PR CI.
describe("N-Questie M2.3 Part 2 synthetic comparisons", function()
    local status = os.execute("command -v lua5.1 >/dev/null 2>&1")
    if status == 0 or status == true then
        it("checks v2 adaptation, all-quest membership and no false confirmation", function()
            local rc = os.execute("lua5.1 tests/test_nquestie_m2_3_batch.lua")
            assert.is_true(rc == 0 or rc == true)
        end)
    else
        pending("M2.3 Part 2 needs Lua 5.1 (not counted as passed)")
    end
end)
