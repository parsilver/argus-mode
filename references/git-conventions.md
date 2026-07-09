# Git conventions

How everything that lands on git is named and written. These are not
style preferences: every artifact — branch, commit, issue, PR — is read
by developers who have zero session context, and by tooling (`bisect`,
`blame`, changelog generators). Write for the next dev, not for the
model. Applied at Stage 1 (issue, branch, draft PR) and at every commit
the lead makes in Stage 3.

## Branch names

Pattern: `<issue-number>-<short-kebab-slug>` — e.g. `42-add-pdf-export`.

- The leading number ties the branch to its issue at a glance, and
  matches what `gh issue develop` generates.
- Slug: lowercase kebab-case, 2–5 words, describes the change.
- Never: spaces, underscores, uppercase, or personal prefixes
  (`johns-fix`).
- Degraded mode (no issue): `<type>/<short-kebab-slug>` using a
  Conventional Commits type — `fix/session-timeout`, `feat/pdf-export`.

## Commit messages — Conventional Commits

Format: `<type>(<scope>)?: <subject>`

- Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`,
  `style`, `build`, `ci`.
- Subject: imperative mood ("add", not "added"/"adds"), lowercase after
  the colon (proper nouns keep their case), ≤72 characters, no trailing
  period. Aim for ≤50 — that survives every git UI untruncated.
- Scope: include when the change is localized (`fix(auth): …`); omit
  for repo-wide changes.
- Body: blank line after the subject, wrapped at 72. It explains
  **why**, not what — the diff already shows what. Omit it when the
  subject says everything.
- Breaking changes: `<type>!:` in the subject plus a `BREAKING CHANGE:`
  footer describing the impact and the migration.
- **Atomic commits.** One logical change per commit, and the tree is
  GREEN after every commit — `git bisect` and clean reverts depend on
  it. Never bundle a refactor and a behavior change in one commit.
- Refusal condition: "wip", "fix stuff", "update" are not commit
  messages — a commit that cannot state its own change is not ready to
  be one.

## Issue titles

One line that states the problem or the goal, specifically. ≤70
characters, no trailing period.

- Bug: the observable defect — "Login form accepts an empty password",
  never "bug in login".
- Feature: the outcome, imperative — "Export monthly report as PDF".

## Issue descriptions

Written so a developer with zero context can pick the issue up cold.

Feature:

- **Context / why** — the problem this solves, one short paragraph.
- **Scope** — a checklist of **failable acceptance criteria**, the same
  standard as `verification.md`: each item checkable, each able to go
  RED.
- **Out of scope** — what this issue deliberately does not cover.

Bug:

- **Expected vs actual** — one line each.
- **Reproduction steps** — numbered, minimal, exact commands or inputs.
- **Evidence** — error output, logs, environment/versions, captured
  verbatim (never paraphrased).

## PR titles and descriptions

The PR title becomes the merge commit subject under squash-merge — so
it follows the Conventional Commits subject rules exactly.

Description, in this order:

- **`Closes #<n>`** on the first line — the link is load-bearing
  (auto-close plus traceability from code back to intent).
- **What changed** — short bullets, grouped by area.
- **Why / approach** — what a reviewer cannot infer from the diff:
  alternatives considered, trade-offs taken, decisions made.
- **How it was verified** — the exact commands run and their results
  (Stage 4 evidence; "tests pass" without the command is not evidence).
- **Breaking changes / migration** — the section exists only when they
  do; omit it rather than writing "none".
- UI changes: before/after screenshots.
- **Keep PRs reviewable** — prefer under ~400 changed lines; when a
  bigger diff is unavoidable, say why in the description and point the
  reviewer at the load-bearing files first.

## How this document is used

- **Stage 1 (Intake)** — the issue title/description, branch name, and
  draft-PR skeleton are written to this standard (`pipeline.md` chains
  a read of this file at intake).
- **Stage 3 (Execute)** — every verified slice the lead commits follows
  the commit rules here (`delegation.md`, isolation model).
- **Stage 5 (Review & deliver)** — the PR description carries its Stage
  4 evidence before the review gate runs, and the PR title is the
  squash subject that lands on the default branch.
