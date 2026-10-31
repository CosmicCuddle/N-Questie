#!/usr/bin/env python3
"""Mutation check for the Gate10 provisioning tests. Each deliberate break of the
loader or data file must make tests/compat/nq_gate10_source_provision.lua fail.
Offline only; mutants live in a temp dir and are never written into the repo."""
import os, shutil, subprocess, sys, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
LOADER = (ROOT / "Compat/NQuestieCustomQuestLoader.lua").read_text()
DATA = (ROOT / "Compat/NQuestieCustomQuestData.lua").read_text()
TEST = ROOT / "tests/compat/nq_gate10_source_provision.lua"
M = [
 ("loader", "no provisioning write", "            QuestieDB[entry.db][entry.id] = entry.record\n", ""),
 ("loader", "provision after approval", "        computeApproved()\n        if #written > 0", "        if #written > 0"),
 ("loader", "skip collision check", "if db[id] ~= nil then return nil end", "if false then return nil end"),
 ("loader", "skip rollback", "if #written > 0 and not sourceBatchClosed(batch, pending) then", "if false then"),
 ("loader", "closure always true", "local function sourceBatchClosed(batch, pending)\n", "local function sourceBatchClosed(batch, pending)\n    do return true end\n"),
 ("loader", "skip drop resolution", "if not (pending.npcs[id] or hasId(QuestieDB.npcData, id)) then return nil end", ""),
 ("loader", "allow item without drops", "if kind == \"items\" and row.npcDrops == nil and row.objectDrops == nil then", "if false then"),
 ("loader", "skip coordinate range", "c < 0 or c > 100", "c < 0"),
 ("loader", "drop memo guard", "local function approvedQuests()\n    if approved then return approved end\n", "local function approvedQuests()\n"),
 ("loader", "remove 2001/437 exemption", "        not isPublic2001(id, q) then return nil end", "        true then return nil end"),
 ("loader", "skip minLevel<=maxLevel", "row.minLevel > row.maxLevel", "false"),
 ("loader", "failed batch not fail-closed", "        return computeApproved(batchDependentQuests())", "        return computeApproved()"),
 ("loader", "no dependent quests excluded", "    local sources, excluded = custom.sources, {}\n", "    do return {} end\n    local sources, excluded = custom.sources, {}\n"),
 ("loader", "unreadable declaration not fail-closed", "    local all = type(sources) ~= \"table\"", "    local all = false\n    if type(sources) ~= \"table\" then return excluded end"),
 ("loader", "no rollback on fault", "        rollback()\n        approved = nil\n        error(err, 0)", "        approved = nil\n        error(err, 0)"),
 ("loader", "fault swallowed", "        error(err, 0)", "        approved = approved or {}"),
 ("loader", "stale memo after fault", "        rollback()\n        approved = nil\n", "        rollback()\n"),
 ("loader", "no pcall around provisioning", "    local ok, err = pcall(function()", "    local ok, err = (function(f) f() return true end)(function()"),
 ("loader", "spawn point extra keys allowed", "            if keys ~= 2 then return nil end", ""),
 ("data", "revision not bumped", "revision = 10", "revision = 9"),
]
def run(lua, loader, data):
    env = dict(os.environ, NQ_LOADER_PATH=loader, NQ_DATA_PATH=data)
    return subprocess.run([lua, str(TEST)], cwd=ROOT, env=env, capture_output=True).returncode
killed = 0
luas = [l for l in ("lua5.1", "lua5.4") if shutil.which(l)]
with tempfile.TemporaryDirectory() as tmp:
    for kind, name, old, new in M:
        src = LOADER if kind == "loader" else DATA
        if src.count(old) != 1:
            sys.exit("FAIL: mutation anchor not unique/found: " + name)
        lp, dp = str(ROOT / "Compat/NQuestieCustomQuestLoader.lua"), str(ROOT / "Compat/NQuestieCustomQuestData.lua")
        p = os.path.join(tmp, name.replace(" ", "_").replace("/", "_") + ".lua")
        mutated = src.replace(old, new)
        if name == "provision after approval":
            mutated = mutated.replace("    local batch, pending = buildSourceBatch()\n", "    computeApproved()\n    local batch, pending = buildSourceBatch()\n", 1)
        Path(p).write_text(mutated)
        if kind == "loader": lp = p
        else: dp = p
        for luac in ("luac5.1", "luac5.4"):
            if shutil.which(luac) and subprocess.run([luac, "-p", p], capture_output=True).returncode != 0:
                sys.exit("FAIL: mutant is not valid Lua (would be a trivial kill): " + name)
        res = {l: run(l, lp, dp) for l in luas}
        ok = all(rc != 0 for rc in res.values())
        killed += ok
        print(("KILLED  " if ok else "SURVIVED"), name, res)
    base = {l: run(l, str(ROOT / "Compat/NQuestieCustomQuestLoader.lua"), str(ROOT / "Compat/NQuestieCustomQuestData.lua")) for l in luas}
print("unmutated baseline:", base)
print(f"{killed}/{len(M)} mutants killed on {', '.join(luas)}")
sys.exit(0 if killed == len(M) and all(v == 0 for v in base.values()) else 1)
