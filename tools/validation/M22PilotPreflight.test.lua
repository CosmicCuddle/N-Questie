-- Public/synthetic pilot-output preflight shell regression.
-- This spec is discovered by the EXISTING Busted CI job. It does not read
-- real AzerothCore records, export quests or write outside a temporary dir.
describe("M2.2 public pilot output preflight", function()
    it("refuses unsafe output paths and accidental evidence clobber", function()
        local status = os.execute("bash tests/test_nquestie_m2_pilot_preflight.sh")
        assert.is_true(status == 0 or status == true)
    end)
end)
