# N-Questie 3.3.5a — first private-test approval and recovery gates

**Status: DRAFT PLAN ONLY — NOT AN AUTHORISATION OR AN EXECUTED TEST.**  
**Prepared:** 21 October 2026. **Source baseline:** guarded integration candidate #148, commit `891a627318ac403d4da28655318286507f96c1aa`.  
**Review references:** G04 #149 (`6922180c3a5a0a5559098766360226cbabc3d583`), source manifest #150 (`610a76765bca957223004f3a95221de456f13bd3`), Windows design #151 (`eac1892dc933c447a0803ef746872a68156cc4d3`), verifier #152 (`a048e95964a5451230a3606f3fc10b36aa766595`).

This is a **human review worksheet**, not an installer, builder, hash-verification script or deployment instruction. It changes no runtime files and grants no permission to copy, install, execute on the owner's computer, replace SavedVariables, use SQL/server commands, create an artifact or release, or merge any PR. Any later owner action requires its own **separate, specific approval**. This file is deliberately outside the frozen 557-file addon inventory.

## 1. Current evidence and hard distinctions

| Subject | What is established | What must not be inferred |
| --- | --- | --- |
| Source inventory | 557 runtime blobs / 109 derived relative directories; 134,356,446 source bytes at #148 | A copied Windows stage matches the source |
| Manifest | `docs/NQ-335-STAGE-EXPECTED-MANIFEST-891a6273.tsv` on #150, SHA-256 `73eccd4498a3a47db4c5d3fca60a83f7c35052174afcbafe350839b34fcb6b52` | The actual owner's disk has those bytes |
| Linux G04 | #149 reviewed synthetic structural preflight | Windows NTFS hardlink, reparse or byte equality checked |
| Windows synthetic verifier | #152 review accepted *only the supported hosted synthetic suite*: 2 positive PASS / 47 expected refusals STOP / 5 NOT TESTED / 0 harness failures on Windows PS Desktop 5.1 / NTFS | Atomic snapshot, cloud-provider exclusion, real user-PC safety, or game execution |
| Client | Intended client WoW 3.3.5a; active root TOC is `Questie-335.toc` loading `Compat/embeds.xml` | Addon loads without Lua errors or supports every progression phase |
| Publication | Four notices are present in the expected source inventory | Redistribution/artwork permissions have been cleared |

A green GitHub Actions job is **not** a real private-test go-ahead. A future source-to-stage result can establish only the stated bytes/layout under the tested filesystem and scan conditions; it does **not** verify Lua runtime, quest state, user backups, license rights or later changes.

## 2. Required owner permission boundaries (all presently unchecked)

- [ ] **A — owner authorises discovery/backup planning** of exact current addon variant names, `AddOns.txt`, account-wide and character-specific SavedVariables and `.bak` files, without changing anything.
- [ ] **B — owner authorises an isolated OFF-GAME stage copy only**, after choosing its exact source, destination and relevant approved read-only verification procedure. This does **not** authorise live WoW AddOns/WTF modification.
- [ ] **C — owner approves a separately reviewed copy into the live client's `Interface/AddOns`**, only after real backup and rollback proof plus approved off-game source/stage acceptance.
- [ ] **D — owner approves a narrowly scoped personal in-game trial**, on an eligible character and with WoW/server data left intact.
- [ ] **E — any merge, new tag, public packaging, distribution or release** is a separate later decision; this draft does not request or imply it.

Do not combine these permissions into one assumed “please continue.” If any approval is missing, **STOP** at that boundary. Never auto-create a ZIP or GitHub Actions upload.

## 3. Before any future authorised copy: environment and recovery

**Mandatory preconditions; none has been done on the owner's PC.**

- [ ] WoW is fully closed. Relevant worldserver/SQL changes are not part of testing.
- [ ] Identify **every** installed Questie / N-Questie / other conflicting addon variant; check installed folder identity and which AddOns are enabled. Do not assume the existing folder is `Questie-335`.
- [ ] Identify the applicable `AddOns.txt` for the actual client/account/character. Preserve exact original bytes and location.
- [ ] Enumerate actual account-wide and per-character Questie SavedVariables files across applicable `WTF` paths, including both `.lua` and `.bak` if present; preserve original names, case, dates and locations. The TOC variable declarations `QuestieConfig` / `QuestieConfigCharacter` **are not proof of concrete filenames**.
- [ ] Choose a backup destination outside the live client tree and any unsafe sync path. Make complete readable backup copies of existing relevant addon directories, `AddOns.txt`, SavedVariables and any other affected configuration **only after owner approval**.
- [ ] Record a private rollback map: original path -> backup path -> approved restore action for *each* saved item. Check backups against originals and perform an appropriate, non-destructive recovery rehearsal before allowing installation. A folder existing is **not** verification of recoverability.
- [ ] Record the source commit, stage expected manifest SHA-256, tester, consent, environment and observed result, with no private paths/account identifiers posted publicly.

**Stop immediately** on unreadable/partial backup, missing variant inventory, uncertain ownership, active client, insufficient permissions, ambiguous restore scope, or lack of explicit owner sign-off. Backups are not claimed to exist as of this document.

## 4. Proposed first OFF-GAME stage gate, subject to its own approval

Only consider a **local, unsynced, quiescent, non-cloud NTFS** scratch folder away from live WoW `Interface/AddOns` and all `WTF` trees. Its final literal name must be `Questie-335`. The source must be the exact frozen candidate with raw Git blob bytes; the inherited `build.py` is **not** an acceptable assembler of the 557-file addon because it omits required runtime paths. A Git checkout with line-ending conversion may also differ from the expected raw blob bytes: do **not** normalise text or adjust hashes to manufacture a PASS.

Each test is independent, and **NOT TESTED** until evidenced on the real, authorised stage:

| Gate | Acceptance observation | STOP condition |
| --- | --- | --- |
| Source identity | Exact #148 SHA and manifest pin recorded | Unknown/rebased source or mismatched TSV |
| Location trust | Proven non-cloud, local, quiet location; WoW closed, not live AddOns/WTF | OneDrive-like/provider state unknown, hydration or recall possible, stage still changing |
| Path provenance | Absolute, unambiguous exact-case path; no `..`, special roots, trailing dot/space or short-name aliases | Relative/drive-relative, path alias, uncertain actual directory spelling |
| Volume/handles | Native NTFS volume confirmation, accessible handle-based checks, no reparse ancestors/children, no extra streams, no regular-file hardlink alias | Non-NTFS, API unavailable, access sharing conflict, junction/symlink, named stream, hardlink/unproven links |
| Shape | **Exactly 557** files and **109** derived relative directories, including empty-folder/extra-file rejection | Any extra/missing/renamed/case-only path or directory |
| Content | Every declared raw file size and SHA-256 matches; retain all four notice files byte-for-byte | Size, CRLF, hash, or notice mismatch; refused/unproven byte read |
| Review | Re-check exact verifier source SHA and syntax/environment; separately apply reviewed G04 structural/read-only preflight where appropriate | Tool change without reciprocal review or environment outside its tested contract |

Required notice files: `Icons/LICENSE.md`, `Icons/MIT.txt`, `Libs/LICENSE.txt`, `Libs/Krowi_WorldMapButtons/LICENSE.md`. The four are **inside** the 557-file total, not additions.

Never weaken flags, share semantics, stream enumeration or volume checks to obtain a green report. The verifier's second hash pass is **diagnostic**, not a snapshot. A tool returning PASS for tested bytes does not stop another process changing the folder afterwards. Avoid unsupported paths instead of forcing them through.

## 5. Five recorded Windows coverage gaps — hold them as NOT TESTED

These are documented synthetic coverage limitations, **not five native failures**:

1. **Concurrent mutation:** sharing-conflict STOP was tested; genuine mid-read mutation without weakening the no-write-share policy was not. Require an independently quiescent off-game source/stage; any conflicting access or drift => **STOP**. Two identical reads do not prove atomicity.
2. **Cloud/sync/hydration:** detection of certain offline/recall/reparse attributes exists; actual cloud placeholders/provider absence were not proven. A path without “OneDrive” in its spelling is insufficient. No trustworthy independent unsynced-location evidence => **STOP**.
3. **Non-NTFS:** source demands a native-reported exact `NTFS` volume; a genuinely separate non-NTFS runner was not executed. Not NTFS or unable to prove it => **STOP**.
4. **On-disk trailing-dot alias:** lexical rejection is tested; exotic actual NTFS trailing-dot names are not. Exact actual-name identity, ordinal inventory and ancestor checks must succeed; any uncertainty => **STOP**.
5. **Malformed FileStreamInfo buffer:** a real disposable 65-stream enumeration was refused; arbitrary forged bad native-return buffers are untested. Managed invented-buffer models, if used, remain **source-logic evidence only**, not native NTFS coverage. Parser completion/bounds unproven => **STOP**.

All five require independent risk disposition and reciprocal review. Any new specific defect should receive its own exact-SHA, bounded draft change and retest before consideration; avoid modifying source-reviewed #152 merely to make a coverage count look better.

## 6. Separate later in-game acceptance — still NOT TESTED on this candidate

After B/C/D each have **separately** been authorised and recovery has been rehearsed, record version/build source, observer and **PASS / FAIL / NOT TESTED** for:

- [ ] Actual addon loading and Lua errors, including first login and `/reload`; no duplicate conflicting Questie.
- [ ] World map and minimap quest markers, quest tracker, icons/tooltip, settings/options and correct SavedVariables persistence.
- [ ] Legitimate Individual Progression phase/faction/prerequisite behavior, without overrides or altered database/GM progression to force the result.
- [ ] Quest **2001** regression: historical basic marker lifecycle was *partial* evidence only; still check intermediate objective counts, NPC 1868/1869 (with prerequisite quest 437), relevant active spawn/phase and reload state.
- [ ] Quest **1203**: natural eligibility and genuine item **3853 x1** objective progression/turn-in; currently **NOT TESTED** in the real client.
- [ ] Other scenario coverage in `docs/TESTING.md`, `docs/NQ-PILOT-QUEST-QA-MATRIX.md` and `docs/NQ-137-GUARDED-INTEGRATION-AND-QA-HANDOFF.md`.

Do not upload screenshots with private player data or server exports. Failed observations must remain FAIL rather than changing character state, SQL, prerequisites, items or coordinates to force PASS.

## 7. Rollback and decision record

On any future install/gameplay failure: **close WoW** before any restoration; stop further testing, preserve private evidence, and follow the previously rehearsed exact path mapping to restore addon folder(s), `AddOns.txt` and affected SavedVariables as appropriate. Restore only what the owner has explicitly approved; never silently overwrite newer SavedVariables or delete unknown addon variants. Confirm the original addon loads and original settings are recoverable before closing the incident. No rollback action is permitted by this document itself.

| Gate | Current state, 21 Oct 2026 |
| --- | --- |
| Hosted synthetic Windows source/CI | **Limited PASS** only at #152 `a048e959` |
| First owner-specific backup, rehearsal and source trust | **NOT DONE / NOT AUTHORISED** |
| Real off-game stage/Windows acceptance | **STOP / NOT TESTED** |
| Live-client copy and WoW in-game acceptance | **STOP / NOT TESTED** |
| SQL/server, merger, tag, packaging, rights clearance, public release | **NOT AUTHORISED** |

**Maintenance:** continue M0/M1/M2.1–M2.2, unfinished M2.3–M2.5, DEV-191/DEV-192, historic quest QA and the rolling review queue in master PR #96. This document is a planning aid; it does **not** redefine the addon source inventory, change the pin, or replace its source-to-stage verifier.
