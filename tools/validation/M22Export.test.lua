-- busted wrapper for the fast M2.2 Step 3 provenance tests. The real-DB
-- integration test (tests/test_nquestie_m2_export_integration.sh) is slow and
-- runs as its own CI step. Pending where lua5.1/git/GNU tools are absent.
describe("N-Questie M2.2 export provenance", function()
    local available = os.execute("command -v lua5.1 >/dev/null 2>&1 && command -v git >/dev/null 2>&1 && command -v sha256sum >/dev/null 2>&1 && realpath -e -- / >/dev/null 2>&1")
    available = available == 0 or available == true
    if available then
        it("provenance tests pass", function()
            local r = os.execute("lua5.1 tests/test_nquestie_m2_provenance.lua >/dev/null 2>&1")
            assert.is_true(r == 0 or r == true)
        end)
    else
        pending("provenance tests (lua5.1, git or GNU coreutils not available in this runner)")
    end
end)
