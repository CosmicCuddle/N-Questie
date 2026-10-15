-- Public/synthetic-only M2.3 Part 1 contract tests. Lua 5.1.
local Status = dofile("tools/validation/StatusCapture.lua")
local Approved = dofile("tools/validation/M23ApprovedExportsParser.lua")
local n, failures = 0, 0
local function ok(value, label)
    n = n + 1
    if not value then
        failures = failures + 1
        io.stderr:write("FAIL: " .. label .. "\n")
    end
end

-- Status checked, NOT inferred from plausible output, with no path disclosure.
local data, rc = Status.Run("printf 'ready'")
ok(data == "ready" and rc == 0, "valid command and raw stdout")
data, rc = Status.Run("printf 'ready\\n'")
ok(data == "ready\n" and rc == 0, "newline content unchanged")
data, rc = Status.Run("sh -c 'printf looks-good; exit 17'")
ok(data == nil and rc == 17, "status 17 beats plausible stdout")
data, rc = Status.Run("sh -c 'exit 17'")
ok(data == nil and rc == 17, "subshell exit retains status marker")
data, rc = Status.Run("false")
ok(data == nil and rc == 1, "ordinary command failure")
data, rc = Status.Run("true")
ok(data == "" and rc == 0, "empty success stdout")
data, rc = Status.Run("printf '__NQ_M23_CAPTURE_STATUS__=0'")
ok(data == nil, "forged marker in stdout refused")
data, rc = Status.Run("printf '\\n__NQ_M23_CAPTURE_STATUS__=0\\n'")
ok(data == nil, "standalone forged marker in stdout refused")
data, rc = Status.Run("sh -c 'printf /very/private/path; exit 17'")
ok(data == nil and rc == 17, "failed command output discarded")
data, rc = Status.Run("")
ok(data == nil, "empty command refused")
data, rc = Status.Run("true\nfalse")
ok(data == nil, "newline command refused")
data, rc = Status.Run(23)
ok(data == nil, "non-string command refused")

-- Never execute the allowlist: read text through the restricted literal parser.
local f = assert(io.open("tools/validation/M23ApprovedExports.lua", "rb"))
local raw = assert(f:read("*a"))
assert(f:close())
local empty, why = Approved.ParseBytes(raw)
ok(empty ~= nil and #empty.entries == 0 and why == nil,
    "real checked-in allowlist has zero entries")
ok(Approved.Validate(empty), "empty allowlist accepted")

-- All of the following approvals are INVENTED IN MEMORY for parser testing;
-- they are not written to the allowlist, repository, or a real data source.
local a, b, c, d = string.rep("a", 40), string.rep("b", 40),
    string.rep("c", 64), string.rep("d", 64)
local record = 'sourceCommit="' .. a .. '", sourceTree="' .. b .. '", '
    .. 'harnessVersion="1.3.0", correctionFingerprint="sha256:' .. c .. '", '
    .. 'correctionCount=28, correctionModules={"NQuestieOne.lua","NQuestieTwo.lua"}, '
    .. 'nQuestieDataRevision=5, tocInterface=30300, flavour="wotlk-335", '
    .. 'harness="validate-335", approvalRef=123, '
    .. 'dataset={questCount=9159,supportedCount=8401,unsupportedCount=758,'
    .. 'idListSha256="' .. d .. '"}'
local valid = 'return {schema="nq-m2-3-approved-exports",schemaVersion=1, entries={{'
    .. record .. '}}}'
local doc, errorCode = Approved.ParseBytes(valid)
ok(doc ~= nil and errorCode == nil and #doc.entries == 1,
    "invented syntactically valid entry accepted by parser")
local function changed(old, replacement)
    local pos = assert(valid:find(old, 1, true), old .. " absent")
    return valid:sub(1, pos - 1) .. replacement .. valid:sub(pos + #old)
end
local function reject(bytes, label)
    local result, err = Approved.ParseBytes(bytes)
    ok(result == nil and err == "REJECTED_ENGINE_CHECKOUT", label)
end
reject(changed('schemaVersion=1', 'schemaVersion=2'), "wrong schema version")
reject(changed('schema="nq-m2-3-approved-exports"', 'schema="wrong"'), "wrong schema")
reject(changed('entries={{', 'unexpected=1,entries={{'), "unknown top key")
reject(changed('sourceCommit="' .. a .. '"', 'sourceCommit="' .. string.rep("A", 40) .. '"'),
    "uppercase source SHA refused")
reject(changed('sourceTree="' .. b .. '"', 'sourceTree="abc"'), "wrong tree length")
reject(changed('harnessVersion="1.3.0"', 'harnessVersion="unknown"'), "harness semver")
reject(changed('correctionFingerprint="sha256:' .. c .. '"',
    'correctionFingerprint="sha256:' .. string.rep("z", 64) .. '"'),
    "malformed fingerprint")
reject(changed('correctionCount=28', 'correctionCount=0'), "zero corrections")
reject(changed('nQuestieDataRevision=5', 'nQuestieDataRevision=0'), "zero revision")
reject(changed('tocInterface=30300', 'tocInterface=30400'), "wrong interface")
reject(changed('flavour="wotlk-335"', 'flavour="wotlk"'), "wrong flavour")
reject(changed('harness="validate-335"', 'harness="other"'), "wrong harness")
reject(changed('approvalRef=123', 'approvalRef=0'), "zero approval PR")
reject(changed('approvalRef=123,', ''), "missing required approval PR")
reject(changed('correctionModules={"NQuestieOne.lua","NQuestieTwo.lua"}',
    'correctionModules={"NQuestieOne.lua","NQuestieOne.lua"}'),
    "duplicate correction module")
reject(changed('correctionModules={"NQuestieOne.lua","NQuestieTwo.lua"}',
    'correctionModules={"../private.lua"}'), "unsafe module name")
reject(changed('correctionModules={"NQuestieOne.lua","NQuestieTwo.lua"}',
    'correctionModules={}'), "missing correction modules")
reject(changed('questCount=9159', 'questCount=9158'), "dataset count mismatch")
reject(changed('idListSha256="' .. d .. '"', 'idListSha256="short"'), "bad dataset SHA")
reject(changed('unsupportedCount=758', 'unsupportedCount=758, secret=12'),
    "unknown dataset key")
reject(changed('sourceTree="' .. b .. '"', 'sourceTree="' .. b .. '", secret="x"'),
    "unknown entry key")
reject(changed('schemaVersion=1', 'schemaVersion=1,schemaVersion=1'),
    "duplicate data literal key")
reject(changed('entries={{', 'entries={[2]={'), "sparse entries")
reject('return os.execute("printf BAD")', "executable source rejected")
reject('return { schema="nq-m2-3-approved-exports", schemaVersion=1, entries=foo }',
    "unresolved symbols rejected")
reject('return {schema="nq-m2-3-approved-exports",schemaVersion=1,entries={{'
    .. record .. '},{' .. record .. '}}}', "duplicate approved commit")
reject('return {schema="nq-m2-3-approved-exports",schemaVersion=1,entries={x=1}}',
    "non-list entries rejected")
reject('return {schema="nq-m2-3-approved-exports",schemaVersion=1,entries=nil}',
    "nil entries rejected")
reject(changed('entries={{', 'entries={[0]={'), "index-zero entries refused")
-- Syntactically valid list with index 1 is allowed, if it is dense.
local dense = 'return {schema="nq-m2-3-approved-exports",schemaVersion=1,'
    .. 'entries={[1]={' .. record .. '}}}'
ok(Approved.ParseBytes(dense) ~= nil, "explicit index-one dense list accepted")
reject(changed('correctionModules={"NQuestieOne.lua","NQuestieTwo.lua"}',
    'correctionModules={[1]="NQuestieOne.lua",[3]="NQuestieTwo.lua"}'),
    "sparse module list")
reject(changed('harnessVersion="1.3.0"', 'harnessVersion="1.3.0",harnessVersion="1.3.0"'),
    "duplicate harness-version key")

if failures ~= 0 then
    print(("FAIL: M2.3 Part 1 (%d/%d checks failed)"):format(failures, n))
    os.exit(1)
end
print(("PASS: M2.3 Part 1 foundation (%d public/synthetic checks)"):format(n))
