# N-Questie QA packaging label gate (draft, 2026-10-24)

The overlay workflow (`.github/workflows/nquestie-overlay.yml`) now builds and
uploads the `N-Questie-335-PR-TestBuild` ZIP **only** for `pull_request` events
where the PR carries the explicit label `nq-qa-ingame-test`.

- Documentation-only and unlabelled PRs: all checks run, no package.
- Push events: never package.
- Adding/removing the label re-triggers the workflow (`labeled`/`unlabeled` types).
- Token is read-only (`contents: read`, `actions: read`); artifacts expire after 7 days.
- Guard: `python3 tests/ci/check_overlay_packaging_gate.py` (stdlib only, runs in CI).

The label is applied only to PRs Michael has approved for in-game testing. The
label itself is not created by this change. Applying this to `335` is a
separate, explicitly approved step after CS01 review.
