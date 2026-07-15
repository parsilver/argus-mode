# Git conventions

How everything that lands on git is named and written. These are not
style preferences: every artifact — branch, commit, issue, PR — is read
by developers who have zero session context, and by tooling (`bisect`,
`blame`, changelog generators). Write for the next dev, not for the
model. Applied at Stage 1 (issue, branch, draft PR), at the Stage 2.5
plan-comment post and every stage-boundary edit that follows it, at
every commit the lead makes in Stage 3, and at the Stage 5 PR text.

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

## Team voice — session machinery stays out of git

Every git artifact reads as one engineer writing to teammates. The
pipeline, its agents, and its internal stage numbers are session
machinery — they run the work; they are not the work. Narrating them to
a repo audience is pasting a shell transcript into a design doc.

- **No session vocabulary.** Agent and pipeline names used as actors,
  gate/verdict narration ("approved by the … gate", "revise cycle",
  "fix-then-ship"), and internal jargon ("failable check", "fan-out",
  "GREEN", "the lead", "checkpoint") never appear on a git artifact.
  Say what happened as a dev would: "plan revised once in design
  review", "code review found two issues; both fixed", "verification
  re-run after the fix".
- **Name work, don't number it.** "the config page", "the token
  migration" — never raw pipeline stage numerals. A stage number means
  nothing outside the session that defined it, and two numbering
  schemes in one tracker read as out-of-order noise.
- **No attribution, ever.** No "generated by/with", no bot sign-offs,
  no tool credit in any form, on any artifact — a standing product
  decision, not a default to re-litigate. The artifact is team
  communication and stands as such. Metadata counts: a label,
  milestone, or field value crediting a tool is never created and
  never reused — one already planted in a repo is not "an appropriate
  existing label"; report it to the user instead of adopting it.
- **Evidence is command → result.** `npm test → 166 pass`,
  `cargo build → exit 0`. Not "tests green", not a paraphrase.
- **Status is a task list.** Progress tracks as `- [ ]` / `- [x]`
  checkboxes — GitHub renders them as progress everywhere the issue
  appears. Status words: done / in progress / blocked. No emoji
  markers.
- **No machine-local paths.** `~/…` and `/Users/…` resolve on one
  machine only. Cite external assets by product + version + source
  ("Fuse v21.1.0, ThemeForest license"), and say where the repo's copy
  lives if one exists.
- **No inlined infra values the artifact doesn't need.** "the API URL
  in `environment.prod.ts` is unchanged" — the file path is the
  reference; the value stays out of the prose.
- **Fold long coordination detail into `<details>`.** The summary stays
  scannable; the folded content follows every rule here — a collapsed
  block is not a jargon amnesty.
- **The lexicon check.** Before posting or editing any issue, PR, or
  comment text, grep the draft:

  ```
  grep -inE 'argus|oracle gate|revise cycle|fix-then-ship|implementer|explorer agent|reviewer agent|checkpoint [0-9]|failable|stage [0-9]+ (done|gate|review)|generated (by|with)|co-authored-by' draft.md
  ```

  Any hit is a rewrite, before it posts — with one triage rule: a hit
  that is the repo's own domain vocabulary (an Oracle database, a WAL
  checkpoint, a rollout's own stage numbering) is a false positive; the
  rewrite command targets session narration. When in doubt, ask whether
  the sentence describes this run's internal process — only that gets
  rewritten.
- **Carve-out — repos whose subject matter is the pipeline.** Where the
  pipeline itself is the product under edit (this plugin's own repo),
  its vocabulary is product terminology and appears as content; the
  lexicon check does not apply verbatim there. Session narration about
  the current run stays banned even then — "the plan-review rubric
  gains a decomposition check" is content; "approved by the oracle gate
  (revise cycle 1)" is narration.
- Refusal condition: session vocabulary, attribution, a machine-local
  path, or an inlined infra value on a git artifact is a Readability
  finding (dimension 2, `verification.md`) — the same defect class as
  an ad-copy docblock, and grounds to rewrite the artifact before it
  ships.

## Diagrams on git artifacts

GitHub renders Mermaid fenced blocks natively in issues, PRs, comments,
discussions, wikis, and Markdown files. A small diagram is welcome on
any git artifact where a flow is easier seen than read — under the same
discipline as everything else in this file:

- **Illustrate, don't govern.** The text is the source of truth: every
  contract, checklist, and acceptance criterion lives in prose that
  checks can grep. A diagram restates what the text already says —
  never carries something the text doesn't. Not every surface renders
  Mermaid (GitHub Projects and the mobile apps show raw source), and
  tooling reads artifacts as text, so content that lives only in a
  diagram is invisible exactly where it matters.
- **Stable types only.** GitHub's deployed renderer trails Mermaid
  releases by months — keep to flowchart, sequence, and state
  diagrams. No click or callback interactivity — GitHub's sandbox
  strips it — and no custom themes.
- **Team voice applies inside the diagram.** Node labels, edge labels,
  and titles are artifact text like any other — the lexicon check
  covers the whole artifact, diagram source included.
- **Beyond a fenced block, route through the diagram skill.** When a
  diagram-rendering skill is installed (routing table, `delegation.md`),
  author through it anything a Mermaid block cannot express — a
  vendor-icon architecture, a data chart — delivered as an image. A
  Mermaid type outside the stable trio (flowchart, sequence, state) is
  delivered as an image too, never as a block.
- **Raster sequencing.** The skill's delivery for a public repo commits
  the image to the repo's orphan `assets` branch and never pushes; the
  lead runs the printed `git push origin assets` before posting any
  artifact that embeds the URL — the URL resolves only after that push.
  `assets` is infrastructure, not a work branch: exempt from the
  `<issue-number>-<slug>` pattern, never force-pushed, never merged.
- **Private repositories get no raster embeds.** There is no attachment
  API, and the image proxy will not fetch private raw content, so an
  embedded image cannot resolve on a private-repo issue, plan comment, or
  PR body — those bodies stay Mermaid blocks only. A raster that matters
  becomes a docs deliverable on the work branch, referenced by relative
  link; otherwise it is omitted and the degrade named.
- **Diagram source is artifact text.** The lexicon check runs on the
  diagram source (`.mmd`/`.py`/`.dot`/`.puml`) before rendering, the same
  as any other artifact text; and a committed image keeps its source
  committed beside it — next to the ADR it illustrates, say — so the
  diagram stays greppable and regenerable.
- Refusal condition: a git artifact whose acceptance criteria, plan
  items, or any other load-bearing content exist only inside a diagram
  has hidden them from the checks and from every non-rendering surface
  — move the content to text and let the diagram restate it.

## Decision records

A decision the plan marks as load-bearing beyond its own PR — an
architecture choice future work must respect, a rejected alternative
that will tempt again — gets a committed decision record:
`docs/adr/NNNN-<slug>.md` (or the repo's native equivalent), one page:
context, the decision, the consequences. Commit it with the change and
link it from the plan comment — the plan comment records state; the
decision record outlives it.

- Refusal condition: a load-bearing decision that lives only in a
  closed issue's comment thread is findable by archaeology, not by the
  next dev — that is mentioned, not recorded.

## Prose style — write like a dev, not a model

Applies to every prose artifact the pipeline writes: issue and PR
descriptions, issue comments (including the plan comment), commit
bodies, docblocks, READMEs, release notes. Adapted,
with credit, from the humanizer skill
([blader/humanizer](https://github.com/blader/humanizer), built on
Wikipedia's "Signs of AI writing"). For long user-facing prose (docs,
READMEs, release notes), route through an installed `humanizer` skill
when present (routing table, `delegation.md`); the rules below are the
shipped baseline for everything the pipeline writes.

- **No filler.** "It's worth noting that", "In summary", "Overall" — the
  sentence works without them, or it doesn't work at all.
- **No promotion.** A PR "adds retry on 5xx errors"; it does not
  "elegantly enhance resilience". Behavior ships; adjectives don't.
- **No rule-of-three padding.** "Faster, simpler, and more maintainable"
  — pick the one that's true and prove it.
- **No sycophancy or collaboration artifacts.** "Great question!",
  "I hope this helps!", "Let me know if…" never belong in a git
  artifact.
- **No generic conclusions.** Never end an issue or PR with a paragraph
  restating what the reader just read.
- **Plain verbs.** "X is the cache key", not "X serves as the cache
  key" or "plays a crucial role in caching".
- **Hedge only with evidence.** "may", "might", "could potentially" —
  either verify and state it, or name the open question directly.
- **Formatting is not emphasis.** No bold spam, no emoji in commit
  messages or code, headings only where structure needs them.
- **Docblocks follow the same rules**: what it does, why it exists, its
  constraints — never "seamlessly", never "a crucial component".
- Refusal condition: prose that reads like a model wrote it is a review
  finding under Readability (dimension 2), exactly like a missing
  docblock.

## How this document is used

- **Stage 1 (Intake)** — the issue title/description, branch name, and
  draft-PR skeleton are written to this standard (`pipeline.md` chains
  a read of this file at intake).
- **Stage 2.5 and every stage boundary** — the plan comment is posted
  and edited to this standard: team voice, checkbox statuses,
  `command → result` evidence (`pipeline.md`, plan-comment lifecycle).
- **Stage 3 (Execute)** — every verified slice the lead commits follows
  the commit rules here (`delegation.md`, isolation model).
- **Stage 5 (Review & deliver)** — the PR description carries its Stage
  4 evidence before the review gate runs, and the PR title is the
  squash subject that lands on the default branch.
- **Prose style and team voice** — bind everywhere prose is written:
  Stage 1 issue/PR text, every issue comment the pipeline posts or
  edits, Stage 3 commit bodies and docblocks, and Stage 5, where a
  violation is a Readability (dimension 2) finding.
