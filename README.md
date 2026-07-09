# Argus Mode

A Claude Code plugin that packages a disciplined, staged engineering workflow as
reusable skills and agents. Like Argus Panoptes — the hundred-eyed giant — every
stage of work is watched by an independent verification eye: an independent
agent reviews the plan before execution, and a separate gate reviews the diff
before merge. Nobody grades their own work.

## Install

Official install — this repo is its own marketplace:

```
/plugin marketplace add parsilver/argus-mode
/plugin install argus-mode
```

The real commands are [`/argus-mode:run`](skills/run/SKILL.md) and
[`/argus-mode:consult`](skills/consult/SKILL.md) — Claude Code always
namespaces plugin skills by plugin name, so `/argus-mode` alone does not
resolve to anything.

Third-party install via `npx skills add parsilver/argus-mode` (vercel-labs) is
**skills-only** — it does not install the agents (`argus-oracle`,
`argus-explorer`, `argus-implementer`, `argus-reviewer`), which ship only with
the Claude Code plugin. A skills-only install may also leave
`${CLAUDE_PLUGIN_ROOT}` unset, making the shared `references/` documents
unreachable — the skills then run from their own inline summaries. Both
`SKILL.md` files check agent availability first; when an agent or a
reference is missing, its gate runs inline by the lead instead — a weaker
check, and the final report says so openly. It is never a silent degrade.

## Updating

```
claude plugin marketplace update argus-mode
claude plugin update argus-mode@argus-mode
```

Then restart the session to apply. Updates are detected by the `version`
field in `plugin.json`, and the installer reads your **local marketplace
clone** — always update the marketplace first, or the installer compares
against a stale snapshot and reports "already installed".

## Model matrix

| Session model | Command | What you get |
|---|---|---|
| Fable, Opus | `/argus-mode:run` | Full pipeline. `argus-reviewer` runs at `inherit` tier — an opus-tier review gate. |
| Sonnet, Haiku | `/argus-mode:consult` | Same pipeline, executed by the cheap model, with mandatory `argus-oracle` (opus) checkpoints at plan review, execution triggers, and final review. |
| Sonnet, Haiku | `/argus-mode:run` | Hard stop. Three doors offered: switch model and re-run, run `/argus-mode:consult` immediately in the same turn, or explicitly say "proceed anyway" to run with reduced guarantees (recorded in the final report). |
| Fable, Opus | `/argus-mode:consult` | Reverse gate: announces the redirect and runs `/argus-mode:run` directly in the same turn — no stop, no retyping. |

## The pipeline

1. **Model gate** — confirm the lead is on an accepted tier for the command invoked.
2. **Intake** — triviality check (escape hatch for genuinely small edits); otherwise git intake: issue → branch/worktree → draft PR.
3. **Plan** — staged three-column plan (what/owner, failable check, architecture & patterns); domain skill routing recorded.
4. **Plan review gate** — `argus-oracle` reviews goal-backward, simpler-alternative pass first; verdict `approve` or `revise`.
5. **Execute** — TDD red → green → refactor, solo or fanned out to `argus-implementer`/`argus-explorer`; the lead verifies and commits every slice.
6. **Verify** — run the real build/test/lint commands; GREEN evidence required before any "done" claim.
7. **Review & deliver** — `argus-reviewer` (or the oracle, in consult mode) runs the 6-dimension gate; verdict `ship / fix-then-ship / rework / reject` maps to merge, fix-and-merge, rework, or stop.

## Agents

| Agent | Model | Mandate |
|---|---|---|
| `argus-oracle` | opus (pinned) | Advisor, never executor: plan review, architecture consultation, and — in consult mode — the final review gate. |
| `argus-explorer` | haiku | Fast, read-only codebase reconnaissance; reports `file:line` findings, not file dumps. |
| `argus-implementer` | sonnet | Executes one self-contained implementation slice TDD-first; edits files but never commits. |
| `argus-reviewer` | inherit | The 6-dimension review gate on the diff; refuses non-GREEN diffs; never spawned in consult mode. |

## What this costs

This is not the cheap path — it is the quality-first path, and it says so up
front. A medium task pays: the git ceremony (issue, branch/worktree, draft
PR), at least one `argus-oracle` run (more if the plan goes through revise
cycles), and a review-gate run before merge. `/argus-mode:consult` is the
cheap-**execution** path, not a cheap path overall — its mandatory oracle
checkpoints can exceed what a plain small-model session would cost on its
own.

**When not to use it:** one-off lookups, throwaway spikes, exploratory
prototypes you intend to discard, or any change that clears the triviality
bar (≤3 changed lines, one file, no public-API or behavior change, no test
warranted) — the pipeline's own escape hatch declines the ceremony for these
and handles them directly.

## Development

The `plugin-dev` plugin (from the official Claude Code plugin marketplace) is
a development dependency of this repo, not a runtime one — it is used to validate
`plugin.json`/`marketplace.json`/skills/agents structurally
(`plugin-dev:plugin-validator`) and to review both `SKILL.md` files for
triggering and clarity (`plugin-dev:skill-reviewer`) before every tagged
release. End users installing `argus-mode` do not need it.

## License

MIT — see [`LICENSE`](./LICENSE).
