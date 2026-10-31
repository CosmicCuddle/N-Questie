#!/usr/bin/env python3
"""Read-only, PINNED 3.3.5a TOC -> XML Include/Script path resolver.

This audits XML *file references*, not a full Blizzard XML runtime/parser.
The inherited Ui XML has undeclared xsi prefix, so we inspect lexical file
attributes after removing <!-- comments -->, not ElementTree validity.
No package, native client, external dependency, code injection or writes.
"""
import argparse
import os
import pathlib
import posixpath
import re
import subprocess
import tempfile

PIN = "26053bd28b0df3a01e5859f779d5f3cb4f57b221"
TOC_SHA = "f59dc1c2b1987697e133297831224e6f0957bae8"
REF = re.compile(r"<\s*(?:Script|Include)\b[^>]*\bfile\s*=\s*[\"']([^\"']+)[\"']", re.I)
COMMENT = re.compile(r"<!--.*?-->", re.S)
MAX_GRAPH = 1200

def cmd(*args):
    return subprocess.run(["git", *args], check=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout

def ensure(ok, reason):
    if not ok:
        raise AssertionError("NQ_ALPHA0_RECURSIVE_LOADGRAPH:" + reason)

def file_at(path):
    return cmd("show", PIN + ":" + path)

def normalize(origin, child):
    child = child.strip().replace("\\", "/")
    ensure(child and not child.startswith("/"), "UNSAFE_REF:" + origin)
    ensure(not re.search(r"(^|/)\.\.?(?:/|$)", child.replace("../", "")),
           "UNSAFE_DOT_REFERENCE:" + origin)
    # Parent steps are legitimate in nested lib XML and must remain inside repo.
    joined = posixpath.normpath(posixpath.join(posixpath.dirname(origin), child))
    ensure(not (joined in (".", "..") or joined.startswith("../") or
                joined.startswith("/")), "ESCAPED_ADDON_ROOT:" + origin)
    ensure(joined.lower().endswith((".lua", ".xml")),
           "UNEXPECTED_XML_PATH_EXTENSION:" + origin + ":" + child)
    return joined

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luac", choices=("luac5.1", "luac5.4"), required=True)
    args = ap.parse_args()
    ensure(cmd("rev-parse", PIN + "^{commit}").decode().strip() == PIN, "PINNED_COMMIT")
    ensure(cmd("rev-parse", PIN + ":Questie-335.toc").decode().strip() == TOC_SHA,
           "PINNED_TOC_BLOB")
    tree = set(cmd("ls-tree", "-r", "--name-only", PIN).decode().splitlines())
    toc = file_at("Questie-335.toc").decode("utf-8-sig")
    direct = []
    for line in toc.splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            direct.append(normalize("Questie-335.toc", line))
    ensure(len(direct) == 143 and len(direct) == len(set(direct)),
           "DIRECT_TOC_EXPECTED_143")
    ensure(all(path in tree for path in direct), "DIRECT_TOC_MISSING")
    ensure(sum(p.endswith(".xml") for p in direct) == 6, "DIRECT_XML_EXPECTED_6")

    scripts = set(path for path in direct if path.endswith(".lua"))
    seen_xml = set()
    pending = [path for path in direct if path.endswith(".xml")]
    total_edges = 0
    duplicates = 0
    while pending:
        path = pending.pop()
        if path in seen_xml:
            continue
        ensure(path in tree, "MISSING_XML:" + path)
        seen_xml.add(path)
        ensure(len(seen_xml) <= MAX_GRAPH, "TOO_MANY_XML_FILES")
        body = file_at(path).decode("utf-8-sig")
        body = COMMENT.sub("", body)
        for m in REF.finditer(body):
            child = normalize(path, m.group(1))
            total_edges += 1
            ensure(total_edges <= MAX_GRAPH * 5, "TOO_MANY_XML_REFERENCES")
            ensure(child in tree, "MISSING_TRANSITIVE_REFERENCE:" + path + ":" + child)
            if child.endswith(".xml"):
                pending.append(child)
            else:
                if child in scripts:
                    duplicates += 1
                scripts.add(child)
    ensure(scripts.issubset(tree), "UNRESOLVED_SCRIPT")
    ensure(len(scripts) >= 137, "LOST_DIRECT_LUA_ENTRY")
    ensure(not (set(scripts) & seen_xml), "XML_LUA_OVERLAP")
    # A raw Lua5.1 parse failure is a release blocker. However, the genuine
    # baseline includes a BOM in an XML-reachable third-party library.
    # Record BOTH raw result and an isolated temporary BOM-stripped *diagnostic*
    # result, without changing the source tree or treating the raw failure as
    # native WoW acceptance. Any other error must fail the whole census.
    known_bom = {"Compat/Libs/LibSharedMedia-3.0/LibSharedMedia-3.0.lua"}
    bom_scripts, bom_rejected, failures = [], [], []
    raw_pass = 0
    with tempfile.TemporaryDirectory(prefix="nq-alpha0-recursive-") as temp:
        for n, path in enumerate(sorted(scripts), 1):
            f = pathlib.Path(temp) / ("script-%04d.lua" % n)
            data = file_at(path)
            has_bom = data.startswith(b"\xef\xbb\xbf")
            if has_bom:
                bom_scripts.append(path)
            f.write_bytes(data)
            p = subprocess.run([args.luac, "-p", str(f)], capture_output=True)
            if p.returncode == 0:
                raw_pass += 1
                continue
            diagnostic = p.stderr.decode("utf-8", "backslashreplace")[:300]
            if not has_bom:
                failures.append("RAW:" + path + ":" + diagnostic)
                continue
            # Diagnostic only. Never transform Git sources or call this
            # an acceptable production/client workaround.
            f.write_bytes(data[3:])
            stripped = subprocess.run([args.luac, "-p", str(f)],
                                      capture_output=True)
            if stripped.returncode:
                second = stripped.stderr.decode("utf-8", "backslashreplace")[:300]
                failures.append("AFTER_BOM_STRIP:" + path + ":" + second)
            else:
                bom_rejected.append(path)
    if failures:
        for message in failures[:30]:
            print("PUBLIC NQ PART50 ALPHA0 XML LUA FAILURE: " + message)
    ensure(not failures, "OTHER_LUA_SYNTAX_FAILURES_" + str(len(failures)))
    unexpected_bom = sorted(set(bom_scripts) - known_bom)
    ensure(not unexpected_bom, "UNREVIEWED_XML_LUA_BOM:" +
           ",".join(unexpected_bom))
    ensure(known_bom.issubset(set(bom_scripts)), "PINNED_KNOWN_BOM_NOT_SEEN")
    if args.luac == "luac5.1":
        ensure(known_bom.issubset(set(bom_rejected)),
               "LUA51_RAW_BOM_REJECTION_NOT_REPRODUCED")
    ensure(raw_pass + len(bom_rejected) == len(scripts),
           "NOT_ALL_LUA_SCRIPTS_EXPLAINED")
    print("PUBLIC NQ PART50 ALPHA0 RECURSIVE TOC DIRECT: 143/143 RESOLVED")
    print("PUBLIC NQ PART50 ALPHA0 RECURSIVE XML: %d XML, %d ACTIVE REFS RESOLVED" %
          (len(seen_xml), total_edges))
    print("PUBLIC NQ PART50 ALPHA0 RECURSIVE LUA: %d/%d PARSE WITH TEMP BOM DIAG %s" %
          (len(scripts), len(scripts), args.luac))
    print("PUBLIC NQ PART50 ALPHA0 RAW LUA PASSES: %d; BOM-ONLY REJECTIONS: %d" %
          (raw_pass, len(bom_rejected)))
    print("PUBLIC NQ PART50 ALPHA0 KNOWN XML LUA BOM: " +
          ",".join(sorted(bom_scripts)))
    print("PUBLIC NQ PART50 ALPHA0 XML REPEAT SCRIPT REFERENCES: %d (NOT REJECTED)" %
          duplicates)
    print("PUBLIC NQ PART50 ALPHA0 BLOCKED: raw Lua5.1 BOM compatibility and native startup NOT PROVEN")
    print("PUBLIC NQ PART50 ALPHA0 STATIC ONLY: no XML widget semantics, native startup, or build")

if __name__ == "__main__":
    main()
