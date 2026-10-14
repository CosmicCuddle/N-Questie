-- busted wrapper for Stage A1 (in-memory v2 round trip) so the existing
-- workflows that run busted -p ".test.lua" tools/validation execute it
-- without any workflow change. Pending where lua5.1 or GNU tools are absent.
-- The real-DB integration additionally needs bit32 (validate-335 compiles the
-- public database); where it is missing it is reported as pending, not passed.
describe("N-Questie Stage A1 v2 round trip", function()
    local function sh(cmd) local r = os.execute(cmd); return r == 0 or r == true end
    local base = sh("command -v lua5.1 >/dev/null 2>&1 && realpath -e -- / >/dev/null 2>&1")
    local db = base and sh("lua5.1 -e 'require(\"bit32\")' >/dev/null 2>&1 && command -v git >/dev/null 2>&1")
    for _, t in ipairs({
        { "v2 builder and round trip (synthetic, negative, tamper)", "lua5.1 tests/test_nquestie_m2_v2_builder.lua", base },
        { "no-write guard", "lua5.1 tests/test_nquestie_m2_no_write_guard.lua", base },
        { "frozen v1 exporter byte-identical to base", "lua5.1 tests/test_nquestie_m2_v1_frozen.lua", base },
        { "mutation test (every mutant killed)", "bash tests/test_nquestie_m2_v2_mutation.sh", base },
        { "real-DB read-only round trip (9159 / 8401 / 758 / 0 diffs)", "bash tests/test_nquestie_m2_v2_roundtrip_integration.sh", db },
    }) do
        if t[3] then
            it(t[1], function() assert.is_true(sh(t[2] .. " >/dev/null 2>&1")) end)
        else
            pending(t[1] .. " (lua5.1, GNU realpath, git or bit32 not available in this runner)")
        end
    end
end)
