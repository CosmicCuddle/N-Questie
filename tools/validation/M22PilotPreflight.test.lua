-- Public/synthetic pilot output preflight checks (no private-server data).
-- The existing default unit-tests container deliberately lacks Bash/GNU tools.
-- There we use a visible PENDING result (not false PASS or failing tests).
-- In the M2 framework runner, where Bash and GNU tools are present, this
-- executes the real negative preflight suite and requires a zero exit code.
describe("M2.2 public pilot output preflight", function()
    local available = os.execute("command -v bash >/dev/null 2>&1 && command -v git >/dev/null 2>&1 && command -v sha256sum >/dev/null 2>&1 && realpath -e -- / >/dev/null 2>&1")
    available = available == 0 or available == true
    if available then
        it("refuses unsafe output paths and accidental evidence clobber", function()
            local status = os.execute("bash tests/test_nquestie_m2_pilot_preflight.sh")
            assert.is_true(status == 0 or status == true)
        end)
    else
        pending("pilot output preflight (Bash/GNU realpath/git/sha256sum unavailable in this runner)")
    end
end)
