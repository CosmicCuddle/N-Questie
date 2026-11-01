#!/usr/bin/env python3
"""Gate10 default-output F7 comparator against unchanged historical 335 golden.

Only known additive source-record and compiled-quest-field differences are
allowed; unmodified output must still match old golden byte-for-byte.
This is a test-only comparator; it never rewrites/repins the golden or source.
"""
import hashlib
from pathlib import Path
import re
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: checker default-output.txt historical-golden.txt")
current = Path(sys.argv[1]).read_bytes()
original = Path(sys.argv[2]).read_bytes()
git_hash = hashlib.sha1(b"blob " + str(len(original)).encode() + b"\0" + original).hexdigest()
if git_hash != "214925d9293ac6257099750d2ce7d43a6e3e0f49":
    raise SystemExit("FAIL F7: original 335 golden Git blob changed")
a, b = current.splitlines(), original.splitlines()
if len(a) != len(b):
    raise SystemExit("FAIL F7: unexpected default output line count")

# Exactly these lines can differ because Gate10 introduces 3 quests and
# provides 10 public source rows. Before-hashes and counts are immutable.
allowed = {
    b"[validate-335] questData  records": rb"\[validate-335\] questData  records=9158 before=f84abb0a after=[0-9a-f]{8} unexpected=0",
    b"[validate-335] questData IDs added": rb"\[validate-335\] questData IDs added by N-Questie: 1207,1208,1209,2001; removed: none",
    b"[validate-335] npcData    records": rb"\[validate-335\] npcData    records=29615 before=d6e37a01 after=[0-9a-f]{8} unexpected=0",
    b"[validate-335] objectData records": rb"\[validate-335\] objectData records=13043 before=8082022e after=[0-9a-f]{8} unexpected=0",
    b"[validate-335] itemData   records": rb"\[validate-335\] itemData   records=36767 before=441bb1af after=[0-9a-f]{8} unexpected=0",
    b"[validate-335] compiled round trip": rb"\[validate-335\] compiled round trip: [0-9]+ quest fields compared, 0 mismatches",
}
seen = set()
for number, (new, old) in enumerate(zip(a, b), 1):
    label = next((prefix for prefix in allowed if old.startswith(prefix)), None)
    if label is None:
        if new != old:
            raise SystemExit("FAIL F7: unrelated default output changed on line %d" % number)
    else:
        if not re.fullmatch(allowed[label], new):
            raise SystemExit("FAIL F7: invalid Gate10 change on line %d: %s" % (number, label.decode()))
        if label == b"[validate-335] compiled round trip":
            fields = int(re.search(rb"round trip: ([0-9]+)", new).group(1))
            if fields <= 82431:
                raise SystemExit("FAIL F7: compiled quest fields did not increase")
        seen.add(label)
if seen != set(allowed):
    raise SystemExit("FAIL F7: expected original structured log lines absent")
print("PASS: F7 original 335 golden unchanged; six Gate10-only differences controlled")
