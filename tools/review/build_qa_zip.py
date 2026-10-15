#!/usr/bin/env python3
"""Private QA-only N-Questie ZIP builder; source must be frozen #66."""
import hashlib
import json
import os
import posixpath
import re
import subprocess
import sys
import zipfile
from pathlib import Path

SHA = "0b4bd40f32658ca96d7816e08edf478aef45300d"
ROOTS = ("Compat", "Database", "Icons", "Libs", "Localization", "Modules")
TOP = ("Questie-335.toc", "Questie.lua", "embeds.xml")
OUT = Path(os.environ["QA_OUTPUT_DIR"])
def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()
if git("rev-parse", "HEAD") != SHA or git("status", "--porcelain"):
    sys.exit("FAIL: source must be the unchanged exact #66 commit")
source = {}
for top in TOP:
    p = Path(top)
    if not p.is_file() or p.is_symlink():
        sys.exit("FAIL: missing required root file " + top)
    source[top] = p
for folder in ROOTS:
    if not Path(folder).is_dir():
        sys.exit("FAIL: missing runtime folder " + folder)
    for p in Path(folder).rglob("*"):
        if p.is_symlink():
            sys.exit("FAIL: symlink in runtime folder " + str(p))
        if p.is_file():
            name = p.as_posix()
            if not name.endswith(".test.lua") and not name.endswith(".pyc") and "/__pycache__/" not in name:
                source[name] = p
if len(source) < 400 or "Compat/NQuestieExistingQuestCorrections.lua" not in source:
    sys.exit("FAIL: incomplete addon runtime source")
toc = source["Questie-335.toc"].read_text(encoding="utf-8-sig")
if "## Interface: 30300" not in toc or "## Title: N-Questie" not in toc:
    sys.exit("FAIL: wrong game client or addon TOC")
folded = {}
for name in source:
    key = name.casefold()
    if key in folded:
        sys.exit("FAIL: Windows path collision: " + name + " and " + folded[key])
    folded[key] = name
xml_seen = set()
def verify_refs(name):
    if name not in source:
        sys.exit("FAIL: referenced runtime file missing " + name)
    if name.endswith(".toc"):
        refs = [v.strip() for v in source[name].read_text(encoding="utf-8-sig").splitlines()
                if v.strip() and not v.lstrip().startswith("#")]
    elif name.endswith(".xml"):
        if name in xml_seen:
            return
        xml_seen.add(name)
        data = re.sub(r"<!--.*?-->", "", source[name].read_text(encoding="utf-8-sig"), flags=re.S)
        refs = re.findall(r"<(?:Script|Include)\b[^>]*\bfile\s*=\s*[\"']([^\"']+)[\"']", data, flags=re.I)
    else:
        return
    for target in refs:
        linked = posixpath.normpath(posixpath.join(posixpath.dirname(name), target.replace("\\", "/")))
        if linked == ".." or linked.startswith("../") or linked.startswith("/"):
            sys.exit("FAIL: unsafe runtime reference " + name)
        if linked not in source:
            sys.exit("FAIL: missing runtime reference " + name + " => " + linked)
        if linked.endswith(".xml"):
            verify_refs(linked)
verify_refs("Questie-335.toc")
OUT.mkdir(parents=True, exist_ok=True)
name = "N-Questie-335-QA-" + SHA[:12] + ".zip"
archive = OUT / name
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as z:
    for path in sorted(source):
        info = zipfile.ZipInfo("Questie-335/" + path, (2026, 10, 15, 12, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        z.writestr(info, source[path].read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=6)
with zipfile.ZipFile(archive) as z:
    if z.testzip() is not None or len(z.namelist()) != len(source):
        sys.exit("FAIL: ZIP integrity error")
    if any(not n.startswith("Questie-335/") for n in z.namelist()):
        sys.exit("FAIL: unexpected top-level ZIP entry")
sha256 = hashlib.sha256(archive.read_bytes()).hexdigest()
metadata = {"source_commit": SHA, "addon_folder": "Questie-335",
            "addon_toc": "Questie-335.toc", "file_count": len(source),
            "xml_files_checked": len(xml_seen), "archive_sha256": sha256,
            "size_bytes": archive.stat().st_size}
(OUT / "QA-build-manifest.json").write_text(json.dumps(metadata, indent=2) + "\n")
(OUT / "SHA256SUMS.txt").write_text(sha256 + "  " + name + "\n")
if git("status", "--porcelain"):
    sys.exit("FAIL: source checkout changed during packaging")
print("PASS: clean pinned source, addon tree, TOC/XML refs, archive CRC and unchanged checkout")
print(json.dumps(metadata, indent=2))
