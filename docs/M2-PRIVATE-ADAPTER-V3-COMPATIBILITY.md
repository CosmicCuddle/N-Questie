# N-Questie — Private Objective Exporter v3 / M2.1 Interoperability

**Date:** 14 October 2026  
**Status:** Draft, report-only and **unmerged**. No in-game installation or live server modification.  
**Public CI proof:** [PR #22](https://github.com/CosmicCuddle/N-Questie/pull/22), child of Grok's [PR #21](https://github.com/CosmicCuddle/N-Questie/pull/21), without modifying Grok's source branch.

## Scope and ownership

The lead quest-data workstream maintains a standalone **private local Python 3 exporter** for the maintainer's offline AzerothCore HeidiSQL world archive. Its source code, source archive and real generated quest records are **not in GitHub**. Grok maintains the actual Lua 5.1 `nq-m2-input` schema, data-only parser, M1 objective rules, M0 validation harness, and proposed M2.2 effective Questie export.

This PR contains **only a fully synthetic sample and CI integration** demonstrating that the local exporter v3 emits data accepted by Grok's M2.1 validator. The synthetic source hash is computed from invented SQL rows and is **not the hash of the maintainer's private archive**. No private data, real source paths, player/account details or per-quest private report is published.

## Private v3 output contract (schema version 1)

```lua
return {
    schema = "nq-m2-input",
    schemaVersion = 1,
    provenance = {
        exporter = "nquestie-private-objectives",
        exporterVersion = "3.0.0",
        sourceLabel = "acore_world-offline",
        sourceFingerprint = "sha256:<64-lowercase-hex-digits>",
        exportedAt = "YYYY-MM-DDThh:mm:ssZ",
        selection = "explicit",
        questCount = 1,
    },
    quests = {
        { ID = 1203, /* all numeric slots 0 or valid counts, explicit flags and KillCredit */ },
    },
}
```

**The snippet illustrates structure, not runnable Lua**; the actual [synthetic fixture](../tests/fixtures/m2_input/private_adapter_v3_synthetic.lua) is valid Lua 5.1 data-only syntax.

- `quests` is a **list**, not a map keyed by quest ID. IDs are unique and selected explicitly, maximum 50 per private exporter invocation.
- Every required `quest_template` objective target/count field, source/drop item field and `StartItem` is an integer, with `0` for unused slots. Negative `RequiredNpcOrGo` IDs are gameobjects.
- The three conditions/IP/script flags are **explicitly `"unknown"`** until real independent evidence justifies a different value. Exporting `false` from an unchecked source is forbidden.
- `killCreditComplete=false` is retained even when a reviewed creature row was found; incomplete/unknown creature credit and script behaviour must never be described as a confirmed mismatch.
- Extra private exporter review metadata such as `_candidateCreatureIdsNotFound` and per-row `provenance` are excluded from the strict public-schema file; source fingerprint and UTC date live in top-level provenance only.
- The private generated files are atomic, mode `0600`, refuse unapproved overwrites, and cannot be written inside a Git checkout (including via resolved symlinks). A private input validation run must use an **absolute path outside the public checkout**, even though M2.1 also supports Git-ignored in-repo `private/` paths.
- The optional local `--format json` is **debug-only**, NOT input for M2.1's Lua data-only parser.

## Evidence and limits

| Check | Evidence |
|---|---|
| Local standalone Python 3 exporter v3 | **30 synthetic Python tests PASS**; v2 package preserved as rollback |
| Local read-only offline world pilot | Only selected **1203 / 2001** quest records exported, verified fields and explicit conservative flags; raw SQL and output remained local/private |
| Local Lua syntax | Generated synthetic and real private Lua **syntax parsed under Lua 5.4, without execution** |
| GitHub actual **Lua 5.1** data-only parser | [Dedicated CI run 38589636591](https://github.com/CosmicCuddle/N-Questie/actions/runs/38589636591) **PASS**: synthetic v3 exporter fixture reports `OK: 2 quest record(s), schema nq-m2-input v1` |
| M2.1 schema/parser regression | Same CI run: 43 validation rejections, 16 parse rejections, 94 Busted tests passing |
| Full integration | [PR #22 CI](https://github.com/CosmicCuddle/N-Questie/pull/22): M1, M0 28 corrections, revision guard, overlay and inherited LuaCheck/Busted/Era/SoD/WotLK checks PASS on its initial code commit |

**Do not overstate:** There has been **no actual Lua 5.1 M2.1 validation of the maintainer's real private output**. That will require the reviewed updated M2.1 path/symlink guard and an authorised private local checkout/run. The GitHub proof uses **synthetic rows only**. M2.2 effective Questie export, M2.3 batch comparison, M2.4 private analysis of 24 item / 151 NPC candidates, and in-game quest QA remain unimplemented/unverified.

## Next actions and approval gates

1. Grok completes review of M2.1 input-path and symlink handling. Fail closed if canonical resolution fails; do not rely on unchecked lexical fallback for untrusted path restrictions.
2. Keep the private exporter and ZIP outside all public Git checkouts; do not upload real quest records or use them as public CI fixtures.
3. After M2.1 is accepted, test the **private v3 output** locally with Grok's CLI, starting with selected quest **1203** and a controlled read-only test. This is a validation step, **not** an automatic correction or in-game action.
4. Only after private M2.1 acceptance should Grok implement M2.2 and later M2.3 in separate reviewable PRs; preserve M0's strict 28-level allow-list and 82,431-field compiled roundtrip.
5. No PR merges, releases/tags, `335` updates, addon-collection changes, installed addon/SavedVariables edits or live AzerothCore database writes without explicit maintainer approval.
