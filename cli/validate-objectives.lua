-- N-Questie M1: print an objective-validation report (report only).
--
-- Usage: lua5.1 cli/validate-objectives.lua [<cases.lua>]
--   <cases.lua> returns a list of { row = <quest_template-shaped row>,
--   questie = <Questie quest record> } tables. Defaults to the public
--   synthetic fixtures. Private inputs belong under private/ (gitignored).
-- Prints findings to stdout. Writes nothing, changes nothing, and makes no
-- statement about quest availability. Exit 0 always unless input is unreadable.
local Rules = dofile("tools/validation/ObjectiveRules.lua")
local path = arg[1] or "tools/validation/fixtures/objective_cases.lua"
local chunk, err = loadfile(path)
if not chunk then io.stderr:write("cannot read " .. path .. ": " .. tostring(err) .. "\n") os.exit(2) end
local cases = chunk()

local totals = {}
for _, case in ipairs(cases) do
    local findings = Rules.Compare(Rules.FromQuestTemplateRow(case.row), case.questie)
    local worst = Rules.Worst(findings)
    totals[worst] = (totals[worst] or 0) + 1
    print(string.format("== quest %s: %s%s", tostring(case.row.ID), worst, case.name and (" (" .. case.name .. ")") or ""))
    for _, f in ipairs(findings) do print("   " .. Rules.Format(f)) end
end
print("\nSummary by worst class per quest:")
for _, cls in ipairs({ "CONFIRMED_MISMATCH", "NEEDS_MANUAL_REVIEW", "UNSUPPORTED", "EXPECTED_REPRESENTATION_DIFF", "CONSISTENT" }) do
    print(string.format("  %-30s %d", cls, totals[cls] or 0))
end
print("Report only. No quest data was changed. Individual Progression, conditions and scripts are not evaluated.")
