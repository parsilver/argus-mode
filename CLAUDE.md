# Repo conventions — argus-mode

Consistency invariants for any session editing this repo. Preserve these automatically.

- Every skill gets an entry in the top-level `README.md` (name linked to its `SKILL.md`). Only list skills in `.claude-plugin/plugin.json` if the manifest schema supports a `skills` field — verify against `skills/` auto-discovery before adding one; don't duplicate what auto-discovery already covers.
- Every agent appears in the README agent table with its model and one-line mandate. Add the agent to both places in the same change — never one without the other.
- `references/` files are shared by both skills (`run` and `consult`). Before finishing any edit under `references/`, re-read both `skills/run/SKILL.md` and `skills/consult/SKILL.md` and confirm they still hold against the change.
- **Every merged PR that changes shipped files** (`skills/`, `agents/`, `references/`, `.claude-plugin/`) **bumps the version** — `.claude-plugin/plugin.json` and `CHANGELOG.md` together, in that same PR. Never bump one without the other, and never merge a shipped-file change under an unchanged version: plugin updates are detected by version comparison only, so an unbumped change is invisible to every installed user.
- After each release merge, tag `v<version>` on the merge commit and create the GitHub Release matching the CHANGELOG entry.
