-- N-Questie nq-m2-effective schema version 2 validator (Stage A2, production).
--
-- Promoted from tools/validation/draft/EffectiveSchemaV2Draft.lua, which now
-- is a thin guarded wrapper around this module for the design tests.
-- Validates the structural v2 record shape (docs/NQ-VALIDATION-M2-EFFECTIVE-
-- V2-DESIGN.md, docs/NQ-VALIDATION-M2-V2-EXPORTER-SPEC.md). v1
-- (EffectiveSchema.lua) is FROZEN and untouched; v1 files are still read and
-- written by the v1 code only.
--
-- Lua 5.1 compatible. Pure: no I/O.

local V1 = dofile("tools/validation/EffectiveSchema.lua")

local M = {}
M.DRAFT = false
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

-- Production module: no draft guard. opts are accepted for call
-- compatibility with the draft wrapper and otherwise ignored.
local function guard(_) end

-- Expected M1 status of a record under the design's rule.
-- M1 classification of a v2 record, in the ESTABLISHED codes of the frozen
-- v1 exporter (EffectiveExport.Record), so the two can be compared code for
-- code (Stage A1 parity). Every v1 refusal a valid v2 record can carry:
--   requiredSourceItems repeated            DUPLICATE_SOURCE_ITEM
--   creature / object / item / spell repeat DUPLICATE_CREATURE/_OBJECT/_ITEM/_SPELL
--   killCredit entry repeating an id        DUPLICATE_KILLCREDIT_ID
--   reputation objective (any value, 0 too) REPUTATION_OBJECTIVE
--   spell objective with itemSourceId       SHAPE_UNUSUAL (v1 has no field for it)
--   extra ref monster / object              EXTRA_CREATURE_REF / EXTRA_OBJECT_REF
--   extra item ref repeated in the quest    DUPLICATE_EXTRA_ITEM
--   killCreditFirst that really reorders    KILLCREDIT_FIRST_REORDER
-- killCreditFirst reorders only when another ordinary objective exists (the
-- killCredit line moves before it) or there are several killCredit entries
-- (they are reversed). One killCredit entry alone is shown where v1 puts it:
-- SUPPORTED, with the v2 flag kept. The repeated killCredit rootId across
-- entries is not a v1 refusal and is not one here. v1 codes that a valid v2
-- record cannot reach (the builder refuses those inputs first):
-- LEVEL_INVALID, SOURCE_ITEM_INVALID, EXTRA_OTHER_REF, the other SHAPE_UNUSUAL
-- cases, and UNCLASSIFIED.
function M.ExpectedM1(q)
    local reasons, seen = {}, {}
    local function add(r) if not seen[r] then seen[r] = true; reasons[#reasons + 1] = r end end
    local DUP = { creature = "DUPLICATE_CREATURE", object = "DUPLICATE_OBJECT", item = "DUPLICATE_ITEM", spell = "DUPLICATE_SPELL" }
    local rs = {}
    for _, v in ipairs(q.requiredSourceItems or {}) do
        if rs[v] then add("DUPLICATE_SOURCE_ITEM") end
        rs[v] = true
    end
    local nKc, nOther = 0, 0
    for _, o in ipairs(q.objectives or {}) do
        if o.kind == "killCredit" then
            nKc = nKc + 1
            local ids = {}
            for _, v in ipairs(o.ids or {}) do
                if ids[v] then add("DUPLICATE_KILLCREDIT_ID") end
                ids[v] = true
            end
        else
            nOther = nOther + 1
            if o.kind == "reputation" then add("REPUTATION_OBJECTIVE") end
            if (o.occurrence or 1) > 1 and DUP[o.kind] then add(DUP[o.kind]) end
            if o.kind == "spell" and o.itemSourceId ~= nil then add("SHAPE_UNUSUAL") end
        end
    end
    local extraItems = {}
    for _, e in ipairs(q.extraObjectives or {}) do
        for _, r in ipairs(e.refs or {}) do
            if r.type == "monster" then add("EXTRA_CREATURE_REF")
            elseif r.type == "object" then add("EXTRA_OBJECT_REF")
            elseif r.type == "item" then
                if extraItems[r.id] then add("DUPLICATE_EXTRA_ITEM") end
                extraItems[r.id] = true
            end
        end
    end
    if q.killCreditFirst and nKc > 0 and (nOther > 0 or nKc > 1) then add("KILLCREDIT_FIRST_REORDER") end
    table.sort(reasons)
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
    -- killCreditFirst = Questie's flag AS IT AFFECTS ORDER: true only when the
    -- quest is flagged AND has at least one killCredit objective.
    if q.killCreditFirst == true then
        local hasKc = false
        for _, o in ipairs(type(q.objectives) == "table" and q.objectives or {}) do
            if type(o) == "table" and o.kind == "killCredit" then hasKc = true end
        end
        if not hasKc then err(w .. ".killCreditFirst: true requires a killCredit objective") end
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
            elseif e.objectiveIndex > #objs + ((#objs == 0 or q.hasTriggerEnd == true) and 1 or 0) then
                -- A quest-log line one past the DB objectives exists only as
                -- the triggerEnd event line or, with no DB objectives, as a
                -- client-only line (Stage A1 measurement: 5 real quests).
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

-- Record-level validation of one quest (used by the Stage A1 round trip,
-- which builds records in memory and has no provenance to validate).
function M.ValidateQuest(q, opts)
    guard(opts)
    local errors = {}
    checkQuest(q, "quest " .. tostring(type(q) == "table" and q.ID or "?"), function(m) errors[#errors + 1] = m end)
    if #errors > 0 then return false, errors end
    return true
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
    if doc.schemaVersion ~= 2 then err("schemaVersion: this validator accepts only 2") end
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

-- Version dispatch: v1 -> frozen v1 validator (unchanged); v2 -> this module;
-- anything else -> rejected.
function M.ValidateAnyVersion(doc, opts)
    guard(opts)
    local v = type(doc) == "table" and doc.schemaVersion or nil
    if v == 1 then return V1.Validate(doc, (opts or {}).v1opts) end
    if v == 2 then return M.Validate(doc, opts) end
    return false, { "schemaVersion: unknown version " .. tostring(v) .. " (known: 1, 2)" }
end

-- v1 -> v2 migration ("v1-held-fields-only"). It never makes a claim v1
-- cannot support: killCreditFirst is emitted as false only for quests with no
-- killCredit entry, where v2 defines the field as false (see Validate).
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
        elseif #q.objectives.killCredit > 0 then
            -- v1 never stored QuestieCorrections.killCreditObjectiveFirst. For a
            -- quest with any killCredit entry the v2 killCreditFirst value (and
            -- with two or more entries, their order) cannot be proven from v1,
            -- whatever exporter version wrote the file. Never inferred.
            refused[#refused + 1] = "quest " .. q.ID .. ": v1 does not record killCreditObjectiveFirst; killCredit order cannot be proven; re-export as v2"
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

-- v2 -> v1 downgrade is never done by discarding data. This module refuses
-- every downgrade; a future version may allow it only when lossless.
function M.DowngradeToV1(_, opts)
    guard(opts)
    return nil, { "downgrade v2 -> v1 refused: v1 cannot hold v2 content and data is never discarded" }
end

-- Provenance pairing (design; used by the M2.3 contract drafts only). An effective export and its companion coverage
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

-- Server document: validated in FULL by the frozen M2.1 validator
-- (InputSchema.Validate: every provenance field, every record) before any
-- provenance is used. There is deliberately no provenance-only entry point,
-- so incomplete server provenance can never reach pairing or comparison.
-- The server sha256 fingerprint is never compared with a git commit/tree.
function M.CheckServerDocument(serverDoc, opts)
    guard(opts)
    local Input = dofile("tools/validation/InputSchema.lua")
    local ok, errs = Input.Validate(serverDoc)
    if not ok then
        local out = { "server document rejected by the M2.1 validator (nothing compared)" }
        for _, e in ipairs(errs) do out[#out + 1] = e end
        return false, out
    end
    return true
end

-- Reproducible comparison form (spec section 8 and F6/F7). Serialises any
-- v1 or v2 document deterministically (sorted keys, integers, no whitespace
-- variation) after removing ONLY the fields named in `exclude`, which must be
-- a subset of the per-run provenance fields below. Production provenance is
-- never changed; this is a test-harness view.
M.RUN_FIELDS = { exportedAt = true, sourceCommit = true, sourceTree = true }
function M.Canonical(doc, exclude, opts)
    guard(opts)
    local skip = {}
    for _, f in ipairs(exclude or {}) do
        if not M.RUN_FIELDS[f] then error("Canonical: may only exclude per-run provenance fields, not " .. tostring(f), 2) end
        skip[f] = true
    end
    local out = {}
    local function emit(v, path)
        local t = type(v)
        if t == "table" then
            local keys = {}
            for k in pairs(v) do keys[#keys + 1] = k end
            table.sort(keys, function(a, b)
                if type(a) == type(b) then return a < b end
                return type(a) == "number"
            end)
            out[#out + 1] = "{"
            for _, k in ipairs(keys) do
                if not (path == "provenance" and skip[k]) then
                    out[#out + 1] = (type(k) == "number" and ("[" .. k .. "]") or k) .. "="
                    emit(v[k], (path == "" and k == "provenance") and "provenance" or "x")
                    out[#out + 1] = ";"
                end
            end
            out[#out + 1] = "}"
        elseif t == "number" then
            if v ~= math.floor(v) then error("Canonical: non-integer number", 2) end
            out[#out + 1] = string.format("%d", v)
        elseif t == "string" then out[#out + 1] = string.format("%q", v)
        elseif t == "boolean" then out[#out + 1] = tostring(v)
        else error("Canonical: unsupported type " .. t, 2) end
    end
    emit(doc, "")
    return table.concat(out)
end

return M
