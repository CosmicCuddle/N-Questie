-- N-Questie M1: quest objective validation rules (report only).
--
-- Compares a server-shaped quest record (AzerothCore quest_template column
-- names, supplied locally or as a synthetic fixture) with Questie's effective
-- quest record (QuestieDB.questKeys indices) and classifies every difference:
--
--   CONFIRMED_MISMATCH            same objective slot, different target, no rule explains it
--   EXPECTED_REPRESENTATION_DIFF  explained by a catalogued rule (rule ids listed)
--   NEEDS_MANUAL_REVIEW           ambiguous or incomplete input; a person must decide
--   UNSUPPORTED                   decided by server conditions, scripts or Individual
--                                 Progression; static data cannot answer it
--
-- Pure Lua 5.1. No WoW API, no globals, no file or network access. It never
-- changes quest data and never states that a quest is available to a player.

local M = {}

M.CLASS = {
    CONFIRMED = "CONFIRMED_MISMATCH",
    EXPECTED = "EXPECTED_REPRESENTATION_DIFF",
    REVIEW = "NEEDS_MANUAL_REVIEW",
    UNSUPPORTED = "UNSUPPORTED",
}
local C = M.CLASS

-- Questie field indices (Database/questDB.lua). Checked by the M0 harness.
M.QK = { objectivesText = 8, triggerEnd = 9, objectives = 10, sourceItemId = 11,
         requiredSourceItems = 21, extraObjectives = 27 }
local QK = M.QK

-- Rule catalogue: id -> human-readable reason. Every finding cites ids from here.
M.RULES = {
    ["E-QTY"] = "Questie does not store objective counts. The client quest log supplies "
        .. "required and current counts at runtime, so count values are not compared.",
    ["E-GO-SIGN"] = "AzerothCore stores gameobject targets as negative RequiredNpcOrGo values. "
        .. "Questie stores the positive id in objectives[2] (object objectives).",
    ["E-KILLCREDIT"] = "The server target creature is listed in a Questie killCreditObjective "
        .. "(objectives[5]) as an alternative or root creature.",
    ["E-KC-TEMPLATE"] = "Questie lists the creature the player actually kills. Its creature_template "
        .. "KillCredit1/KillCredit2 points at the server's RequiredNpcOrGo target.",
    ["E-STARTITEM"] = "The required item is the quest's StartItem (given on accept). Questie keeps "
        .. "it as sourceItemId or requiredSourceItems instead of an item objective.",
    ["E-SRCITEM"] = "ItemDrop items are source items, not counted objectives. Questie may list "
        .. "them in requiredSourceItems/extraObjectives or omit them.",
    ["E-ORDER-TYPE"] = "Questie groups objectives by type (creature, object, item). The server's "
        .. "slot order differs only across types, which Questie's own ordering accounts for.",
    ["M-ITEM-TARGET"] = "Same item objective slot, different item id on each side, and no "
        .. "representation rule applies. Treat as a genuine data difference until reviewed.",
    ["M-NPC-TARGET"] = "Same creature slot, different creature id, and the supplied KillCredit "
        .. "data does not link them. Treat as a genuine data difference until reviewed.",
    ["R-ITEM-UNPAIRED"] = "An item appears on only one side. It may be a missing objective, an "
        .. "extra Questie objective, or a source item. A person must check the quest text.",
    ["R-NPC-NOCREDIT"] = "Creature targets differ and creature_template KillCredit data was not "
        .. "supplied, so a kill-credit relationship cannot be ruled out.",
    ["R-NPC-UNPAIRED"] = "A creature target appears on only one side.",
    ["R-GO-UNPAIRED"] = "A gameobject target appears on only one side. Questie sometimes models "
        .. "object use as a spell, event or extra objective.",
    ["R-GO-AS-NPC"] = "The server marks the target as a gameobject (negative id) but Questie lists "
        .. "the same id as a creature objective.",
    ["R-SRC-AS-OBJECTIVE"] = "Questie lists an ItemDrop source item as an item objective, but the "
        .. "server does not require it. The tracker may show an extra objective.",
    ["R-ORDER-WITHIN-TYPE"] = "Two targets of the same type are in a different order. Questie maps "
        .. "quest-log objective N to its N-th objective, so pins may attach to the wrong line.",
    ["R-ORDER-MIXED"] = "The server places a gameobject slot before a creature slot. Questie lists "
        .. "creatures first, so quest-log indexes may not line up with Questie's objective list.",
    ["R-MALFORMED"] = "The server-shaped input is malformed (non-integer id, negative count, "
        .. "count without id). The record was not classified further.",
    ["R-QUEST-MISSING"] = "The quest exists in the server data but not in Questie. Handled by the "
        .. "reviewed import workflow, not by objective rules.",
    ["C-COND"] = "conditions rows affect this quest. Questie has no equivalent, so availability "
        .. "and objective visibility cannot be validated offline.",
    ["C-IP"] = "Individual Progression decides when this quest is available. Static data can "
        .. "only show consistency, not eligibility for a character.",
    ["C-SCRIPT"] = "Objective credit is granted by a server script (SmartAI or C++). The "
        .. "credited creature or object is not visible in quest_template.",
}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------
local function isInt(v) return type(v) == "number" and v == math.floor(v) end

local function finding(list, questId, kind, class, rules, explanation, server, questie)
    for _, r in ipairs(rules) do
        assert(M.RULES[r], "unknown rule id " .. tostring(r))
    end
    list[#list + 1] = {
        questId = questId, kind = kind, class = class, rules = rules,
        explanation = explanation, server = server, questie = questie,
    }
end

-- Convert one quest_template-shaped row (flat column map, as an SQL export
-- would produce) into the normalised server record used by M.Compare.
-- Extra keys used by the validator (not quest_template columns):
--   KillCredit = {[creatureId] = {credit1, credit2}}  (from creature_template)
--   killCreditComplete = true when KillCredit covers every creature involved
--   hasConditions, ipGated, scriptedCredit (booleans from the reviewer)
function M.FromQuestTemplateRow(row)
    local s = { id = row.ID or row.Id or row.id, npcOrGo = {}, items = {}, itemDrops = {},
                startItem = row.StartItem or 0, killCredit = row.KillCredit or {},
                killCreditComplete = row.killCreditComplete == true,
                hasConditions = row.hasConditions == true, ipGated = row.ipGated == true,
                scriptedCredit = row.scriptedCredit == true, problems = {} }
    for i = 1, 4 do
        local id, count = row["RequiredNpcOrGo" .. i] or 0, row["RequiredNpcOrGoCount" .. i] or 0
        if not isInt(id) or not isInt(count) or count < 0 or (id == 0 and count > 0) then
            s.problems[#s.problems + 1] = "RequiredNpcOrGo" .. i .. "=" .. tostring(id) .. " count " .. tostring(count)
        elseif id ~= 0 then
            s.npcOrGo[#s.npcOrGo + 1] = { slot = i, id = id, count = count }
        end
    end
    for i = 1, 6 do
        local id, count = row["RequiredItemId" .. i] or 0, row["RequiredItemCount" .. i] or 0
        if not isInt(id) or id < 0 or not isInt(count) or count < 0 or (id == 0 and count > 0) then
            s.problems[#s.problems + 1] = "RequiredItemId" .. i .. "=" .. tostring(id) .. " count " .. tostring(count)
        elseif id > 0 then
            s.items[#s.items + 1] = { slot = i, id = id, count = count }
        end
    end
    for i = 1, 4 do
        local id = row["ItemDrop" .. i] or 0
        if not isInt(id) or id < 0 then
            s.problems[#s.problems + 1] = "ItemDrop" .. i .. "=" .. tostring(id)
        elseif id > 0 then
            s.itemDrops[#s.itemDrops + 1] = id
        end
    end
    if not isInt(s.id) or s.id <= 0 then s.problems[#s.problems + 1] = "ID=" .. tostring(s.id) end
    if not isInt(s.startItem) or s.startItem < 0 then s.problems[#s.problems + 1] = "StartItem=" .. tostring(s.startItem) end
    return s
end

-- Questie's effective objective lists, as {id = position} maps and ordered lists.
local function questieLists(q)
    local obj = type(q[QK.objectives]) == "table" and q[QK.objectives] or {}
    local function list(slot)
        local out = {}
        for _, e in ipairs(type(obj[slot]) == "table" and obj[slot] or {}) do
            if type(e) == "table" and isInt(e[1]) then out[#out + 1] = e[1] end
        end
        return out
    end
    local kc = {}
    for _, e in ipairs(type(obj[5]) == "table" and obj[5] or {}) do
        if type(e) == "table" then
            if type(e[1]) == "table" then for _, id in ipairs(e[1]) do kc[id] = true end end
            if isInt(e[2]) then kc[e[2]] = true end
        end
    end
    local src = {}
    if isInt(q[QK.sourceItemId]) and q[QK.sourceItemId] > 0 then src[q[QK.sourceItemId]] = "sourceItemId" end
    for _, id in ipairs(type(q[QK.requiredSourceItems]) == "table" and q[QK.requiredSourceItems] or {}) do
        src[id] = src[id] or "requiredSourceItems"
    end
    for _, e in ipairs(type(q[QK.extraObjectives]) == "table" and q[QK.extraObjectives] or {}) do
        if type(e) == "table" and type(e[5]) == "table" then
            for _, ref in ipairs(e[5]) do
                if type(ref) == "table" and ref[1] == "item" and isInt(ref[2]) then
                    src[ref[2]] = src[ref[2]] or "extraObjectives"
                end
            end
        end
    end
    local hasAlt = (type(obj[6]) == "table" and next(obj[6]) ~= nil) or q[QK.triggerEnd] ~= nil
                   or (type(q[QK.extraObjectives]) == "table" and next(q[QK.extraObjectives]) ~= nil)
    return { creatures = list(1), objects = list(2), items = list(3), killCredit = kc,
             sourceItems = src, hasAltObjective = hasAlt }
end

local function indexOf(list, v)
    for i, x in ipairs(list) do if x == v then return i end end
    return nil
end

-------------------------------------------------------------------------------
-- Comparison
-------------------------------------------------------------------------------
-- server: record from M.FromQuestTemplateRow
-- questie: effective Questie quest record (questKeys indices) or nil
-- returns: list of findings (empty list = statically consistent)
function M.Compare(server, questie)
    local out, qid = {}, server.id

    if #server.problems > 0 then
        finding(out, qid, "input", C.REVIEW, { "R-MALFORMED" },
            "Malformed server-shaped input: " .. table.concat(server.problems, "; ") .. ". Fix the export before reviewing this quest.")
        return out
    end
    if type(questie) ~= "table" then
        finding(out, qid, "quest", C.REVIEW, { "R-QUEST-MISSING" },
            "Quest " .. qid .. " is in the server data but not in Questie's effective database. Use the reviewed import workflow.")
        return out
    end
    if server.hasConditions then
        finding(out, qid, "availability", C.UNSUPPORTED, { "C-COND" },
            "Quest " .. qid .. " has conditions rows. Availability and objective visibility are not validated.")
    end
    if server.ipGated then
        finding(out, qid, "availability", C.UNSUPPORTED, { "C-IP" },
            "Quest " .. qid .. " is gated by Individual Progression. Nothing here says whether a character can take it.")
    end

    local q = questieLists(questie)

    -- Quantities ----------------------------------------------------------
    local counted = {}
    for _, t in ipairs(server.npcOrGo) do if t.count > 0 then counted[#counted + 1] = t end end
    for _, t in ipairs(server.items) do if t.count > 0 then counted[#counted + 1] = t end end
    if #counted > 0 then
        finding(out, qid, "quantity", C.EXPECTED, { "E-QTY" },
            "Server requires counts for " .. #counted .. " objective(s). Questie stores targets only; the quest log supplies counts.")
    end

    -- Creatures and gameobjects --------------------------------------------
    local unmatchedNpc, matchedCreatureOrder, matchedObjectOrder = {}, {}, {}
    local sawObjectBeforeCreature, seenObject = false, false
    for _, t in ipairs(server.npcOrGo) do
        if t.id < 0 then
            seenObject = true
            local go = -t.id
            local pos = indexOf(q.objects, go)
            if pos then
                matchedObjectOrder[#matchedObjectOrder + 1] = pos
                finding(out, qid, "object", C.EXPECTED, { "E-GO-SIGN" },
                    "Server slot " .. t.slot .. " is gameobject " .. go .. " (stored as " .. t.id .. "). Questie lists object " .. go .. ".",
                    t.id, go)
            elseif indexOf(q.creatures, go) then
                finding(out, qid, "object", C.REVIEW, { "R-GO-AS-NPC" },
                    "Server slot " .. t.slot .. " is gameobject " .. go .. ", but Questie lists " .. go .. " as a creature objective.",
                    t.id, go)
            elseif server.scriptedCredit then
                finding(out, qid, "object", C.UNSUPPORTED, { "C-SCRIPT" },
                    "Gameobject " .. go .. " is not in Questie and credit is scripted on the server.", t.id, nil)
            else
                finding(out, qid, "object", C.REVIEW, { "R-GO-UNPAIRED" },
                    "Server gameobject " .. go .. " (slot " .. t.slot .. ") has no Questie object objective" ..
                    (q.hasAltObjective and "; Questie has spell/event/extra objectives that may model it." or "."), t.id, nil)
            end
        else
            if seenObject then sawObjectBeforeCreature = true end
            local pos = indexOf(q.creatures, t.id)
            if pos then
                matchedCreatureOrder[#matchedCreatureOrder + 1] = pos
            elseif q.killCredit[t.id] then
                finding(out, qid, "creature", C.EXPECTED, { "E-KILLCREDIT" },
                    "Server creature " .. t.id .. " (slot " .. t.slot .. ") is covered by a Questie kill-credit objective.", t.id, t.id)
            else
                unmatchedNpc[#unmatchedNpc + 1] = t
            end
        end
    end

    -- Questie creatures not matched directly or by kill credit
    local serverCreature = {}
    for _, t in ipairs(server.npcOrGo) do
        -- A gameobject id that Questie lists as a creature is already reported (R-GO-AS-NPC).
        serverCreature[math.abs(t.id)] = true
    end
    local extraCreatures = {}
    for _, id in ipairs(q.creatures) do
        if not serverCreature[id] then extraCreatures[#extraCreatures + 1] = id end
    end

    -- Resolve unmatched server creatures through creature_template KillCredit
    local stillUnmatched = {}
    for _, t in ipairs(unmatchedNpc) do
        local via
        for i, id in ipairs(extraCreatures) do
            local credits = server.killCredit[id]
            if credits and (credits[1] == t.id or credits[2] == t.id) then via = i break end
        end
        if via then
            local creature = table.remove(extraCreatures, via)
            finding(out, qid, "creature", C.EXPECTED, { "E-KC-TEMPLATE" },
                "Questie creature " .. creature .. " gives kill credit for server target " .. t.id .. " (creature_template KillCredit).",
                t.id, creature)
        else
            stillUnmatched[#stillUnmatched + 1] = t
        end
    end
    for i, t in ipairs(stillUnmatched) do
        local other = extraCreatures[i]
        if server.scriptedCredit then
            finding(out, qid, "creature", C.UNSUPPORTED, { "C-SCRIPT" },
                "Server creature " .. t.id .. " is credited by a script. Questie's " .. tostring(other) .. " cannot be checked offline.",
                t.id, other)
        elseif other and server.killCreditComplete then
            finding(out, qid, "creature", C.CONFIRMED, { "M-NPC-TARGET" },
                "Server requires creature " .. t.id .. " (slot " .. t.slot .. "); Questie lists creature " .. other ..
                ". KillCredit data was supplied and does not link them.", t.id, other)
        elseif other then
            finding(out, qid, "creature", C.REVIEW, { "R-NPC-NOCREDIT" },
                "Server requires creature " .. t.id .. "; Questie lists creature " .. other .. ". Supply creature_template KillCredit1/2 to decide.",
                t.id, other)
        else
            finding(out, qid, "creature", C.REVIEW, { "R-NPC-UNPAIRED" },
                "Server creature " .. t.id .. " (slot " .. t.slot .. ") has no Questie creature or kill-credit objective.", t.id, nil)
        end
    end
    for i = #stillUnmatched + 1, #extraCreatures do
        finding(out, qid, "creature", C.REVIEW, { "R-NPC-UNPAIRED" },
            "Questie creature objective " .. extraCreatures[i] .. " is not a server RequiredNpcOrGo target.", nil, extraCreatures[i])
    end

    -- Items -------------------------------------------------------------------
    local serverItem, dropSet = {}, {}
    for _, t in ipairs(server.items) do serverItem[t.id] = true end
    for _, id in ipairs(server.itemDrops) do dropSet[id] = true end
    local unmatchedItems, matchedItemOrder = {}, {}
    for _, t in ipairs(server.items) do
        local pos = indexOf(q.items, t.id)
        if pos then
            matchedItemOrder[#matchedItemOrder + 1] = pos
        elseif t.id == server.startItem and q.sourceItems[t.id] then
            finding(out, qid, "item", C.EXPECTED, { "E-STARTITEM" },
                "Required item " .. t.id .. " is the StartItem; Questie stores it as " .. q.sourceItems[t.id] .. ".", t.id, t.id)
        elseif q.sourceItems[t.id] then
            finding(out, qid, "item", C.REVIEW, { "R-ITEM-UNPAIRED" },
                "Required item " .. t.id .. " is only in Questie's " .. q.sourceItems[t.id] .. ", not an item objective.", t.id, t.id)
        else
            unmatchedItems[#unmatchedItems + 1] = t
        end
    end
    local extraItems = {}
    for _, id in ipairs(q.items) do
        if not serverItem[id] then
            if dropSet[id] or id == server.startItem then
                finding(out, qid, "item", C.REVIEW, { "R-SRC-AS-OBJECTIVE" },
                    "Questie item objective " .. id .. " is a server " .. (dropSet[id] and "ItemDrop" or "StartItem") ..
                    " source item, not a required item.", nil, id)
            else
                extraItems[#extraItems + 1] = id
            end
        end
    end
    for _, id in ipairs(server.itemDrops) do
        if not serverItem[id] and not indexOf(q.items, id) then
            finding(out, qid, "item", C.EXPECTED, { "E-SRCITEM" },
                "ItemDrop " .. id .. " is a source item. Questie " ..
                (q.sourceItems[id] and ("lists it in " .. q.sourceItems[id]) or "does not list it") .. ".", id, q.sourceItems[id] and id or nil)
        end
    end
    if #unmatchedItems == #extraItems and #extraItems > 0 then
        for i, t in ipairs(unmatchedItems) do
            finding(out, qid, "item", C.CONFIRMED, { "M-ITEM-TARGET" },
                "Server requires item " .. t.id .. " (RequiredItemId" .. t.slot .. "); Questie's item objective is " .. extraItems[i] ..
                ". No representation rule explains the difference.", t.id, extraItems[i])
        end
    else
        for _, t in ipairs(unmatchedItems) do
            finding(out, qid, "item", C.REVIEW, { "R-ITEM-UNPAIRED" },
                "Server requires item " .. t.id .. " (RequiredItemId" .. t.slot .. ") but Questie has no matching item objective.", t.id, nil)
        end
        for _, id in ipairs(extraItems) do
            finding(out, qid, "item", C.REVIEW, { "R-ITEM-UNPAIRED" },
                "Questie item objective " .. id .. " is not a server RequiredItemId.", nil, id)
        end
    end

    -- Ordering ------------------------------------------------------------------
    local function increasing(list)
        for i = 2, #list do if list[i] < list[i - 1] then return false end end
        return true
    end
    if not increasing(matchedCreatureOrder) or not increasing(matchedObjectOrder) or not increasing(matchedItemOrder) then
        finding(out, qid, "order", C.REVIEW, { "R-ORDER-WITHIN-TYPE" },
            "Targets of the same type are ordered differently on the server and in Questie.")
    end
    if sawObjectBeforeCreature then
        finding(out, qid, "order", C.REVIEW, { "R-ORDER-MIXED" },
            "Server lists a gameobject before a creature; Questie's creature-first order may not match quest-log indexes.")
    elseif #server.npcOrGo > 0 and #server.items > 0 then
        finding(out, qid, "order", C.EXPECTED, { "E-ORDER-TYPE" },
            "Creature/object slots precede item slots on both sides.")
    end
    return out
end

-- Highest-priority class for a set of findings (for summaries).
local priority = { [C.CONFIRMED] = 4, [C.REVIEW] = 3, [C.UNSUPPORTED] = 2, [C.EXPECTED] = 1 }
function M.Worst(findings)
    local worst
    for _, f in ipairs(findings) do
        if not worst or priority[f.class] > priority[worst] then worst = f.class end
    end
    return worst or "CONSISTENT"
end

function M.Format(f)
    local rules = #f.rules > 0 and (" [" .. table.concat(f.rules, ",") .. "]") or ""
    return string.format("quest %s %-8s %-28s%s %s", tostring(f.questId), f.kind, f.class, rules, f.explanation)
end

return M
