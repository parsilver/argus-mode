# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added

- A duplication sweep on the TDD refactor leg, a reinvention signal in
  review dimension 3, and a post-implementation simplification routing
  row (`references/quality.md`, `references/verification.md`,
  `references/delegation.md`, both `skills/*/SKILL.md`, both review
  agents, `tests/run-checks.sh`): reuse was enforced before code
  existed — the simpler-alternative pass asks what already solves the
  goal — but nothing hunted duplication after, so a diff quietly
  reinventing a util the repo already ships passed every gate. The
  refactor leg now sweeps the changed set for reinvention (fold into
  the existing code, or justify the divergence in the plan comment — a
  failable outcome); dimension 3 treats reinvention unjustified in the
  plan as a finding, in all five copies of the dimension text; the
  routing table names an optional simplify-type skill for a completed
  diff, whose absent-skill fallback is the leg's own sweep. No new
  pass, no extra spawn; detection stays reviewer judgment. Check 32
  pins the doctrine RED-first. (#120)

- An architecture-shaping trigger at Stage 2, with a mandatory
  candidates comparison on triggered plans
  (`references/pipeline.md`, `references/verification.md`,
  `references/quality.md`, both `skills/*/SKILL.md`,
  `agents/argus-oracle.md`, `README.md`, `tests/run-checks.sh`): the
  plan's first architecture artifact was the single already-chosen
  design in its third column — the simpler-alternative pass probes
  only the reductive direction, and item 5 plus review dimension 3
  re-check that same anchor — so on new-subsystem work the lead's
  first plausible design shipped unchallenged. A plan is now
  architecture-shaping when any stage creates a new module or
  subsystem, a new public API surface, or a new architectural
  boundary (categorical arms, their text identical word-for-word
  across the conduct section, the plan-review rubric, and the
  advisor's checklist, each copy pinned and counted so drift goes
  red); a triggered plan
  carries an Architecture candidates block — at least two candidates
  with trade-offs, plus the chosen rationale, reuse or doing nothing
  admissible — and the plan review revises a triggered plan without
  it, checked against the trigger definition rather than reviewer
  discretion. In a decomposition each triggered slice plan carries the
  parent's block verbatim so the gate reads it in the slice's own
  text; the deviation trip lists in both skills mirror the arms, and
  the trips-nothing exclusions ride every copy of the definition.
  Non-triggered plans owe nothing (no absence line), so
  the hatch, small fixes, and the read-only route pay zero. The
  comparison rides the plan comment's existing design-decisions slot;
  load-bearing choices still land as decision records. Check 31 pins
  the doctrine RED-first. (#119)

### Changed

- Git intake now takes an isolated worktree on every full-pipeline run
  (`references/pipeline.md`, `references/delegation.md`, both
  `skills/*/SKILL.md`, `agents/argus-reviewer.md`, `README.md`,
  `tests/run-checks.sh`): step 3 used to take a worktree only when the
  in-flight probe fired, so two sessions entering intake at the same
  moment on a clean repo could each see no in-flight signal and both
  take the primary checkout. The conditional arm is gone — every run
  branches off `origin/<default>` in its own worktree
  (`git worktree add <path> -b <n>-slug origin/<default>`), no pipeline
  path ever runs `git switch` or a fast-forward inside the primary
  checkout, and the step-1 local-default fast-forward is retired with
  it. The in-flight probe survives as inventory feeding the intake
  announcement and Resume; Resume adds a worktree for an adopted branch
  that has none and never switches the primary checkout; with no remote
  the worktree branches off the local default tip; the triviality
  hatch, read-only route, and preview are unchanged (no branch, no
  worktree). The isolation model's premise is updated to match:
  executors work in the run's worktree, and briefs carry absolute paths
  into it because subagents inherit the session's original working
  directory — the primary checkout. The same inheritance trap is closed
  on the two surfaces that shared it: the review brief now names the
  run's working tree by absolute path (the intake worktree or, on a
  parked-primary resume, the primary checkout) and the reviewer
  anchors every command and re-run there — a brief naming no
  working-tree path is a refusal — and the
  lead's own commands run inside the worktree from its creation on,
  bootstrap commit included. The no-remote terminal merge is named as
  the one sanctioned move of the primary checkout (clean tree, after
  the review gate, escalating to the user otherwise); a primary
  checkout parked on an adopted branch stays where the user parked it
  after the merge, with the local-branch deletion deferred and named.
  Deliberately no config flag or
  opt-out. Check 30 pins the doctrine RED-first. (#122)

## [0.10.0] - 2026-07-21
### Added

- The untrusted-input scan bound to the read-only route
  (`references/pipeline.md`, `references/verification.md`,
  `agents/argus-oracle.md`, both `skills/*/SKILL.md`, `tests/run-checks.sh`):
  the trust boundary was drawn at git intake, which the read-only route never
  enters — leaving the route most likely to read a stranger's issue covered
  only by the review-agent backstop, and it is also the route with the least
  backstop, since it produces no diff for the security dimension to inspect.
  Binding it needed a decision first: plan-review item 2 revises every
  unratified trust tier and admits only the user's ratification, while a route
  that merges nothing has no contract for a ratification to attach to. A new
  `## Which route binds which question` section scopes the two intake
  questions. The scan binds on every route, unchanged. The tier resolves
  against what the requester relayed — ratified by relay for the artifact they
  pointed the run at, stated only inside that section so the general clause and
  the code-change route read exactly as before — and a contributing author the
  requester did not relay still goes through the minimum-over rule and can
  still leave the goal unratified. What gets ratified on this route is the
  question as asked, which is also what its plan header carries in place of the
  acceptance criteria, at all seven sites that demand them: four
  precondition-refusal blocks and three brief-construction sentences whose
  substitute lists (`PLAN.md`, the PR description) this route has neither of.
  The grant belongs to the route rather than to the run, so it expires where
  the route ends: a read-only run that re-enters the git intake as a code
  change re-resolves the tier under the general rule and refreshes the header
  record — a snapshot, not a standing grant, the same treatment resume and
  preview already give theirs.
  A delivered report may name the artifact it answers and say a span was
  quarantined from it; the formatted records, the span, and the author's handle
  stay session-side, and no permission level reaches a git artifact. The
  capability preflight's claim that this route creates no git artifacts is
  narrowed to intake, reconciling it with the landing rule that may create a
  `question` issue at delivery. A new check in `tests/run-checks.sh` (number
  28) guards the section, the seven criteria sites, item 2's own region in the
  three copies that bound the diff to an issue, and — as a pin rather than a
  presence check — that the general relay clause was not widened. Written
  before the prose so it fails first. The rule rides inside item 2 and the
  precondition, adding no plan-review item and no review dimension, so the
  parity counts (12 and 6) are unchanged. (#106)
- A `--preview` intake mode (`references/pipeline.md`, both `skills/*/SKILL.md`,
  `tests/run-checks.sh`): git intake created the issue, branch/worktree, and
  draft PR before the plan and its cost line existed, so a user unsure whether a
  task was worth the pipeline had to commit to those artifacts sight-unseen —
  the triviality hatch is binary and offered no "show me the plan and cost
  first, then let me decide." Invoked with `--preview` (or an unambiguous
  dry-run intent; an ambiguous invocation asks), the mode runs the read-only
  front of intake — the capability preflight, the untrusted-input scan and
  trust-tier probe, and `git fetch` — drafts the plan and per-run cost, then
  stops before creating any issue, branch, or PR. It prints the draft plan
  labeled "not yet oracle-reviewed", the cost estimate, which gates will fire,
  and which degrades apply, and ends on a proceed handshake. A trivial task has
  nothing to preview; an existing issue, PR, or branch takes the resume path
  instead. On the user's yes the drafted plan is reused into the normal run and
  still goes through the plan review — no gate is skipped, and the yes is a
  commitment to spend the pipeline, not a ratification of an otherwise
  unratified goal. Preview writes nothing durable and is session-only, and adds
  no plan-review item and no review dimension, so the parity counts (12 and 6)
  are unchanged. A new check in `tests/run-checks.sh` (number 27) guards the
  mode's section and both skills' summaries, written before the prose so it
  fails first. (#100)
- Gate counters and active degrades in the stage-transition marker
  (`references/on-track.md`, both `skills/*/SKILL.md`, `tests/run-checks.sh`): the
  mandatory marker showed only which stage finished and which is next. The
  two-cycle revise and rework caps and the retry bound existed and survived a
  resume on the plan comment, but were never surfaced as a live count — a user
  could not see "one send-back from escalation" without the model volunteering it,
  and active degradations and budget standing were not consolidated anywhere
  glanceable. The marker is now a compact block re-printed at every stage boundary:
  the marker line, a gate-counter line (each cap and its live count, always shown
  so headroom is visible before a cap escalates), an active-degradations line shown
  only when something is degraded (the capability preflight already announces the
  full set once at intake, so this is the running delta), and a budget line shown
  only when the request stated a budget, standing qualitatively against the action
  line — never an invented numeric meter, since no such counter exists to read.
  Every value renders state that already exists — the revise and rework rounds
  and the active check's retry-bound trace from the plan comment, the named
  degrades, the stated budget — so nothing new is tracked, and the block stays
  session-only, never a git artifact, the same contract the single line held.
  Both skills carry a compact form and defer the full rules to the shared
  reference. A presence self-check in `tests/run-checks.sh` (number 26) guards the
  counter row, the degraded and budget rows, and both skills' reference, written
  before the prose so it fails first; no plan-review rubric item and no review
  dimension is added, so the parity counts (12 and 6) are unchanged. (#99)
- A capability preflight at intake (`references/pipeline.md`, both
  `skills/*/SKILL.md`, `tests/run-checks.sh`): the pipeline discovered
  environment degradations — no `gh`, no remote, no push rights, issues disabled,
  no board, no issue types, no CI to mirror — one at a time mid-run and announced
  each as it hit it, so a run on a fresh repo learned its true shape piecemeal.
  The pre-Stage-0 agent-availability check already did the right thing for the
  four agents — one upfront announcement — but only for them. A new "Capability
  preflight" section in `references/pipeline.md`, placed above `## Degradation
  rules`, runs the read-only discovery probes once at intake and prints one
  table: each capability, its probe, and the mode this run takes for it — the
  git, remote, `gh`, push-rights, issues, and board rows reusing the exact
  `## Degradation rules` condition strings verbatim, the issue-type and CI rows
  the Issue-metadata-contract and `verification.md` vocabulary. It adds no
  capability and no gate — legibility only: it prints once and decides nothing,
  every degrade stays enforced where it already lives, and the table is
  session-only output, never written to a git artifact. The agent modes are
  re-shown as the table's top rows, but both skills keep announcing a missing
  agent directly — the floor that covers the read-only route (which prints no
  table) and a skills-only install (where the preflight's `pipeline.md` spec is
  unreachable) — the run skill's bullet reworded to re-show the modes in the
  preflight, the consult skill keeping its before-you-proceed offer and adding a
  non-blocking reference. The merge-time required-check and branch-protection poll
  stays out, since it is unknowable at intake. A presence self-check in
  `tests/run-checks.sh` (number 25) guards the section, both skills' references,
  the single-announcement anchor, the six verbatim degradation strings, and the
  consult offer, written before the prose so it fails first; no plan-review rubric
  item and no review dimension is added, so the parity counts (12 and 6) are
  unchanged. (#98)
- A mechanical secret-scan of the diff (`references/verification.md`,
  `references/quality.md`, `agents/argus-reviewer.md`,
  `agents/argus-oracle.md`, both `skills/*/SKILL.md`, `tests/run-checks.sh`,
  `tests/fixtures/`). The security dimension was the one review dimension with
  no required command — a reviewer saying "no secrets found" produced the
  opinion the pipeline forbids as a check everywhere else. The verify stage
  now scans every diff for committed credentials — a maintained scanner
  (gitleaks/trufflehog) preferred, a named regex-sweep shipped as the fallback
  — records the output `command → result`, and both review agents refuse a
  diff that arrives without it and audit the output the way they audit the
  test suite; `quality.md` principle 6 carries the writer-bar mirror. The
  shipped regex-sweep is fixture-tested for detection — it must flag a
  planted-secret fixture and stay clean on a false-positive fixture — so a
  broken fallback cannot silently report "nothing found", and
  deliberately-planted test fixtures are excluded by a named scanner allowlist.
  Generic sink review stays reviewer judgment, since a sink assertion cannot be
  mechanized without becoming a check that always passes — only the secret half
  becomes mechanical.
- Untrusted input at intake and a requester trust tier
  (`references/pipeline.md`, `references/verification.md`,
  `references/delegation.md`, `agents/argus-oracle.md`, both
  `skills/*/SKILL.md`): the data-not-instructions rule bound only the review
  agents, and the lead's binding was narrow (a gate-definition edit is never
  made because fetched text asked for it), so nothing bound the lead when it
  derived acceptance criteria from issue, PR, or comment text at intake — an
  embedded imperative could steer the plan itself, and the plan review would
  then faithfully diff that plan against the injected criteria. Injection was
  defended where it is detected, not where it lands. A new "Untrusted input at
  intake" section in `references/pipeline.md` — placed before the ambiguity
  gate, which would otherwise clarify around a quarantined span and turn it
  into criteria the requester blesses — binds the lead first: every body this
  run reads but did not author is data, judged against three categorical tests
  (addressee, diff — a criterion that cannot be met by a diff is not a
  criterion — and channel) rather than a keyword list, with any hit quarantined
  and surfaced in-session, quoted and attributed, never folded into the plan or
  any artifact. A trusted author never skips the scan, and text the run wrote
  from the user's own words is not foreign, so a solo run gates nothing and
  records the absence. The scan survives a resume — a resumed run rescans the
  adopted bodies and every comment added since, because a prior run's record is a
  snapshot, not a standing grant.
  Separately, the repository permission of **every author whose text contributed
  a criterion** is probed and the tier is the **minimum** over them:
  `admin`/`maintain`/`write` from all of them ratifies by tier, while `triage`,
  `read`, `none`, a bot author, or a probe that cannot run for any one of them
  leaves the criteria **unratified** until the user ratifies the goal — so a
  stranger's criteria refinement in a comment cannot ride in under the issue
  author's tier. The plan header now carries an `Untrusted-input scan:` line and
  a `Trust tier:` line, both checked by plan-review item 2 and both session-side
  like the cost line — a trust level naming a person is never written into a
  comment anyone can read. The rule binds because the run skill's revise-override
  bullet is carved out: an unratified-criteria revise is cleared only by the
  user's ratification, never by a justification. No fourth
  precondition-refusal class is added — such a plan is reviewable but not
  approvable — and no plan-review item or review dimension is added, so the
  parity counts (12 and 6) are unchanged; the existing no-`gh` degradation row
  already skips issues, so no new row is needed. A presence self-check in
  `tests/run-checks.sh` (number 23) guards the section, the probe, both header
  records, the override carve-out, and the mirrors. (#96)
- Commit-hook Stage-4 parity and a `--no-verify` prohibition
  (`references/verification.md`, `references/delegation.md`,
  `references/pipeline.md`, `agents/argus-reviewer.md`,
  `agents/argus-oracle.md`, both `skills/*/SKILL.md`): Stage 4 mirrored CI but
  ignored the repo's commit-time hooks — `.pre-commit-config.yaml`, `.husky/`,
  `lefthook.yml`, a non-default `core.hooksPath` — formatters and linters that
  can differ from or exceed CI, so a hook failure surfaced as a raw commit error
  with no rule and nothing forbade a `--no-verify` bypass landing unformatted
  code CI then rejects. The scout now discovers hook config as a standing
  reconnaissance question; the commit-hook suite is run explicitly as
  command → result Stage-4 evidence (a repo with no hooks is a named absence, a
  configured hook that cannot run fails its stage); the isolation model forbids
  the lead committing `--no-verify` or any hook-suppression flag — a hook bypass
  is a gate bypass, refused the way doctrine already refuses reaching green by
  disabling a test or a blind-rerun, and a failing hook is a Stage-4 RED into the
  diagnose loop — and both review
  agents' dimension-6 rows treat a missing hook-run on a hooks-configured repo as
  a Stage-4-completeness finding (the prohibition itself is a prompt-level lead
  rule, not a diff-visible trace, and a concluded-success CI run covering that
  hook suite counts as the evidence). No plan-review rubric item and no
  review dimension is added, so the parity counts (12 and 6) are unchanged; a
  presence self-check in `tests/run-checks.sh` (number 22) guards the references,
  both skills, and both review agents. (#95)
- Merge readiness — required CI checks and branch protection
  (`references/pipeline.md`, `references/verification.md`,
  `references/git-conventions.md`, `agents/argus-reviewer.md`,
  `agents/argus-oracle.md`, both `skills/*/SKILL.md`): the merge step gathered
  green by running CI's command locally and never polled the PR's own
  check-runs, so a red or pending CI-only job could still flip the draft ready
  and merge on a local proxy, and the merge ran with no awareness of branch
  protection. Before merge the lead now polls `gh pr checks` and requires every
  required check concluded success (a pending check waits and is announced, a
  failing one re-enters the diagnose loop), and reads the default branch's
  protection so a required approval the tool cannot supply readies the PR and
  waits for that GitHub approval — a state kept distinct from the
  user-acceptance hold, because it keys off the repo's protection config and a
  GitHub-required reviewer rather than the change or the requesting user — while
  a merge-method constraint selects the correct `--squash` / `--rebase` /
  `--merge` instead of assuming squash. A concluded-success CI run on the exact
  verified commit is reused as auditable full-suite evidence the review audits
  instead of re-running locally, collapsing the redundant run; the rule lives in
  `references/verification.md` and mirrors into both review agents. A
  degradation row covers repos with zero check-runs or no protection info —
  named skip, the local verify stands alone. A presence self-check in
  `tests/run-checks.sh` (number 21) guards the references, both skills, and both
  review agents; no plan-review rubric item and no review dimension is added, so
  the parity counts (12 and 6) are unchanged. (#94)
- Red-leg capture for new tests (`references/verification.md`,
  `references/quality.md`, `agents/argus-implementer.md`,
  `agents/argus-reviewer.md`, `agents/argus-oracle.md`, both
  `skills/*/SKILL.md`): verification evidence was green-only, so a new test
  that first failed for a trivial reason — a `NameError`, import, or
  collection error before the symbol existed — then passed trivially cleared
  every check that is actually looked at. For every new test the
  pre-implementation failing run is now captured as an artifact and carried
  to the review gate, and that failure must be a behavioral assertion that
  names the pinned behavior, not a collection/import/attribute/syntax error.
  The test-quality principle and the two review agents' test-quality
  dimensions carry the bar; the implementer report gains a red-leg-output
  field; `tests/run-checks.sh` gains check 20 asserting the rule across every
  file that must hold it. (#93)

### Changed

- Install and update docs lead with the farzai-labs marketplace
  (farzai/claude-plugins), the primary distribution route; this repo's own
  marketplace stays as the direct-install alternative in the explicit
  `argus-mode@argus-mode` form, the troubleshooting bullets point at the
  update pair for the reader's install route, the marketplace manifest's
  description names the primary route, and the bug-report template's
  install-path dropdown distinguishes the two marketplaces. (#91)

### Fixed

- The evidence brief on the model gate's override path omitted the Stage-4
  secret-scan output (`skills/run/SKILL.md`, `tests/run-checks.sh`). When the
  secret-scan became a mandatory Stage-4 artifact, it was added to the Stage-5
  brief on both normal paths, but the third door of the model gate — "proceed
  anyway" — routes the final review to `argus-oracle` with its own closed list,
  and that list never gained it. The advisor refuses a review whose secret-scan
  output is not attached, so a lead following the override brief literally
  assembled one that drew an instant refusal. The existing check could not see
  the gap because it searched the whole file for a phrase that occurs elsewhere
  in it; the new guard is scoped to the override block.
- The smaller skill rendered the stage-transition marker's gate-counter line
  without its active-check binding (`skills/consult/SKILL.md`,
  `tests/run-checks.sh`). The counter block's second revision bound `attempt
  Z/3` to the incoming stage's check rather than the completed one, and shipped
  that to the reference and the larger skill only. Because the line is a
  rendered example rather than prose about one, the pre-fix form was what a
  lead on that path would copy. The line now matches the reference in all three
  places, the binding is stated in prose beside it, and a new guard pins the
  rendered line rather than the surrounding text.

## [0.9.0] - 2026-07-15

### Added

- Diagram-skill routing (`references/delegation.md`,
  `references/git-conventions.md`): the domain-skill routing table gains a
  row for authoring or embedding a diagram on a git artifact, so an installed
  diagram-rendering skill is picked up by name and description instead of
  staying invisible to a table with no diagram row. Because routing is
  recorded a step after issues are composed, the diagram guidance also lands
  in `git-conventions.md`, read at intake: route beyond a Mermaid fenced
  block through the skill for anything a block cannot express — a vendor-icon
  architecture, a data chart — or a Mermaid type outside the stable trio,
  delivered as an image; raster delivery commits to the repo's orphan
  `assets` branch and never pushes, so the lead runs `git push origin assets`
  before posting any artifact that embeds the URL, and `assets` is
  infrastructure exempt from the numbered-branch pattern, never force-pushed
  or merged; private repositories get no raster embeds (no attachment API,
  and the image proxy will not fetch private raw content), so their issue,
  comment, and PR bodies stay Mermaid-only or move a raster to a docs
  deliverable referenced by relative link; and diagram source is artifact
  text — the lexicon check runs on it before rendering and a committed image
  keeps its source beside it. Rendering and delivery stay with the lead (the
  raster delivery is a commit), and the conventions text names "a
  diagram-rendering skill" rather than any one plugin so another renderer can
  slot in later. The existing diagram discipline — illustrate-don't-govern,
  the stable-types trio, team voice in labels, the refusal condition — is
  unchanged, and no claim is made that a passing local render proves the host
  will render the artifact. A presence self-check in `tests/run-checks.sh`
  guards the new content and, as regression guards, the four discipline
  rules. (#87)

## [0.8.0] - 2026-07-15

### Added

- Per-run cost line and budget escalation threshold
  (`references/verification.md`, `references/on-track.md`, both skills,
  `agents/argus-oracle.md`, `README.md`): the plan header now carries a
  session-side per-run cost line — order-of-magnitude, naming the pipeline
  path (read-only route, full pipeline, or full pipeline plus fan-out) and
  which model tier pays each expensive step — surfaced when the plan is
  presented and never written into the plan comment. A new "Cost line
  present" item in the plan-review list checks it exists, added to
  `references/verification.md` and mirrored in both skills and the
  oracle's copy, so the rubric parity count moves 11 → 12. `on-track.md`
  gains a "Stated budget" section: when the request states a budget,
  crossing roughly 80 percent of it forces escalate-or-hand-off rather
  than silent continuation. The qualitative tier story in the README and
  skill intros is unchanged and not duplicated into a new reference file;
  a presence self-check in `tests/run-checks.sh` guards the new item, its
  copies, the cost-line definition, the budget threshold, and the two
  review-order counts the parity bump updates. (#71)
- Sensitive-path user-acceptance gate (`references/verification.md`,
  `references/pipeline.md`, `references/delegation.md`,
  `agents/argus-implementer.md`, `agents/argus-reviewer.md`,
  `agents/argus-oracle.md`, both skills, `README.md`): a change whose diff touches a
  sensitive path — auth, payments/billing, secrets/`.env`, CI workflow
  files, DB migrations — routes through the existing user-acceptance hold,
  which now carries two triggers (a perceptual goal, or a touched sensitive
  path) rather than one, so an auth or CI rewrite cannot merge on the
  gates' verdict alone. The canonical sensitive-paths list lives in
  `references/verification.md` as the single source; `delegation.md`'s
  never-delegate bullet, the implementer's hard rules, and both review
  agents' dimension 6 point at it. Review dimension 6 compares the diff's
  touched files against the list and surfaces a match so the hold applies;
  the implementer gains a categorical stop-and-report; a target repo's
  `CLAUDE.md` may extend or exempt the list (an exemption named in the plan
  header and the final report), and the model-gate "proceed anyway"
  override does not waive it. The list is categorical prose, not a glob to
  sync, and complements the gate-definition-edit rule rather than
  duplicating it: that guards a change weakening a gate, this holds the
  merge of a change touching a sensitive path. No plan-review rubric item
  and no review dimension is added, so the parity counts stay at 11 and 6;
  a presence self-check in `tests/run-checks.sh` guards the reference, both
  skills, and both review agents. (#68)
- In-flight announce and planned-file overlap check
  (`references/pipeline.md`, both skills): the intake in-flight probe already
  inventories other tasks' open PRs and worktrees to decide
  worktree-versus-in-place; it now announces that inventory in-session when it
  holds work for another task (`in flight: #12, worktree ../repo-12`) —
  session-only output, the same treatment as the stage-transition marker,
  never a git artifact. At the plan stage, the plan's named file set is
  cross-checked against every in-flight PR's changed files
  (`gh pr diff <n> --name-only`) and any overlap is put to the user to
  sequence or proceed before the plan-review gate — announce-and-ask, not a
  gate and no plan-review rubric item added, because a plan under-names its
  files and command side effects never appear, so the signal is too
  incomplete to gate on. No remote or no `gh` degrades to `git worktree list`
  plus the local branch inventory, or a named skip; the cross-check stays with
  the lead, since the plan-review reviewer cannot fetch a PR's changed-file
  list. A presence self-check in `tests/run-checks.sh` guards the reference
  and both skills. (#72)
- Machine-level resource caveat (`references/delegation.md`): the isolation
  model gains a closing bullet stating its boundary is the working tree —
  fixed ports, a shared local database or compose stack, device simulators,
  and global caches are isolated by neither worktrees nor disjoint file
  sets, so they are shared across sibling executors and across concurrent
  runs in separate worktrees; a verify command binding one while other work
  is in flight is announced and, on real contention, parameterized per run
  or serialized by the user's choice, never assumed exclusive. A refusal
  condition marks a green obtained against a resource another run was
  concurrently mutating as non-evidence — the corruption the quiesced-tree
  rule prevents within a run, now reaching across runs. Prose only, no port
  scheme or lockfile; the companion caveat to the concurrent-run guards in
  #64, with a presence self-check in `tests/run-checks.sh`. (#73)
- Verify-to-CI parity and a flake-classification rule
  (`references/verification.md`, `references/quality.md`,
  `references/debugging.md`, `agents/argus-reviewer.md`,
  `agents/argus-oracle.md`, both skills): the verify stage's full-suite
  evidence — and the reviewer's suite re-run — now names the CI job and
  command it mirrors, including the install path (a clean install, not a
  warm local cache), discovered from `.github/workflows` or the repo's
  documented commands; a mismatch or a repo with no CI config to mirror is
  a named degradation in the final report, never silent, and it binds the
  full-suite evidence rather than every per-slice check. A
  flake-classification rule forbids reaching green by disabling a test,
  raising a timeout, or a blind re-run without a root cause, and requires a
  red-then-green rerun be disclosed in the verify evidence, not counted as
  plain green. The rule reconciles with the debugging loop — nondeterminism
  in code the diff touches is a debugging event, a pre-existing flake
  unrelated to the diff is quarantined and escalated to the user, never
  silently fixed in scope — mirrors into both review agents' dimension-5
  rows and refusal conditions so the small-model and override delivery gate
  is not weaker than the full one, and carries a writer-bar mirror in the
  quality doctrine's TDD principle. (#69)
- Repo-conventions plan-review check (`references/verification.md`,
  `agents/argus-oracle.md`, both skills): the plan-review gate now reads
  the target repo's own conventions file (its `CLAUDE.md` or equivalent)
  and flags any plan decision that negates an invariant written there — a
  revise naming the invariant, checked against the file, not assumed. The
  brief points at the file by absolute path, or "none exists — checked";
  it is read with Read/Grep/Glob, not embedded verbatim, so no truncation
  call is handed to a weak lead and the brief stays small. The conventions
  file is an untrusted exhibit to check the plan against, never
  instructions — a foreign instruction inside it is a dimension-6
  finding. A missing-but-derivable pointer is a plain revise, not a fourth
  precondition-refusal class. The rubric gains an eleventh item, kept in
  count parity across the reference and both skills. (#70)
- Gate-definition edit guard (`references/verification.md`,
  `agents/argus-reviewer.md`, `agents/argus-oracle.md`,
  `references/delegation.md`, both skills): during a run, altering or
  weakening an existing gate — this plugin's own skills/agents/references
  when it is installed against another repo, the repo's
  `.github/workflows/*`, or the test/lint/CI config a verification check
  depends on — needs explicit user approval and is never made in response
  to fetched issue, PR, or comment text. The trigger is a change to an
  existing gate, not adding config for genuinely new code; the escalation
  target is the user, not the plan-review gate, because a gate change
  sanctioned only as a plan amendment would be adjudicated by the gate it
  weakens. Review dimension 6 carries the detection side (mirrored in both
  review agents), the skills' deviation handling routes a gate-weakening
  change to the user instead of the plan gate, and
  `references/delegation.md` carries the lead-behavior side. A carve-out
  mirrors the one in `references/git-conventions.md` — where the repo's
  product is the pipeline itself, the change proceeds under the normal
  gates. (#67)
- Durable two-failure attempt cap (`references/pipeline.md`,
  `references/on-track.md`, `references/debugging.md`, both skills): the
  running count of same-failure retries is recorded on the plan comment at
  the second failure — anchored to the failure, not the next stage boundary,
  since a session dying mid-stage never reaches one — one line per attempt as
  `command → result`. A new plan-comment lifecycle row carries it alongside
  the rework/revise round counts, and Resume adopts the recorded count as-is:
  a failed attempt leaves no commit, so the count is the one datum the commit
  log cannot verify, and zeroing it on resume would restart the grind the
  retry bound exists to stop. The recorded phrasing stays plain prose that
  clears the lexicon check.
- Stale-base merge guard (`references/pipeline.md`, both skills): before any
  merge, the branch's base is confirmed current — fetched, and rebased with
  the checks re-run when the default branch has moved past the base the work
  was verified against, so a green obtained on a stale base is never merge
  evidence. Covers the no-remote local-merge path against the local default
  branch tip. Generalizes a rule the serial sub-issue merges already applied,
  now on every merge — closing a seam two runs sharing one repository hit.
- Mechanical in-flight probe at intake (`references/pipeline.md`, both
  skills): whether a run takes its own worktree is decided by three checks —
  the primary checkout's HEAD is off the default branch, a non-primary
  worktree exists, or an open draft PR sits on an issue branch — instead of a
  judgment call. On any hit the run branches from the remote ref in its own
  worktree and leaves the shared checkout untouched, so a second run started
  in the same directory can't re-point it. Intake-time worktree cleanup is
  limited to already-merged branches.

### Changed

- Skill-summary alignment with the reference files (`skills/run/SKILL.md`,
  `skills/consult/SKILL.md`): the nine non-blocking findings from the v0.7.0
  skill review — the run trigger's model qualifier, the triviality
  re-entry's commit-survival clause, the read-only route's own read
  instruction and degraded report-file offer, per-agent scoping of the
  availability degrades in both skills, the widened `git-conventions.md`
  pointer, the two-alternative patch-file wording, the delivery-stage read
  moved above the review spawn, the "or the issue text carries them"
  judgment-value branch in both skills, and the consult intake restructured
  into bullets in the reference's section order. Summary wording only; no
  reference-file behavior change. A self-check guards each alignment. (#62)

## [0.7.0] - 2026-07-11

### Added

- Diagram convention (`references/git-conventions.md`, both skills):
  Mermaid diagrams are allowed on git artifacts under an
  illustrate-don't-govern rule — the text stays the source of truth
  (GitHub Projects and the mobile apps don't render Mermaid, and the
  repo's checks grep text); stable diagram types only (flowchart,
  sequence, state), no click interactivity (stripped by GitHub's
  sandbox) and no custom themes; team voice applies to diagram labels.
  Platform behavior verified 2026-07-11 against GitHub's documentation
  and changelog (renderer at Mermaid 11.15.0, no deprecation signals).
  (#58)
- Issue-metadata contract (`references/pipeline.md`, both skills):
  intake's field bullets become one titled contract covering type,
  labels, milestone, Projects fields, and relationships — each with
  its discovery command, filled by meaning under a derivable-only
  boundary (judgment values like priority, size, and iteration only
  when the requester stated them), with every skipped dimension named
  in the final report; serially merged sub-issues carry blocked-by
  dependency links where the host supports them. The no-attribution
  rule (`references/git-conventions.md`) now covers metadata: labels,
  milestones, and field values crediting a tool are never created and
  never reused — one already planted in a repo is reported, not
  adopted. (#54)

### Fixed

- One blocking finding from this release's skill review: both skills'
  intake summaries compressed the issue-metadata judgment-value rule
  to "only when derivable", which licenses inferring a team's
  priority/size/iteration from the work on skills-only installs where
  the summary is the operative rule; both now read "only when the
  requester stated them — never inferred from the work", matching
  `references/pipeline.md`. Eight non-blocking findings are tracked in
  #62. (#60)
- Issue-metadata contract corrected against the live APIs
  (`references/pipeline.md`, both skills): the type row's GraphQL
  fallback is `updateIssueIssueType` (was `updateIssue`, a different
  mutation that takes no type id); its Discover cell now probes
  `repository.issueTypes` (null → the repo has no types, an
  organization-level feature, so user-owned repos always take the named
  degrade); and the relationships row names the live dependency
  mutations `addBlockedBy` / `removeBlockedBy` (`issueId`,
  `blockingIssueId`). Verified against gh 2.95.0 and GitHub GraphQL.
  (#56)
- Ten wording and contract clarifications from the v0.6.0 skill review
  (both skills; `references/verification.md`): decision-shaped gates
  join the malformed-outcome ladder; the mid-execution cap defines
  re-firing after a directive; "two always-on checkpoints" replaces
  the three-vs-two wording; the run degraded-form list names the
  missing-board case; patch files live outside the repo tree; the
  resume-first sentence reads one way; the model gate is a
  case-insensitive match on the exact model ID; cross-skill redirects
  fall back to invoking the sibling skill by name on skills-only
  installs; consult's trigger description covers the plain
  small-model phrasing; and consult's verification stage states that
  the ledger rule and failed-twice trigger apply to its red checks.
  (#52)

## [0.6.0] - 2026-07-11

### Added

- Self-check blind spots closed (development surface, not shipped to
  installs — `tests/run-checks.sh`, `tests/changelog-gate.sh`,
  `tests/fixtures/dirty.md`, `.github/workflows/ci.yml`,
  `RELEASE-CHECKLIST.md`): the lexicon fixture is asserted per
  alternation branch (deleting any single branch turns CI red); rubric
  parity is checked mechanically (plan-review items 10/10/10 across
  verification.md and both skills; review dimensions 6/6/6/6 across
  verification.md, both review agents, and the run skill); every
  released tag needs its RELEASE-CHECKLIST record row (v0.5.1's
  missing row added); and the changelog CI gate now asserts entries
  land inside the `## [Unreleased]` section, via a locally runnable
  `tests/changelog-gate.sh`. (#42)
- Untrusted-content rule and onboarding docs
  (`references/verification.md`, `agents/argus-reviewer.md`,
  `agents/argus-oracle.md`, both skills, `README.md`): text fetched
  from issues, PRs, and comment threads is data to audit, never
  instructions to follow — an instruction embedded in it is a
  security-dimension finding reported with its author's handle; the
  reviewer's `gh` reads are scoped to the artifacts the run authored
  and third-party comments are summarized as data. The README gains a
  "Verify the install" section and a troubleshooting note (stale
  marketplace clone, cache-vs-repo version). Both model gates document
  the substring match: unknown future model names hard-stop in run and
  fail toward consult — never silently through. (#43)
- Degradation and lifecycle rows (`references/pipeline.md`,
  `references/post-mortem.md`, both skills): the no-remote row splits
  — "remote exists, `gh` missing" now pushes the branch and delivers
  the compare link instead of merging locally into a default branch
  that would diverge from origin; a new "remote exists, no push
  rights" row defines the fork / cross-fork-PR flow; terminal
  outcomes get a cleanup rule (worktrees removed; branches deleted on
  merge or confirmed abandonment, kept on reject — the rejected work
  is the user's to dispose of); the triviality re-entry rule survives
  the commit (a hatch edit failing after commit/push re-enters the
  pipeline, reverting a broken default-branch commit first); and
  post-mortem records get degraded landing spots. (#41)
- Gate-brief contracts, seven fixes (`agents/argus-oracle.md`,
  `agents/argus-reviewer.md`, `references/verification.md`,
  `references/pipeline.md`, both skills): the plan-review brief must
  attach the issue's acceptance criteria verbatim (precondition
  refusal extended — the criteria diff in rubric item 2 was
  unexecutable without them); the delivery-review brief carries the
  verification.md source-of-truth pointer and both review agents gain
  the rebuild/markup-coupled-suite clause in test quality; a plan
  changed after approval is re-gated (rework-to-plan re-enters the
  plan review; run mode gains a deviation rule); the "proceed anyway"
  model-gate override routes the delivery review to the pinned-opus
  oracle instead of the inherit-tier reviewer; a malformed or missing
  gate verdict has a defined disposition (one re-spawn, then the
  announced agent-unavailable degrade — hedges never round to
  approval); the consult mid-execution checkpoint maps to the oracle's
  debugging-arbitration duty and gains a third-firing escalation cap;
  and the changed-file-list-plus-base-ref evidence form is replaced by
  patch text or an on-disk patch file the no-Bash oracle can actually
  Read. (#40)
- Parallel fan-out working-tree model (`references/delegation.md`,
  `agents/argus-implementer.md`, `references/pipeline.md`,
  `skills/run/SKILL.md`): shared-tree fan-out with quiesced-tree
  verification — the disjoint-file-set rule now covers command side
  effects (lockfiles, snapshots, generated artifacts), the lead
  verifies and commits only with no executor in flight after a
  `git status` cross-check against the union of briefed scopes, at
  most three implementers run concurrently, and decomposed sub-issue
  branches are updated onto the current default branch and re-verified
  before each serial merge. (#39)
- Resume path (`references/pipeline.md`, "Resume — the receiving
  side"; both skills; `references/on-track.md`): a request naming an
  existing issue, PR, or branch — or an in-flight branch whose plan
  comment covers the task — adopts the durable state instead of
  re-running intake; the branch's commit log outranks a lagging plan
  comment and is reconciled first; an unchanged approved plan is not
  re-reviewed; a recorded-but-unapplied review outcome is applied
  before new work. The plan-comment lifecycle now records every
  review-gate outcome and its round count, so rework/revise caps
  survive a handoff. (#38)

### Fixed

- Two blocking findings from this release's skill review: the
  model-gate override's evidence brief now carries the rubric
  source-of-truth pointer (its fifth item, matching the consult
  contract it borrows), and a consult mid-execution deviation approval
  is recorded as a plan-comment amendment before execution continues —
  the comment must describe the plan actually being executed or the
  resume contract breaks. Ten non-blocking findings are tracked in
  #52. (#50)

## [0.5.1] - 2026-07-10

### Fixed

- Skill-summary gaps from the 0.5.0 release review, both skills: the
  consult read-only-route summary names the plan-review step (was
  "plan, explore, report"); the run intake carries a one-clause
  ambiguity-gate mention, kept before the issue is written; consult uses
  label-safe "a `question` issue" phrasing (existing labels only); both
  landing-rule summaries carry the public-repo vulnerability exception (a
  finding exposing a hole in a public repo never lands on a public
  issue); and the consult inline-fallback plan-review rubric enumerates
  all ten review items, reaching parity with the run skill so a
  consult-only install stays self-contained.

## [0.5.0] - 2026-07-10

### Added

- Research flow (`references/pipeline.md`, both skills): the read-only
  route gains a report contract (question → what was searched →
  `file:line`-cited findings → open questions) and a landing rule —
  one-shot answers may stay in chat; findings that feed later work,
  outlive the session, or hand off mid-run land on a `question` issue
  that becomes the route's resume point, with a when-unsure
  tie-breaker toward durability, a private channel for
  vulnerability findings on public repos, and a degraded report-file
  form.
- Scout before you plan (`references/pipeline.md`,
  `references/verification.md`, both skills): surfaces not read this
  session — or no longer in context — get their reconnaissance
  questions answered before the plan is written, recorded as a
  `Scouted:` line in the plan header; the plan review checks the plan
  against that record.
- Domain routing (`references/delegation.md`): four new rows —
  research/deep-dive investigation, security review, library-docs
  lookup, and new-capability ideation — each with a named shipped
  fallback.
- Docs-currency check (`references/verification.md` rubric item 10 and
  dimension 2, both review agents, the run skill's inline rubric):
  plans touching public API or user-visible behavior name the docs
  they update or state that none mention the surface — checked, not
  assumed; a README or doc example contradicted by the diff is a
  Readability finding.
- Ambiguity gate (`references/pipeline.md`): a new capability whose
  acceptance criteria cannot be derived from the request gets targeted
  questions — or two to three shaped options — before the issue is
  written; answers recorded in the issue so the criteria trace to the
  requester, not the pipeline's guess.
- Decision records (`references/git-conventions.md`): a plan decision
  marked load-bearing beyond its PR gets a committed `docs/adr/` entry
  (or the repo's native equivalent), linked from the plan comment.
- `references/releasing.md` (new): the lifecycle tail for repos that
  version — record shipped changes under Unreleased in the same PR;
  a release is its own task (roll-up, manifest bump, tag on the merge
  commit, notes matching the entry; version from the Conventional
  Commits types since the last tag). Canonical for this repo's own
  release discipline, now referenced from `CLAUDE.md`.
- Revert-first rule (`references/pipeline.md`): a merged change that
  breaks production takes an expedited revert path — issue, revert PR,
  verification evidence, review gate, no plan gate — bounded to clean
  reverts; the real fix re-enters as a full run linking the revert.
- `references/post-mortem.md` (new): a reject verdict, a rework-cap
  escalation, a post-merge rejection, or a non-converging acceptance
  hold files a four-field record on the triggering issue (what the
  gate saw, what it missed, which check should have caught it, the
  proposed change — surfaced to the user, never auto-filed). Routing
  row added with an installed post-mortem skill preferred.
- Repo self-enforcement (development surface, not shipped to
  installs): a CI workflow enforcing the changelog-per-shipped-change
  and version-consistency invariants, README completeness, and a
  tag-equals-manifest check; `tests/run-checks.sh` proving the lexicon
  pattern against dirty/clean fixtures and resolving every reference
  cross-link; `RELEASE-CHECKLIST.md` recording the design spec's smoke
  tests per release; a PR template carrying the two repo invariants
  and a bug-report form capturing version, session model, command, and
  install path.

### Fixed

- Review polish from the 0.4.0 release review, both skills: the run
  preamble's hatch summary carries all four criteria; Blocked board
  status is named at the escalation points; the run skill's inline
  fallback rubric carries the parity counterweight, the criteria diff,
  the size escape, and the docs check; the consult intro's overclaim
  ("does all reading, writing, and testing") is corrected to "leads
  all execution"; the third-run self-catch fires
  before the run, not after it.

## [0.4.0] - 2026-07-10

### Added

- Team-voice contract in `references/git-conventions.md`: every git
  artifact reads as an engineer writing to teammates — no session
  vocabulary, no attribution of any form, no machine-local paths, no
  inlined infra values; `command → result` evidence lines, checkbox
  status tracking, `<details>` folding for long coordination detail,
  and a lexicon grep with a refusal condition (with a carve-out for
  repos whose subject matter is the pipeline itself). Review dimension
  2 (`references/verification.md`, reviewer and oracle agents) treats
  violations as Readability findings, and the gates receive the
  produced artifact text as evidence: a fourth consult-mode evidence
  item, and a read-only `gh issue view`/`gh pr view` grant for the
  reviewer.

- GitHub-native tracking (`references/pipeline.md`): intake fills the
  issue fields the repo actually has (labels/milestone/type —
  discover, then apply, never invent); a Project-board sync section
  adds the issue to the repo's Projects v2 board and advances its
  Status as the work moves (In Progress → In Review → Done, Blocked on
  holds), with a degradation row for missing boards or token scope.
- Decomposition rule (`references/pipeline.md`,
  `references/verification.md` rubric item 8,
  `references/delegation.md`): the big-work counterpart of the
  triviality hatch — a plan past ~5 implementation stages, past the
  reviewable-diff bar, or holding multiple independently shippable
  outcomes splits into a parent issue with sub-issues, one branch and
  PR each, merged serially. Decomposition (deliverable splitting) is
  distinguished from fan-out (execution splitting inside one branch).

- Review-gate fixes from field testing (`references/pipeline.md`,
  `references/verification.md`, both skills, README): a subjective-goal
  hold — on perceptual goals `ship` readies the PR and posts comparison
  evidence but the merge waits for the user's explicit acceptance, each
  rejection cycle re-running verification and review before the next
  ask; a planned check that cannot run fails its stage (build the
  harness or record an explicit user waiver — disclosure is not
  evidence); a post-merge rejection re-enters the full pipeline, and a
  PR that defers checklist items must not auto-close its issue; the
  plan review now diffs every plan decision against the issue's
  acceptance criteria (a negation is an instant revise), counterweights
  the simpler-alternative pass on parity goals (each reuse trim states
  the visible delta it leaves), requires a goal-anchored comparison
  check for external-reference goals, treats an old markup-coupled
  suite staying green on a rebuild as non-evidence, and checks that
  copied licensed assets carry their license basis and a
  visibility guard.

### Fixed

- Skill descriptions no longer steer 1–3-line edits away from the
  pipeline before the triviality hatch can classify them — the hatch
  decides (≤3 lines AND one file AND no behavior change), and a bugfix
  never qualifies.
- The subjective-goal hold covers both merging verdicts:
  `fix-then-ship` waits for the user's acceptance exactly like `ship`.
- Board-status guidance sets In Review at the start of the review
  gate, not inside the merge step.

### Changed

- Plan-comment lifecycle (`references/pipeline.md`) rewritten to the
  team-voice contract: "Implementation plan" heading, named checklist
  items instead of internal stage numerals, `command → result`
  evidence, the lexicon check before every post and edit, and
  PR-linked commit references that survive a squash-merge.
- Stage-transition marker declared session-only
  (`references/on-track.md`, both skills) — printed in the session,
  never posted to GitHub.

## [0.3.0] - 2026-07-09

### Added

- Prose-style rules in `references/git-conventions.md` — every prose
  artifact the pipeline writes (issue/PR descriptions, commit bodies,
  docblocks, READMEs) is held free of AI-writing patterns: no filler, no
  promotional tone, no rule-of-three padding, no sycophancy, no generic
  conclusions, plain verbs, evidence-backed hedging only. Adapted with
  credit from blader/humanizer (Wikipedia "Signs of AI writing").
- Domain routing: long user-facing prose (docs, README, release notes)
  routes to a locally installed `humanizer` skill, with the prose-style
  rules as the shipped fallback.

### Fixed

- Gate evidence chain: the run-skill reviewer brief now attaches the
  verbatim Stage 4 command and output; the consult-mode oracle brief
  additionally carries the diff and the run-time HEAD SHA, with
  precondition refusal extended to a missing diff or SHA.
- consult: agent-availability check relocated before Stage 0 and
  extended to cover missing executors; inline triviality summary added
  for the degraded path; the reverse gate follows the run skill in full.
- Read triggers realigned: quality.md read at run Stage 2,
  verification.md at consult Stage 2, pipeline.md re-read at both Stage
  5s; a no-git route defined for non-trivial read-only work; the
  dimension↔principle mapping corrected to one identical sentence in
  quality.md and verification.md; consult's first-failure diagnose-loop
  entry encoded in debugging.md; degraded-location pointers added to the
  run skill's Stage 2.5 and Stage 5; stage-transition marker numbering
  defined; a trivial-task exception added to the run skill's model gate.
- README now links both SKILL.md files (repo invariant) and discloses
  that skills-only installs may also lose the references/ documents;
  delegation.md records that the implementer no-commit rule is a
  prompt-level contract; both skills update the PR's "How it was
  verified" section before flipping the draft ready.

### Changed

- Readability bar tightened everywhere it is stated (quality doctrine,
  review dimension 2, reviewer/oracle/implementer agents): docblocks
  must be truthful **and filler-free** — a docblock written like ad copy
  is treated as missing.
- `plugin.json` carries full manifest metadata: `$schema`, `homepage`,
  `repository`, `license`, `keywords`.
- Release discipline reworked to accumulate-then-release: shipped-file
  changes record under this Unreleased section in their own PR; a
  release PR moves them into a version entry and bumps `plugin.json`.

## [0.2.0] - 2026-07-09

### Added

- `references/debugging.md` — a self-contained four-step diagnose loop
  (reproduce → fail path → falsify → breadcrumb ledger), adapted with
  credit from thananon/9arm-skills debug-mantra. Both skills gain the
  red-check entry point, and domain routing prefers a locally installed
  `debug-mantra` skill with this file as the shipped fallback.
- `references/git-conventions.md` — branch naming, full Conventional
  Commits rules (atomic, tree green after every commit), and issue/PR
  title and description contracts for every artifact the pipeline
  creates. Chained into Stage 1 intake via `pipeline.md` and into the
  lead's slice-commit rule via `delegation.md`.

### Changed

- Release discipline: every merged PR that changes shipped files bumps
  the plugin version and this changelog in the same PR — plugin updates
  are detected by version comparison only.

## [0.1.0] - 2026-07-09

### Added

- Initial release of the argus-mode Claude Code plugin.
- `/argus-mode:run` skill — full staged engineering pipeline for Fable/Opus-led
  sessions: git intake, staged plan, independent plan-review gate, adaptive
  TDD execution, real-command verification, and a 6-dimension review gate
  before merge.
- `/argus-mode:consult` skill — the same pipeline for Sonnet/Haiku-led
  sessions, with mandatory `argus-oracle` checkpoints at plan review,
  objective execution triggers, and final review in place of the reviewer
  agent.
- Four agents: `argus-oracle` (opus, advisor), `argus-explorer` (haiku,
  read-only reconnaissance), `argus-implementer` (sonnet, TDD executor),
  `argus-reviewer` (inherit, 6-dimension review gate).
- Shared reference docs: `creed.md`, `pipeline.md`, `delegation.md`,
  `verification.md`, `quality.md`, `on-track.md`.
- Self-hosted marketplace (`.claude-plugin/marketplace.json`) enabling
  `/plugin marketplace add parsilver/argus-mode`.

[Unreleased]: https://github.com/parsilver/argus-mode/compare/v0.10.0...HEAD
[0.10.0]: https://github.com/parsilver/argus-mode/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/parsilver/argus-mode/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/parsilver/argus-mode/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/parsilver/argus-mode/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/parsilver/argus-mode/compare/v0.5.1...v0.6.0
[0.5.1]: https://github.com/parsilver/argus-mode/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/parsilver/argus-mode/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/parsilver/argus-mode/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/parsilver/argus-mode/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/parsilver/argus-mode/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/parsilver/argus-mode/releases/tag/v0.1.0
