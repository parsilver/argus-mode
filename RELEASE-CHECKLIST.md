# Release checklist

Run before every tagged release; record the outcome per release in the
table at the bottom. The two validation agents ship with the
`plugin-dev` plugin (see README, Development).

## Every release

- [ ] `bash tests/run-checks.sh` → exit 0
- [ ] Plugin structure validation (plugin-dev validator agent) → pass
- [ ] Skill review of both `SKILL.md` files (plugin-dev skill-reviewer
      agent) → blocking findings fixed before the tag
- [ ] Version identical in `.claude-plugin/plugin.json`, the top
      CHANGELOG heading, and the tag (CI re-checks the tag on push)

## Smoke tests — from the design spec's validation section

Manual, per model tier. Run each at least once per minor release when
its surface changed; record honestly — "pending" beats a claimed pass.

| # | Test | Last passed |
|---|---|---|
| 1 | Full pipeline end-to-end on a Fable/Opus session: issue → plan → plan review → execution → verification → review gate → merge | v0.4.0 — this repo's own release ran it live (PRs #19–#22) |
| 2 | Sonnet/Haiku invoking the run command hits the hard stop with three doors; "proceed anyway" recorded in the final report | pending |
| 3 | Consult mode: a seeded mid-execution deviation fires its trigger and the advisor rules on it before work continues | pending |
| 4 | No-remote degradation: the plan lands in `PLAN.md`, the merge is a local `--no-ff`, the degrade named in the final report | pending |
| 5 | Mid-execution kill: a fresh session resumes from the plan comment alone, no hand-written summary | pending |
| 6 | Triviality hatch: a genuinely trivial edit is declined by the pipeline with the classification announced | pending |

## Release record

| Release | Every-release checks | Smoke tests |
|---|---|---|
| v0.5.0 | `bash tests/run-checks.sh` pass (35 checks) · plugin validation pass (7/7) · skill review pass, non-blocking (follow-ups filed) | #1 live — this release's own run (PRs #28–#31 and the release PR) |
| v0.5.1 | `bash tests/run-checks.sh` pass (35 checks) · plugin validation and skill review not re-run — docs-only patch from the 0.5.0 release review | none exercised — docs-only patch |
| v0.6.0 | `bash tests/run-checks.sh` pass (55 checks) · plugin validation pass (51 checks) · skill review: two blocking findings fixed in the release PR, ten non-blocking filed as #52 | #1 live — the hardening runs and this release (PRs #44–#49, #51) |
| v0.7.0 | `bash tests/run-checks.sh` pass (56 checks) · plugin validation pass (26 checks) · skill review: one blocking finding fixed in the release PR, eight non-blocking filed as #62 | #1 live — this cycle's full runs (PRs #57, #59) and this release; #2–#6 pending (this release's #52 fixes were wording clarifications, not behavior changes on those surfaces) |
| v0.8.0 | `bash tests/run-checks.sh` pass (164 checks) · plugin validation pass (13 checks) · skill review not re-run — the release PR changes no skill file, and both summaries were reviewed this cycle when #62 landed (v0.5.1 precedent) | #1 live — this cycle's full runs (#63 / PR #83, #62 / PR #84) and this release's own pipeline; #2–#6 pending (the roll-up changes no behavior surface those tests cover) |
| v0.9.0 | `bash tests/run-checks.sh` pass (177 checks) · plugin validation pass (16 checks) · skill review not re-run — neither #88 nor the release PR changes a skill file (v0.8.0 precedent) | #1 live — this cycle's run (#87 / PR #88) and this release's own pipeline; #2–#6 pending (the roll-up changes no behavior surface those tests cover) |
