# Repo conventions — argus-mode

Consistency invariants for any session editing this repo. Preserve these automatically.

- Every skill gets an entry in the top-level `README.md` (name linked to its `SKILL.md`). Only list skills in `.claude-plugin/plugin.json` if the manifest schema supports a `skills` field — verify against `skills/` auto-discovery before adding one; don't duplicate what auto-discovery already covers.
- Every agent appears in the README agent table with its model and one-line mandate. Add the agent to both places in the same change — never one without the other.
- `references/` files are shared by both skills (`run` and `consult`). Before finishing any edit under `references/`, re-read both `skills/run/SKILL.md` and `skills/consult/SKILL.md` and confirm they still hold against the change.
- **Every merged PR that changes shipped files** (`skills/`, `agents/`, `references/`, `.claude-plugin/`) **records the change under `## [Unreleased]` in `CHANGELOG.md`, in that same PR.** Release mechanics — Unreleased roll-up, manifest bump, tag on the merge commit, GitHub Release — follow `references/releasing.md` (the canonical statement; this repo dogfoods it). Repo-specific facts: plugin updates are detected by version comparison only, so Unreleased changes on `main` are invisible to installed users until a release PR lands — deliberate batching the Unreleased section makes visible.
