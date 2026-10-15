-- DRAFT wrapper, kept for the design tests and history. The validator itself
-- was promoted to tools/validation/EffectiveSchemaV2.lua in Stage A2; this
-- file only adds the original draft guard: every entry point (except the
-- pure ExpectedM1 rule) refuses to run unless opts.allowDraft == true.
-- Lua 5.1 compatible. Pure: no I/O.

local P = dofile("tools/validation/EffectiveSchemaV2.lua")

local M = {}
for k, v in pairs(P) do M[k] = v end
M.DRAFT = true

local function guard(opts)
    if not (type(opts) == "table" and opts.allowDraft == true) then
        error("EffectiveSchemaV2Draft is a DRAFT prototype; pass { allowDraft = true } (tests only)", 3)
    end
end

function M.ValidateQuest(q, opts) guard(opts) return P.ValidateQuest(q, opts) end
function M.Validate(doc, opts) guard(opts) return P.Validate(doc, opts) end
function M.ValidateAnyVersion(doc, opts) guard(opts) return P.ValidateAnyVersion(doc, opts) end
function M.MigrateV1(doc, opts) guard(opts) return P.MigrateV1(doc, opts) end
function M.DowngradeToV1(doc, opts) guard(opts) return P.DowngradeToV1(doc, opts) end
function M.CheckPairing(a, b, opts) guard(opts) return P.CheckPairing(a, b, opts) end
function M.CheckServerDocument(doc, opts) guard(opts) return P.CheckServerDocument(doc, opts) end
function M.Canonical(doc, exclude, opts)
    guard(opts)
    local ok, res = pcall(P.Canonical, doc, exclude, opts)
    if not ok then error(res, 2) end
    return res
end

return M
