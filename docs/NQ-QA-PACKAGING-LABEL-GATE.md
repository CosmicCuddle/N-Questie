# N-Questie QA packaging label gate (draft, 2026-10-24)

The overlay workflow (`.github/workflows/nquestie-overlay.yml`) builds and
uploads the `N-Questie-335-PR-TestBuild` ZIP only when every part of the
same predicate is true:

- The event is `pull_request`. Push events never package.
- The pull request carries the exact label `nq-qa-ingame-test`.
- `git diff --name-only` shows at least one changed path that is not
  documentation.

Assemble and Upload use that same predicate. If the changed-file list cannot
be determined, or the list is empty, the workflow does not package (fail closed).

The diff is from the merge base of `pull_request.base.sha` and
`pull_request.head.sha` to the head SHA. Files that exist only on a newer
base are not treated as changes made by the pull request. A shallow checkout
fetches enough history to compute that merge base (`git fetch` with the
read-only token). The job does not need write permission, does not use
`pull_request_target`, and does not add an action for this lookup.

Documentation paths are case-sensitive and narrow. A changed path is
documentation only when it matches one of these:

- `docs/**` — a file under the top-level `docs/` directory (`docs/guide.md`,
  `docs/foo.lua`). A file named `docs` at the repository root does not match.
- `**/*.md` — a path matching `*.md` (`README.md`, `docs/a.md`,
  `Modules/notes.md`).
- `LICENSE*` — a repository-root file whose name starts with `LICENSE`
  (`LICENSE`, `LICENSE.txt`, `LICENSE.md`). `vendor/LICENSE` does not match.

Any other path (Lua, TOC, tests, tools, `.github/workflows`) is not
documentation. A labelled pull request that changes only documentation does
not package. A labelled pull request that changes documentation and any
other path does.

- Unlabelled pull requests, a wrong label, removing the label, and push
  events: no package.
- `labeled` and `unlabeled` re-run the workflow.
- Token stays read-only (`contents: read`, `actions: read`). Artifacts
  expire after 7 days.
- Guard: `python3 tests/ci/check_overlay_packaging_gate.py` (stdlib only,
  runs in CI).

The label `nq-qa-ingame-test` is a technical trigger for this workflow, not proof of owner consent and not a cryptographic approval check. Only the owner or an authorised maintainer should apply it, and only to a pull request intentionally approved for in-game testing. This change does not create or
apply the label. Updating protected `335` is a separate, explicitly approved
step after review.
