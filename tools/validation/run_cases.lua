-- Shared checker for objective-rule fixtures. Returns a function that runs
-- every case and returns (failures, results). Used by the plain Lua 5.1 test
-- and the busted spec so both test exactly the same thing.
return function(Rules, cases)
    local failures, results = {}, {}
    for _, case in ipairs(cases) do
        local findings = Rules.Compare(Rules.FromQuestTemplateRow(case.row), case.questie)
        results[#results + 1] = { case = case, findings = findings }
        local function fail(msg) failures[#failures + 1] = case.name .. ": " .. msg end
        for _, f in ipairs(findings) do
            if type(f.explanation) ~= "string" or #f.explanation < 20 then fail("finding without a clear explanation") end
            if #f.rules == 0 then fail("finding without a rule id") end
            for _, r in ipairs(f.rules) do if not Rules.RULES[r] then fail("unknown rule " .. r) end end
        end
        for _, e in ipairs(case.expect or {}) do
            local found = false
            for _, f in ipairs(findings) do
                if f.kind == e[1] and f.class == e[2] then
                    if not e[3] then found = true end
                    for _, r in ipairs(f.rules) do if r == e[3] then found = true end end
                end
            end
            if not found then fail("missing " .. e[1] .. " " .. e[2] .. " " .. tostring(e[3])) end
        end
        if case.maxFindings and #findings > case.maxFindings then
            fail(#findings .. " findings, expected at most " .. case.maxFindings)
        end
        for _, cls in ipairs(case.forbid or {}) do
            for _, f in ipairs(findings) do
                if f.class == cls then fail("unexpected " .. cls .. ": " .. f.explanation) end
            end
        end
    end
    return failures, results
end
