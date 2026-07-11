# Pipeline

The git/GitHub mechanics shared by both skills: how work enters the repo
(Stage 1), how the plan stays durable and visible (Stage 2.5 onward), what
degrades when the platform doesn't cooperate, and how a Stage 5 verdict
turns into an action. Read this file at Stage 1, apply its scout step
and decomposition test at Stage 2, and read it again at Stage 5.

## Stage 1 — Triviality escape hatch (run this first)

Canonical definition, shared by both skills. Trivial means ALL of:

- ≤3 changed lines, AND
- one file, AND
- no public-API or behavior change — a bugfix changes behavior, so a
  bugfix is never trivial, AND
- no new test warranted.

Read-only lookups: trivial if answerable from one file.

Trivial → announce the classification ("this is a trivial edit — skipping
the pipeline"), handle it directly, stop. No creed, no ceremony.

**Re-entry rule:** if the "trivial" edit turns out to need a second edit,
a second file, or its first check fails → stop, announce the
reclassification, and enter the full pipeline at the git intake below.
The rule survives the commit: a hatch edit that fails **after** being
committed or pushed re-enters the full pipeline the same way, and a
broken commit it left on the default branch is reverted first ("A bad
merge reverts first", below) — the hatch never leaves a red default
branch as someone else's problem.

- Refusal condition: the hatch is not a bypass valve — a borderline task
  classified trivial without announcing the classification is an
  undisclosed skip of the pipeline.

## Read-only work (non-trivial lookups)

Analysis, investigation, or a question that needs more than one file
fails the hatch but produces **no diff and nothing to merge** — it never
enters the git intake. Route: plan (Stage 2) → oracle plan review →
explore/verify → deliver the report. The moment the work turns out to
need a code change, re-enter at the git intake below.

**The report contract.** Findings deliver in this shape, matching the
scout agent's own output rules: the question as asked → what was
searched (so a negative result reads as informed, not skipped) →
findings, each carrying a `file:line` citation → open questions the
codebase could not answer.

**The landing rule.** A one-shot answer may deliver in chat. Findings
that feed later work, outlive the session, or hand off mid-run land on
a `question` issue — created for the investigation, labeled per the
intake's label rule (existing label only; absent → skip the label and
say so in the issue body), answered as a comment in the report shape,
then closed; closed issues stay searchable. When unsure whether a
finding outlives the session, land it on an issue — durability is
cheap to over-provide and impossible to retrofit. On a mid-run
handoff, create the issue at the handoff point: the plan comment and
its lifecycle attach to that issue, and it becomes the route's resume
point exactly as the intake issue is for code work. One exception
outranks the tie-breaker: findings that expose a vulnerability in a
publicly visible repo never land on a public issue — use a private
channel (a security advisory, or a report file on a branch) and name
the exception in the report. Degraded (no repo, no remote, or issues
disabled): offer a committed report file; if declined, deliver in chat
and name the degrade in the report.

- Refusal condition: an investigation whose findings the user will act
  on later, delivered only as chat prose, evaporates with the session
  — the landing rule is part of delivering, not an optional extra.

## Ambiguous ask — clarify before the issue

Acceptance criteria are the contract every later gate checks against —
inventing them for a vague ask makes the criteria-negation check
validate the author's own framing. When the request is a new
capability whose acceptance criteria cannot be derived from what the
user actually said: ask targeted questions, or present two or three
shaped options, before the issue is written. Record the answers in the
issue's Context section — the criteria then trace to the requester,
not to the pipeline's guess.

- Refusal condition: an issue authored for an ambiguous ask without a
  recorded clarification is self-made framing wearing a contract.

## Stage 1 — Git intake

Run these four steps, in order, when the project is a git repo. (No repo,
no remote, no `gh`, no issue permission — see Degradation rules below;
each has a defined substitute for these steps, never a silent skip.)

**Every name and message these steps produce follows
`git-conventions.md` — read it together with this file.** Branches,
commits, issues, and PRs land on shared repos and are read by developers
with zero session context; the conventions are part of the deliverable,
not decoration.

1. `git fetch origin`, then fast-forward the default branch to origin —
   branch off the latest, not a stale local copy.
2. Create a GitHub issue describing the work: `gh issue create` — title
   and description per `git-conventions.md` (failable acceptance
   criteria; bugs carry expected/actual, repro steps, verbatim
   evidence). Fill every metadata dimension the repo actually has —
   the Issue metadata contract below: discover, then apply; never
   invent.
3. Branch — named `<issue-number>-<short-kebab-slug>`:
   - `gh issue develop <n>` (or `git switch -c` if `gh issue develop`
     isn't available).
   - Use an isolated git worktree whenever the working tree is dirty OR
     other work is in flight.
   - A clean solo checkout may branch in place — no worktree needed.
4. Bootstrap the PR immediately, before writing any implementation code:
   - Create an empty bootstrap commit.
   - Open a **draft** PR with `Closes #<n>` on the first line of the
     description; title and description contract per
     `git-conventions.md` (the title is the future squash subject).
   - This draft PR mirrors the plan comment (posted at Stage 2.5) and
     anchors the durable state its checklist updates keep current.

- Refusal condition: implementation work starting before the draft PR
  exists skips the durable-state contract every later stage depends on —
  do step 4 first, not last.
- The PR flips from draft to ready only at Stage 5, on a `ship` or
  `fix-then-ship` verdict (see the mapping below) — never before the
  review gate.

## Issue metadata — fill what the repo has, invent nothing

One discovery pass at intake, five dimensions. Fill each by meaning; a
dimension the repo doesn't have, or a value that isn't derivable, is
left empty and named once in the final report — never a silent skip.

The boundary: a value is filled when it is **derivable** from the work
itself or from the requester's words. Type, labels, and relationships
follow from the work; a milestone is assigned when an open one clearly
covers it. Judgment values — priority, size, iteration — are filled
only when the requester stated them or the issue text carries them;
the pipeline never invents a team's judgment call, because an empty
field reads as unset while a guessed one reads as decided.

| Dimension | Discover | Apply |
|---|---|---|
| Labels | `gh label list` | Map the work's Conventional Commits type onto existing labels (feat → enhancement, fix → bug, docs → documentation). No match → skip; create a label only on the user's ask. |
| Milestone | `gh api repos/<owner>/<repo>/milestones` | Assign when an open milestone clearly covers the work; otherwise leave empty. |
| Issue type | Probe `repository.issueTypes` via GraphQL; null means the repo has no types — an organization-level feature, so user-owned repos always return null and take the named degrade. | Set Bug / Feature / Task by the work's nature: `gh issue create --type` / `gh issue edit --type` (recent `gh`, verified on 2.95.0), or GraphQL `updateIssueIssueType` with the type id; neither available → named degrade. |
| Projects fields | The board per Project-board sync below; `gh project field-list` for its fields | Status follows the sync table — its mechanics live there, not here. Other fields fill only under the derivable boundary above; fields and options are never created. |
| Relationships | Native sub-issues via GraphQL `addSubIssue`; issue dependencies via GraphQL `addBlockedBy` / `removeBlockedBy` (`issueId`, `blockingIssueId`) | Decomposition slices land as native sub-issues of the parent. Serially merged sub-issues carry blocked-by dependency links when supported — slice N+1 blocked by slice N; unsupported → the ordering stays in the parent checklist and the degrade is named. |

- Attribution metadata is banned the same way attribution prose is
  (`git-conventions.md`, team voice): a label, milestone, or field
  value crediting a tool is never created and never reused.
- Refusal condition: a dimension skipped without being named in the
  final report is a silent skip — the contract's one job is making
  every gap visible.

## Resume — the receiving side

Intake creates durable state; resume reads it back. When the request
names an existing issue, PR, or branch — or the repo already holds an
in-flight branch whose plan comment covers this task (`gh pr list
--state open`, `git branch --list '<n>-*'`) — adopt that state instead
of re-running intake:

1. The model gate still runs — the resuming session's model may differ
   from the one that started the work. The creed is recited once per
   session, resumed runs included.
2. Intake steps 2–4 are replaced by adoption: fetch, check out the
   existing branch (or its worktree), and read the plan comment — it
   is the checklist of record. Adopted state with **no** plan comment
   means the run died before plan approval — enter at Stage 2 and
   plan against the adopted issue and branch.
3. **Reconcile before trusting it: the branch's commit log outranks
   the comment.** A session can die between a commit and the comment's
   update, so diff the ticked items against
   `git log <default-branch>..HEAD` first — tick what the commits
   prove done, append the missing evidence, then enter at the first
   genuinely open item.
4. An approved plan whose content is unchanged is not re-reviewed on
   resume; a plan the resuming session changes re-enters the plan
   review gate before execution continues.
5. A review outcome recorded on the comment but not yet acted on (see
   the plan-comment lifecycle) is applied before any new work — its
   findings fixed or its rework path taken, exactly as if the verdict
   had just arrived.

Intake creates new state only when no prior state exists — no issue,
no branch, no plan comment.

- Refusal condition: re-running intake over discoverable in-flight
  state files a duplicate issue and PR for half-finished work — the
  split-brain the durable state exists to prevent.

## Scout before you plan

A plan written against surfaces the lead has not read is guesswork
wearing a table. When the task touches files or subsystems not read
this session — or read but no longer available in context; when in
doubt, scout — name the reconnaissance questions first, answer them —
direct reads, or the scout agent for breadth — and record the result
as a `Scouted:` line in the plan header (areas read, questions
answered, anything that changed the plan's shape). The plan review
checks the plan against this record (`verification.md`).

- Refusal condition: a plan header with no `Scouted:` record on a
  surface the lead first opened this run is unreviewable optimism —
  the plan review sends it back.

## Decomposition — the big-work counterpart of the triviality hatch

Trivial work escapes the pipeline; oversized work must not squeeze
through it as one piece. At Stage 2, when the plan crosses any of:

- more than ~5 implementation stages, or
- an expected diff past the reviewable bar (`git-conventions.md`,
  ~400 changed lines), or
- multiple independently shippable outcomes,

decompose instead of proceeding as one PR:

- The parent issue holds the goal and the full plan checklist.
- Each slice becomes a sub-issue — native sub-issues where available
  (GraphQL `addSubIssue`); a task list of issue links in the parent
  body otherwise — with its own branch and PR, sized to review.
- Slices merge serially — with blocked-by dependency links between
  consecutive slices per the Issue metadata contract above, where the
  host supports them — and the tree is releasable after every merge.
  Sub-issue branches may be *developed* in parallel, but before each
  serial merge the branch is updated onto the current default branch
  (rebase or merge) and its verification suite re-runs there — a green
  obtained on a stale base is not merge evidence.
- The parent closes only when its checklist is complete — never by a
  PR that leaves items unmet.

The oracle checks this at the plan review (`verification.md`): an
oversized single-PR plan is a `revise`.

- Refusal condition: a plan that fails the size test and ships as one
  PR anyway has bypassed the reviewable-PR bar the same way a skipped
  gate would — decompose it, or justify the size in the PR description
  per `git-conventions.md`.

## Project-board sync

Work that isn't on the repo's board is invisible to everyone who
tracks the project there. At intake, detect a Projects v2 board —
`gh project list --owner <owner>` (requires the `project` token
scope), or the board the repo's recent issues already sit on. When one
exists, add the issue to it and advance its Status field at these
boundaries:

| Pipeline event | Board Status |
|---|---|
| Intake complete (issue + branch + draft PR) | In Progress |
| Review gate begins (Stage 5) | In Review |
| Merged | Done |
| Escalation to the user, a hold, or a blocked dependency | Blocked |

Map by meaning onto the board's own option names ("Doing" counts as In
Progress); never create fields or options on the board. Sub-issues get
the same treatment as their parent.

- Refusal condition: a board update skipped silently at a boundary is
  the board lying to its readers — when the board can't be updated (no
  board, missing scope, no option that maps by meaning), name it once
  in the final report instead.

## Plan-comment lifecycle

Posted once, then kept current — this comment is the pipeline's durable
state and the exact resume point a handoff relies on (`on-track.md`).
It is also a git artifact read by humans: written in the team voice
(`git-conventions.md`) — headed "Implementation plan", plain
engineering language, no session vocabulary — and it passes the
lexicon check before the initial post and before every subsequent
edit.

| Event | Action |
|---|---|
| Stage 2.5 oracle verdict = `approve` | Post the plan as an issue comment headed "Implementation plan": the stages as a `- [ ]` task list, each item named (never numbered by pipeline stage), each carrying its done-check as `command → expected result`; design decisions with their reasons; long coordination detail folded into `<details>`. Mirror a link to it in the draft PR description. |
| Every stage completion, Stage 3 onward | Tick the finished item's checkbox and append its evidence as `command → result`. Status words for anything not checkbox-shaped: done / in progress / blocked. |
| Stage 5 verdict received (and any plan re-review after it) | Before acting on the verdict, append the outcome in team voice — what the review found, in one line, and the running round count ("code review round 2 of 2: two findings, fixing"). Rework and revise caps survive a handoff only when the comment carries the count. |
| Mid-pipeline handoff | Comment reflects state at the moment of handoff; a fresh session resumes via the Resume path above — the branch's commit log outranks the comment, so the resuming session reconciles first. |

- Commit SHAs cited in the comment stop resolving on the default
  branch after a squash-merge — cite them as PR-linked references (the
  PR keeps them alive) or as full commit URLs.
- Refusal condition: a stage boundary that passes without updating the
  comment breaks the resume contract, and a post or edit that skips
  the lexicon check ships session vocabulary to a human audience — the
  update, in the team voice, is part of finishing the stage.

## Degradation rules

Every stage has a defined degraded form. Never silently skip a pipeline
step — name the degraded form, every time it triggers, in the final
report.

| Condition | Issue / PR | Plan lives in | Reviewer scope | Merge semantics |
|---|---|---|---|---|
| No git repo | Offer `git init`; if declined, skip the git layer for every stage | The final report | Files created/modified this session | N/A — deliver = the final report |
| Git repo, no remote at all | Local branch only; skip issue and PR | `PLAN.md`, committed on the branch | `git diff <default-branch>...HEAD` | Local `git merge --no-ff` into the default branch, after the review gate — remove `PLAN.md` in a final commit on the branch first, so run state never lands on the default branch |
| Remote exists, `gh` CLI missing | Skip issue and PR (no API access); push the branch to the remote | `PLAN.md`, committed on the branch | `git diff <default-branch>...HEAD` | **Never merge locally while a remote exists** — the local default branch would diverge from origin and the next intake's fast-forward breaks. Deliver the pushed branch and its compare link, named in the final report; opening and merging the PR is the user's step. Push rejected (no rights) → deliver the branch locally (`git bundle` or patch file, or the user pushes), named the same way |
| Remote exists, no push rights (fork / OSS contribution) | Issue on upstream when creatable, else skip and note; `gh repo fork --remote`, branch pushed to the fork | Issue comment as usual (PR description when no upstream issue) | Normal — PR diff | Cross-fork draft PR, readied after the review gate; merging belongs to the maintainer — deliver = the ready PR, named in the final report |
| Issues disabled on the repo, or no permission to create them | Branch + PR, no issue | Plan comment moves to the PR description (no issue thread to host it) | Normal — PR diff | Normal — merge the PR; note the missing issue in the final report |
| User opts out ("no issue for this one") | Honor it: branch + PR, no issue | Plan comment moves to the PR description | Normal — PR diff | Normal — merge the PR; note the opt-out in the final report |
| No Projects v2 board, or the token lacks the project scope (`project` in `gh auth status`) | Normal issue/PR flow | Issue comment as usual | Normal — PR diff | Normal — board sync skipped, named in the final report |

- Refusal condition: a degraded form that isn't named in the final
  report is an undisclosed degrade, not a permitted one.

## Terminal-outcome cleanup

A run's last artifact is a clean tree. At every terminal outcome —
merge, `reject`, or an abandonment the user confirms — remove what the
run created and no longer needs, and name it in the final report:

- a worktree created at intake is removed (`git worktree remove`);
- the local branch is deleted after its merge (the remote branch per
  the repo's delete-on-merge setting); an abandoned branch is deleted
  locally and on the remote once the user confirms the abandonment;
- on `reject`, remove the worktree but **keep the branch** — it holds
  the rejected work the user was just pointed at (and, degraded, the
  post-mortem record); deleting it is the user's call, never the
  run's.

An unmerged branch under an open escalation or hold stays — cleanup
applies to terminal outcomes, not pauses.

- Refusal condition: a merged run that leaves its worktree and branch
  behind turns the next intake's "other work in flight" check into a
  false positive — cleanup is part of delivering, not housekeeping to
  skip.

## Stage 5 — Verdict → action mapping

| Verdict | Action |
|---|---|
| `ship` | Flip the draft PR to ready, merge — the issue auto-closes. |
| `fix-then-ship` | Fix the findings, re-run Stage 4 (verify), then merge. No fresh review required. |
| `rework` | Return to Stage 3 (or Stage 2 if the plan itself is implicated — the revised plan re-enters the Stage 2.5 plan review before execution resumes, and the revise-cycle cap keeps counting). A fresh Stage 5 review is mandatory afterward. |
| `reject` | Stop. Do not merge. Report the reviewer's reason to the user. |

- **Rework cap: two cycles.** A third `rework` verdict on the same piece
  of work does not get a third silent attempt — escalate to the user
  with both positions (what the reviewer flagged, what was tried) and
  proceed per their call, noted in the final report.
- Refusal condition: merging over a `rework` or `reject` verdict, or
  skipping the fresh Stage 5 review after a `rework` cycle, is not a
  shortcut — it is the review gate failing to gate.

## Subjective goals — the user holds the acceptance ask

When the goal is perceptual — visual fidelity to a reference, look and
feel, "reads like X" — a merging verdict (`ship`, or `fix-then-ship`
once its fixes are in and re-verified) readies the PR and posts the
comparison evidence (per-surface screenshots against the named
reference, light and dark where schemes exist), but does not merge.
The merge waits for the user's explicit yes at the acceptance ask: a
diff-reading review cannot judge what the user will see, and the model
does not grade "looks right" on the user's behalf.

- A rejection at the acceptance ask returns the work to Stage 3 on the
  same branch. Each such cycle re-runs Stage 4 and the Stage 5 review
  gate before the next acceptance ask — no fast path from edit to
  re-ask.
- User-directed cycles sit outside the rework cap: the cap bounds
  automation disagreement, and here the human is the gate. But a
  non-converging repeat — the same rejection reason returning with no
  new information — is a loop signal (`on-track.md`): stop, lay out
  what each cycle tried and what changed, and ask for direction
  instead of churning.
- Refusal condition: merging a subjective-goal PR on the reviewer's
  verdict alone — `ship` or `fix-then-ship` — without the user's
  acceptance repeats the failure this rule exists to prevent: the gate
  that mattered would run after the merge.

## A check that cannot run fails its stage

A planned check that turns out to be un-runnable — missing harness,
unavailable backend, absent fixture — leaves its stage NOT done.
Disclosure is not a substitute for evidence. Two exits:

1. Build what makes the check runnable — a mock backend, a fixture, a
   comparison harness — or
2. ask the user for an explicit waiver, recorded in the plan comment
   before any merge.

- Refusal condition: `ship` or `fix-then-ship` over a planned check
  that never ran is a green claim without its evidence — the exact
  thing Stage 4 exists to forbid.

## Post-merge rejection re-enters the full pipeline

When the user rejects an already-merged result, the follow-up is a
full pipeline run — plan, plan review, execution, review gate.
Urgency is not a fast path: the rejected merge is evidence the gates
were needed, not license to skip them.

- An issue closes only when its acceptance checklist is met. A PR that
  defers checklist items does not carry `Closes #<n>` — the unmet
  criteria move to a follow-up issue, named in the PR description.
- Refusal condition: a rejection-driven follow-up that skips the plan
  or the review gate, or a deferring PR that auto-closes its issue,
  reproduces the failure being corrected.

## A bad merge reverts first

When a merged change breaks production or must come off the default
branch now, the default is revert-first, fix-forward second:

- **Expedited revert path:** issue (one line — what broke, which
  merge) → revert PR (`git revert` of the squash commit) → Stage 4
  evidence → review gate → merge. No plan gate: the revert's goal and
  content are fully specified by the commit it inverts.
- The expedited path applies only to a **clean revert**: `git revert`
  applies without conflict, reintroduces no symbol the tree no longer
  defines or references, and removes no symbol the remaining tree
  still references. Anything else is a real change — full pipeline.
- **Fix-forward instead** only when the revert is not clean or data
  has already migrated — justified in the issue, not assumed.
- The real fix re-enters as a full pipeline run (Post-merge rejection,
  above), linking the revert commit from its issue.

- Refusal condition: an outage "hotfix" that skips the review gate,
  and a full plan cycle demanded before reverting a breaking merge,
  are the same mistake in opposite directions — the expedited path
  exists so neither happens.
