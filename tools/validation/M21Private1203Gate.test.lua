-- Bridge the public synthetic private-1203 gate into existing Busted CI.
-- The inherited minimal Busted container lacks Bash or GNU realpath.
-- There, explicit PENDING is correct; in the M2 framework workflow, it
-- executes the negative tests and a failure is a real CI failure.
describe("N-Questie M2.1 selected-1203 privacy gate", function()
    local ready = os.execute("command -v bash >/dev/null 2>&1 && command -v lua5.1 >/dev/null 2>&1 && command -v git >/dev/null 2>&1 && command -v sed >/dev/null 2>&1 && realpath -e -- / >/dev/null 2>&1")
    ready = ready == 0 or ready == true
    if ready then
        it("accepts only a valid synthetic quest-1203 input without revealing provenance", function()
            local status = os.execute("bash tests/test_nquestie_private_1203_gate.sh")
            assert.is_true(status == 0 or status == true)
        end)
    else
        pending("single-1203 gate tests require Bash, Lua 5.1 and GNU realpath")
    end
end)
