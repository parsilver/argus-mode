# Verification

Every stage of the pipeline is watched by a check that can fail. This
document defines what counts as a check, the rubric the oracle applies to
a plan before execution starts, and the operating rules the reviewer
applies to a diff before it ships.

## What a failable check is

A failable check is a concrete command plus its expected output, run and
read — not eyeballed, not assumed.

- Valid: `pytest tests/auth/ -v` → all tests pass, exit 0. `npm run build`
  → exit 0, no type errors. `curl -s localhost:3000/health` →
  `{"status":"ok"}`.
- Invalid — these are not checks, they are opinions: "looks good", "review
  the code", "seems fine", "should work now".
- For a goal defined by an external reference ("matches the Fuse
  template", "behaves like the legacy exporter"), at least one check
  must compare against that reference — a side-by-side artifact a
  disagreeing reviewer could point at. "Screenshots exist" is an
  eyeball, not a check; "screenshot of each page against the matching
  reference page, attached to the PR" is one.
- Refusal condition: any claim of "done", "fixed", or "passing" that is
  not backed by a command that was actually run, plus its actual output,
  is rejected on sight — by the lead, the oracle, and the reviewer alike.

## The oracle's plan-review rubric

The oracle reviews the plan **goal-backward**, in this order. Earlier
items are prerequisites for later ones — see Precondition refusal below
for the two that skip the rest of the rubric entirely when missing.

1. **Simpler-alternative pass — mandatory, first.** Should this work exist
   at all? Is there a smaller or more elegant route to the same goal —
   doing nothing, reusing something that already exists in the codebase, a
   10%-of-the-risk change that solves 90% of the goal, or solving it at a
   different layer? This is the single most valuable output the review can
   produce, and it runs before any other check.
   **Parity-goal counterweight:** when the goal is resemblance or parity
   with a named reference, invert the default — reuse-over-replace is
   the risk, not the simplification, because the trimmed delta IS the
   goal. Every "keep our existing X" trim must state the visible delta
   it leaves against the reference; a trim that cannot name its delta
   is a scope change for the user to approve, not a simplification to
   apply.
2. **Goal-backward stage check.** Do these stages, taken together, actually
   reach the stated goal — not just keep the lead busy? Mechanically:
   diff every plan decision against the issue's acceptance-criteria
   checklist, item by item — a decision that negates a written
   criterion is an instant `revise` naming that criterion. Plan
   approval is approval against the issue as written, never a quietly
   re-scoped version of it. Check the plan against its recorded
   reconnaissance too — the `Scouted:` line in the plan header
   (`pipeline.md`, Scout before you plan): a plan whose header carries
   no `Scouted:` record on an unfamiliar surface is guesswork →
   `revise`.
3. **Failable-check reality.** Is every stage's check capable of actually
   going RED, per the definition above?
4. **Test list present.** Is a test list named, before the code, for every
   implementation stage — TDD requires the tests exist as a plan artifact
   before implementation begins, not as an afterthought?
5. **Architecture vs `quality.md`.** Does the chosen architecture hold
   under the doctrine — SOLID, single-responsibility modules, patterns
   that carry a written justification?
6. **Lead-only decisions not delegated.** Is any stage quietly delegating a
   decision that belongs to the lead alone — architecture, debugging,
   review, merge (see `delegation.md`)?
7. **Domain routing matches surfaces.** Does the domain-skill routing
   recorded in the plan header actually match the surfaces the task
   touches (see the domain table in `delegation.md`)?
8. **Right-sized for review.** Does the plan clear the decomposition
   test (`pipeline.md`) — or is it pushing an oversized single PR
   through the gate? Past ~5 implementation stages, a diff beyond the
   reviewable bar, or multiple independently shippable outcomes →
   `revise` toward a parent issue with sub-issues, one PR each —
   unless the plan carries the unavoidable-size justification
   `git-conventions.md` permits (a rename sweep, generated code), in
   which case judge the justification, not the size alone.
9. **Third-party assets carry their license.** A plan that copies
   licensed or purchased assets into the repo names the license basis
   and why the use complies, plus a guard when compliance depends on
   repo visibility (private-only assets flagged before any visibility
   change). Provenance language stays neutral — "licensed Fuse v21.1.0
   assets", not a narration of the copying.
10. **Docs stay truthful.** A plan whose diff touches public API or
    user-visible behavior names the docs and examples it updates — or
    states "no doc mentions this surface", checked against the repo's
    docs, not assumed. A README the diff will contradict is a defect
    the plan must already own.

Verdict is structured: `approve`, or `revise` with reasons tied to the
specific rubric item(s) that failed.

## Precondition refusal

A plan arriving **without failable checks**, or **without a test list**
for an implementation stage, gets an instant `revise` naming the missing
precondition — the oracle does not attempt items 1–10 above on a plan it
cannot actually review. Reviewing a plan with no way to fail is theater;
name the gap and send it back.

## Reviewer operating rules

These apply to `argus-reviewer` in `/argus-mode:run`, and to
`argus-oracle` when it performs the final review in `/argus-mode:consult`.

- **End-to-end, not diff-local.** The diff is the entry point, not the
  scope. Trace the call graph through the unchanged code around it — bugs
  hide at the seams between changed and unchanged code, not just inside
  the changed lines.
- **No rubber-stamps.** "LGTM" is not an output, ever. Finding nothing
  means reporting *what was traced and what was checked* — the lead needs
  to be able to judge whether the review actually covered the surface that
  mattered, not just that it concluded "fine."
- **Cite or it didn't happen.** Every finding references `file:line`. A
  finding without a citation is an opinion, not a review result.
- **Report format.** Each finding: **Finding / Why it matters / Evidence /
  Suggested change**, ordered most severe first.
- **Closing verdict.** One of `ship / fix-then-ship / rework / reject`,
  with the single biggest reason stated plainly — not a list of caveats,
  the one reason that actually drove the verdict.

## The six review dimensions

Checked on every review, every time — not opted into per task:

1. **Correctness.** Does it do what the issue says; are edge cases
   handled?
2. **Readability.** Docblocks present, truthful, and free of filler
   prose (`git-conventions.md`, prose style) on all public API; names
   communicate intent without needing a comment to explain them. Prose
   artifacts are in scope too: session vocabulary, attribution, or a
   machine-local path on any git artifact the run produced (issue, PR,
   comment) violates `git-conventions.md`'s team voice and is a
   dimension-2 finding, exactly like filler prose — the lexicon check
   in `git-conventions.md` is the mechanical probe for it. Repo
   documentation is in scope the same way: grep the docs for the
   changed surface — a README or doc example contradicted by the diff
   is a dimension-2 finding.
3. **Architecture fit.** Boundaries respected; single responsibility held.
4. **Pattern justification.** Every pattern in the diff earns its
   complexity — a pattern applied without a stated reason is unjustified
   complexity, not craftsmanship.
5. **Test quality.** Tests can actually fail — no tautologies, no tests
   that pass regardless of whether the code is correct. On a rebuild or
   redesign, an old markup-coupled suite staying green measures how
   little changed — anti-correlated with the goal; rewriting the specs
   against the new surface is the default, and keeping old specs as a
   constraint needs an explicit justification in the plan.
6. **Security.** Injection surfaces, authorization seams, secrets in the
   diff, unsafe defaults — checked on every review, not only on tasks
   labeled "security."

## How this document is used

- **Stage 2.5 (Plan Review Gate)** — the oracle applies the plan-review
  rubric and precondition refusal above before the plan is allowed to
  become durable.
- **Stage 4 (Verify)** — "what a failable check is" is the standard every
  stage's check, and every "done" claim, is held to.
- **Stage 5 (Review & Deliver)** — the reviewer (or the oracle, in consult
  mode) applies the operating rules and the six dimensions to the diff
  before any merge.
- **`quality.md`** — review dimensions 2–6 map onto doctrine principles
  1, 2, 3, 5, and 6 respectively; principle 4 (refactor-ready) is upheld
  through dimensions 3 and 5 together. The reviewer and the oracle hold
  the diff to the same bar the implementer was briefed against.
