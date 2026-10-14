#!/usr/bin/env lua5.1
-- N-Questie: read-only, privacy-minimising pilot check for exactly quest 1203.
-- RUN ONLY from a trusted development checkout, never from live worldserver.
-- Usage: lua5.1 cli/check-private-1203.lua /absolute/private/quest-1203.lua
-- Optional: add --archive /absolute/private/original-acore_world.zip
-- The optional archive must be the EXACT bytes the exporter claimed to read.
-- A matching hash alone never proves the exporter really read those bytes.
--
-- The shared M2.1 parser reads DATA literals, never executes the input Lua.
-- This tool writes nothing, prints no private source rows, paths, fingerprints
-- or server labels, and never connects to a server/database.
-- A PASS means shape + selection + public expected objective only; it is NOT
-- archive SHA verification, current server attestation or a real M2.3 compare.

local Input = dofile("tools/validation/InputSchema.lua")
local path = arg[1] or os.getenv("NQ_M2_INPUT")
local archive = nil
if arg[2] ~= nil then
    if arg[2] ~= "--archive" or type(arg[3]) ~= "string" or arg[3] == "" or arg[4] ~= nil then
        io.stderr:write("FAIL: invalid arguments; use input path, optionally --archive with an absolute archive path\n")
        os.exit(1)
    end
    archive = arg[3]
elseif arg[3] ~= nil then
    io.stderr:write("FAIL: invalid arguments (details not printed)\n")
    os.exit(1)
end

-- The general M2.1 path validator intentionally permits public synthetic
-- fixtures in tests/fixtures/m2_input/ and private/ inside the checkout.
-- This *real private evidence* gate is stricter: only an input resolving
-- OUTSIDE the entire public checkout may pass. Never trust a path by text.
local allowed, resolved = Input.CheckInputPath(path or "", ".")
local root = Input.resolver(".")
if not allowed or type(root) ~= "string" or type(resolved) ~= "string" then
    io.stderr:write("FAIL: private M2.1 input rejected (path, parser or schema); investigate locally\n")
    os.exit(1)
end
if resolved == root or resolved:sub(1, #root + 1) == root .. "/" then
    io.stderr:write("FAIL: private input must resolve outside the public checkout\n")
    os.exit(1)
end

-- Require operator-private Linux ownership and permissions BEFORE reading
-- any contents. Check the resolved target, not the symlink's visible mode.
-- We deliberately require an immediate parent directory 0700 and file 0600
-- rather than silently accepting public-readable private source data.
local function shellQuote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end
local function capture(cmd)
    local ok, h = pcall(io.popen, cmd .. " 2>/dev/null")
    if not ok or not h then return nil end
    local output = h:read("*a")
    h:close()
    return output and output:match("^(.-)\n?$")
end
local uid = capture("id -u")
local function secureStat(p, expectedMode, expectedType)
    local s = capture("stat -c '%u %a %F' -- " .. shellQuote(p))
    if not s or not uid or not uid:match("^%d+$") then return false end
    local owner, mode, kind = s:match("^(%d+) (%d+) (.+)$")
    return owner == uid and mode == expectedMode and kind == expectedType
end
local parent = resolved:match("^(.*)/[^/]+$") or "/"
if not secureStat(parent, "700", "directory")
    or not (secureStat(resolved, "600", "regular file") or secureStat(resolved, "600", "regular empty file")) then
    io.stderr:write("FAIL: private input permissions refused; require current-user-owned 0700 folder and 0600 regular file\n")
    os.exit(1)
end

-- Run from repository root, as with cli/validate-m2-input.lua.
local doc = Input.LoadFile(path or "", ".")
if not doc then
    io.stderr:write("FAIL: private M2.1 input rejected (path, parser or schema); investigate locally\n")
    os.exit(1)
end

if #doc.quests ~= 1 or doc.quests[1].ID ~= 1203 then
    io.stderr:write("FAIL: private selection is not exactly quest 1203\n")
    os.exit(1)
end

local q = doc.quests[1]
local expectedItems = 0
for i = 1, 6 do
    local id, count = q["RequiredItemId" .. i], q["RequiredItemCount" .. i]
    if id == 3853 and count == 1 then
        expectedItems = expectedItems + 1
    elseif id ~= 0 or count ~= 0 then
        io.stderr:write("FAIL: quest 1203 has an additional/different item objective; human review needed\n")
        os.exit(1)
    end
end
if expectedItems ~= 1 then
    io.stderr:write("FAIL: quest 1203 does not have exactly one required item 3853 x1\n")
    os.exit(1)
end
for i = 1, 4 do
    if q["RequiredNpcOrGo" .. i] ~= 0 or q["RequiredNpcOrGoCount" .. i] ~= 0 then
        io.stderr:write("FAIL: quest 1203 has an unexpected creature/object objective; human review needed\n")
        os.exit(1)
    end
end

-- Optional provenance verification: hash the original archive *as bytes*
-- without opening its SQL contents or printing its path, digest or metadata.
-- This is separate from M2.1's syntax-only sourceFingerprint check. Do NOT
-- claim to have authenticated the exporter's source selection or live DB.
if archive then
    local sourceOk, sourcePath = Input.CheckInputPath(archive, ".")
    if not sourceOk or type(sourcePath) ~= "string" then
        io.stderr:write("FAIL: private source archive path rejected\n")
        os.exit(1)
    end
    if sourcePath == root or sourcePath:sub(1, #root + 1) == root .. "/" then
        io.stderr:write("FAIL: private source archive must resolve outside the public checkout\n")
        os.exit(1)
    end
    local archiveParent = sourcePath:match("^(.*)/[^/]+$") or "/"
    if not secureStat(archiveParent, "700", "directory")
        or not (secureStat(sourcePath, "600", "regular file") or secureStat(sourcePath, "600", "regular empty file")) then
        io.stderr:write("FAIL: private source archive permissions refused; require owned 0700 folder and 0600 regular file\n")
        os.exit(1)
    end

    -- Using stdin avoids printing a pathname in sha256sum's output.
    local line = capture("sha256sum < " .. shellQuote(sourcePath))
    local digest = line and line:match("^([0-9a-f]+)%s+")
    if not digest or #digest ~= 64 then
        io.stderr:write("FAIL: private source archive SHA-256 unavailable\n")
        os.exit(1)
    end
    if digest ~= doc.provenance.sourceFingerprint:sub(8) then
        io.stderr:write("FAIL: source archive SHA-256 differs from declared input provenance\n")
        os.exit(1)
    end
end

-- Flags and credit evidence remain as supplied: do not rewrite unknown to
-- false or infer KillCredit completeness from the selected quest.
io.stdout:write("PASS: quest 1203 M2.1 schema, single-ID selection and public 3853 x1 item-only objective\n")
if archive then
    io.stdout:write("PASS: supplied offline archive SHA-256 matches the declared source fingerprint (byte comparison only)\n")
    io.stdout:write("NOT VERIFIED: whether exporter read that archive, current-world freshness, IP/conditions/scripts and M2.3 match\n")
else
    io.stdout:write("NOT VERIFIED: private archive fingerprint, current-world freshness, IP/conditions/scripts and M2.3 match\n")
end
os.exit(0)
