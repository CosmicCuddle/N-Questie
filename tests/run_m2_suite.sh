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
step "Lua 5.1 syntax (M1, M2.1, M2.2 modules, fixtures, specs, tests)" bash -c "luac5.1 -p tools/validation/*.lua tools/validation/draft/*.lua tools/validation/fixtures/*.lua cli/validate-335.lua cli/validate-m2-input.lua cli/validate-objectives.lua tests/test_nquestie_m2_*.lua tests/check_m2_export_values.lua tests/check_m2_v2_export_file.lua tests/fixtures/m2_input/*.lua tests/fixtures/m2_effective/*.lua tests/fixtures/m2_effective_v2_draft/*.lua tests/fixtures/m2_v2_builder/*.lua"
step "private/ guard" bash tests/check_no_tracked_private.sh
step "private/ guard self-test" bash tests/test_check_no_tracked_private.sh
step "M1 objective rules" "$LUA" tests/test_nquestie_objective_rules.lua
step "M2.1 input schema and parser" "$LUA" tests/test_nquestie_m2_input_schema.lua
step "M2.1 path and symlink safety" "$LUA" tests/test_nquestie_m2_input_paths.lua
step "Single-quest 1203 gate syntax" luac5.1 -p cli/check-private-1203.lua
step "Private-1203 gate (public synthetic cases only)" bash tests/test_nquestie_private_1203_gate.sh
step "M2.2 effective schema" "$LUA" tests/test_nquestie_m2_effective_schema.lua
step "M2.2 snapshot (compiled shapes)" "$LUA" tests/test_nquestie_m2_effective_export.lua
step "M2.2 safe writer" "$LUA" tests/test_nquestie_m2_safe_write.lua
step "M2.2 provenance" "$LUA" tests/test_nquestie_m2_provenance.lua
step "Harness version pin" "$LUA" tests/test_nquestie_harness_version.lua
step "M2.2 coverage (synthetic)" "$LUA" tests/test_nquestie_m2_coverage.lua
step "M2.2 objective order (killCreditObjectiveFirst)" "$LUA" tests/test_nquestie_m2_order.lua
step "M2 v2 DRAFT prototype (design validation only)" "$LUA" tests/test_nquestie_m2_effective_v2_draft.lua
step "M2 v2 exporter acceptance DRAFT (spec only)" "$LUA" tests/test_nquestie_m2_v2_acceptance.lua
step "Stage A1 v2 builder and round trip (synthetic)" "$LUA" tests/test_nquestie_m2_v2_builder.lua
step "Stage A1 M1 parity with frozen v1 (synthetic matrix)" "$LUA" tests/test_nquestie_m2_v2_m1_parity.lua
step "Stage A1 no-write guard" "$LUA" tests/test_nquestie_m2_no_write_guard.lua
step "Stage A1 frozen v1 exporter (byte-identical to base)" "$LUA" tests/test_nquestie_m2_v1_frozen.lua
step "Stage A2 v2 serialiser and export pipeline (synthetic)" "$LUA" tests/test_nquestie_m2_v2_export.lua
step "Stage A2 verify clean-checkout gate (synthetic + temp git repo)" "$LUA" tests/test_nquestie_m2_v2_verify_clean.lua
step "Stage A2 verify clean-checkout gate through the CLI (temp clone)" bash tests/test_nquestie_m2_v2_verify_cli.sh
step "Stage A1/A2 mutation test" bash tests/test_nquestie_m2_v2_mutation.sh
step "M2.3 contract DRAFT (design only)" "$LUA" tests/test_nquestie_m2_3_report_draft.lua
step "nq-m2-markers DRAFT (design only)" "$LUA" tests/test_nquestie_m2_markers_draft.lua
step "Correction regression and text QA DRAFT" "$LUA" tests/test_nquestie_m2_qa_draft.lua
step "pilot script syntax" bash -n tools/validation/run-m2-pilot.sh
step "pilot output path and no-clobber preflight" bash tests/test_nquestie_m2_pilot_preflight.sh
step "busted tools/validation" busted -p ".test.lua" tools/validation
if [ "${NQ_M2_SKIP_INTEGRATION:-0}" != "1" ]; then
    step "M2.2 real-DB export integration (M0 + export)" bash tests/test_nquestie_m2_export_integration.sh
    step "M2.2 real-DB coverage integration" bash tests/test_nquestie_m2_coverage_integration.sh
    step "Stage A1 real-DB read-only v2 round trip" bash tests/test_nquestie_m2_v2_roundtrip_integration.sh
    step "Stage A2 real-DB v2 export acceptance (F1-F8)" bash tests/test_nquestie_m2_v2_export_integration.sh
fi
[ $status -eq 0 ] && echo "PASS: M2 suite" || { echo "FAILED: M2 suite"; exit 1; }
