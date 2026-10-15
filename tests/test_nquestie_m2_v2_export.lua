-- Stage A2: v2 serialiser and export pipeline (synthetic data only).
-- Writes only into private temporary directories made with mktemp -d (0700)
-- and removes them. Linux + GNU coreutils. Lua 5.1.
local V2 = dofile("tools/validation/EffectiveExportV2.lua")
local X = dofile("tools/validation/ExportV2.lua")
local Schema = dofile("tools/validation/EffectiveSchemaV2.lua")
local Input = dofile("tools/validation/InputSchema.lua")
local S = dofile("tests/fixtures/m2_v2_builder/compiled_synthetic.lua")
local n, fails = 0, 0
local function ok(c, m) n = n + 1; if not c then fails = fails + 1; print("FAIL: " .. m) end end
local function sh(cmd) local r = os.execute(cmd .. " >/dev/null 2>&1"); return r == 0 or r == true end
local function cap(cmd) local h = io.popen(cmd .. " 2>/dev/null"); local s = h:read("*a"); h:close(); return (s:gsub("\n$", "")) end
local function q(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
local function copy(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = copy(v) end return o end
local function readAll(p) local f = io.open(p, "rb"); if not f then return nil end local s = f:read("*a"); f:close(); return s end
local function listDir(d) return cap("ls -A " .. q(d)) end
local function has(errs, s) for _, e in ipairs(errs or {}) do if tostring(e):find(s, 1, true) then return true end end return false end

local ROOT = cap("pwd -P")
local TMP = {}
local function tmpdir() local d = cap("mktemp -d"); sh("chmod 700 " .. q(d)); TMP[#TMP + 1] = d; return d end

local Q = function(id, key) return S.quests[id] and S.quests[id][key] end
local CTX = { killCreditFirst = S.killCreditFirst }
local IDS = {}
for id in pairs(S.quests) do IDS[#IDS + 1] = id end
table.sort(IDS)
-- Synthetic provenance with every field the frozen v1 provenance rules need.
local PROV = { harness = "validate-335", harnessVersion = "1.3.0", dataKind = "effective", flavour = "wotlk-335",
    tocInterface = 30300, sourceCommit = string.rep("a", 40), sourceTree = string.rep("b", 40), sourceDirty = false,
    nQuestieDataRevision = 5, correctionCount = 28, correctionModules = { "NQuestieCustomQuestData.lua" },
    correctionFingerprint = "sha256:" .. string.rep("c", 64), m0Checks = 232, exportedAt = "2026-10-15T08:00:00Z" }
local function args(out, extra)
    local a = { query = Q, ids = IDS, ctx = CTX, provenance = copy(PROV), out = out, repoRoot = ROOT,
        expectCorrectionCount = 28, expectHarnessVersion = "1.3.0" }
    for k, v in pairs(extra or {}) do a[k] = v end
    return a
end

-- ---------------------------------------------------------------- serialiser
local recs = assert(V2.BuildAll(Q, IDS, CTX))
local doc = V2.BuildDocument(recs, PROV)
ok(doc.provenance.questCount == #IDS and doc.provenance ~= PROV and doc.quests[1] ~= recs[1], "BuildDocument deep copies and sets questCount")
ok(PROV.questCount == nil, "BuildDocument does not touch the caller's provenance")
ok(Schema.Validate(doc), "synthetic document valid")
local t1 = V2.Serialise(doc, X.HEADER)
local t2 = V2.Serialise(copy(doc), X.HEADER)
ok(t1 == t2, "serialisation deterministic (independent copies, different table insertion history)")
-- rebuild the same document with reversed insertion order of every table
local function reversed(v)
    if type(v) ~= "table" then return v end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) > tostring(b) end)
    local o = {}
    for _, k in ipairs(keys) do o[k] = reversed(v[k]) end
    return o
end
ok(V2.Serialise(reversed(doc), X.HEADER) == t1, "serialisation independent of key insertion order")
ok(t1:find("\r", 1, true) == nil and t1:sub(-1) == "\n", "\\n line endings only, newline-terminated")
local nl = 0 for _ in t1:gmatch("\n") do nl = nl + 1 end
ok(nl == 3 + 1 + 4 + 1 + #IDS + 2, "fixed layout: 3 header lines, return, 4 top fields, quests open, one line per quest, 2 closing lines")
ok(t1:find('{ID=910001,requiredLevel=20,questLevel=22,sourceItemId=0,requiredSourceItems={},killCreditFirst=false,hasTriggerEnd=true,m1Status=', 1, true),
   "quest fields in the fixed order")
ok(t1:find('{position=1,kind="creature",slotIndex=1,id=101,occurrence=1}', 1, true), "objective fields in the fixed order")
ok(t1:find('refs={{refIndex=1,type="object",id=', 1, true), "ref fields in the fixed order")
local p1 = t1:match("\nprovenance=(%b{})")
ok(p1 and p1:find('^{harness="validate%-335",harnessVersion="1%.3%.0",dataKind="effective",flavour="wotlk%-335",tocInterface=30300,sourceCommit='),
   "provenance fields in the fixed order")
ok(p1 and p1:find('m0Checks=232,questCount=15,exportedAt="2026%-10%-15T08:00:00Z"}$'), "questCount and exportedAt last")
local parsed = Input.ParseString(t1)
ok(parsed and Schema.Validate(parsed), "serialised text parses with the safe literal parser and validates")
ok(parsed and Schema.Canonical(parsed, {}) == Schema.Canonical(doc, {}), "parsed text equals the document (canonical)")
ok(parsed and #parsed.quests[1].requiredSourceItems == 0 and type(parsed.quests[1].extraObjectives) == "table", "empty lists survive")
do
    local r12 = parsed and parsed.quests[12]
    ok(r12 and r12.ID == 910012 and r12.questLevel == -1 and r12.objectives[1].requiredValue == -42000, "negative integers survive")
end

local function serFails(mut, label, want)
    local d = copy(doc); mut(d)
    local okS, e = pcall(V2.Serialise, d)
    ok(not okS and (not want or tostring(e):find(want, 1, true)), "serialiser refuses: " .. label .. " (" .. tostring(e) .. ")")
end
serFails(function(d) d.quests[1].extra = 1 end, "unknown quest field", "no fixed position")
serFails(function(d) d.quests[1].objectives[1].text = "x" end, "unknown objective field (display text)", "no fixed position")
serFails(function(d) d.quests[1].extraObjectives[1].refs[1].x = 1 end, "unknown ref field", "no fixed position")
serFails(function(d) d.provenance.private = "x" end, "unknown provenance field", "no fixed position")
serFails(function(d) d.extra = true end, "unknown top-level field", "no fixed position")
serFails(function(d) d.quests[1].requiredLevel = 1.5 end, "non-integer", "integer required")
serFails(function(d) d.quests[1].requiredLevel = 0 / 0 end, "NaN", "integer required")
serFails(function(d) d.quests[1].requiredLevel = 2 ^ 40 end, "out-of-range integer", "integer required")
serFails(function(d) d.provenance.harness = 'a"b' end, "quote in string", "printable ASCII")
serFails(function(d) d.provenance.harness = "a\nb" end, "newline in string", "printable ASCII")
serFails(function(d) d.provenance.harness = "a\\b" end, "backslash in string", "printable ASCII")
serFails(function(d) d.quests[1].requiredSourceItems = { [1] = 1, [3] = 3 } end, "list with holes", "plain list")
serFails(function(d) d.quests[1].m1Reasons = { a = 1 } end, "map where a list is required", "plain list")
serFails(function(d) d.quests[1].objectives[1] = 5 end, "scalar where a record is required", "table required")
serFails(function(d) d.quests[1].hasTriggerEnd = function() end end, "function value", "unsupported type")
serFails(function(d) d.quests = { [2] = d.quests[1] } end, "quests not a list", "plain list")

-- ---------------------------------------------------------------- pipeline: success
local D = tmpdir()
local okE, info = X.Export(args(D .. "/v2.lua"))
ok(okE, "export succeeds: " .. (okE and "" or table.concat(info, "; ")))
if okE then
    ok(info.final == D .. "/v2.lua" and readAll(info.final) == info.text, "file holds exactly the serialised text")
    ok(info.text == V2.Serialise(V2.BuildDocument(recs, PROV), X.HEADER), "file equals an independent serialisation")
    ok(cap("stat -c %a " .. q(info.final)) == "600", "file mode 0600")
    ok(cap("stat -c %a " .. q(D)) == "700", "directory still 0700")
    ok(listDir(D) == "v2.lua", "no temporary files left")
    ok(info.aggregate.processed == #IDS and info.aggregate.questsDiffering == 0 and info.aggregate.v1Differing == 0,
       "parsed-text round trip: every quest, 0 differences")
    local d2 = X.ParseAndValidate(readAll(info.final), { expectCorrectionCount = 28, expectHarnessVersion = "1.3.0" })
    ok(d2 and #d2.quests == #IDS, "written file re-reads and validates")
    ok(not X.ParseAndValidate(readAll(info.final), { expectCorrectionCount = 27 }), "re-read refuses a different correction count")
    ok(not X.ParseAndValidate(readAll(info.final), { expectHarnessVersion = "1.2.0" }), "re-read refuses a different harness version")
end
-- determinism across two exports to different directories
local D2 = tmpdir()
local okE2, info2 = X.Export(args(D2 .. "/v2.lua"))
ok(okE and okE2 and info.text == info2.text, "two exports (same provenance) byte-identical")
local okE3, info3 = X.Export(args(tmpdir() .. "/v2.lua", { provenance = (function() local p = copy(PROV); p.exportedAt = "2026-10-15T09:00:00Z"; return p end)() }))
if okE and okE3 then
    local a = Input.ParseString(info.text); local b = Input.ParseString(info3.text)
    ok(info.text ~= info3.text, "different exportedAt gives different bytes (real timestamp kept)")
    ok(Schema.Canonical(a, { "exportedAt" }) == Schema.Canonical(b, { "exportedAt" }), "equal after Canonical excluding only exportedAt")
    ok(info.text:gsub('exportedAt="[^"]*"', "") == info3.text:gsub('exportedAt="[^"]*"', ""), "only the exportedAt value differs in the bytes")
end

-- ---------------------------------------------------------------- pipeline: refusals, nothing left behind
local function refused(label, a, hooks, want, dir)
    local okR, e = X.Export(a, hooks)
    ok(not okR and (not want or has(e, want)), "refused: " .. label .. " (" .. (okR and "succeeded" or table.concat(e, "; ")) .. ")")
    if dir then ok(listDir(dir) == "", "no file left after: " .. label) end
end
local E = tmpdir()
-- existing file: not replaced, content kept
local f = io.open(E .. "/v2.lua", "wb"); f:write("keep"); f:close(); sh("chmod 600 " .. q(E .. "/v2.lua"))
refused("existing output file", args(E .. "/v2.lua"), nil, "exists")
ok(readAll(E .. "/v2.lua") == "keep" and listDir(E) == "v2.lua", "existing file untouched, no temp left")
refused("existing file even if a caller passes force", args(E .. "/v2.lua"), { writeOpts = { force = true } }, "exists")
ok(readAll(E .. "/v2.lua") == "keep", "force is ignored: existing file still untouched")
-- symlink as final path (to a file, and dangling)
local Y = tmpdir()
local tgt = tmpdir() .. "/target"
f = io.open(tgt, "wb"); f:write("target"); f:close()
sh("ln -s " .. q(tgt) .. " " .. q(Y .. "/v2.lua"))
refused("final path is a symlink to a file", args(Y .. "/v2.lua"), nil, "symlink")
ok(readAll(tgt) == "target", "symlink target untouched")
local Y2 = tmpdir()
sh("ln -s " .. q(Y2 .. "/nowhere") .. " " .. q(Y2 .. "/v2.lua"))
refused("final path is a dangling symlink", args(Y2 .. "/v2.lua"), nil, "symlink")
ok(cap("ls -A " .. q(Y2)) == "v2.lua" and not readAll(Y2 .. "/nowhere"), "dangling symlink not followed")
-- unsafe directories
local G = tmpdir(); sh("chmod 755 " .. q(G))
refused("group/other-accessible directory", args(G .. "/v2.lua"), nil, "chmod 700", G)
local R = tmpdir(); sh("chmod 500 " .. q(R))
refused("read-only directory (unwritable)", args(R .. "/v2.lua"), nil, "temporary file", R)
sh("chmod 700 " .. q(R))
refused("relative path", args("v2.lua"), nil, "absolute")
refused("dot-dot path", args(D .. "/../x/v2.lua"), nil, ". or ..")
refused("missing directory", args(D .. "/missing/v2.lua"), nil, "does not exist")
refused("directory inside the public checkout", args(ROOT .. "/tests/v2.lua"), nil, "inside the public checkout")
ok(not readAll(ROOT .. "/tests/v2.lua"), "nothing written into the checkout")
-- malformed / failed validation: no file
local M_ = tmpdir()
refused("malformed record (position wrong)", args(M_ .. "/v2.lua"), { mutateDocument = function(d) d.quests[1].objectives[1].position = 9 end }, "position", M_)
refused("malformed record (reputation value dropped)", args(M_ .. "/v2.lua"), { mutateDocument = function(d)
    for _, qq in ipairs(d.quests) do for _, o in ipairs(qq.objectives) do if o.kind == "reputation" then o.requiredValue = nil end end end end }, nil, M_)
refused("false SUPPORTED", args(M_ .. "/v2.lua"), { mutateDocument = function(d) d.quests[1].m1Status = "SUPPORTED"; d.quests[1].m1Reasons = {} end }, "no false SUPPORTED", M_)
refused("quest dropped from the document", args(M_ .. "/v2.lua"), { mutateDocument = function(d) table.remove(d.quests, 3); d.provenance.questCount = #d.quests end }, "quest", M_)
refused("display text smuggled into a record", args(M_ .. "/v2.lua"), { mutateDocument = function(d) d.quests[2].text = "x" end }, "unknown field", M_)
refused("provenance invalid (dirty)", args(M_ .. "/v2.lua", { provenance = (function() local p = copy(PROV); p.sourceDirty = true; return p end)() }), nil, nil, M_)
refused("serialised text changed (id altered)", args(M_ .. "/v2.lua"), { mutateText = function(t) return (t:gsub("id=101,", "id=1101,", 1)) end }, "differs", M_)
refused("serialised text truncated", args(M_ .. "/v2.lua"), { mutateText = function(t) return t:sub(1, #t - 40) end }, nil, M_)
refused("missing killCreditFirst set", args(M_ .. "/v2.lua", { ctx = { killCreditFirst = {} } }), nil, "killCreditObjectiveFirst", M_)
do local a = args(M_ .. "/v2.lua"); a.ctx = nil; refused("no context", a, nil, "killCreditObjectiveFirst", M_) end
refused("missing provenance", args(M_ .. "/v2.lua", { provenance = false }), nil, "provenance", M_)
local bad = copy(S.quests); bad[910012].objectives[4] = { 1098 }
refused("malformed compiled record (reputation without value)",
    args(M_ .. "/v2.lua", { query = function(id, k) return bad[id] and bad[id][k] end }), nil, nil, M_)
refused("duplicate quest ID requested", args(M_ .. "/v2.lua", { ids = { 910001, 910001 } }), nil, "duplicate", M_)
refused("empty ID list", args(M_ .. "/v2.lua", { ids = {} }), nil, nil, M_)
refused("compiled data changed before writing (preWrite)", args(M_ .. "/v2.lua", { preWrite = function() return false, "changed" end }), nil, "changed", M_)
local okP, eP = pcall(X.Export, args(M_ .. "/v2.lua", { preWrite = function() error("boom") end }))
ok(not okP or not eP, "preWrite raising never yields success")
ok(listDir(M_) == "", "no file after a raising preWrite")
-- SafeWrite failure injection before install: no file, no temp
for _, h in ipairs({ "afterTempCreate", "afterWrite", "beforeInstall" }) do
    refused("SafeWrite failure at " .. h, args(M_ .. "/v2.lua"), { writeOpts = { hooks = { [h] = function() return false end } } }, "simulated", M_)
end
-- re-read mismatch after install: reported, file left for inspection (not deleted)
local W = tmpdir()
local fake = { WriteFile = function(path, _, o)
    ok(o.force == nil, "pipeline never passes force to the writer")
    local ff = io.open(path, "wb"); ff:write("return {}"); ff:close(); return true, path end }
refused("written file differs on re-read", args(W .. "/v2.lua"), { writer = fake }, "left for inspection")
ok(readAll(W .. "/v2.lua") == "return {}", "a file that is not provably ours is not deleted")
local fake2 = { WriteFile = function(path, content) local ff = io.open(path, "wb"); ff:write((content:gsub("schemaVersion=2", "schemaVersion=3"))); ff:close(); return true, path end }
refused("written file fails validation on re-read", args(tmpdir() .. "/v2.lua"), { writer = fake2 }, "left for inspection")
local fake3 = { WriteFile = function() return false, "disk full" end }
refused("writer failure reported", args(tmpdir() .. "/v2.lua"), { writer = fake3 }, "disk full")

-- ---------------------------------------------------------------- docs never claim durability
local src = readAll("tools/validation/ExportV2.lua")
ok(src:find("No fsync is performed", 1, true) and not src:find("fsync()", 1, true), "pipeline documents that it does not fsync")

for _, d in ipairs(TMP) do sh("chmod -R u+rwx " .. q(d) .. " && rm -rf -- " .. q(d)) end
if fails > 0 then print("FAIL: " .. fails .. " of " .. n .. " checks failed"); os.exit(1) end
print("PASS: M2 v2 serialiser and export pipeline (" .. n .. " checks)")
