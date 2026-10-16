-- M2.3 Part 2: pure v2 SUPPORTED record -> frozen M1 questKeys shape.
-- Report-only. No filesystem, subprocess, or WoW API; no input mutation.
local V2 = dofile("tools/validation/EffectiveSchemaV2.lua")
local M = {}

function M.ToQuestieRecordV2(rec)
    local ok = V2.ValidateQuest(rec)
    if not ok or rec.m1Status ~= "SUPPORTED" then return nil, "REJECTED_MALFORMED_INPUT" end
    local slots = { {}, {}, {}, {}, {}, {} }
    local byKind = { creature = 1, object = 2, item = 3, killCredit = 5, spell = 6 }
    for _, o in ipairs(rec.objectives) do
        local slot = byKind[o.kind]
        if not slot or slots[slot][o.slotIndex] ~= nil then
            return nil, "REJECTED_MALFORMED_INPUT"
        end
        local value
        if o.kind == "killCredit" then
            local ids = {}
            for i, id in ipairs(o.ids) do ids[i] = id end
            value = { ids, o.rootId }
        else
            value = { o.id }
        end
        slots[slot][o.slotIndex] = value
    end
    -- M1 iterates with ipairs: a sparse slot list would silently drop targets.
    for _, slot in ipairs({ 1, 2, 3, 5, 6 }) do
        local n = 0
        for k in pairs(slots[slot]) do
            if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
                return nil, "REJECTED_MALFORMED_INPUT"
            end
            n = n + 1
        end
        if n ~= #slots[slot] then return nil, "REJECTED_MALFORMED_INPUT" end
    end
    local q = { [10] = slots, [4] = rec.requiredLevel, [5] = rec.questLevel }
    q[11] = rec.sourceItemId > 0 and rec.sourceItemId or nil
    local rsi = {}
    for i, id in ipairs(rec.requiredSourceItems) do rsi[i] = id end
    q[21] = rsi
    if rec.hasTriggerEnd then q[9] = {} end
    if #rec.extraObjectives > 0 then
        q[27] = {}
        for i, e in ipairs(rec.extraObjectives) do
            local refs = {}
            for j, r in ipairs(e.refs) do
                -- Monster/object extras cannot be represented by frozen M1.
                if r.type ~= "item" then return nil, "REJECTED_MALFORMED_INPUT" end
                refs[j] = { "item", r.id }
            end
            q[27][i] = { nil, nil, nil, e.objectiveIndex, refs }
        end
    end
    -- V2 does not export objectivesText; M1 does not read slot [8].
    return q
end

return M
