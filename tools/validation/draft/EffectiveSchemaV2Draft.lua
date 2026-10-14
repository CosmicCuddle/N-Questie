-- DRAFT ONLY. NOT FOR PRODUCTION. NOT USED BY ANY EXPORTER OR HARNESS.
--
-- Prototype validator for the proposed nq-m2-effective v2 record shape
-- (docs/NQ-VALIDATION-M2-EFFECTIVE-V2-DESIGN.md). It exists only to check that
-- the synthetic v2 fixtures are internally consistent and that the design's
-- versioning rules are implementable. v1 (EffectiveSchema.lua) is FROZEN and
-- untouched; nothing here changes how v1 files are read or written.
--
-- Every entry point refuses to run unless opts.allowDraft == true.
-- Lua 5.1 compatible. Pure: no I/O.

local V1 = dofile("tools/validation/EffectiveSchema.lua")

local M = {}
M.DRAFT = true
M.SCHEMA = "nq-m2-effective"
M.SCHEMA_VERSION = 2
M.MAX_ID = 2147483647

local function isInt(v) return type(v) == "number" and v == math.floor(v) and v == v end
local function posId(v) return isInt(v) and v >= 1 and v <= M.MAX_ID end

-- Ordinary objective kinds, in Questie's ObjectiveData order
-- (QuestieDB.GetQuest: monster, object, item, reputation, killcredit, spell).
M.KINDS = { creature = 1, object = 2, item = 3, reputation = 4, killCredit = 5, spell = 6 }
M.EXTRA_REF_TYPES = { monster = true, object = true, item = true }
-- Kinds and features the current M1 rules can interpret.
M.M1_KINDS = { creature = true, object = true, item = true, killCredit = true, spell = true }
-- Static, per record: can the current M1 rules evaluate this content at all?
-- (NEEDS_MANUAL_REVIEW is NOT a record status: it is an M2.3 comparison
-- outcome when rules ran but evidence was incomplete. See the design doc.)
M.M1_STATUS = { SUPPORTED = true, UNSUPPORTED_BY_RULES = true }
-- v2 is a structural objective schema. Display text and exact custom spawn
-- coordinates are deliberately NOT exported; this marker makes that explicit
-- so an omission is never read as "no marker data exists".
M.DISPLAY_SCOPE = "structural-only"

local QUEST_KEYS = { ID = 1, requiredLevel = 1, questLevel = 1, sourceItemId = 1, requiredSourceItems = 1,
    objectives = 1, killCreditFirst = 1, hasTriggerEnd = 1, extraObjectives = 1, m1Status = 1, m1Reasons = 1 }
local OBJ_KEYS = { position = 1, kind = 1, slotIndex = 1, id = 1, occurrence = 1, ids = 1, rootId = 1,
    factionId = 1, requiredValue = 1, itemSourceId = 1 }
local EXTRA_KEYS = { position = 1, icon = 1, hasText = 1, spawnZones = 1, objectiveIndex = 1, refs = 1 }

local function isList(t)
    if type(t) ~= "table" then return false end
    local n = 0
    for k in pairs(t) do n = n + 1; if not (isInt(k) and k >= 1) then return false end end
    return n == #t
end

local function guard(opts)
    if not (type(opts) == "table" and opts.allowDraft == true) then
        error("EffectiveSchemaV2Draft is a DRAFT prototype; pass { allowDraft = true } (tests only)", 3)
    end
end

-- Expected M1 status of a record under the design's rule.
function M.ExpectedM1(q)
    local reasons, seen = {}, {}
    local function add(r) if not seen[r] then seen[r] = true; reasons[#reasons + 1] = r end end
    for _, o in ipairs(q.objectives or {}) do
        if o.kind == "reputation" then add("REPUTATION_OBJECTIVE") end
        if (o.occurrence or 1) > 1 then
            add(o.kind == "creature" and "DUPLICATE_CREATURE" or o.kind == "object" and "DUPLICATE_OBJECT" or "DUPLICATE_OTHER")
        end
    end
    for _, e in ipairs(q.extraObjectives or {}) do
        for _, r in ipairs(e.refs or {}) do
            if r.type == "monster" then add("EXTRA_CREATURE_REF") elseif r.type == "object" then add("EXTRA_OBJECT_REF") end
        end
    end
    table.sort(reasons)
    -- killCreditFirst content is representable in v2 but the M1 rules have no
    -- quest-log position semantics, so it is not M1-evaluable either.
    if q.killCreditFirst then add("KILLCREDIT_FIRST_REORDER"); table.sort(reasons) end
    return (#reasons == 0) and "SUPPORTED" or "UNSUPPORTED_BY_RULES", reasons
end

local function checkQuest(q, w, err)
    if type(q) ~= "table" then err(w .. ": not a table") return end
    for k in pairs(q) do if not QUEST_KEYS[k] then err(w .. "." .. tostring(k) .. ": unknown field") end end
    if not posId(q.ID) then err(w .. ".ID: positive integer required") end
    if not (isInt(q.requiredLevel) and q.requiredLevel >= 0 and q.requiredLevel <= 255) then err(w .. ".requiredLevel") end
    if not (isInt(q.questLevel) and q.questLevel >= -1 and q.questLevel <= 255) then err(w .. ".questLevel") end
    if not (isInt(q.sourceItemId) and q.sourceItemId >= 0) then err(w .. ".sourceItemId") end
    if not isList(q.requiredSourceItems) then err(w .. ".requiredSourceItems: list required")
    else for i, v in ipairs(q.requiredSourceItems) do if not posId(v) then err(w .. ".requiredSourceItems[" .. i .. "]") end end end
    for _, b in ipairs({ "killCreditFirst", "hasTriggerEnd" }) do
        if type(q[b]) ~= "boolean" then err(w .. "." .. b .. ": boolean required") end
    end

    local objs = q.objectives
    if not isList(objs) then err(w .. ".objectives: list required") objs = {} end
    local occ, slotCount, slotSeen = {}, {}, {}
    for i, o in ipairs(objs) do
        local ow = w .. ".objectives[" .. i .. "]"
        if type(o) ~= "table" then err(ow .. ": not a table")
        else
            for k in pairs(o) do if not OBJ_KEYS[k] then err(ow .. "." .. tostring(k) .. ": unknown field") end end
            if o.position ~= i then err(ow .. ".position: must equal list position " .. i) end
            local kind = M.KINDS[o.kind]
            if not kind then err(ow .. ".kind: unknown kind " .. tostring(o.kind))
            else
                slotCount[o.kind] = (slotCount[o.kind] or 0) + 1
                slotSeen[o.kind] = slotSeen[o.kind] or {}
                if not isInt(o.slotIndex) or o.slotIndex < 1 or slotSeen[o.kind][o.slotIndex] then
                    err(ow .. ".slotIndex: unique positive index within the compiled slot required")
                else slotSeen[o.kind][o.slotIndex] = true end
                local function only(allowed)
                    for k in pairs(o) do
                        if not (k == "position" or k == "kind" or k == "slotIndex" or allowed[k]) then
                            err(ow .. "." .. k .. ": not allowed for kind " .. o.kind)
                        end
                    end
                end
                if o.kind == "reputation" then
                    only({ factionId = 1, requiredValue = 1 })
                    if not posId(o.factionId) then err(ow .. ".factionId: positive integer required") end
                    -- Every real reputation objective is a {factionId, value} pair;
                    -- 22 have value 0, which must stay 0 (never dropped or defaulted).
                    if not isInt(o.requiredValue) then err(ow .. ".requiredValue: integer required (0 is a real value)") end
                    if slotCount.reputation > 1 then err(ow .. ": at most one reputation objective (objectives[4] is a single pair)") end
                elseif o.kind == "killCredit" then
                    only({ ids = 1, rootId = 1 })
                    if not (isList(o.ids) and #o.ids > 0) then err(ow .. ".ids: non-empty list required")
                    else for j, v in ipairs(o.ids) do if not posId(v) then err(ow .. ".ids[" .. j .. "]") end end end
                    if not posId(o.rootId) then err(ow .. ".rootId") end
                else
                    only({ id = 1, occurrence = 1, itemSourceId = (o.kind == "spell") and 1 or nil })
                    if not posId(o.id) then err(ow .. ".id: positive integer required") end
                    local key = o.kind .. ":" .. tostring(o.id)
                    occ[key] = (occ[key] or 0) + 1
                    if o.occurrence ~= occ[key] then
                        err(ow .. ".occurrence: must be " .. occ[key] .. " (duplicates are kept and numbered)")
                    end
                    if o.itemSourceId ~= nil and not posId(o.itemSourceId) then err(ow .. ".itemSourceId") end
                end
            end
        end
    end

    -- Questie ObjectiveData order (QuestieDB.GetQuest): kinds ascend, entries
    -- in compiled slot order; with killCreditFirst every killCredit entry is
    -- inserted at position 1, so killCredit comes first in REVERSE slot order.
    for kind, seen in pairs(slotSeen) do
        for i = 1, slotCount[kind] do if not seen[i] then err(w .. ".objectives: " .. kind .. " slotIndex values must be 1.." .. slotCount[kind]) break end end
    end
    local function key(o)
        local rank = M.KINDS[o.kind] or 99
        local si = isInt(o.slotIndex) and o.slotIndex or 0
        if o.kind == "killCredit" and q.killCreditFirst then return 0, -si end
        return rank, si
    end
    for i = 2, #objs do
        local a, b = objs[i - 1], objs[i]
        if type(a) == "table" and type(b) == "table" then
            local ra, sa = key(a); local rb, sb = key(b)
            if ra > rb or (ra == rb and sa > sb) then err(w .. ".objectives[" .. i .. "]: out of Questie objective order") end
        end
    end

    local extras = q.extraObjectives
    if not isList(extras) then err(w .. ".extraObjectives: list required") extras = {} end
    for i, e in ipairs(extras) do
        local ew = w .. ".extraObjectives[" .. i .. "]"
        if type(e) ~= "table" then err(ew .. ": not a table")
        else
            for k in pairs(e) do if not EXTRA_KEYS[k] then err(ew .. "." .. tostring(k) .. ": unknown field") end end
            if e.position ~= i then err(ew .. ".position: must equal list position " .. i) end
            if not (isInt(e.icon) and e.icon >= 1 and e.icon <= 16) then err(ew .. ".icon: Questie icon type 1-16 required") end
            if type(e.hasText) ~= "boolean" then err(ew .. ".hasText: boolean required") end
            if not isList(e.spawnZones) then err(ew .. ".spawnZones: list required (may be empty)")
            else for j, z in ipairs(e.spawnZones) do if not isInt(z) then err(ew .. ".spawnZones[" .. j .. "]") end end end
            -- Questie data always carries [4]: 0 = not linked (696 real entries), n = linked to objective n.
            if not (isInt(e.objectiveIndex) and e.objectiveIndex >= 0) then
                err(ew .. ".objectiveIndex: integer >= 0 required (0 = not linked to an ordinary objective)")
            elseif e.objectiveIndex > #objs then
                err(ew .. ".objectiveIndex: points past the ordinary objectives")
            end
            if not isList(e.refs) then err(ew .. ".refs: list required (may be empty)")
            else
                for j, r in ipairs(e.refs) do
                    local rw = ew .. ".refs[" .. j .. "]"
                    if type(r) ~= "table" then err(rw .. ": not a table")
                    else
                        for k in pairs(r) do if k ~= "type" and k ~= "id" and k ~= "refIndex" then err(rw .. "." .. tostring(k) .. ": unknown field") end end
                        if not M.EXTRA_REF_TYPES[r.type] then err(rw .. ".type: monster, object or item required") end
                        if not posId(r.id) then err(rw .. ".id") end
                        if r.refIndex ~= j then err(rw .. ".refIndex: must be " .. j) end
                    end
                end
            end
            if #(e.refs or {}) == 0 and #(e.spawnZones or {}) == 0 then err(ew .. ": neither refs nor spawns") end
        end
    end

    if not M.M1_STATUS[q.m1Status] then err(w .. ".m1Status: SUPPORTED or UNSUPPORTED_BY_RULES required") end
    if not isList(q.m1Reasons) then err(w .. ".m1Reasons: list required")
    else
        local want, wr = M.ExpectedM1(q)
        if q.m1Status ~= want or table.concat(q.m1Reasons, "+") ~= table.concat(wr, "+") then
            err(w .. ".m1Status/m1Reasons: must be " .. want .. " [" .. table.concat(wr, "+") .. "] (no false SUPPORTED)")
        end
    end
end

-- Provenance: identical fields and rules to v1 (reused, not duplicated).
local function checkProvenance(p, err)
    local stub = { schema = V1.SCHEMA, schemaVersion = V1.SCHEMA_VERSION, provenance = {}, quests = { {
        ID = 1, requiredLevel = 1, questLevel = 1, sourceItemId = 0, requiredSourceItems = {},
        objectives = { creatures = {}, objects = {}, items = {}, killCredit = {}, spells = {} },
        hasTriggerEnd = false, hasExtraObjectives = false, extraObjectiveItems = {} } } }
    if type(p) ~= "table" then err("provenance: missing") return end
    for k, v in pairs(p) do stub.provenance[k] = v end
    stub.provenance.questCount = 1
    local ok, errs = V1.Validate(stub)
    if not ok then for _, e in ipairs(errs) do if e:find("^provenance") then err(e) end end end
end

function M.Validate(doc, opts)
    guard(opts)
    local errors = {}
    local function err(m) errors[#errors + 1] = m end
    if type(doc) ~= "table" then return false, { "input: top level must be a table" } end
    for k in pairs(doc) do
        if k ~= "schema" and k ~= "schemaVersion" and k ~= "provenance" and k ~= "quests" and k ~= "displayScope" then
            err("input." .. tostring(k) .. ": unknown field")
        end
    end
    if doc.displayScope ~= M.DISPLAY_SCOPE then
        err("displayScope: must be \"" .. M.DISPLAY_SCOPE .. "\" (display text and exact spawn coordinates are intentionally not exported)")
    end
    if doc.schema ~= M.SCHEMA then err("schema") end
    if doc.schemaVersion ~= 2 then err("schemaVersion: this draft validator accepts only 2") end
    checkProvenance(doc.provenance, err)
    if not (isList(doc.quests) and #doc.quests > 0) then err("quests: non-empty list required")
    else
        local seen = {}
        for i, q in ipairs(doc.quests) do
            checkQuest(q, "quests[" .. i .. "]", err)
            if type(q) == "table" and isInt(q.ID) then
                if seen[q.ID] then err("quests[" .. i .. "]: duplicate quest ID " .. q.ID) end
                seen[q.ID] = true
            end
        end
        if type(doc.provenance) == "table" and doc.provenance.questCount ~= #doc.quests then err("provenance.questCount") end
    end
    if #errors > 0 then return false, errors end
    return true
end

-- Version dispatch: v1 -> frozen v1 validator (unchanged); v2 -> this draft;
-- anything else -> rejected.
function M.ValidateAnyVersion(doc, opts)
    guard(opts)
    local v = type(doc) == "table" and doc.schemaVersion or nil
    if v == 1 then return V1.Validate(doc, opts.v1opts) end
    if v == 2 then return M.Validate(doc, opts) end
    return false, { "schemaVersion: unknown version " .. tostring(v) .. " (known: 1, 2-draft)" }
end

-- v1 -> v2 migration. Lossless for what v1 holds. Facts v1 never recorded are
-- NOT guessed: killCreditFirst is unknown in v1, and v1 extraObjectives only
-- list item references without icon/index, so a v1 record that has extra
-- objectives is refused for migration (re-export from the harness instead).
function M.MigrateV1(doc, opts)
    guard(opts)
    local ok, errs = V1.Validate(doc)
    if not ok then return nil, errs end
    local out = { schema = M.SCHEMA, schemaVersion = 2, displayScope = M.DISPLAY_SCOPE, provenance = {}, quests = {} }
    for k, v in pairs(doc.provenance) do out.provenance[k] = v end
    local refused = {}
    for _, q in ipairs(doc.quests) do
        if q.hasExtraObjectives then
            refused[#refused + 1] = "quest " .. q.ID .. ": v1 extraObjectives lack icon/index; re-export as v2 (not guessed)"
        elseif #q.objectives.killCredit > 0 and (#q.objectives.creatures + #q.objectives.objects + #q.objectives.items
            + #q.objectives.spells) > 0 then
            refused[#refused + 1] = "quest " .. q.ID .. ": killCredit position relative to other objectives unknown in v1; re-export as v2"
        else
            local objs = {}
            local function add(kind, id, extra)
                local slot = 0
                for _, o in ipairs(objs) do if o.kind == kind then slot = slot + 1 end end
                local o = { position = #objs + 1, kind = kind, slotIndex = slot + 1 }
                if extra then for k, v in pairs(extra) do o[k] = v end else o.id = id; o.occurrence = 1 end
                objs[#objs + 1] = o
            end
            for _, id in ipairs(q.objectives.creatures) do add("creature", id) end
            for _, id in ipairs(q.objectives.objects) do add("object", id) end
            for _, id in ipairs(q.objectives.items) do add("item", id) end
            for _, kc in ipairs(q.objectives.killCredit) do add("killCredit", nil, { ids = kc.ids, rootId = kc.rootId }) end
            for _, id in ipairs(q.objectives.spells) do add("spell", id) end
            local rsi = {}
            for i, v in ipairs(q.requiredSourceItems) do rsi[i] = v end
            local nq = { ID = q.ID, requiredLevel = q.requiredLevel, questLevel = q.questLevel, sourceItemId = q.sourceItemId,
                requiredSourceItems = rsi, objectives = objs, killCreditFirst = false, hasTriggerEnd = q.hasTriggerEnd,
                extraObjectives = {} }
            nq.m1Status, nq.m1Reasons = M.ExpectedM1(nq)
            out.quests[#out.quests + 1] = nq
        end
    end
    if #refused > 0 then return nil, refused end
    out.provenance.questCount = #out.quests
    return out
end

-- v2 -> v1 downgrade is never done by discarding data. This draft refuses
-- every downgrade; a future version may allow it only when lossless.
function M.DowngradeToV1(_, opts)
    guard(opts)
    return nil, { "downgrade v2 -> v1 refused: v1 cannot hold v2 content and data is never discarded" }
end

-- Provenance pairing (DRAFT). An effective export and its companion coverage
-- manifest must come from the same checkout and corrections. The private
-- server document is validated on its own terms and is never compared with a
-- Questie git commit.
M.PAIR_FIELDS = { "sourceCommit", "sourceTree", "nQuestieDataRevision", "correctionCount",
    "correctionFingerprint", "tocInterface", "flavour", "harness", "harnessVersion" }

local function sameList(a, b)
    if type(a) ~= "table" or type(b) ~= "table" or #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

function M.CheckPairing(effectiveProv, coverageProv, opts)
    guard(opts)
    local errs = {}
    if type(effectiveProv) ~= "table" or type(coverageProv) ~= "table" then return false, { "pairing: both provenance records required" } end
    if effectiveProv.dataKind ~= "effective" then errs[#errs + 1] = "pairing: effective export must have dataKind \"effective\"" end
    if effectiveProv.sourceDirty ~= false or coverageProv.sourceDirty ~= false then errs[#errs + 1] = "pairing: dirty checkout" end
    for _, f in ipairs(M.PAIR_FIELDS) do
        if effectiveProv[f] == nil or effectiveProv[f] ~= coverageProv[f] then
            errs[#errs + 1] = "pairing: " .. f .. " differs or is missing (" .. tostring(effectiveProv[f]) .. " vs " .. tostring(coverageProv[f]) .. ")"
        end
    end
    if not sameList(effectiveProv.correctionModules, coverageProv.correctionModules) then
        errs[#errs + 1] = "pairing: correctionModules differ"
    end
    if #errs > 0 then return false, errs end
    return true
end

-- Server provenance: own checks only (nq-m2-input v1 rules), plus a guard that
-- nobody tries to match it to a git commit.
function M.CheckServerProvenance(serverProv, opts)
    guard(opts)
    local Input = dofile("tools/validation/InputSchema.lua")
    local errs = {}
    if type(serverProv) ~= "table" then return false, { "server provenance missing" } end
    for k in pairs(serverProv) do
        if not Input.PROVENANCE_FIELDS[k] then errs[#errs + 1] = "server provenance." .. tostring(k) .. ": unknown field" end
    end
    if serverProv.sourceCommit ~= nil or serverProv.sourceTree ~= nil then
        errs[#errs + 1] = "server provenance must not carry a git commit/tree (it is a private archive, identified by sourceFingerprint)"
    end
    if type(serverProv.sourceFingerprint) ~= "string" or not serverProv.sourceFingerprint:match("^sha256:" .. string.rep("[0-9a-f]", 64) .. "$") then
        errs[#errs + 1] = "server provenance.sourceFingerprint: sha256:<64 hex> required"
    end
    if serverProv.selection ~= "explicit" then errs[#errs + 1] = "server provenance.selection: must be \"explicit\"" end
    if #errs > 0 then return false, errs end
    return true
end

return M
