#!/usr/bin/env python3
"""Test-only F7 comparator self-test on synthetic public CLI output.

No Questie source, historical baseline, server or artifact is modified.
Uses the frozen default golden as read-only input; synthetic changes live in
a private TemporaryDirectory and must be rejected except for the six allowed.
"""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

golden=Path("tests/fixtures/m2_v2_export/default_cli_golden.txt")
helper=Path("tests/check_nquestie_m2_gate10_f7.py")
original=golden.read_bytes()
if not original.startswith(b"== stdout\n"):
    raise SystemExit("FAIL: no frozen F7 golden")
replacements = {
    b"[validate-335] questData  records": b"[validate-335] questData  records=9158 before=f84abb0a after=decaf123 unexpected=0",
    b"[validate-335] questData IDs added": b"[validate-335] questData IDs added by N-Questie: 1207,1208,1209,2001; removed: none",
    b"[validate-335] npcData    records": b"[validate-335] npcData    records=29615 before=d6e37a01 after=decaf123 unexpected=0",
    b"[validate-335] objectData records": b"[validate-335] objectData records=13043 before=8082022e after=decaf123 unexpected=0",
    b"[validate-335] itemData   records": b"[validate-335] itemData   records=36767 before=441bb1af after=decaf123 unexpected=0",
    b"[validate-335] compiled round trip": b"[validate-335] compiled round trip: 82500 quest fields compared, 0 mismatches",
}
def substitute(prefixes):
    rows=original.splitlines(keepends=True)
    hits=set()
    for i,row in enumerate(rows):
        for k,v in prefixes.items():
            if row.startswith(k):
                rows[i]=v+b"\n"
                hits.add(k)
                break
    if hits!=set(prefixes):
        raise SystemExit("FAIL: fixture does not include expected six lines")
    return b"".join(rows)
positive=substitute(replacements)
with tempfile.TemporaryDirectory(prefix="nq-gate10-f7-") as dir:
    test=Path(dir)/"default.txt"
    def check(blob,expected):
        test.write_bytes(blob)
        result=subprocess.run([sys.executable,str(helper),str(test),str(golden)],capture_output=True,text=True)
        if (result.returncode==0)!=expected:
            raise SystemExit("FAIL F7 fixture: expected %s, got %s: %s" %
                             (expected,result.returncode,(result.stdout+result.stderr)[-400:]))
    check(positive,True)
    check(positive.replace(b"1207,1208,1209,2001",b"1207,1208,2001"),False)
    check(positive.replace(b"PASS: 232 checks",b"PASS: 231 checks"),False)
    check(positive.replace(b"82500 quest fields",b"82431 quest fields"),False)
print("PASS: F7 comparator accepts exact Gate10 structural changes, rejects three mutants")
