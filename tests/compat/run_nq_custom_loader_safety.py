#!/usr/bin/env python3
"""Offline synthetic-only loader contract tests. No client/server or SQL access."""
from pathlib import Path
import ctypes
import ctypes.util
import hashlib
import os
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
LOADER = ROOT / "Compat/NQuestieCustomQuestLoader.lua"
TESTS = ROOT / "tests/compat/nq_custom_loader_safety.lua"
STAGE1 = ROOT / "Modules/QuestieInit.lua"
EXPECTED_LOADER_BLOB_SHA1 = "b12b7ce93e3f2c7e71d82937bd25a836558ce596"

def assert_source_revision():
    data = LOADER.read_bytes()
    git_blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
    if git_blob != EXPECTED_LOADER_BLOB_SHA1:
        raise SystemExit("FAIL: loader differs from exact candidate (blob SHA-1 " + git_blob + ")")
    print("Verified exact candidate Git blob SHA-1:", git_blob, flush=True)

def assert_stage1_guard_order():
    code = STAGE1.read_text(encoding="utf-8")
    stage_start = code.index("QuestieInit.Stages[1] =")
    stage_end = code.index("QuestieInit.Stages[2] =", stage_start)
    stage = code[stage_start:stage_end]
    try:
        locations = [stage.index(fragment) for fragment in (
            "loadFullDatabase()",
            "QuestieCompat.VerifyNQuestieCustomEffectiveSources()",
            "QuestieDBCompiler:Compile()",
            "Questie.db.global.nQuestieDataRevision = nQuestieRevision",
        )]
    except ValueError:
        raise SystemExit("FAIL: required Stage1 postflight/compiler/revision call is missing")
    if locations != sorted(locations):
        raise SystemExit("FAIL: complete effective source verification is not before Stage1 compile/revision")
    if "coYield()" in stage[locations[1]:locations[2]]:
        raise SystemExit("FAIL: unexpected yield between complete effective source postflight and compilation")
    # Source-placement regression only (not a runtime coroutine execution):
    # configured 3.3.5a custom quests must not silently skip a missing hook.
    for required in (
        'type(nQuestieData.quests) == "table" and next(nQuestieData.quests) ~= nil',
        'if type(QuestieCompat.VerifyNQuestieCustomEffectiveSources) ~= "function" then',
        'error("N-Questie effective source postflight unavailable; refusing compilation")',
    ):
        if required not in stage[locations[0]:locations[2]]:
            raise SystemExit("FAIL: configured custom quests can skip required postflight hook")
    print("PASS: postflight is required for configured quests before compile/revision", flush=True)

def run_executable(executable):
    env = dict(os.environ, NQ_LOADER_PATH=str(LOADER))
    subprocess.run([executable, str(TESTS)], env=env, check=True)
    print("PASS: Lua interpreter", executable, flush=True)

def run_lua54_shared():
    path = ctypes.util.find_library("lua5.4")
    if not path:
        return False
    lib = ctypes.CDLL(path)
    lib.luaL_newstate.restype = ctypes.c_void_p
    lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
    lib.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    lib.luaL_loadfilex.restype = ctypes.c_int
    lib.lua_pcallk.argtypes = [
        ctypes.c_void_p, ctypes.c_int, ctypes.c_int,
        ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p,
    ]
    lib.lua_pcallk.restype = ctypes.c_int
    lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    lib.lua_tolstring.restype = ctypes.c_char_p
    lib.lua_close.argtypes = [ctypes.c_void_p]
    state = lib.luaL_newstate()
    if not state:
        raise SystemExit("FAIL: cannot initialize Lua 5.4")
    try:
        lib.luaL_openlibs(state)
        status = lib.luaL_loadfilex(state, os.fsencode(TESTS), None)
        if status == 0:
            status = lib.lua_pcallk(state, 0, -1, 0, 0, None)
        if status:
            error = lib.lua_tolstring(state, -1, None) or b"unknown Lua error"
            raise SystemExit("FAIL: Lua 5.4 synthetic tests: " + error.decode(errors="replace"))
    finally:
        lib.lua_close(state)
    print("PASS: Lua 5.4 shared-library synthetic tests", flush=True)
    return True

if __name__ == "__main__":
    assert_source_revision()
    assert_stage1_guard_order()
    os.environ["NQ_LOADER_PATH"] = str(LOADER)
    lua51 = shutil.which("lua5.1")
    lua54 = shutil.which("lua5.4") or shutil.which("lua")
    ran = False
    if lua51:
        run_executable(lua51)
        ran = True
    else:
        print("NOT TESTED: Lua 5.1 executable unavailable", flush=True)
    if lua54:
        run_executable(lua54)
        ran = True
    else:
        ran = run_lua54_shared() or ran
    if not ran:
        raise SystemExit("No supported local Lua runtime available")
    print("Client, production compiler and live game remain NOT TESTED.")
