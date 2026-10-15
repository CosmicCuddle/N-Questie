#!/usr/bin/env bash
# Stage A1 mutation test: each mutant deliberately breaks the v2 builder,
# the round trip or the no-write guard in a TEMPORARY copy, and the synthetic
# tests must then FAIL. A mutant that survives means the tests do not
# exercise that code. Also checks the unmutated copy passes. Writes only to
# a temporary directory.
set -u
cd "$(dirname "$0")/.."
LUA="${LUA:-lua5.1}"
fails=0; passes=0
ok()  { passes=$((passes+1)); echo "PASS: $1"; }
bad() { fails=$((fails+1)); echo "FAIL: $1"; }
T="$(mktemp -d)"; trap 'rm -rf -- "$T"' EXIT
# The CLI gate test needs bit32 and git (cli/validate-335.lua requires bit32).
# Without them the CLI mutants are reported as SKIPPED, never as killed.
HAVE_CLI=0; "$LUA" -e 'require("bit32")' >/dev/null 2>&1 && command -v git >/dev/null 2>&1 && HAVE_CLI=1
skipped=0
copy() {
    rm -rf "$T/w"; mkdir -p "$T/w/tools/validation/draft" "$T/w/tests" "$T/w/cli"
    cp cli/validate-335.lua "$T/w/cli/"
    cp tools/validation/*.lua "$T/w/tools/validation/"
    cp tools/validation/draft/*.lua "$T/w/tools/validation/draft/"
    cp tests/test_nquestie_m2_v2_builder.lua tests/test_nquestie_m2_no_write_guard.lua tests/test_nquestie_m2_v2_m1_parity.lua \
       tests/test_nquestie_m2_v2_export.lua tests/test_nquestie_m2_v2_verify_clean.lua tests/test_nquestie_m2_v2_acceptance.lua tests/test_nquestie_m2_effective_v2_draft.lua "$T/w/tests/"
    cp -r tests/fixtures "$T/w/tests/"
}
run_tests() { mkdir -p "$T/tmp"; (cd "$T/w" && export TMPDIR="$T/tmp" && for t in test_nquestie_m2_v2_builder test_nquestie_m2_no_write_guard test_nquestie_m2_v2_m1_parity \
    test_nquestie_m2_v2_export test_nquestie_m2_v2_verify_clean test_nquestie_m2_v2_acceptance test_nquestie_m2_effective_v2_draft; do
    "$LUA" "tests/$t.lua" >/dev/null 2>&1 || exit 1; done) || return 1
    # the CLI gate test (temporary clone with the mutated sources committed) only
    # for mutants of the CLI or the checkout-state module
    if [ "${WITH_CLI:-0}" = 1 ]; then NQ_VERIFY_CLI_SRC="$T/w" bash tests/test_nquestie_m2_v2_verify_cli.sh >/dev/null 2>&1 || return 1; fi
}
# mutant FILE 'exact old text' 'new text' 'label'
mutant() {
    local file="$1" old="$2" new="$3" label="$4"
    copy
    if ! OLD="$old" NEW="$new" F="$T/w/$file" "$LUA" -e '
        local f = io.open(os.getenv("F")); local s = f:read("*a"); f:close()
        local old, new = os.getenv("OLD"), os.getenv("NEW")
        local i = s:find(old, 1, true); if not i then os.exit(3) end
        s = s:sub(1, i - 1) .. new .. s:sub(i + #old)
        f = io.open(os.getenv("F"), "w"); f:write(s); f:close()'; then
        bad "mutant not applied (text not found): $label"; return
    fi
    WITH_CLI=0; case "$file" in cli/*|*CheckoutState.lua) WITH_CLI=$HAVE_CLI;; esac
    case "$file" in cli/*) if [ $HAVE_CLI = 0 ]; then skipped=$((skipped+1)); echo "SKIP (no bit32/git): $label"; return; fi;; esac
    if run_tests; then bad "mutant SURVIVED: $label"; else ok "mutant killed: $label"; fi
}
copy
WITH_CLI=$HAVE_CLI run_tests && ok "unmutated copy passes (CLI gate test included: $HAVE_CLI)" || bad "unmutated copy fails"

B=tools/validation/EffectiveExportV2.lua
R=tools/validation/RoundTripV2.lua
G=tools/validation/NoWriteGuard.lua
D=tools/validation/EffectiveSchemaV2.lua
S=tools/validation/EffectiveExportV2.lua
P=tools/validation/ExportV2.lua
# M1 parity (decision t54u): each mutant breaks one v1-equivalent rule.
mutant $D 'if rs[v] then add("DUPLICATE_SOURCE_ITEM") end' '' "parity: repeated requiredSourceItems not classified"
mutant $D 'item = "DUPLICATE_ITEM"' 'item = "DUPLICATE_OTHER"' "parity: generic code for repeated item"
mutant $D 'spell = "DUPLICATE_SPELL"' 'spell = "DUPLICATE_OTHER"' "parity: generic code for repeated spell"
mutant $D 'if ids[v] then add("DUPLICATE_KILLCREDIT_ID") end' '' "parity: repeated killCredit id not classified"
mutant $D 'if o.kind == "spell" and o.itemSourceId ~= nil then add("SHAPE_UNUSUAL") end' '' "parity: spell itemSourceId not classified"
mutant $D 'if extraItems[r.id] then add("DUPLICATE_EXTRA_ITEM") end' '' "parity: repeated extra item not classified"
mutant $D 'if o.kind == "reputation" then add("REPUTATION_OBJECTIVE") end' '' "parity: reputation not classified"
mutant $D 'elseif r.type == "object" then add("EXTRA_OBJECT_REF")' 'elseif r.type == "object" then add("EXTRA_CREATURE_REF")' "parity: object ref given the creature code"
mutant $D 'if q.killCreditFirst and nKc > 0 and (nOther > 0 or nKc > 1) then' 'if q.killCreditFirst then' "parity: killCreditFirst always reorders (old rule)"
mutant $D '(nOther > 0 or nKc > 1)' '(nOther > 0)' "parity: several killCredit entries not seen as reversed"
mutant $D '(nOther > 0 or nKc > 1)' '(nKc > 1)' "parity: killCredit moved before other kinds not seen"
mutant $D '            nOther = nOther + 1' '' "parity: other objectives not counted"
mutant $R 'if not reorders then a.killCreditFirstFlaggedSingle = a.killCreditFirstFlaggedSingle + 1 end' '' "flagged-not-reordered counter dead"
mutant $B 'table.insert(list, 1, o)' 'list[#list + 1] = o' "killCreditFirst not inserted first (no reversal)"
mutant $B 'o.occurrence = occ[key]' 'o.occurrence = 1' "duplicate occurrences not numbered"
mutant $B 'requiredValue = list[2] }' 'requiredValue = (list[2] ~= 0) and list[2] or nil }' "reputation value 0 dropped"
mutant $B 'refs[j] = { type = r[1], id = r[2], refIndex = j }' 'if j == 1 then refs[j] = { type = r[1], id = r[2], refIndex = j } end' "extra refs after the first dropped"
mutant $B 'ids[j] = v' 'ids = e[1]' "killCredit ids aliased (shallow copy)"
mutant $B 'if isInt(e.objectiveIndex) and e.objectiveIndex > M.MaxObjectiveIndex(rec) then' 'if false then' "objectiveIndex upper bound removed"
mutant $B 'if not ok then err("query for "' 'if false then err("query for "' "query failure swallowed"
mutant $B 'zones[#zones + 1] = z' 'table.insert(zones, 1, z)' "spawn zones not sorted"
mutant $B 'if src == nil then src = 0 end' 'if src == nil then src = nil end' "absent sourceItemId not exported as 0"
mutant $B '        table.sort(reasons)' '' "m1 reasons not sorted"
mutant $B 'rec.requiredSourceItems[i] = v' 'if i == 1 then rec.requiredSourceItems[i] = v end' "requiredSourceItems truncated"
mutant $B 'rec.hasTriggerEnd = raw.triggerEnd ~= nil' 'rec.hasTriggerEnd = false' "triggerEnd presence lost"
mutant $B 'if #refs == 0 and #zones == 0 then' 'if false then' "empty extra entry accepted"
mutant $B 'if not posId(e[1]) then err(w .. " id "' 'if false then err(w .. " id "' "invalid objective id accepted"
mutant $B 'if not isInt(list[2]) then' 'if false then' "missing reputation value accepted"
mutant $B 'rec.killCreditFirst = kcfFlag and #slots.killCredit > 0' 'rec.killCreditFirst = false' "killCreditFirst flag ignored"
mutant $B 'if type(ctx) ~= "table" or type(ctx.killCreditFirst) ~= "table" or next(ctx.killCreditFirst) == nil then' 'if false then' "missing killCreditFirst context accepted"
mutant $R 'if a ~= b then out[#out + 1] = path end' 'if false then out[#out + 1] = path end' "Compare made vacuous"
mutant $R 'if name == "killCredit" and flagged then' 'if false then' "RecomputePositions ignores killCreditFirst"
mutant $R '    return d
end' '    return {}
end' "V1Equivalent made vacuous"
mutant $R 'if not okv then r.validateError = verrs end' '' "record validation ignored"
mutant $R 'if #r.diffs > 0 then a.questsDiffering = a.questsDiffering + 1 end' '' "aggregate never counts differing quests"
mutant $R 'a.buildErrors = a.buildErrors + 1' '' "aggregate never counts build errors"
mutant $R 'for _, p in ipairs(M.Compare(rebuilt, projected)) do' 'for _, p in ipairs({}) do' "round trip comparison skipped"
mutant $G 'state.count = state.count + 1' '' "guard does not count"
mutant $G 'if m:find("[wa+]") then block("io.open:" .. m) end' '' "guard lets write-mode io.open through"
mutant $G 'env.os.execute = function() block("os.execute") end' '' "guard lets os.execute through"
# Stage A2: serialiser, document, export pipeline and schema gates.
mutant $S 'for k in pairs(t) do if not known[k] then serr(path, "field "' 'for k in pairs(t) do if false then serr(path, "field "' "serialiser: unknown record field silently dropped"
mutant $S 'if v ~= v or v ~= math.floor(v) or' 'if v ~= v or' "serialiser: non-integer numbers accepted"
mutant $S 'if not v:match' 'if false and not v:match' "serialiser: unsafe strings accepted"
mutant $S 'if not isList(t) then serr(path, "plain list required") end' '' "serialiser: maps written as lists"
mutant $S 'p.questCount = #records' '' "document: questCount not set"
mutant $S 'quests = copy(records) }' 'quests = records }' "document: records aliased"
mutant $S 'local p = copy(provenance)' 'local p = provenance' "document: caller provenance mutated"
mutant $S 'if not first then out[#out + 1] = "," end' '' "serialiser: separators dropped"
mutant $P 'if Schema.Canonical(parsed, {}) ~= Schema.Canonical(doc, {}) then' 'if false then' "pipeline: parsed text not compared with the document"
mutant $P 'if not agg then return false, rerr end' '' "pipeline: round trip result ignored"
mutant $P 'wopts.force = nil' '' "pipeline: force passed through"
mutant $P 'if back ~= text then' 'if false then' "pipeline: re-read byte check removed"
mutant $P 'if args.preWrite then' 'if false then' "pipeline: preWrite check skipped"
mutant $P 'if opts.expectCorrectionCount and p.correctionCount ~= opts.expectCorrectionCount then' 'if false then' "pipeline: correction count not checked"
mutant $P 'if opts.expectHarnessVersion and p.harnessVersion ~= opts.expectHarnessVersion then' 'if false then' "pipeline: harness version not checked"
# Equivalent mutants, deliberately not listed (the check is repeated by
# another layer, so no test can kill them): removing the re-read validation
# in ExportV2.Export (the re-read bytes are already proven equal to text that
# was parsed and validated before writing), and removing the pipeline's own
# CheckContext call (BuildAll checks the same context first). Both checks
# are kept as defence in depth.
mutant $P 'if not q then' 'if false then' "pipeline: quest missing from the document not detected"
mutant $P 'if a.questsDiffering > 0 then' 'if false then' "pipeline: differing quests not refused"
mutant $D 'if doc.schemaVersion ~= 2 then' 'if false then' "schema: unknown version accepted"
mutant $D 'if doc.displayScope ~= M.DISPLAY_SCOPE then' 'if false then' "schema: displayScope not enforced"
mutant $D 'for k in pairs(q) do if not QUEST_KEYS[k] then' 'for k in pairs(q) do if false then' "schema: unknown quest field accepted"
# t56u: clean-checkout gate of NQ_V2_VERIFY_IN
K=tools/validation/CheckoutState.lua
V=cli/validate-335.lua
mutant $K 'if status == nil then err("cannot read git status")' 'if false then err("cannot read git status")' "verify gate: unreadable git status not refused"
mutant $K 'elseif status ~= "" then' 'elseif false then' "verify gate: dirty status accepted"
mutant $K 'if rc ~= 0 or out == nil then return nil end' 'if out == nil then return nil end' "verify gate: git exit code ignored"
mutant $K 'if line ~= "" and not line:match("^[ MADRCU?!][ MADRCU?!] .") then' 'if false then' "verify gate: unexpected status output not reported"
mutant $K 'if not (commit and commit:match("^%x+$") and #commit == 40) then' 'if not commit then' "verify gate: malformed HEAD accepted"
mutant $K ' or realTop ~= root then' ' then' "verify gate: root not checked against the git top level"
mutant $K 'if #errs > 0 then return nil, errs end' '' "verify gate: errors collected but not returned"
mutant $K 'if rrc ~= 0 or realTop == nil' 'if realTop == nil' "verify gate: realpath exit status ignored"
mutant $K 'if not top or top == "" then' 'if not top then' "verify gate: empty git top level accepted"
mutant $K '"status --porcelain --untracked-files=all"' '"status --porcelain --untracked-files=no"' "verify gate: untracked files not seen"
mutant $V 'if not state then
        for _, e in ipairs(serr) do errs[#errs + 1] = "v2 verify: " .. e end
    end' '' "verify CLI: gate result ignored"
mutant $V 'local state, serr = dofile("tools/validation/CheckoutState.lua").Check(root, dofile("tools/validation/ExportProvenance.lua"))' 'local state, serr = { commit = "", tree = "" }, nil' "verify CLI: gate not called"
# Not killable without a test hook in the CLI, so not listed: the second
# CheckoutState.Check after verification in runVerifyV2 (the checkout would
# have to become dirty during the run). It is defence in depth only; the
# first check before compile is the tested gate.
echo "mutation test: $passes passed, $fails failed, $skipped skipped (CLI mutants need bit32 and git)"
[ $fails -eq 0 ]
