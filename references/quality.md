# Quality doctrine

The single source of truth for what "good" means in this pipeline. Every
principle is a rule to check against, not an ideal to admire.

## 1. Code for humans

Docblocks on every public class/method/function (PHPDoc/JSDoc/rustdoc/etc.
per language) — plain and truthful: what it does, why it exists, its
constraints, with none of the filler prose banned by
`git-conventions.md` ("seamlessly", "a crucial component"). Meaningful
names. Code a new teammate can read without guessing.

- Refusal condition: a public API without a docblock does not ship —
  and a docblock written like ad copy is treated as missing.

## 2. Architecture before code

SOLID; small single-responsibility composable modules; explicit layer
boundaries. Maintainable and scalable by construction, not by later
heroics. An architecture-shaping change — the trigger and its arms
live at the plan gate (`verification.md`, rubric item 5; conducted at
Stage 2 per `pipeline.md`) — picks its structure from a compared field:
at least two candidate architectures with their trade-offs, never just
the first plausible design.

- Refusal condition: a stage that skips architecture in favor of "just
  make it work" gets sent back before implementation starts.

## 3. Design patterns that earn their keep

Chosen in the plan with a written justification; a pattern that doesn't
reduce maintenance cost doesn't ship.

- Refusal condition: a pattern applied without a stated reason in the
  plan is unjustified complexity — remove it or justify it.

## 4. Refactor-ready, always

Boy-scout rule; no god files; test coverage is the license to refactor at
any time.

- Refusal condition: code that cannot be safely refactored (no tests, no
  boundaries) is not done, regardless of whether it currently works.

## 5. TDD, non-negotiable

Red → green → refactor. Tests are named in the plan before implementation
code exists; the refactor leg is a planned step, not an afterthought. The
red leg is captured, not just performed: a new test's pre-implementation
failure is recorded as evidence, and it must be a behavioral assertion
failure naming the pinned behavior — not a collection/import/attribute/
syntax error that fails before the behavior ever runs.

- Refusal condition: implementation code written before its test exists
  is a stop-and-return-to-the-test-list event, not a style preference.
- Refusal condition: a new test whose red leg was never captured, or
  whose red is a collection/import/attribute/syntax error rather than a
  behavioral assertion failure naming the pinned behavior, has not shown
  it can fail for the right reason — capture the behavioral red first.
- Refusal condition: green reached by disabling a test, raising a
  timeout, or a blind-rerun to green is not a real green — a flaky suite
  is root-caused, not silenced.

## 6. Secure by default

No injection surfaces, authorization respected at every seam, no secrets
in code or diffs, safe defaults. Security is part of the writer's bar, not
only the reviewer's. The secret half is mechanical, not eyeballed: the
writer runs the diff's secret-scan (`verification.md`, "what a failable
check is") and records the clean output as evidence — a maintained scanner
when installed, the shipped regex-sweep fallback otherwise — the same way a
new test's red leg is captured rather than taken on faith.

- Refusal condition: a diff with an injection surface, an authz gap, or a
  secret in it does not ship, security task or not.
- Refusal condition: a "no secrets" claim with no secret-scan output behind
  it is the opinion this principle forbids — run the scan, attach the result.

## How this document is used

Four consumers hold themselves to this same standard, so writer and
reviewer never grade against different bars:

1. **Plan template** (Stage 2) — the "Architecture & patterns" column is
   checked against principles 2, 3, and 5 before the plan can be approved.
2. **Implementer briefs** (`argus-implementer`) — every brief embeds this
   doctrine; the executor is held to it while writing, not just at review.
3. **Oracle rubric** (`argus-oracle`, plan review and consult-mode final
   review) — "does the chosen architecture hold under the doctrine" is a
   direct check against this file.
4. **Reviewer rubric** (`argus-reviewer`) — review dimensions 2–6 map
   onto principles 1, 2, 3, 5, and 6 respectively (readability→code for
   humans, architecture fit→architecture before code, pattern
   justification→patterns that earn their keep, test quality→TDD,
   security→secure by default); principle 4 (refactor-ready) is upheld
   through dimensions 3 and 5 together.
