# N-Questie Part42: Alpha 0 3.3.5a packaging-readiness preflight

**28 October 2026 • PUBLIC-SAFE TEST-ONLY • NO ZIP, INSTALL, MERGE OR RELEASE.**

## Practical intent

The owner wants to move toward a first private in-game smoke test. An instruction to continue research and testing does NOT approve package generation, distribution, installation, changing protected 335, using private game data, or a release. This independent draft changes only a test, a dedicated CI workflow and this public research note.

## Original source evidence, pinned to protected 335

Protected original commit:
https://github.com/CosmicCuddle/N-Questie/commit/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070

- Questie-335.toc: interface 30300, N-Questie display identity and QuestieConfig/QuestieConfigCharacter SavedVariables. Its complete ordered 3.3.5a file list has more than 130 actual file references, including Compat/embeds.xml and six further Compat files. All paths must match the Git source tree exactly, including case.
- Compat/embeds.xml: several active Script/Include declarations resolve to extra library and compatibility code; static references are checked relative to the XML. This does NOT execute WoW XML parsing or library initialization.
- README.md: documents the Questie-335 installed folder, first-unmerged prototype status, and requirement to back up both original installed folder and Questie SavedVariables before any in-game tests.

## Independently identified blockers in the existing build.py

Original:
https://github.com/CosmicCuddle/N-Questie/blob/8b23c6e2cfa00bb81cb26d40c44fef154e9e0070/build.py

The legacy upstream script does NOT yet select the correct 3.3.5a addon file list:

1. Output addon folder is named Questie, while the installed addon folder must be Questie-335.
2. The Wrath -w path uses Questie-WOTLKC.toc, not Questie-335.toc.
3. Its included directories omit Compat, while the protected 335 TOC references Compat/embeds.xml and more Compat source files.

It is therefore unsafe to claim that simply running the existing legacy builder produces an Alpha 0 N-Questie 3.3.5a package. The separate release.py may change version files, commit and tag; do not run it for this milestone.

## What the preflight actually does

The read-only Python standard library fixture uses git show and git ls-tree against the exact pinned source commit, AST-inspects build.py configuration, verifies the actual TOC and Compat XML script/include paths, and compares an in-memory legacy file-selection plan to a hypothetical corrected file-selection plan. It checks deliberate missing-file mutants and excludes test/docs/.github/release-only payloads.

There are 27 strict preflight controls. The GitHub Actions workflow fetches pinned public source to its ephemeral job, checks the three summary markers, publishes no artifacts, and does not execute build.py, create an addon folder, create a ZIP, call release.py, install into a WoW game client, read private SavedVariables, modify a production branch, or publish a release.

A green result therefore means the static target 335 manifest and required corrections are understood, NOT that a usable build has been assembled or tested.

## Owner-gated next steps before Alpha 0

1. Approve an explicitly limited private build scope and frozen source commit, with unfinished Gate08 / all-writer epoch / uncertain owner-private quest data disabled or excluded.
2. Only with separate explicit authorization, implement and use a 335-aware packager on an isolated reviewed branch. Verify output folder Questie-335, original TOC, Compat tree and all dependencies, file hashes, absence of tests/docs/.github and accidental private content.
3. Before any physical client installation, back up the existing Interface/AddOns/Questie-335 directory plus account and character Questie SavedVariables; preserve a rollback copy.
4. Carry out reversible native WoW 3.3.5a smoke checks: cold launch, normal login, map/tracker/quest startup, logout/relog, recovery/rollback, with sanitized logs. A green source unit test is not a substitute for this.
5. Separate full N-Questie release acceptance still requires Gate08 real E01-E08 writer ownership and source isolation, global stream lifetime, checked four-kind eight Bin/Ptrs+metadata atomicity, native SavedVariables disk/crash/relog and Individual Progression QA.

Project gates stay 3 COMPLETE / 6 UNDERWAY / 3 TECHNICALLY PENDING, Gate08 MAJOR RED. 439 RAW research records are not approved quest additions; eligible denominator UNKNOWN, pilot 1207–1209 is 0/3 implemented. No time-to-build guarantee is implied by a static manifest preflight.
