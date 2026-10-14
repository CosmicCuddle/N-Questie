#!/usr/bin/env bash
# Runs every M2 test (M2.1 + M2.2) in dependency order. Synthetic and public
# data only. The real-DB export test needs a clean checkout and ~3 minutes;
# set NQ_M2_SKIP_INTEGRATION=1 to skip it locally.
set -u
cd "$(dirname "$0")/.."
LUA="${LUA:-lua5.1}"
status=0
step() { echo "== $1"; shift; if "$@"; then echo "   ok"; else echo "   FAILED"; status=1; fi; }
step "GNU realpath available" bash -c 'realpath -e -- / >/dev/null && realpath --version | head -1 | grep -q GNU'
step "Lua 5.1 syntax (M1, M2.1, M2.2 modules, fixtures, specs, tests)" bash -c "luac5.1 -p tools/validation/*.lua tools/validation/fixtures/*.lua cli/validate-335.lua cli/validate-m2-input.lua cli/validate-objectives.lua tests/test_nquestie_m2_*.lua tests/check_m2_export_values.lua tests/fixtures/m2_input/*.lua tests/fixtures/m2_effective/*.lua"
step "private/ guard" bash tests/check_no_tracked_private.sh
step "private/ guard self-test" bash tests/test_check_no_tracked_private.sh
step "M1 objective rules" "$LUA" tests/test_nquestie_objective_rules.lua
step "M2.1 input schema and parser" "$LUA" tests/test_nquestie_m2_input_schema.lua
step "M2.1 path and symlink safety" "$LUA" tests/test_nquestie_m2_input_paths.lua
step "M2.2 effective schema" "$LUA" tests/test_nquestie_m2_effective_schema.lua
step "M2.2 snapshot (compiled shapes)" "$LUA" tests/test_nquestie_m2_effective_export.lua
step "M2.2 safe writer" "$LUA" tests/test_nquestie_m2_safe_write.lua
step "M2.2 provenance" "$LUA" tests/test_nquestie_m2_provenance.lua
step "busted tools/validation" busted -p ".test.lua" tools/validation
if [ "${NQ_M2_SKIP_INTEGRATION:-0}" != "1" ]; then
    step "M2.2 real-DB export integration (M0 + export)" bash tests/test_nquestie_m2_export_integration.sh
fi
[ $status -eq 0 ] && echo "PASS: M2 suite" || { echo "FAILED: M2 suite"; exit 1; }
