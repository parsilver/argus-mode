#!/usr/bin/env bash
# Self-checks for the argus-mode plugin. Run from the repo root:
#   bash tests/run-checks.sh
# CI runs this on every push and pull request.
set -uo pipefail
fail=0
note() { printf 'ok:   %s\n' "$*"; }
err()  { printf 'FAIL: %s\n' "$*"; fail=1; }

# 1. Lexicon check — the pattern shipped in git-conventions.md must flag
#    the seeded dirty fixture, branch by branch, and produce zero hits
#    in aggregate on the clean one (which carries the known
#    false-positive traps: Oracle DB, green environments, WAL
#    checkpoints, rollout stages). Per-branch coverage catches a branch
#    that has silently stopped matching anything — an aggregate count
#    alone hides that as long as the other branches keep clearing the
#    floor.
[ -f tests/fixtures/dirty.md ] || err "dirty fixture missing (tests/fixtures/dirty.md)"
[ -f tests/fixtures/clean.md ] || err "clean fixture missing (tests/fixtures/clean.md)"
pattern=$(grep -o "grep -inE '[^']*'" references/git-conventions.md | head -1 | sed "s/^grep -inE '//; s/'\$//")
if [ -z "$pattern" ] || [ ! -f tests/fixtures/dirty.md ] || [ ! -f tests/fixtures/clean.md ]; then
  [ -n "$pattern" ] || err "lexicon pattern not found in references/git-conventions.md"
else
  # Split the pattern into its top-level alternation branches. A '|'
  # only ends a branch at paren depth 0, so nested groups like
  # "generated (by|with)" and "stage [0-9]+ (done|gate|review)" stay
  # intact as one branch each; bracket expressions ([0-9]) are copied
  # verbatim so a '|' can never be mistaken for one hiding inside one.
  branches=$(awk -v s="$pattern" 'BEGIN {
    depth = 0; branch = ""; n = length(s);
    for (i = 1; i <= n; i++) {
      c = substr(s, i, 1);
      if (c == "(") { depth++; branch = branch c; }
      else if (c == ")") { depth--; branch = branch c; }
      else if (c == "[") {
        branch = branch c; i++;
        while (i <= n && substr(s, i, 1) != "]") { branch = branch substr(s, i, 1); i++; }
        if (i <= n) branch = branch substr(s, i, 1);
      }
      else if (c == "|" && depth == 0) { print branch; branch = ""; }
      else { branch = branch c; }
    }
    if (branch != "") print branch;
  }')
  while IFS= read -r branch; do
    [ -n "$branch" ] || continue
    bhits=$(grep -icE -e "$branch" tests/fixtures/dirty.md || true)
    if [ "${bhits:-0}" -ge 1 ]; then
      note "lexicon branch '$branch' flags the dirty fixture ($bhits hits)"
    else
      err "lexicon branch '$branch' has zero hits on the dirty fixture"
    fi
  done <<< "$branches"
  # The per-branch loop can't see a branch that was deleted from the
  # shipped pattern — the fixture side anchors that direction: every
  # seeded dirty line (headings exempt) must still be flagged by the
  # aggregate pattern, so deleting a branch orphans its line and fails.
  orphans=$(grep -vE '^[[:space:]]*$|^#' tests/fixtures/dirty.md | grep -ivcE "$pattern" || true)
  if [ "${orphans:-0}" -eq 0 ]; then
    note "every seeded dirty line is flagged by the aggregate pattern"
  else
    err "lexicon: $orphans seeded dirty line(s) no longer flagged — was a pattern branch deleted? $(grep -vE '^[[:space:]]*$|^#' tests/fixtures/dirty.md | grep -ivE "$pattern")"
  fi
  clean=$(grep -icE "$pattern" tests/fixtures/clean.md || true)
  if [ "${clean:-0}" -eq 0 ]; then note "lexicon passes the clean fixture (0 hits)"; else err "lexicon: expected 0 hits on clean fixture, got ${clean:-0}: $(grep -inE "$pattern" tests/fixtures/clean.md)"; fi
fi

# 2. Reference cross-links — every read-target in skills/ and agents/,
#    and every lowercase .md name mentioned inside references/, must
#    resolve to a file under references/.
for t in $(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/references/[a-z-]+\.md' skills agents 2>/dev/null | sed 's|.*/||' | sort -u); do
  [ -f "references/$t" ] && note "read-target references/$t resolves" || err "read-target references/$t is missing"
done
for t in $(grep -rhoE '`[a-z-]+\.md`' references 2>/dev/null | tr -d '\`' | sort -u); do
  [ -f "references/$t" ] && note "cross-mention references/$t resolves" || err "references/ mentions $t but references/$t is missing"
done

# 3. Plugin manifests parse and carry their required keys.
jq empty .claude-plugin/plugin.json 2>/dev/null && note "plugin.json parses" || err "plugin.json does not parse"
jq -e '.name and .version and .description' .claude-plugin/plugin.json >/dev/null 2>&1 && note "plugin.json has name/version/description" || err "plugin.json missing required keys"
jq empty .claude-plugin/marketplace.json 2>/dev/null && note "marketplace.json parses" || err "marketplace.json does not parse"
jq -e '.plugins[0].source == "./"' .claude-plugin/marketplace.json >/dev/null 2>&1 && note "marketplace self-hosts (source ./)" || err "marketplace.json plugins[0].source is not ./"

# 4. Version <-> changelog, both phases: while accumulating, the top
#    heading is [Unreleased] and the manifest equals the latest release
#    heading; at release, the top heading equals the manifest.
version=$(jq -r .version .claude-plugin/plugin.json)
top=$(grep -m1 -oE '^## \[[^]]+\]' CHANGELOG.md | sed 's/## \[//; s/\]//')
if [ "$top" = "Unreleased" ]; then
  second=$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | head -1 | sed 's/## \[//; s/\]//')
  [ "$second" = "$version" ] && note "accumulate phase: manifest $version matches latest release heading" || err "manifest $version != latest release heading $second"
else
  [ "$top" = "$version" ] && note "release phase: manifest $version matches top heading" || err "manifest $version != top heading $top"
fi

# 5. README completeness — every skill linked, every agent named with
#    its model.
for d in skills/*/; do
  n=$(basename "$d")
  grep -q "skills/$n/SKILL.md" README.md && note "README links skill $n" || err "README does not link skills/$n/SKILL.md"
done
for a in agents/*.md; do
  n=$(awk -F': ' '/^name:/{print $2; exit}' "$a")
  m=$(awk -F': ' '/^model:/{print $2; exit}' "$a")
  [ -n "$n" ] || { err "agent $a has no name: line"; continue; }
  [ -n "$m" ] || { err "agent $a has no model: line"; continue; }
  grep -q "\`$n\`" README.md && note "README lists agent $n" || err "README does not list agent $n"
  grep -qE "\`$n\`.*$m" README.md && note "README carries model $m for $n" || err "README missing model $m for agent $n"
done

# 6. Rubric parity counts — the plan-review rubric and the six review
#    dimensions are each duplicated, for degraded-mode self-containment,
#    across references/verification.md, both skills, and (for the
#    dimensions) both review agents. A count drift means one copy was
#    edited without the others; this proves the copies still agree, not
#    just that each individually looks plausible.
count_numbered_in_section() {
  # Counts lines matching ^[0-9]+\. between an exact heading line (arg
  # 2, matched whole-line in file arg 1) and the next top-level '## '
  # heading, or end of file when the section is last. Echoes the count;
  # returns 1 with no output when the heading isn't found.
  local file="$1" heading="$2" start end total
  start=$(grep -nxF "$heading" "$file" 2>/dev/null | head -1 | cut -d: -f1)
  [ -n "$start" ] || return 1
  total=$(wc -l < "$file")
  end=$(awk -v s="$start" 'NR > s && /^## / { print NR; exit }' "$file")
  [ -n "$end" ] || end=$((total + 1))
  sed -n "$((start + 1)),$((end - 1))p" "$file" | grep -cE '^[0-9]+\.'
}

rubric_ref=$(count_numbered_in_section references/verification.md "## The oracle's plan-review rubric")
rubric_run=$(count_numbered_in_section skills/run/SKILL.md "## Stage 2.5 — Plan review gate")
rubric_consult=$(count_numbered_in_section skills/consult/SKILL.md "## Stage 2.5 — Plan review gate (checkpoint 1 of 3)")
if [ -n "$rubric_ref" ] && [ -n "$rubric_run" ] && [ -n "$rubric_consult" ] \
   && [ "$rubric_ref" -eq "$rubric_run" ] && [ "$rubric_ref" -eq "$rubric_consult" ] && [ "$rubric_ref" -ge 10 ]; then
  note "plan-review rubric parity: verification.md/run/consult all carry $rubric_ref items"
else
  err "plan-review rubric drift: verification.md=${rubric_ref:-missing} run=${rubric_run:-missing} consult=${rubric_consult:-missing}"
fi

dims_ref=$(count_numbered_in_section references/verification.md "## The six review dimensions")
dims_run=$(count_numbered_in_section skills/run/SKILL.md "## Stage 5 — Review & deliver")
dims_reviewer=$(grep -cE '^\| [0-9] \|' agents/argus-reviewer.md || true)
dims_oracle=$(grep -cE '^\| [0-9] \|' agents/argus-oracle.md || true)
if [ -n "$dims_ref" ] && [ "$dims_ref" -eq 6 ] && [ "${dims_reviewer:-0}" -eq 6 ] \
   && [ "${dims_oracle:-0}" -eq 6 ] && [ -n "$dims_run" ] && [ "$dims_run" -eq 6 ]; then
  note "six review dimensions parity: verification.md/reviewer/oracle/run all carry 6"
else
  err "review-dimension drift: verification.md=${dims_ref:-missing} reviewer=${dims_reviewer:-0} oracle=${dims_oracle:-0} run=${dims_run:-missing}"
fi

# 7. Release-record check — every git tag matching v* at or after the
#    earliest version already recorded in RELEASE-CHECKLIST.md's
#    "## Release record" table must have its own row there. Tags older
#    than the earliest recorded version predate the checklist itself,
#    so they're note-skipped rather than required — there was no
#    checklist yet to run against them. A shallow clone with no tags is
#    a skip too, never a false pass presented as coverage.
tags=$(git tag -l 'v*' 2>/dev/null | sort -V)
if [ -z "$tags" ]; then
  note "release-record check skipped — no tags found (shallow clone?)"
else
  table_versions=$(grep -oE '^\| v[0-9]+\.[0-9]+\.[0-9]+ ' RELEASE-CHECKLIST.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  if [ -z "$table_versions" ]; then
    err "RELEASE-CHECKLIST.md's Release record table has no v<version> rows to anchor the check"
  else
    earliest=$(printf '%s\n' "$table_versions" | sort -V | head -1)
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      ver=${t#v}
      older=$(printf '%s\n%s\n' "$ver" "$earliest" | sort -V | head -1)
      if [ "$older" = "$ver" ] && [ "$ver" != "$earliest" ]; then
        note "release record: $t predates the checklist (earliest recorded v$earliest) — skipped"
      elif grep -qE "^\| $t " RELEASE-CHECKLIST.md; then
        note "release record has a row for $t"
      else
        err "release record: RELEASE-CHECKLIST.md is missing a row for $t (table covers v$earliest and later)"
      fi
    done <<< "$tags"
  fi
fi

# 8. Concurrent-run safety doctrine (issue #64). The stale-base merge guard
#    and the in-flight intake probe must each be present in the reference
#    and carried in summary by both skills. Each assertion greps a phrase
#    unique to the new doctrine, and is written before the doctrine so it
#    fails first (RED) and passes once the text lands.
grep -q "merge base is current" references/pipeline.md && note "pipeline.md carries the stale-base merge guard" || err "pipeline.md missing the stale-base merge guard"
grep -q "local default branch tip" references/pipeline.md && note "pipeline.md merge guard covers the no-remote path" || err "pipeline.md merge guard missing the no-remote path"
grep -q "merge base is current" skills/run/SKILL.md && note "run skill carries the merge-base freshness summary" || err "run skill missing the merge-base freshness summary"
grep -q "merge base is current" skills/consult/SKILL.md && note "consult skill carries the merge-base freshness summary" || err "consult skill missing the merge-base freshness summary"
grep -q "in-flight probe" references/pipeline.md && grep -q "primary checkout" references/pipeline.md && note "pipeline.md carries the mechanical in-flight probe" || err "pipeline.md missing the mechanical in-flight probe"
grep -q "in-flight probe" skills/run/SKILL.md && note "run skill names the in-flight probe" || err "run skill missing the in-flight probe"
grep -q "branch in place" skills/run/SKILL.md && err "run skill still carries the bare judgment-call worktree wording ('branch in place')" || note "run skill dropped the bare judgment-call worktree wording"
grep -q "in-flight probe" skills/consult/SKILL.md && note "consult skill names the in-flight probe" || err "consult skill missing the in-flight probe"

# 9. Attempt-cap persistence doctrine (issue #66). A run that dies after two
#    identical failures leaves no commit — a failed attempt produces none — so
#    the two-failure attempt count is durable only on the plan comment. Each
#    assertion greps a phrase unique to the new doctrine, written before the
#    doctrine so it fails first (RED) and passes once the text lands. The
#    example wording also lands in the clean lexicon fixture (check 1), which
#    guards that the recorded phrasing stays free of the banned token.
grep -q "the check ran twice, same failure" references/pipeline.md && note "pipeline.md carries the plain-prose attempt example" || err "pipeline.md missing the plain-prose attempt example"
grep -q "two-failure attempt count" references/pipeline.md && note "pipeline.md extends the handoff-count sentence to the attempt cap" || err "pipeline.md handoff-count sentence not extended to the attempt cap"
grep -q "adopt the recorded attempt count" references/pipeline.md && note "pipeline.md Resume adopts the attempt count as recorded" || err "pipeline.md Resume does not adopt the attempt count as recorded"
grep -q "attempt count on the plan comment" references/on-track.md && note "on-track.md records the attempt count at the second failure" || err "on-track.md missing the attempt-count record"
grep -q "one line per attempt" references/debugging.md && note "debugging.md records one line per attempt as evidence" || err "debugging.md missing the per-attempt evidence record"
grep -q "attempt count on the plan comment" skills/run/SKILL.md && note "run skill names the attempt-count record" || err "run skill missing the attempt-count record"
grep -q "attempt count on the plan comment" skills/consult/SKILL.md && note "consult skill names the attempt-count record" || err "consult skill missing the attempt-count record"
grep -q "the check ran twice, same failure" tests/fixtures/clean.md && note "clean fixture guards the attempt example wording" || err "clean fixture missing the attempt example wording"

# 10. Gate-definition edit guard (issue #67). A mid-run edit that alters or
#     weakens an existing gate — this plugin's own skills/agents/references
#     when it is installed against another repo, the repo's
#     .github/workflows/*, or the test/lint/CI config a verification check
#     depends on — needs explicit user approval and escalates to the user,
#     not the plan-review gate. Detection lives in review dimension 6
#     (references/verification.md, mirrored in both review agents);
#     prevention lives in references/delegation.md and both skills'
#     deviation handling. Each assertion greps a phrase unique to the
#     doctrine, written before the doctrine so it fails first (RED) and
#     passes once the text lands.
grep -q "Gate-definition edits are a security surface" references/verification.md && note "verification.md dimension 6 carries the gate-definition edit guard" || err "verification.md dimension 6 missing the gate-definition edit guard"
grep -q "adjudicated by the very gate it weakens" references/verification.md && note "verification.md names the plan-gate self-adjudication loophole" || err "verification.md missing the plan-gate self-adjudication loophole"
grep -q "adding a test or lint config for genuinely new code" references/verification.md && note "verification.md scopes the trigger to altering an existing gate" || err "verification.md missing the new-config-is-not-the-trigger scoping"
grep -q "proceeds under the normal gates" references/verification.md && note "verification.md carries the pipeline-is-the-product carve-out" || err "verification.md missing the pipeline-is-the-product carve-out"
grep -q "Gate-definition edits are a security surface" agents/argus-reviewer.md && note "reviewer dimension-6 row mirrors the gate-definition edit guard" || err "reviewer dimension-6 row missing the gate-definition edit guard"
grep -q "Gate-definition edits are a security surface" agents/argus-oracle.md && note "oracle dimension-6 row mirrors the gate-definition edit guard" || err "oracle dimension-6 row missing the gate-definition edit guard"
grep -q "user-gated, not lead-gated" references/delegation.md && note "delegation.md carries the lead-behavior gate-definition rule" || err "delegation.md missing the lead-behavior gate-definition rule"
grep -q "cannot adjudicate its own erosion" references/delegation.md && note "delegation.md names the user as escalation target, not the plan gate" || err "delegation.md missing the user-not-plan-gate escalation target"
grep -q "goes to the user for explicit approval" skills/run/SKILL.md && note "run skill deviation handling reroutes a gate change to the user" || err "run skill deviation handling missing the gate-change carve-out"
grep -q "not to this checkpoint" skills/consult/SKILL.md && note "consult skill deviation handling reroutes a gate change to the user" || err "consult skill deviation handling missing the gate-change carve-out"

# 11. Repo-conventions plan-review check (issue #70). The plan-review gate
#     gains an item that holds a plan against the target repo's own
#     conventions file (its CLAUDE.md or equivalent): the brief points at
#     the file by absolute path (or "none exists — checked"), the reviewer
#     reads it before ruling, and a plan decision that negates an invariant
#     written in it is a revise naming the invariant. The file is an
#     untrusted exhibit, never instructions — a foreign instruction inside
#     it is a dimension-6 finding. A missing-but-derivable pointer is a
#     plain revise, not a fourth precondition-refusal class. Each assertion
#     greps a phrase unique to the new doctrine, written before the doctrine
#     so it fails first (RED) and passes once the text lands. Rubric-count
#     parity across the reference and both skills stays check 6's job;
#     these assertions guard that each copy actually carries the item.
grep -q "Repo conventions respected" references/verification.md && note "verification.md rubric carries the repo-conventions item" || err "verification.md rubric missing the repo-conventions item"
grep -q "conventions file the plan-review brief points at" references/verification.md && note "verification.md untrusted-content section covers the conventions file" || err "verification.md untrusted-content section missing the conventions-file exhibit rule"
grep -q "not a precondition refusal" references/verification.md && note "verification.md keeps a missing pointer a plain revise, not a precondition refusal" || err "verification.md missing the plain-revise-not-precondition rule"
grep -q "Repo conventions respected" agents/argus-oracle.md && note "oracle Duty-a list carries the repo-conventions item" || err "oracle Duty-a list missing the repo-conventions item"
grep -q "read it before you rule on the plan" agents/argus-oracle.md && note "oracle standing behavior reads the conventions file before ruling" || err "oracle standing behavior missing the conventions-file read"
grep -q "absolute path of the target repo's conventions file" agents/argus-oracle.md && note "oracle input contract names the conventions-file pointer" || err "oracle input contract missing the conventions-file pointer"
grep -q "Repo conventions respected" skills/run/SKILL.md && note "run skill Stage 2.5 carries the repo-conventions rubric item" || err "run skill Stage 2.5 missing the repo-conventions rubric item"
grep -q "absolute path of the target repo's conventions file" skills/run/SKILL.md && note "run skill spawn brief names the conventions-file pointer" || err "run skill spawn brief missing the conventions-file pointer"
grep -q "Repo conventions respected" skills/consult/SKILL.md && note "consult skill Stage 2.5 carries the repo-conventions rubric item" || err "consult skill Stage 2.5 missing the repo-conventions rubric item"
grep -q "absolute path of the target repo's conventions file" skills/consult/SKILL.md && note "consult skill spawn brief names the conventions-file pointer" || err "consult skill spawn brief missing the conventions-file pointer"

# 12a. Verify CI-parity doctrine (issue #69). The verify stage's full-suite
#      evidence — and the reviewer's suite re-run — names the CI job/command and
#      install path it mirrors, so a warm-cache green isn't mistaken for CI's
#      clean-install path; a mismatch or a repo with no CI config to mirror is a
#      named degradation, never silent. Carried in summary by both skills' verify
#      stage. Each assertion greps a single-line phrase, written before the
#      doctrine so it fails first (RED) and passes once the text lands.
grep -q "the install path CI uses" references/verification.md && note "verification.md binds full-suite evidence to CI's install path" || err "verification.md missing the CI-parity install-path clause"
grep -q "no CI config to mirror" references/verification.md && note "verification.md names the no-CI-config degradation" || err "verification.md missing the no-CI-config degradation"
grep -q "the install path CI uses" skills/run/SKILL.md && note "run skill Stage 4 carries the CI-parity summary" || err "run skill Stage 4 missing the CI-parity summary"
grep -q "the install path CI uses" skills/consult/SKILL.md && note "consult skill Stage 4 carries the CI-parity summary" || err "consult skill Stage 4 missing the CI-parity summary"

# 12b. Flake-classification doctrine (issue #69). A flaky test is not a passing
#      test: never disable a test, raise a timeout, or blind-rerun to green
#      without a root cause; a red-then-green rerun is disclosed in the verify
#      evidence, not counted as plain green. The clause lands in dimension 5 and
#      the reviewer's refusal conditions, reconciles with references/debugging.md
#      (touched-code nondeterminism is a debugging event; a pre-existing
#      unrelated flake is quarantined and escalated to the user), carries a
#      writer-bar mirror in quality.md principle 5, and mirrors into both review
#      agents' dimension-5 rows AND both agents' refusal conditions (the
#      refuse-hook token "name the concealed rerun" is unique to the refusal
#      limb, so deleting it — in either agent — flips the suite RED independently
#      of the dim-5 rows). All text rides inside existing numbered items and
#      table rows, so check 6's parity count stays at 6.
grep -q "blind-rerun to green" references/verification.md && note "verification.md dimension 5 forbids blind-rerun to green" || err "verification.md dimension 5 missing the blind-rerun-to-green rule"
grep -q "red-then-green rerun" references/verification.md && note "verification.md dimension 5 discloses a red-then-green rerun" || err "verification.md dimension 5 missing the red-then-green disclosure"
grep -q "blind-rerun to green" references/quality.md && note "quality.md principle 5 carries the flake writer-bar" || err "quality.md principle 5 missing the flake writer-bar"
grep -q "pre-existing flake" references/debugging.md && note "debugging.md reconciles the pre-existing-flake case" || err "debugging.md missing the pre-existing-flake reconciliation"
grep -q "quarantined and escalated" references/debugging.md && note "debugging.md quarantines and escalates an unrelated flake" || err "debugging.md missing the quarantine-and-escalate rule"
grep -q "blind-rerun to green" agents/argus-reviewer.md && note "reviewer dimension-5 row carries the flake clause" || err "reviewer dimension-5 row missing the flake clause"
grep -q "not counted as plain green" agents/argus-reviewer.md && note "reviewer dimension-5 row disallows counting a rerun as plain green" || err "reviewer dimension-5 row missing the not-plain-green wording"
grep -q "name the concealed rerun" agents/argus-reviewer.md && note "reviewer refuse-first precondition carries the flake refusal" || err "reviewer refuse-first precondition missing the flake refusal"
grep -q "blind-rerun to green" agents/argus-oracle.md && note "oracle dimension-5 row carries the flake clause" || err "oracle dimension-5 row missing the flake clause"
grep -q "not counted as plain green" agents/argus-oracle.md && note "oracle dimension-5 row disallows counting a rerun as plain green" || err "oracle dimension-5 row missing the not-plain-green wording"
grep -q "name the concealed rerun" agents/argus-oracle.md && note "oracle Duty-c precondition refusal carries the flake refusal" || err "oracle Duty-c precondition refusal missing the flake refusal"
grep -q "blind-rerun to green" skills/run/SKILL.md && note "run skill carries the flake summary" || err "run skill missing the flake summary"
grep -q "blind-rerun to green" skills/consult/SKILL.md && note "consult skill carries the flake summary" || err "consult skill missing the flake summary"

# 13. Machine-level resource caveat (issue #73). Worktrees isolate files, not
#     the machine — fixed ports, a shared local DB or compose stack, device
#     simulators, and global caches are shared across sibling executors and
#     across concurrent runs, so a verify command binding one while other work
#     is in flight can go falsely green or red across runs. The isolation
#     model's closing bullet in references/delegation.md states that boundary
#     and its refusal condition. The doctrine lives only there — both skills
#     already point at the isolation model, so no skill edit is made (issue
#     acceptance criterion 3). Each assertion greps a single-line phrase,
#     written before the doctrine so it fails first (RED) and passes once the
#     text lands.
grep -q "boundary is the working tree" references/delegation.md && note "delegation.md isolation model states its working-tree boundary" || err "delegation.md missing the working-tree boundary caveat"
grep -q "across concurrent runs" references/delegation.md && note "delegation.md caveat covers concurrent runs, not just sibling executors" || err "delegation.md caveat missing the concurrent-run scope"
grep -q "concurrently mutating is not evidence" references/delegation.md && note "delegation.md carries the concurrent-mutation refusal condition" || err "delegation.md missing the concurrent-mutation refusal condition"

# 14. In-flight announce + planned-file overlap doctrine (issue #72). The
#     intake probe already inventories other tasks' PRs and worktrees to decide
#     worktree-vs-in-place; it now also announces that inventory in-session
#     (session-only, the same treatment as the stage-transition marker, never a
#     git artifact), and the plan stage cross-checks its named file set against
#     in-flight PRs' changed files (gh pr diff <n> --name-only), putting any
#     overlap to the user before the plan-review gate — announce-and-ask, not a
#     gate (a plan under-names files and command side effects never appear),
#     with a no-remote/no-gh degradation. Source of truth in
#     references/pipeline.md, summarised in both skills. Each assertion greps a
#     phrase unique to the new doctrine, written before the doctrine so it fails
#     first (RED) and passes once the text lands. The overlap check lands as
#     Stage-2 (plan) doctrine, not a Stage-2.5 rubric item, so check 6's parity
#     count stays at 11.
grep -q "Announce in-flight work at intake" references/pipeline.md && note "pipeline.md carries the in-flight announce section" || err "pipeline.md missing the in-flight announce section"
grep -q "in flight: #12, worktree ../repo-12" references/pipeline.md && note "pipeline.md carries the in-flight announce example" || err "pipeline.md missing the in-flight announce example"
grep -q "Planned-file overlap check" references/pipeline.md && note "pipeline.md carries the planned-file overlap section" || err "pipeline.md missing the planned-file overlap section"
grep -q "gh pr diff <n> --name-only" references/pipeline.md && note "pipeline.md names the overlap cross-check command" || err "pipeline.md missing the overlap cross-check command"
grep -q "announce-and-ask, not a gate" references/pipeline.md && note "pipeline.md frames the overlap check as announce-and-ask, not a gate" || err "pipeline.md missing the announce-and-ask-not-a-gate framing"
grep -q "PR registry is unavailable" references/pipeline.md && note "pipeline.md carries the overlap-check degradation" || err "pipeline.md missing the overlap-check degradation"
grep -q "announce in-flight work" skills/run/SKILL.md && note "run skill carries the in-flight announce summary" || err "run skill missing the in-flight announce summary"
grep -q "planned-file overlap" skills/run/SKILL.md && note "run skill carries the planned-file overlap summary" || err "run skill missing the planned-file overlap summary"
grep -q "announce in-flight work" skills/consult/SKILL.md && note "consult skill carries the in-flight announce summary" || err "consult skill missing the in-flight announce summary"
grep -q "planned-file overlap" skills/consult/SKILL.md && note "consult skill carries the planned-file overlap summary" || err "consult skill missing the planned-file overlap summary"

# 15. Sensitive-path user-acceptance gate (issue #68). A change whose diff
#     touches a sensitive path (auth, payments/billing, secrets/.env, CI
#     workflow files, DB migrations) routes through the existing
#     user-acceptance hold — the perceptual-goal hold generalized to two
#     triggers, one hold mechanism, not a new gate. The canonical list lives
#     in references/verification.md as the single source; delegation.md's
#     never-delegate bullet, the implementer, and both review agents point at
#     it; review dimension 6 compares the diff's touched files against it; a
#     repo's CLAUDE.md may extend or exempt the list, and the model-gate
#     override does not waive it. No rubric item or dimension is added, so
#     check 6's parity counts stay at 11 and 6. Each assertion greps a phrase
#     unique to the doctrine, written before the doctrine so it fails first
#     (RED) and passes once the text lands.
grep -q "## Sensitive paths" references/verification.md && note "verification.md carries the canonical sensitive-paths section" || err "verification.md missing the canonical sensitive-paths section"
grep -q "override does not waive" references/verification.md && note "verification.md states the model-gate override does not waive the path gate" || err "verification.md missing the override-does-not-waive note"
grep -q "may extend or exempt" references/verification.md && note "verification.md lets a repo's conventions file extend or exempt the list" || err "verification.md missing the extend-or-exempt allowance"
grep -q "against the sensitive-paths list" references/verification.md && note "verification.md dimension 6 compares touched files against the list" || err "verification.md dimension 6 missing the touched-file comparison"
grep -q "two triggers" references/pipeline.md && note "pipeline.md generalizes the hold to two triggers" || err "pipeline.md missing the two-trigger hold"
grep -q "sensitive path" references/pipeline.md && note "pipeline.md names the sensitive-path trigger on the hold" || err "pipeline.md missing the sensitive-path trigger"
grep -q "sensitive-paths list" references/delegation.md && note "delegation.md never-delegate bullet points at the sensitive-paths list" || err "delegation.md missing the sensitive-paths-list pointer"
grep -q "categorical STOP" agents/argus-implementer.md && note "implementer hard rules carry the categorical sensitive-path stop" || err "implementer missing the categorical sensitive-path stop"
grep -q "sensitive-paths list" agents/argus-reviewer.md && note "reviewer dimension-6 row points at the sensitive-paths list" || err "reviewer dimension-6 row missing the sensitive-paths-list pointer"
grep -q "sensitive-paths list" agents/argus-oracle.md && note "oracle dimension-6 row points at the sensitive-paths list" || err "oracle dimension-6 row missing the sensitive-paths-list pointer"
grep -q "sensitive path" skills/run/SKILL.md && note "run skill names the sensitive-path hold trigger" || err "run skill missing the sensitive-path hold trigger"
grep -q "sensitive path" skills/consult/SKILL.md && note "consult skill names the sensitive-path hold trigger" || err "consult skill missing the sensitive-path hold trigger"

# 16. Per-run cost line + stated-budget threshold (issue #71). The plan header
#     gains a session-side cost line (order-of-magnitude, the pipeline path and
#     which model tier pays each expensive step; never written into the plan
#     comment), a new plan-review item "Cost line present" checks it exists —
#     added to references/verification.md and mirrored in both skills and
#     agents/argus-oracle.md's Duty-a list — and references/on-track.md gains a
#     "Stated budget" section forcing escalate-or-hand-off at ~80% of a stated
#     budget. Adding the numbered review item bumps check 6's rubric parity
#     11 -> 12, which also stales two prose self-counts (the verification.md
#     precondition sentence and the consult review-order count); those are
#     edited AND guarded here with grep-new-present / grep-old-absent pairs
#     (check 6 counts list items, not prose, so it cannot see a stale count).
#     Each assertion greps a contiguous single-line phrase, written before the
#     doctrine so it fails first (RED) and passes once the text lands. The
#     old-absent greps err-when-present so they too are RED until the edit lands.
grep -q "Cost line present" references/verification.md && note "verification.md rubric carries the cost-line item" || err "verification.md rubric missing the cost-line item"
grep -q "Cost line present" skills/run/SKILL.md && note "run skill Stage 2.5 carries the cost-line rubric item" || err "run skill Stage 2.5 missing the cost-line rubric item"
grep -q "Cost line present" skills/consult/SKILL.md && note "consult skill Stage 2.5 carries the cost-line rubric item" || err "consult skill Stage 2.5 missing the cost-line rubric item"
grep -q "Cost line present" agents/argus-oracle.md && note "oracle Duty-a list carries the cost-line rubric item" || err "oracle Duty-a list missing the cost-line rubric item"
grep -q "which model tier pays each expensive step" references/verification.md && note "verification.md cost-line item names the model-tier detail" || err "verification.md cost-line item missing the model-tier detail"
grep -q "per-run cost line" skills/run/SKILL.md && note "run skill Stage 2 defines the per-run cost line" || err "run skill Stage 2 missing the per-run cost-line definition"
grep -q "per-run cost line" skills/consult/SKILL.md && note "consult skill Stage 2 defines the per-run cost line" || err "consult skill Stage 2 missing the per-run cost-line definition"
grep -q "never written into the plan comment" skills/run/SKILL.md && note "run skill marks the cost line session-side" || err "run skill missing the cost-line session-side rule"
grep -q "never written into the plan comment" skills/consult/SKILL.md && note "consult skill marks the cost line session-side" || err "consult skill missing the cost-line session-side rule"
grep -q "## Stated budget" references/on-track.md && note "on-track.md carries the stated-budget section" || err "on-track.md missing the stated-budget section"
grep -q "roughly 80 percent" references/on-track.md && note "on-track.md sets the ~80% budget threshold" || err "on-track.md missing the ~80% budget threshold"
grep -q "never continue silently" references/on-track.md && note "on-track.md forces escalate-or-hand-off, never silent" || err "on-track.md missing the never-continue-silently refusal"
grep -q "items 1–12" references/verification.md && note "verification.md precondition sentence updated to items 1–12" || err "verification.md precondition sentence not updated to items 1–12"
grep -q "items 1–11 above" references/verification.md && err "verification.md still carries the stale 'items 1–11 above' count" || note "verification.md dropped the stale 'items 1–11 above' count"
grep -q "twelve-item review order" skills/consult/SKILL.md && note "consult review-order count updated to twelve-item" || err "consult review-order count not updated to twelve-item"
grep -q "eleven-item review order" skills/consult/SKILL.md && err "consult still carries the stale 'eleven-item review order' count" || note "consult dropped the stale 'eleven-item review order' count"

# 17. Changelog-gate release roll-up loss check (issue #63). Release mode
#     asserted structure only — empty Unreleased, correct headings, a
#     non-empty new section, prior sections untouched — but never compared the
#     entries leaving the Unreleased span against those arriving in the new
#     version section, so a roll-up that dropped or reworded an entry passed.
#     tests/changelog-gate.sh now compares the two sets; tests/changelog-gate.test.sh
#     exercises it against throwaway repos (dropped, altered, lossless,
#     fresh-notes, and stranded-line scenarios), each RED against the old gate
#     and GREEN once the comparison lands. A jq-absent host skips inside the
#     harness (release mode is jq-guarded), reported as a skip here.
if cl_scen=$(bash tests/changelog-gate.test.sh 2>&1); then
  case "$cl_scen" in
    skip:*) note "changelog-gate scenarios skipped — ${cl_scen#skip: }" ;;
    *)      note "changelog-gate release-mode scenarios pass" ;;
  esac
else
  err "changelog-gate release-mode scenarios failed (bash tests/changelog-gate.test.sh):"
  printf '%s\n' "$cl_scen"
fi

# 18. v0.7.0 skill-review findings (issue #62). Nine skill-summary alignments
#     bring skills/run and skills/consult back in sync with the reference files
#     they defer to. Each assertion greps the aligned phrase — RED before the
#     edit, GREEN after. Items 4 and 9 span BOTH skills, so each is asserted in
#     both files; item 5 checks the restructured bullet header; item 7 asserts
#     the reviewer-operating-rules read now precedes the review spawn; item 8
#     also asserts the old three-alternative patch-file phrasing is gone.
grep -q "running on a Fable or Opus model" skills/run/SKILL.md && note "run description carries the model qualifier (item 1)" || err "run description missing the model qualifier (item 1)"
grep -q "The rule survives the commit" skills/run/SKILL.md && note "run triviality summary carries the commit-survival clause (item 2)" || err "run triviality summary missing the commit-survival clause (item 2)"
grep -q "offer a committed report file" skills/run/SKILL.md && note "run read-only route carries the degraded report-file offer (item 3)" || err "run read-only route missing the degraded report-file offer (item 3)"
grep -q "Scope each degrade to the agent" skills/run/SKILL.md && note "run availability scopes each degrade per-agent (item 4)" || err "run availability degrade not scoped per-agent (item 4)"
grep -q "independent of the oracle" skills/consult/SKILL.md && note "consult scopes the executors-missing degrade independent of the oracle (item 4)" || err "consult executors-missing degrade still nested under the oracle (item 4)"
grep -qF -- "- **Ambiguity gate:**" skills/consult/SKILL.md && note "consult intake restructured into bullets (item 5)" || err "consult intake not restructured into bullets (item 5)"
grep -q "prose-style, diagram, and decision-record standard" skills/run/SKILL.md && note "run intake pointer widened past naming and message (item 6)" || err "run intake pointer not widened (item 6)"
r18_read=$(grep -n "reviewer operating rules" skills/run/SKILL.md | head -1 | cut -d: -f1)
r18_spawn=$(grep -nF 'Spawn `argus-reviewer`' skills/run/SKILL.md | head -1 | cut -d: -f1)
if [ -n "$r18_read" ] && [ -n "$r18_spawn" ] && [ "$r18_read" -lt "$r18_spawn" ]; then
  note "run delivery reads the review operating rules before the review spawn (item 7)"
else
  err "run delivery reads the operating rules after the spawn (item 7): read line ${r18_read:-none}, spawn line ${r18_spawn:-none}"
fi
grep -qF -- "repo tree (the session's scratch directory)" skills/run/SKILL.md && note "run model-gate door 3 renders the patch-file rule as two alternatives (item 8)" || err "run model-gate door 3 not aligned to the two-alternative form (item 8)"
grep -qF -- "repo tree, in the session's scratch directory" skills/run/SKILL.md && err "run model-gate door 3 still carries the old three-alternative phrasing (item 8)" || note "run dropped the old three-alternative patch-file phrasing (item 8)"
grep -q "or the issue text carries them" skills/run/SKILL.md && note "run judgment-value summary carries the second branch (item 9)" || err "run judgment-value summary missing the second branch (item 9)"
grep -q "or the issue text carries them" skills/consult/SKILL.md && note "consult judgment-value summary carries the second branch (item 9)" || err "consult judgment-value summary missing the second branch (item 9)"

# 19. Diagram-skill routing doctrine (issue #87). Domain-skill routing is
#     table-driven in references/delegation.md and recorded a step after
#     issues are composed, so a diagram-rendering skill was never picked up
#     when composing a git artifact. A row in the routing table names the
#     skill; a delegation note keeps rendering and delivery undelegated (the
#     raster delivery is a commit) and briefs an image-producing slice with
#     an absolute-path command; and references/git-conventions.md's diagram
#     section (read at intake) gains the route-through-the-skill guidance,
#     raster sequencing on the orphan assets branch, the private-repo
#     no-raster-embed degrade, and the diagram-source-is-artifact-text rule.
#     Asserts #1-#8 are RED-first (written before the content); asserts
#     #9-#12 are regression guards on the pre-existing diagram discipline
#     (green now, red if a future edit removes it — the shape of checks 5/8).
#     Adds no plan-review rubric item and no review dimension, so check 6's
#     parity counts (12 and 6) are untouched.
grep -q "author or embed on a git artifact" references/delegation.md && note "delegation.md routing table carries the diagram row" || err "delegation.md missing the diagram routing row"
grep -q "visualize" references/delegation.md && note "delegation.md routing row names the diagram skill" || err "delegation.md routing row does not name the diagram skill"
grep -q "create the target directory first" references/delegation.md && note "delegation.md briefs an image slice to create the target directory" || err "delegation.md missing the create-target-directory reminder"
grep -q "resolved to an absolute path" references/delegation.md && note "delegation.md briefs the image command with an absolute path" || err "delegation.md missing the absolute-path brief clause"
grep -q "git push origin assets" references/git-conventions.md && note "git-conventions.md carries the assets-branch push sequencing" || err "git-conventions.md missing the assets-branch push sequencing"
grep -q "no raster embeds" references/git-conventions.md && note "git-conventions.md carries the private-repo no-raster-embed degrade" || err "git-conventions.md missing the private-repo no-raster-embed degrade"
grep -q "delivered as an image" references/git-conventions.md && note "git-conventions.md routes a non-Mermaid diagram through the skill as an image" || err "git-conventions.md missing the route-through-the-skill-as-an-image rule"
grep -q '\.mmd' references/git-conventions.md && note "git-conventions.md treats diagram source (.mmd/...) as artifact text" || err "git-conventions.md missing the diagram-source-is-artifact-text rule"
grep -q "Illustrate, don't govern" references/git-conventions.md && note "diagram discipline intact: illustrate-don't-govern" || err "diagram discipline weakened: illustrate-don't-govern removed"
grep -q "Stable types only" references/git-conventions.md && note "diagram discipline intact: stable-types trio" || err "diagram discipline weakened: stable-types rule removed"
grep -q "Team voice applies inside the diagram" references/git-conventions.md && note "diagram discipline intact: team voice inside diagram labels" || err "diagram discipline weakened: label-voice rule removed"
grep -q "let the diagram restate it" references/git-conventions.md && note "diagram discipline intact: the refusal condition" || err "diagram discipline weakened: the refusal condition removed"

echo
if [ "$fail" -eq 0 ]; then echo "all checks passed"; else echo "checks failed"; exit 1; fi
