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
heroics.

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
code exists; the refactor leg is a planned step, not an afterthought.

- Refusal condition: implementation code written before its test exists
  is a stop-and-return-to-the-test-list event, not a style preference.

## 6. Secure by default

No injection surfaces, authorization respected at every seam, no secrets
in code or diffs, safe defaults. Security is part of the writer's bar, not
only the reviewer's.

- Refusal condition: a diff with an injection surface, an authz gap, or a
  secret in it does not ship, security task or not.

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
