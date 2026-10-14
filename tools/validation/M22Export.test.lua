-- busted wrapper for the fast M2.2 Step 3 provenance tests. The real-DB
-- integration test (tests/test_nquestie_m2_export_integration.sh) is slow and
-- runs as its own CI step.
describe("N-Questie M2.2 export provenance", function()
    it("provenance tests pass", function()
        local r = os.execute("lua5.1 tests/test_nquestie_m2_provenance.lua >/dev/null 2>&1")
        assert.is_true(r == 0 or r == true)
    end)
end)
