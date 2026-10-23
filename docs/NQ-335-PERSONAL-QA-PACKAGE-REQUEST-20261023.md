# Personal N-Questie 3.3.5a QA package request (never merge)

This one-file, documentation-only QA branch is based on protected `335` at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`.

Purpose: intentionally invoke the repository's pre-existing, review-only GitHub Actions "Assemble PR-only WoW 3.3.5a addon package" and "Upload temporary N-Questie PR test build" steps on a PR targeting `335`, for the owner's requested private in-game testing ZIP. This is **not** an official release and must **never be merged**.

The runtime addon payload is unchanged from protected `335`: the only difference between this QA branch and its parent is this Markdown file **outside** the workflow's package contents. The packager copies only:
- `Questie.lua`, `Questie-335.toc`, `embeds.xml`.
- `Compat/`, `Database/`, `Icons/`, `Libs/`, `Localization/`, `Modules/`.

Expected archive install folder: `Interface/AddOns/Questie-335/`. The installed addon and both SavedVariables are untouched by building/uploading a temporary artifact.

Safety:
- Do not merge this QA PR; do not retarget; do not create tags; do not publish to CurseForge/WAGO/GitHub Releases.
- Do not import private server SQL, edit client files, install into anyone's game, or modify a live server.
- Downloadable artifact is for private owner testing only, once the exact protected-branch review is cleared.
- The initial `335` source is pinned at `8b23c6e2cfa00bb81cb26d40c44fef154e9e0070`; if that branch later changes, this request no longer certifies a current build and must be revalidated.
