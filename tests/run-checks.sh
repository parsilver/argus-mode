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

# 20. Red-leg witness doctrine (issue #93). Verification evidence was
#     green-only, so a new test that first failed for a trivial reason — a
#     NameError, import, or collection error before the symbol existed — then
#     passed trivially cleared every check that is actually looked at. The
#     pre-implementation failing run is now a captured artifact, and that
#     failure must be a behavioral assertion that names the pinned behavior,
#     not a collection/import/attribute/syntax error. "What a failable check
#     is" (verification.md) carries the red-provenance clause and the RED-leg
#     token; the behavioral-assertion bar rides principle 5 / dimension 5
#     across quality.md and both review agents; the implementer report gains a
#     red-leg-output field; both skills' verify sections reference the capture.
#     Written RED-first — the two tokens do not exist until the prose lands, so
#     this check fails before #93's content and passes after it. Rides inside
#     no numbered rubric item or dimension row, so check 6's parity counts (12
#     and 6) are untouched.
for f in references/verification.md references/quality.md agents/argus-reviewer.md agents/argus-oracle.md; do
  if grep -qi "behavioral assertion failure" "$f"; then
    note "red-leg behavioral-assertion bar present in $f"
  else
    err "red-leg behavioral-assertion bar missing from $f"
  fi
done
for f in references/verification.md agents/argus-implementer.md skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -qi "RED leg" "$f"; then
    note "red-leg capture reference present in $f"
  else
    err "red-leg capture reference missing from $f"
  fi
done

# 21. Merge CI-check + branch-protection gate (issue #94). The merge step
#     gathered green by running CI's command locally and never polled the PR's
#     own check-runs, so a red or pending CI-only job could still merge on a
#     local proxy; the merge also ran with no awareness of branch protection.
#     The merge now polls the PR's required check-runs (`gh pr checks`), reads
#     the default branch's protection (a required approval readies-and-waits, a
#     merge-method constraint selects the flag), reuses a concluded-success CI
#     run on the verified commit as auditable evidence instead of a redundant
#     local re-run, and degrades by a named skip when there are zero check-runs
#     or no protection info. Written RED-first — the tokens below do not exist
#     until #94's prose lands, so this check fails before it and passes after.
#     Rides inside no numbered rubric item or dimension row, so check 6's parity
#     counts (12 and 6) are untouched.
for f in references/pipeline.md skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -q "gh pr checks" "$f"; then
    note "merge CI-check poll present in $f"
  else
    err "merge CI-check poll (gh pr checks) missing from $f"
  fi
  if grep -q "/protection" "$f"; then
    note "branch-protection read present in $f"
  else
    err "branch-protection read (/protection) missing from $f"
  fi
done
if grep -q "zero check-runs" references/pipeline.md; then
  note "pipeline.md degradation row covers zero check-runs / no protection"
else
  err "pipeline.md missing the zero-check-runs degradation row"
fi
for f in references/verification.md agents/argus-reviewer.md agents/argus-oracle.md; do
  if grep -q "concluded success" "$f"; then
    note "CI-conclusion-as-evidence present in $f"
  else
    err "CI-conclusion-as-evidence (concluded success) missing from $f"
  fi
done
if grep -q "merge method" references/git-conventions.md; then
  note "git-conventions.md carries the merge-method-from-protection note"
else
  err "git-conventions.md missing the merge-method-from-protection note"
fi

# 22. Commit-hook Stage-4 parity + --no-verify refusal (issue #95). Stage 4
#     mirrored CI but ignored the repo's commit-time hooks (.pre-commit-config.yaml,
#     .husky/, lefthook.yml, a non-default core.hooksPath) — formatters/linters that
#     can differ from or exceed CI; a hook failure had no pipeline rule and nothing
#     forbade a --no-verify bypass. The scout now discovers hook config, the hook
#     suite is explicit command->result Stage-4 evidence (no hooks configured = named
#     absence), the isolation model forbids the lead committing --no-verify (a hook
#     bypass is a gate bypass, a failing hook a Stage-4 RED into debugging), and both
#     review agents' dimension-6 rows flag a missing hook-run on a hooks-configured
#     repo as a Stage-4-completeness finding (the prohibition itself is a prompt-level
#     lead rule). Written RED-first — the tokens below do not exist until #95's prose
#     lands, so this check fails before it and passes after. Rides inside no numbered
#     rubric item or dimension row, so check 6's parity counts (12 and 6) are untouched.
if grep -q "no-verify" references/delegation.md; then
  note "delegation.md carries the --no-verify prohibition"
else
  err "delegation.md missing the --no-verify prohibition (no-verify)"
fi
if grep -q "hook bypass is a gate bypass" references/delegation.md; then
  note "delegation.md carries the gate-bypass anchor phrase"
else
  err "delegation.md missing the 'hook bypass is a gate bypass' anchor"
fi
if grep -q "core.hooksPath" references/pipeline.md; then
  note "pipeline.md scout discovers hook config (core.hooksPath)"
else
  err "pipeline.md scout missing hook discovery (core.hooksPath)"
fi
for f in references/verification.md skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -q "commit-hook suite" "$f"; then
    note "commit-hook Stage-4 evidence doctrine present in $f"
  else
    err "commit-hook Stage-4 evidence doctrine (commit-hook suite) missing from $f"
  fi
done
if grep -q "core.hooksPath" references/verification.md; then
  note "verification.md names the hook runners generically (core.hooksPath)"
else
  err "verification.md missing generic runner naming (core.hooksPath)"
fi
if grep -q "no commit hooks configured" references/verification.md; then
  note "verification.md carries the no-hooks named-absence rule"
else
  err "verification.md missing the no-hooks named-absence rule"
fi
for f in agents/argus-reviewer.md agents/argus-oracle.md; do
  if grep -q "no-verify" "$f"; then
    note "dimension-6 --no-verify completeness-check mirror present in $f"
  else
    err "dimension-6 --no-verify completeness-check mirror (no-verify) missing from $f"
  fi
done

# 23. Untrusted input at intake + requester trust tier (issue #96). The
#     data-not-instructions rule bound only the review agents, and the lead's
#     binding was narrow (gate-definition edits), so an imperative embedded in a
#     fetched issue/PR/comment body could steer the plan itself — and the
#     plan-review gate would then faithfully diff that plan against the injected
#     criteria. Injection was defended where it is detected, not where it lands.
#     Separately, a non-write author's criteria were treated as the trusted
#     contract. The lead now scans every body it did not author (addressee/diff/
#     channel tests, not a keyword list), quarantines and surfaces an imperative
#     in-session, probes every contributing author's permission and takes the minimum, and records both an
#     Untrusted-input scan line and a Trust tier line in the plan header;
#     unratified criteria are a revise that ONLY the user's ratification
#     clears (the run skill's override bullet is carved out — without that the
#     rule does not bind, since the override is written against any revise).
#     Written RED-first — every token below is absent until #96's prose lands.
#     Rides inside existing rubric item 2, adds no dimension and no fourth
#     precondition class, so check 6's parity counts (12 and 6) are untouched.
if grep -q "## Untrusted input at intake" references/pipeline.md; then
  note "pipeline.md carries the untrusted-input intake section"
else
  err "pipeline.md missing the '## Untrusted input at intake' section"
fi
if grep -q "did not author" references/pipeline.md; then
  note "pipeline.md scopes the scan to text this run did not author"
else
  err "pipeline.md missing the 'did not author' scope clause"
fi
if grep -q "collaborators/" references/pipeline.md; then
  note "pipeline.md carries the author-permission probe"
else
  err "pipeline.md missing the author-permission probe (collaborators/)"
fi
if grep -q "Untrusted input at intake" references/delegation.md; then
  note "delegation.md points at the general lead-side rule"
else
  err "delegation.md missing the pointer to 'Untrusted input at intake'"
fi
# The carve-out is the single mechanism that makes the boundary bind, so it
# is guarded in the reference that wins on conflict AND in both skills — the
# consult mode-comparison table describes run's override rule, so a stale copy
# there re-advertises the bypass this closes.
for f in skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -q "only the user's ratification" "$f"; then
    note "override carve-out for the unratified revise present in $f"
  else
    err "override carve-out (only the user's ratification) missing from $f"
  fi
done
if grep -q "nothing else clears it" references/verification.md; then
  note "verification.md carries the carve-out as the source of truth"
else
  err "verification.md missing the carve-out (nothing else clears it)"
fi
# The tier must be the MINIMUM over every contributing author, in the reference
# AND in both skills — the skills are what the lead executes, so a singular copy
# there reopens the attack (a non-write commenter's criterion riding in under the
# issue author's tier) no matter what the reference says.
for f in references/pipeline.md skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -q "minimum over" "$f"; then
    note "tier-is-the-minimum-over-contributing-authors rule present in $f"
  else
    err "tier plurality rule (minimum over) missing from $f"
  fi
done
# The scan and probe must survive a resume — they are per-run duties, not state
# to adopt.
if grep -q "the tier probe still run" references/pipeline.md && grep -qi "rescan" references/pipeline.md; then
  note "pipeline.md binds the scan/probe across a resume"
else
  err "pipeline.md missing the resume binding (still run / rescan)"
fi
for f in references/pipeline.md skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -q "Trust tier" "$f"; then
    note "trust-tier plan-header record present in $f"
  else
    err "trust-tier plan-header record (Trust tier) missing from $f"
  fi
done
for f in references/verification.md skills/run/SKILL.md skills/consult/SKILL.md agents/argus-oracle.md; do
  if grep -q "Untrusted-input scan" "$f"; then
    note "untrusted-input-scan record present in $f"
  else
    err "untrusted-input-scan record (Untrusted-input scan) missing from $f"
  fi
  # Case-insensitive: the header flag is UNRATIFIED, the prose says
  # "unratified criteria" — the concept is the assertion, not its case.
  if grep -qi "unratified" "$f"; then
    note "unratified-criteria block present in $f"
  else
    err "unratified-criteria block (unratified) missing from $f"
  fi
done

# 24. Mechanical secret-scan of the diff (issue #97). Dimension 6's secret half
#     was reviewer judgment with no required command — "no secrets found" is the
#     opinion the pipeline forbids as a check everywhere else. Stage 4 now runs a
#     secret-scan over the diff (gitleaks/trufflehog preferred, a named
#     regex-sweep shipped as the fallback), its output recorded and attached;
#     both review agents refuse a diff without it and audit the output under
#     dimension 6, and quality.md principle 6 carries the writer-bar mirror. The
#     shipped regex-sweep is fixture-tested for efficacy the way check 1 tests
#     the lexicon pattern: extracted from verification.md and run against a dirty
#     fixture it MUST flag and a clean fixture (false-positive traps) it must
#     NOT. Written RED-first — the tokens and the shipped pattern are absent
#     until #97's prose lands, so this fails before it and passes after. All
#     prose rides inside dimension 6 / "what a failable check is", and the
#     fixtures plus the extraction assertion live outside every region check 6
#     counts, so check 6's parity counts (12 and 6) are untouched.
for f in references/verification.md references/quality.md agents/argus-reviewer.md agents/argus-oracle.md skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -q "secret-scan" "$f"; then
    note "secret-scan doctrine present in $f"
  else
    err "secret-scan doctrine (secret-scan) missing from $f"
  fi
done
grep -q "gitleaks" references/verification.md && note "verification.md names the preferred scanners (gitleaks)" || err "verification.md missing the preferred-scanner naming (gitleaks)"
grep -q "regex-sweep" references/verification.md && note "verification.md names the shipped regex-sweep fallback" || err "verification.md missing the regex-sweep fallback name"
grep -qi "no scanner installed" references/verification.md && note "verification.md carries the no-scanner named degradation" || err "verification.md missing the no-scanner named degradation"
for f in agents/argus-reviewer.md agents/argus-oracle.md; do
  if grep -q "secret-scan output" "$f"; then
    note "dimension-6 refuses a diff without secret-scan output in $f"
  else
    err "dimension-6 secret-scan-output refusal missing from $f"
  fi
done
# Efficacy: extract the shipped regex-sweep pattern from verification.md and
# exercise it against the fixtures, the way check 1 exercises the lexicon
# pattern (a single grep -iEn '...' command, distinct flags from the lexicon's
# grep -inE and in a different file, so no extraction collision). A
# shipped-but-untested matcher would let the fallback report "no secrets found"
# as an unvalidated opinion — the exact thing this change removes.
[ -f tests/fixtures/secrets-dirty.md ] || err "secret dirty fixture missing (tests/fixtures/secrets-dirty.md)"
[ -f tests/fixtures/secrets-clean.md ] || err "secret clean fixture missing (tests/fixtures/secrets-clean.md)"
sweep=$(grep -o "grep -iEn '[^']*'" references/verification.md | head -1 | sed "s/^grep -iEn '//; s/'\$//")
if [ -z "$sweep" ]; then
  err "shipped regex-sweep pattern not found in references/verification.md (expected one grep -iEn '...' command)"
elif [ -f tests/fixtures/secrets-dirty.md ] && [ -f tests/fixtures/secrets-clean.md ]; then
  dhits=$(grep -icE -e "$sweep" tests/fixtures/secrets-dirty.md || true)
  if [ "${dhits:-0}" -ge 1 ]; then
    note "shipped regex-sweep flags the dirty secret fixture ($dhits hits)"
  else
    err "shipped regex-sweep has zero hits on the dirty secret fixture — pattern malformed?"
  fi
  chits=$(grep -icE -e "$sweep" tests/fixtures/secrets-clean.md || true)
  if [ "${chits:-0}" -eq 0 ]; then
    note "shipped regex-sweep passes the clean secret fixture (0 hits)"
  else
    err "shipped regex-sweep flagged the clean secret fixture (${chits}): $(grep -inE "$sweep" tests/fixtures/secrets-clean.md)"
  fi
fi
# Per-branch coverage (review follow-up): dhits>=1 is a single OR over the
# pattern's branches, so a broken single branch can stay green while the fixture
# still hits via another. Drive each detector branch with its own probe,
# constructed at runtime so no full provider-token literal is committed (GitHub
# push protection and the dogfood scan both stay clean), and require each to
# match — breaking or deleting any branch turns this RED, so the doctrine's "a
# broken pattern cannot silently report nothing found" holds per branch.
if [ -n "$sweep" ]; then
  d5=$(printf -- '-%.0s' $(seq 5))
  declare -a sweep_probes=(
    "AKIA$(printf 'A%.0s' $(seq 16))"
    "ghp_$(printf 'a%.0s' $(seq 36))"
    "xoxb-$(printf '0%.0s' $(seq 12))"
    "AIza$(printf 'a%.0s' $(seq 35))"
    "${d5}BEGIN RSA PRIVATE KEY${d5}"
    "token=$(printf 'a%.0s' $(seq 16))"
  )
  declare -a sweep_names=( AKIA ghp_ xox AIza PEM keyword-assign )
  for i in "${!sweep_probes[@]}"; do
    if printf '%s\n' "${sweep_probes[$i]}" | grep -qiE -e "$sweep"; then
      note "secret-sweep branch '${sweep_names[$i]}' matches its probe"
    else
      err "secret-sweep branch '${sweep_names[$i]}' does not match — branch broken or removed"
    fi
  done
  # Guard against a future branch added to the pattern without a matching probe:
  # count the pattern's top-level alternation branches (paren-depth and bracket
  # aware, the way check 1 splits the lexicon pattern) and require it to equal
  # the probe count, so extending the pattern without extending the probes here
  # turns this RED instead of silently under-covering.
  inner=${sweep#(}; inner=${inner%)}
  nbranch=$(awk -v s="$inner" 'BEGIN {
    depth = 0; n = length(s); count = 1;
    for (i = 1; i <= n; i++) {
      c = substr(s, i, 1);
      if (c == "(") depth++;
      else if (c == ")") depth--;
      else if (c == "[") { i++; while (i <= n && substr(s, i, 1) != "]") i++; }
      else if (c == "|" && depth == 0) count++;
    }
    print count;
  }')
  if [ "${nbranch:-0}" -eq "${#sweep_probes[@]}" ]; then
    note "secret-sweep per-branch probes cover all $nbranch pattern branches"
  else
    err "secret-sweep branch/probe mismatch: pattern has $nbranch top-level branches, ${#sweep_probes[@]} probes"
  fi
fi
# The scan output is bound to the diff's freshness/range, like the test evidence
# (review follow-up: a stale/mis-ranged clean scan must not pass the gate).
grep -q "Stage-4 HEAD SHA" references/verification.md && note "verification.md binds the secret-scan to the Stage-4 HEAD SHA" || err "verification.md missing the secret-scan freshness/range binding (Stage-4 HEAD SHA)"

# 25. Capability preflight (issue #98). The pipeline discovered environment
#     degradations one at a time mid-run and announced each as it hit it, so a run
#     on a fresh repo learned its true shape piecemeal. A new "## Capability
#     preflight" section in references/pipeline.md consolidates the probes into one
#     intake table — legibility only, no new gate, session-only — generalizing the
#     pre-Stage-0 agent-availability announcement to the git/CI capabilities too.
#     Both skills keep announcing a missing agent DIRECTLY — the floor that covers
#     the read-only route and a skills-only install — and re-show the modes in the
#     preflight when it runs; the consult skill also keeps its pre-Stage-0
#     oracle-missing OFFER. The six environment mode cells that map to a
#     "## Degradation rules" condition reuse it verbatim, so a two-sided drift guard
#     requires each string in both the preflight and the live Degradation section.
#     Written RED-first — the phrases below
#     are absent until #98's prose lands, so this fails before it and passes after.
#     Rides inside no numbered rubric item or dimension row, so check 6's parity
#     counts (12 and 6) are untouched.
preflight=$(awk '/^## Capability preflight$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
if [ -n "$preflight" ]; then
  note "pipeline.md carries the '## Capability preflight' section"
else
  err "pipeline.md missing the '## Capability preflight' section"
fi
if printf '%s\n' "$preflight" | grep -q "announcement, not a gate"; then
  note "preflight section frames itself as an announcement, not a gate"
else
  err "preflight section missing the 'announcement, not a gate' framing"
fi
if printf '%s\n' "$preflight" | grep -q "decides nothing"; then
  note "preflight section states it decides nothing (session-only)"
else
  err "preflight section missing the 'decides nothing' session-only framing"
fi
# Drift guard (two-sided): each string below must appear verbatim in BOTH the
# extracted preflight section AND the live "## Degradation rules" section.
# Presence in the preflight proves it reuses the vocabulary; presence in the
# live Degradation section couples the guard to the real source — rewording a
# Degradation condition (or truncating the preflight cell) turns this RED instead
# of drifting silently against a frozen copy. Only the six rows that map to a
# Degradation-rules condition are pinned; the issue-type and CI rows reuse the
# Issue-metadata-contract and verification.md vocabulary, not this table. The
# Projects string carries its full parenthetical, so a truncated cell fails.
degrada=$(awk '/^## Degradation rules$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
while IFS= read -r cond; do
  [ -n "$cond" ] || continue
  in_pf=$(printf '%s\n' "$preflight" | grep -qF "$cond" && echo y || echo n)
  in_dg=$(printf '%s\n' "$degrada" | grep -qF "$cond" && echo y || echo n)
  if [ "$in_pf" = y ] && [ "$in_dg" = y ]; then
    note "preflight and Degradation rules both carry the verbatim string: $cond"
  else
    err "drift: '$cond' — in preflight=$in_pf, in Degradation rules=$in_dg (both must be y)"
  fi
done <<'PFCONDS'
No git repo
Git repo, no remote at all
Remote exists, `gh` CLI missing
Remote exists, no push rights (fork / OSS contribution)
Issues disabled on the repo, or no permission to create them
No Projects v2 board, or the token lacks the project scope (`project` in `gh auth status`)
PFCONDS
# The issue's own failable check: preflight referenced from BOTH skills.
for f in skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -q "preflight" "$f"; then
    note "preflight referenced from $f (issue #98 failable check)"
  else
    err "preflight not referenced from $f (issue #98 failable check)"
  fi
done
# Preflight-anchor retention: both skills carry the "announced in the capability
# preflight" anchor in their availability sections, so the preflight re-shows each
# agent's mode alongside the environment capabilities — the direct floor
# announcement stays; this is the consolidated view, not a replacement.
for f in skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -q "announced in the capability preflight" "$f"; then
    note "preflight anchor present in $f"
  else
    err "preflight anchor (announced in the capability preflight) missing from $f"
  fi
done
# Regression guards — no rename broke a cross-reference, and consult's pre-Stage-0
# severe oracle-missing OFFER survives the reword (a decision the post-Stage-0
# preflight cannot host, so it must stay in place).
grep -q "## Agent availability check" skills/run/SKILL.md && note "run skill keeps the Agent availability check heading" || err "run skill lost the Agent availability check heading"
grep -q "## Agent availability check" skills/consult/SKILL.md && note "consult skill keeps the Agent availability check heading" || err "consult skill lost the Agent availability check heading"
grep -q "per the Agent availability check above" skills/run/SKILL.md && note "run skill keeps the 'per the Agent availability check above' cross-refs" || err "run skill lost the 'per the Agent availability check above' cross-refs"
grep -q "Offer the user the choice before proceeding" skills/consult/SKILL.md && note "consult keeps the pre-Stage-0 severe oracle-missing offer" || err "consult lost the pre-Stage-0 severe oracle-missing offer"

# 26. Stage-transition marker counter block (issue #99). The marker showed only
#     "Stage N done → next"; the revise (2) / rework (2) / attempt (3) caps, the
#     active degradations, and the stated-budget standing were never surfaced as a
#     live glance, so a user could not see "one send-back from escalation" without
#     the model volunteering it. The "## Stage-transition marker" section in
#     references/on-track.md is extended into a compact block re-printed at every
#     boundary — a gates counter line, a degraded line (shown only when degraded),
#     and a budget line (shown only when a budget was stated) — rendering state that
#     already exists (plan-comment counts, named degrades, stated budget), never a
#     new count, session-only. The three counters are asserted SEPARATELY, never
#     grepping the "·" middot separator (load-bearing — a hand-wrap could split the
#     line around it). Written RED-first — the tokens are absent until #99's prose
#     lands, so this fails before it and passes after. Rides inside no numbered
#     rubric item or dimension row, so check 6's parity counts (12 and 6) are
#     untouched.
marker=$(awk '/^## Stage-transition marker$/{f=1;next} /^## /{f=0} f' references/on-track.md)
# Each counter binds to the code-fence gates line via its base-zero literal
# (revise 0/2 / rework 0/2 / attempt 0/3) — the prose deliberately uses letter
# placeholders (revise X/2) and non-zero examples (rework 2/2, attempt 2/3), so a
# zero-literal appears ONLY on the rendered gates line; deleting that line turns
# all three RED, not just revise. Still asserted separately, never grepping the
# "·" middot separator (a hand-wrap could split the line around it).
if printf '%s\n' "$marker" | grep -qF 'revise 0/2'; then
  note "marker block carries the revise counter (revise 0/2 on the gates line)"
else
  err "marker block missing the revise counter (revise 0/2)"
fi
if printf '%s\n' "$marker" | grep -qF 'rework 0/2'; then
  note "marker block carries the rework counter (rework 0/2 on the gates line)"
else
  err "marker block missing the rework counter (rework 0/2)"
fi
if printf '%s\n' "$marker" | grep -qF 'attempt 0/3'; then
  note "marker block carries the attempt counter (attempt 0/3 on the gates line)"
else
  err "marker block missing the attempt counter (attempt 0/3)"
fi
# degraded/budget bind to their fence forms ("degraded: <each" / "budget: <standing"),
# not the backticked prose mentions ("`degraded:`" / "`budget:`"), so deleting either
# fence row turns this RED — the same fence-binding the three counters now have.
if printf '%s\n' "$marker" | grep -qF 'degraded: <each'; then
  note "marker block carries the degraded row (degraded: <each on the fence)"
else
  err "marker block missing the degraded row (degraded: <each)"
fi
if printf '%s\n' "$marker" | grep -qF 'budget: <standing'; then
  note "marker block carries the budget row (budget: <standing on the fence)"
else
  err "marker block missing the budget row (budget: <standing)"
fi
for f in skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -q "stage-transition marker block" "$f"; then
    note "stage-transition marker block referenced from $f"
  else
    err "stage-transition marker block reference missing from $f"
  fi
done

# 27. Preview intake mode (issue #100). Git intake created the issue,
#     branch/worktree, and draft PR (steps 2-4) BEFORE Stage 2 drafted the plan
#     and its cost line, so a user unsure whether a task was worth the pipeline
#     had to commit to those artifacts sight-unseen; the triviality hatch is
#     binary and offered no "show me the plan and cost first, then let me decide".
#     A new "## Preview mode" section in references/pipeline.md defines an intake
#     mode that runs the read-only front of intake (capability preflight +
#     untrusted-input scan/tier + git fetch) and a Stage 2 draft plan + cost line,
#     then STOPS before git-intake step 2 (no issue, no branch, no PR), prints the
#     draft labeled "not yet oracle-reviewed" with a proceed handshake, and on the
#     user's yes reuses the draft into the normal run where it still goes through
#     the Stage 2.5 plan review -- no gate is skipped, and the handshake yes is not
#     a ratification (an unratified trust tier stays unratified, keeping #96
#     closed). Both skills document it. Written RED-first -- the phrases below are
#     absent until #100's prose lands, so this fails before it and passes after.
#     Preview is an intake mode, not a gate: it adds no plan-review rubric item and
#     no review dimension, so check 6's parity counts (12 and 6) are untouched. The
#     load-bearing phrases are grep -qF within the awk-extracted section body
#     (existence via -n, since the awk strips the heading line the way checks 25/26
#     do); each phrase sits on one line in the prose, so a hand-wrap across a line
#     break would turn its assertion RED.
preview=$(awk '/^## Preview mode$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
if [ -n "$preview" ]; then
  note "pipeline.md carries the '## Preview mode' section"
else
  err "pipeline.md missing the '## Preview mode' section"
fi
while IFS= read -r phrase; do
  [ -n "$phrase" ] || continue
  if printf '%s\n' "$preview" | grep -qF -- "$phrase"; then
    note "preview section carries: $phrase"
  else
    err "preview section missing the load-bearing phrase: $phrase"
  fi
done <<'PVPHRASES'
not yet oracle-reviewed
proceed handshake
no issue, no branch, no PR
no gate is skipped
not a ratification
still goes through the Stage 2.5 plan review
nothing to preview
creates no durable state
--preview
PVPHRASES
# The issue's own check (grep -rn "preview" skills/) plus the two summary tokens
# that guard against a references-only edit -- the skills are the executed
# prompt, so each must carry the mode and its no-skip and label guarantees, not
# merely point at the reference.
for f in skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -q "preview" "$f"; then
    note "preview mode referenced from $f (issue #100 check)"
  else
    err "preview mode not referenced from $f (issue #100 check)"
  fi
  if grep -qF "not yet oracle-reviewed" "$f"; then
    note "preview 'not yet oracle-reviewed' label carried in $f"
  else
    err "preview 'not yet oracle-reviewed' label missing from $f"
  fi
  if grep -qF "no gate is skipped" "$f"; then
    note "preview 'no gate is skipped' guarantee carried in $f"
  else
    err "preview 'no gate is skipped' guarantee missing from $f"
  fi
done

# 28. Bind the untrusted-input scan to the read-only route (issue #106). #96
#     drew the trust boundary at git intake; the read-only route never enters
#     that intake, so the scan bound nothing there -- on the route most likely
#     to read a stranger's issue, since answering a question from fetched text
#     is its whole job. It is also the route with the least backstop: no diff,
#     so review dimension 6 never sees the text. Binding it needed a decision
#     first, because plan-review item 2 revises every UNRATIFIED tier and admits
#     only the user's ratification, while a route that merges nothing has no
#     contract for a ratification to attach to. The resolution: the scan binds
#     on every route; the tier resolves against what the requester relayed and
#     stalls on nothing, with the QUESTION AS ASKED as the object that gets
#     ratified and as the stand-in for the acceptance criteria at all seven
#     sites that demand them (four precondition-refusal blocks plus three
#     brief-construction sentences whose substitute lists this route cannot
#     satisfy). Written RED-first -- every phrase below is absent at its
#     asserted scope until #106's prose lands.
#
#     Two assertions here are deliberately NOT absence checks, and are labelled
#     so no later reader mistakes them for RED-first phrases:
#       * the pastes-in-session pin and the relay COUNT are pins on text that
#         exists today. Their red leg is a mutation test -- widen the general
#         relay clause and watch them fail -- not an absence check. They exist
#         because carrying this rule by widening that shared clause would make a
#         stranger-authored issue ratified on the CODE-CHANGE route too (the
#         requester pointing at an issue is how nearly every run starts), which
#         is the exact attack the tier exists to catch. Containment must be
#         proven, not assumed.
#     Rides inside item 2 and the precondition; adds no rubric item and no
#     dimension, so check 6's parity counts (12 and 6) are untouched.

# Prints the block starting at the first line containing $2 (fixed string) and
# ending before the next line matching $3 (ERE). Used to bind a phrase to the
# region that must carry it, rather than to the file as a whole -- a whole-file
# grep would pass just as happily on a copy that put the phrase somewhere the
# rule does not govern.
extract_block() {
  awk -v a="$2" -v e="$3" '
    !f && index($0, a) { f = 1; print; next }
    f && $0 ~ e { exit }
    f { print }
  ' "$1"
}

ro_section=$(awk '/^## Which route binds which question$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
if [ -n "$ro_section" ]; then
  note "pipeline.md carries the '## Which route binds which question' section"
else
  err "pipeline.md missing the '## Which route binds which question' section"
fi
# Each phrase sits on one line in the prose, so a hand-wrap across a line break
# turns its assertion RED -- the same discipline check 27 applies.
while IFS= read -r phrase; do
  [ -n "$phrase" ] || continue
  if printf '%s\n' "$ro_section" | grep -qF -- "$phrase"; then
    note "read-only binding section carries: $phrase"
  else
    err "read-only binding section missing the load-bearing phrase: $phrase"
  fi
done <<'ROPHRASES'
binds on every route
the question as asked
on the read-only route
never a permission level
stay session-side
ROPHRASES
# The route's own section must reach the rule, or the binding is unreachable
# from the place that needs it.
if awk '/^## Read-only work/{f=1;next} /^## /{f=0} f' references/pipeline.md \
   | grep -qF "Which route binds which question"; then
  note "the read-only route section points at the binding rule"
else
  err "the read-only route section does not point at the binding rule"
fi
# The route-scoped grant needs an expiry at the one transition that crosses
# its scope: read-only -> git intake. Resume and Preview both restate that a
# ratification is a snapshot rather than a standing grant; this transition is
# the only one the new rule makes consequential, so it says so too. Asserted
# at the reference AND both skills, since the skills are what runs.
# Scoped to the block that must carry it, and matched on a contiguous phrase
# that runs PAST the rule's own verb — a two-substring whole-file grep let the
# reference's second copy be deleted outright (the other copy satisfied both
# substrings) and let an "unless …" exception be inserted mid-sentence. Both
# mutations shipped green before this shape.
if extract_block references/pipeline.md "## Read-only work" '^## ' \
   | grep -qF "ratification does not survive that re-entry. It was granted because the"; then
  note "the read-only route states the relay grant's expiry"
else
  err "the read-only route section does not state the relay grant's expiry"
fi
# Two phrases, because the line break falls between the framing clause and
# the operative one. Pinning only the first let the rule be REVERSED outright
# ("keeps it, and the tier stands") with the whole suite green: grep works a
# line at a time, so a phrase cannot reach across the wrap to its own verb.
binding=$(awk '/^## Which route binds which question$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
while IFS= read -r phrase; do
  [ -n "$phrase" ] || continue
  if printf '%s\n' "$binding" | grep -qF -- "$phrase"; then
    note "the binding section carries: $phrase"
  else
    err "the binding section is missing the route-not-run rule: $phrase"
  fi
done <<'ROUTENOTRUN'
The grant belongs to the route, not to the run: a read-only run that
re-enters the git intake loses it and re-resolves the tier there.
ROUTENOTRUN
# Terminators differ per skill. The run skill writes each rule as one line
# followed by a blank, so '^$' bounds it at one line. The consult skill's
# bullet list runs 71 lines without a blank, so '^$' there would swallow four
# later bullets and scope nothing — its own bullet marker is the boundary.
while IFS='|' read -r f anchor endre phrase; do
  [ -n "$f" ] || continue
  if extract_block "$f" "$anchor" "$endre" | grep -qF "$phrase"; then
    note "the relay grant's re-entry expiry is carried at its rule site in $f"
  else
    err "no re-entry expiry for the relay grant at its rule site in $f"
  fi
done <<'EXPIRY'
skills/run/SKILL.md|**Non-trivial read-only work**|^$|does not survive that re-entry — a run that now merges re-resolves the tier under the general rule.
skills/consult/SKILL.md|- **Read-only route**|^- \*\*|does not survive re-entry into the git intake — a run that now merges
EXPIRY
if grep -qF "creates no git artifacts at intake" references/pipeline.md; then
  note "pipeline.md scopes the no-git-artifacts claim to intake"
else
  err "pipeline.md still claims the read-only route creates no git artifacts at all"
fi

# PIN, not a RED-first phrase (see the header note). The general relay clause
# must read exactly as it does today, and `ratified by relay` must occur exactly
# twice in pipeline.md: once in the general tier list, once in the read-only
# section. A third occurrence means someone re-generalised the trigger and must
# re-account for it here.
# WHOLE LINE, not a substring. A substring pin is defeated by the most
# natural widening of all -- inserting an alternative into the sentence
# ("A body the user pastes in-session, or an artifact they point the run at,
# is ratified by relay"), which leaves every pinned substring intact and the
# occurrence counts unmoved. Mutation-tested: the substring form shipped that
# widening green.
pastes=$(grep -cFx -- '- A body the user pastes in-session is **ratified by relay**: relaying it' references/pipeline.md || true)
if [ "${pastes:-0}" -eq 1 ]; then
  note "the general relay clause is intact, whole-line (unwidened)"
else
  err "the general relay clause has been reworded or widened — its first line no longer matches verbatim"
fi
# Belt to that brace: the pointing gesture is what must never grant relay
# outside the read-only section, so it may not appear in the general tier
# section at all. Bounded to '## Untrusted input at intake', which ends where
# '## Which route binds which question' begins.
if awk '/^## Untrusted input at intake$/{f=1;next} /^## /{f=0} f' references/pipeline.md \
   | grep -qE 'point(s|ed|ing)? the run at'; then
  err "the general tier section grants relay for a pointed-at artifact — that belongs only to the read-only route"
else
  note "the general tier section never grants relay for a pointed-at artifact"
fi
# The count is pinned per FILE, not only in the reference. A pin on
# pipeline.md alone leaves the executed prompt unguarded: a widening sentence
# added to either skill would ship green, and skills-copy divergence is this
# repo's live failure mode. Any new occurrence anywhere must be re-accounted
# for here.
#
# OCCURRENCES, not lines: `grep -c` counts matching lines, and the skills wrap
# a whole rule onto one long line, so a second grant appended to a line that
# already carries one would not move a line count. Mutation-tested in both
# directions before this shape was settled on.
while IFS='|' read -r f want; do
  [ -n "$f" ] || continue
  got=$(grep -oF "ratified by relay" "$f" | wc -l | tr -d " ")
  if [ "${got:-0}" -eq "$want" ]; then
    note "relay mentions accounted for in $f ($want)"
  else
    err "relay containment drift in $f: 'ratified by relay'=${got:-0} (want $want)"
  fi
done <<'RELAYCOUNTS'
references/pipeline.md|2
references/verification.md|1
skills/run/SKILL.md|2
skills/consult/SKILL.md|2
agents/argus-oracle.md|0
RELAYCOUNTS
# Defense in depth behind the counts: every paragraph that grants the relay
# trigger must also carry the route that scopes it. The one exception is the
# general clause, which grants it for a pasted body on every route.
for f in references/pipeline.md references/verification.md skills/run/SKILL.md skills/consult/SKILL.md; do
  unscoped=$(awk 'BEGIN{RS="";FS="\n"} /ratified by relay/ && !/read-only/ && !/pastes in-session/ {n++} END{print n+0}' "$f")
  if [ "${unscoped:-0}" -eq 0 ]; then
    note "every relay grant is route-scoped in $f"
  else
    err "$unscoped relay grant(s) in $f are not scoped to the read-only route"
  fi
done
# The actor of the relay trigger is the REQUESTER, never the lead. The run
# skill addresses the lead as "you", so "what you relayed" there would let the
# lead's own fetch satisfy the trigger and defeat the minimum-over rule for
# contributors the requester never relayed.
if grep -rqn "you relayed\|you pointed the run at" references/ skills/ agents/; then
  err "the relay trigger names the lead as its actor somewhere — it is the requester"
else
  note "the relay trigger names the requester as its actor everywhere"
fi

# The criteria substitution at all seven sites. The four precondition-refusal
# blocks are what produce a verdict; the three brief-construction sentences are
# what the lead executes FIRST, and they enumerate a closed substitute list
# (PLAN.md or the PR description) that this route has neither of -- so a
# precondition-only carve-out would leave a file contradicting a file three
# lines away.
if extract_block references/verification.md "## Precondition refusal" '^## ' \
   | grep -qF "the question as asked"; then
  note "verification.md's precondition refusal carries the read-only substitution"
else
  err "verification.md's precondition refusal missing the read-only substitution"
fi
if extract_block agents/argus-oracle.md "### Precondition refusal" '^### ' \
   | grep -qF "the question as asked"; then
  note "argus-oracle.md's precondition refusal carries the read-only substitution"
else
  err "argus-oracle.md's precondition refusal missing the read-only substitution"
fi
if extract_block agents/argus-oracle.md "### Input contract" '^### ' \
   | grep -qF "the question as asked"; then
  note "argus-oracle.md's input contract carries the read-only substitution"
else
  err "argus-oracle.md's input contract missing the read-only substitution"
fi
for f in skills/run/SKILL.md skills/consult/SKILL.md; do
  # Bounded by the blank line, not the next heading: in the consult skill the
  # brief sits inside the same section, so a heading bound would let the
  # brief's phrase satisfy the precondition's assertion and vice versa.
  if extract_block "$f" "**Precondition refusal:**" '^$' \
     | grep -qF "the question as asked"; then
    note "precondition refusal carries the read-only substitution in $f"
  else
    err "precondition refusal missing the read-only substitution in $f"
  fi
  if extract_block "$f" 'Spawn `argus-oracle`' '^$' \
     | grep -qF "the question as asked"; then
    note "the plan-review brief carries the read-only substitution in $f"
  else
    err "the plan-review brief missing the read-only substitution in $f"
  fi
done

# Item 2's own region, in the three copies that bind the diff to an ISSUE's
# criteria. agents/argus-oracle.md:47 already reads "the attached acceptance
# criteria" -- route-neutral, deliberately left alone, and deliberately not
# asserted here. Scoped extraction matters: `read-only` is already present
# elsewhere in all three files, so a whole-file grep would be green today.
# The payload, not the token. Asserting only "read-only" inside the region
# passes on a copy stating the OPPOSITE rule ("on the read-only route this
# item does not apply at all") -- mutation-tested green before this was
# tightened. The phrase below is the rule itself, contiguous on one line in
# all three copies.
while IFS='|' read -r f anchor; do
  [ -n "$f" ] || continue
  if extract_block "$f" "$anchor" '^[0-9]+\. ' \
     | grep -qF "read-only route the diff target is the question as asked"; then
    note "plan-review item 2 carries the read-only scoping in $f"
  else
    err "plan-review item 2 missing the read-only scoping in $f"
  fi
done <<'ITEM2'
references/verification.md|2. **Goal-backward stage check.**
skills/run/SKILL.md|2. Do these stages actually reach the stated goal?
skills/consult/SKILL.md|2. **Goal-backward stage check**
ITEM2

# The report disposition and the header composition are the two halves the
# issue asked for by name ("a rule for which header lines a read-only plan
# carries"), and both are prose the section-body phrase list above could
# otherwise be satisfied without -- the skills are the executed prompt, so each
# must carry them rather than merely point at the reference.
# Scoped, not whole-file — the discipline this check states for itself
# above. A whole-file grep passed after the disposition sentence was deleted
# from its rule site and the phrase restated somewhere unrelated in the same
# file; mutation-tested.
# Anchors differ per skill: the run skill writes each rule as one long line,
# the consult skill wraps its bullets, so each names its own governing block.
while IFS='|' read -r f header_anchor route_anchor; do
  [ -n "$f" ] || continue
  if extract_block "$f" "$header_anchor" '^$' | grep -qF "never a permission level"; then
    note "report disposition (never a permission level) carried at its rule site in $f"
  else
    err "report disposition (never a permission level) missing from its rule site in $f"
  fi
  if extract_block "$f" "$route_anchor" '^$' | grep -qF "Which route binds which question"; then
    note "read-only binding referenced from the route's own bullet in $f"
  else
    err "read-only binding not referenced from the route's own bullet in $f"
  fi
done <<'SKILLSITES'
skills/run/SKILL.md|**Untrusted-input scan and trust tier:**|**Non-trivial read-only work**
skills/consult/SKILL.md|intake-trust lines|- **Read-only route**
SKILLSITES

# 29. Two copies that drifted, and the guards that let them (release v0.10.0's
#     skill review). Both defects were introduced by the very epic this release
#     ships, and both are the same class: a rule mirrored across skills where
#     one copy moved and the other did not.
#
#     (a) #97 made the Stage-4 secret-scan output mandatory and added it to the
#     Stage-5 brief on both normal paths -- but the model gate's third door
#     ("proceed anyway") routes the final review to argus-oracle with its OWN
#     closed-list brief, and that list never gained it. agents/argus-oracle.md
#     refuses a review whose secret-scan output is not attached, so a lead
#     following the override brief literally assembles one that draws an
#     instant refusal. Check 24 could not see it: it greps the whole file for
#     "secret-scan", which matches elsewhere. The guard below is therefore
#     SCOPED to the override block -- a whole-file grep is exactly what failed.
#
#     (b) #99's second rework bound `attempt Z/3` to the INCOMING check rather
#     than the completed one, and shipped that binding to on-track.md and the
#     run skill. The consult skill kept the pre-fix render. It is a rendered
#     fence line, which this repo treats as the thing a model copies verbatim,
#     and it lands on the path that leans hardest on literal examples. The
#     guard pins the RENDERED line in all three places, not the prose near it.
if extract_block skills/run/SKILL.md "3. User explicitly replies" '^$' \
   | grep -qF "secret-scan"; then
  note "the override path's evidence brief requires the secret-scan output"
else
  err "the override path's evidence brief omits the secret-scan output (run skill, model gate door 3)"
fi
# Scoped to the block that renders it, per file. A whole-file grep here is
# satisfied by any planted occurrence — an HTML comment, an unrelated example —
# while the rendered line itself has drifted. Mutation-confirmed: with the real
# line changed and a decoy appended at end of file, the unscoped form stayed
# green in all three files.
while IFS='|' read -r f anchor endre; do
  [ -n "$f" ] || continue
  if extract_block "$f" "$anchor" "$endre" | grep -qF "attempt 0/3 (active: <next-cmd>)"; then
    note "the gate-counter line binds attempt to the active check in $f"
  else
    err "the gate-counter line drops the active-check binding in $f"
  fi
done <<'FENCE'
references/on-track.md|Stage N done — failable check|^```
skills/run/SKILL.md|Stage N done — failable check|^```
skills/consult/SKILL.md|Print the **stage-transition marker block**|^$
FENCE
# The DISCRIMINATING clause, scoped to the block that states it — not the
# noun "active check", which survives reversing the rule outright ("the check
# line 1 just reported complete, not the incoming stage's") and which the run
# skill carries only incidentally, so a whole-file grep reported a binding
# there that the file never states. Mutation-tested both ways.
# The run skill is deliberately absent: its fence line renders the binding
# (asserted above) and it defers the per-row rules to on-track.md rather than
# restating them, so asserting the prose there would demand text the design
# does not want.
# Per-file phrases, because each file wraps its prose differently and a
# phrase cannot span a line break: on-track.md breaks "the incoming /
# stage's check" across lines 126-127. Each phrase below is the clause that
# distinguishes incoming from completed, verified contiguous in its own file.
if awk '/^## Stage-transition marker$/{f=1;next} /^## /{f=0} f' references/on-track.md \
   | grep -qF "not the completed one on line 1"; then
  note "on-track.md binds the retry count to the incoming, not the completed, check"
else
  err "on-track.md no longer distinguishes the incoming check from the completed one"
fi
if extract_block skills/consult/SKILL.md "Print the **stage-transition marker block**" '^$' \
   | grep -qF "the incoming stage's check"; then
  note "the consult marker block binds the retry count to the incoming stage's check"
else
  err "the consult marker block does not bind the retry count to the incoming stage's check"
fi

# 30. Unconditional worktree isolation at git intake (issue #122). Step 3 took
#     a worktree only when the in-flight probe fired; a clean solo checkout
#     branched in place via gh issue develop. Two sessions entering intake at
#     the same moment on a clean repo each saw no in-flight signal and both
#     took the primary checkout — the one collision conditional isolation left
#     open, and the owner runs several sessions against one project routinely.
#     Every full-pipeline run now takes its own worktree branched off
#     origin/<default>, unconditionally; the in-flight probe survives as
#     inventory (feeding the intake announcement and Resume, never a checkout
#     choice); no remote branches the worktree off the local default tip; the
#     hatch, read-only route, and preview are unchanged (no branch, no
#     worktree). Written RED-first: every phrase below is absent until #122's
#     prose lands, each pinned on one rendered line so a hand-wrap turns its
#     assertion RED. Scoped to their sections the way checks 27/29 scope
#     theirs — a whole-file grep is satisfied by decoys.
intake30=$(awk '/^## Stage 1 — Git intake$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
if [ -n "$intake30" ]; then
  note "pipeline.md carries the git-intake section (check 30)"
else
  err "pipeline.md missing the git-intake section (check 30)"
fi
if printf '%s\n' "$intake30" | grep -qF "its own worktree, unconditionally"; then
  note "git intake takes a worktree unconditionally"
else
  err "git intake does not take a worktree unconditionally"
fi
if printf '%s\n' "$intake30" | grep -qF "gh issue develop"; then
  err "git intake still offers the branch-in-place arm (gh issue develop)"
else
  note "the branch-in-place arm is gone from git intake"
fi
if printf '%s\n' "$intake30" | grep -qF "never which checkout"; then
  note "the in-flight probe is narrowed to inventory, never checkout selection"
else
  err "git intake does not narrow the probe to inventory (never which checkout)"
fi
announce30=$(awk '/^## Announce in-flight work at intake$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
if printf '%s\n' "$announce30" | grep -qF "every run takes its own worktree"; then
  note "the announce section reflects unconditional worktrees"
else
  err "the announce section still frames the probe as a checkout decision"
fi
degr30=$(awk '/^## Degradation rules$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
if printf '%s\n' "$degr30" | grep -qF "worktree off the local default tip"; then
  note "the no-remote degradation names the local-default-tip worktree"
else
  err "the no-remote degradation does not name the local-default-tip worktree"
fi
resume30=$(awk '/^## Resume — the receiving side$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
if printf '%s\n' "$resume30" | grep -qF 'never runs `git switch` inside the primary checkout'; then
  note "Resume adoption never switches the primary checkout"
else
  err "Resume adoption does not forbid switching the primary checkout"
fi
preview30=$(awk '/^## Preview mode$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
if printf '%s\n' "$preview30" | grep -qF "local-default fast-forward"; then
  err "preview still references the retired step-1 local-default fast-forward"
else
  note "preview no longer references a step-1 fast-forward"
fi
for f30 in skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -qF "always in its own isolated worktree" "$f30"; then
    note "unconditional worktree rule carried in $f30"
  else
    err "unconditional worktree rule missing from $f30"
  fi
done
# Panel additions (#122 review): the reviewer and the lead both start in the
# session's original cwd — the primary checkout, which under this doctrine
# never holds the change — so the Stage-5 brief must anchor the reviewer to
# the run's worktree and the lead must be told to work inside it from the
# worktree's creation on; the no-remote terminal merge is the one sanctioned
# move of the primary checkout, and cleanup carries the parked-primary
# post-merge switch-back. The primary-checkout-invariant and isolation-model
# pins predate their assertions (regression pins, the check-29 idiom); the
# rest were written RED-first.
if grep -qF "the run's working tree by absolute path" skills/run/SKILL.md; then
  note "the review brief contract anchors the reviewer to the run's working tree"
else
  err "the review brief contract does not carry the run's working tree by absolute path"
fi
for f30 in skills/run/SKILL.md agents/argus-reviewer.md; do
  if grep -qF "names no working-tree path" "$f30"; then
    note "the missing-working-tree refusal class carried in $f30"
  else
    err "the missing-working-tree refusal class missing from $f30"
  fi
done
if grep -qF "inside the brief's worktree" agents/argus-reviewer.md; then
  note "the reviewer binds its commands to the brief's worktree"
else
  err "the reviewer does not bind its commands to the brief's worktree"
fi
if printf '%s\n' "$degr30" | grep -qF "run inside the primary checkout"; then
  note "the no-remote terminal merge names its execution location"
else
  err "the no-remote terminal merge does not name its execution location"
fi
if awk '/^## Terminal-outcome cleanup$/{f=1;next} /^## /{f=0} f' references/pipeline.md \
   | grep -qF "defers the local-branch deletion"; then
  note "cleanup defers branch deletion on a parked-primary merge, keeping no-switch absolute"
else
  err "cleanup missing the parked-primary branch-deletion deferral"
fi
if printf '%s\n' "$intake30" | grep -qF "the bootstrap commit included"; then
  note "git intake binds the lead's commands to the run's worktree"
else
  err "git intake does not bind the lead's commands to the run's worktree"
fi
if printf '%s\n' "$intake30" | grep -qF "nothing in the primary checkout moves"; then
  note "git intake pins the primary-checkout invariant"
else
  err "git intake dropped the primary-checkout invariant"
fi
if awk '/^## Isolation model$/{f=1;next} /^## /{f=0} f' references/delegation.md \
   | grep -qF "every brief carries absolute paths into the run's worktree"; then
  note "the isolation model anchors briefs to the run's worktree"
else
  err "the isolation model no longer anchors briefs to the run's worktree"
fi
if printf '%s\n' "$preview30" | grep -qF "worktree branch → draft PR"; then
  note "the preview on-yes path reflects unconditional worktrees"
else
  err "the preview on-yes path still carries the retired branch/worktree pairing"
fi

# 31. Architecture-shaping trigger + candidates comparison (issue #119). The
#     plan's first architecture artifact was the single already-chosen design
#     in the third column; item 1 probes only the reductive direction and
#     item 5 / dimension 3 re-check that same anchor, so on new-subsystem work
#     the lead's first plausible design shipped unchallenged. Stage 2 now
#     applies a mechanical trigger — any stage creating a new module or
#     subsystem, a new public API surface, or a new architectural boundary —
#     and a triggered plan carries an Architecture candidates block (at least
#     two candidates with trade-offs, plus the chosen rationale) before the
#     plan review, which revises a triggered plan without it, checked against
#     the trigger definition rather than discretion. Non-triggered plans owe
#     nothing (no absence line — the gate re-applies the same trigger to the
#     same text), so the hatch, small fixes, and the read-only route pay zero.
#     Decision record for the design itself: three homes were compared
#     (conduct section in pipeline.md / doctrine home in quality.md / gate
#     home in verification.md); the conduct home won on zero ceremony and on
#     matching the scout/overlap/decomposition slot, stealing the
#     identical-arm-lines drift guard from the gate home (the plan-review
#     brief reaches only verification.md, so the arms are restated there and
#     in the advisor's checklist, line-for-line identical, each pinned below)
#     and the one-sentence principle-2 mirror from the doctrine home.
#     Written RED-first: one FAIL line per absent pin.
arch31=$(awk '/^## Architecture-shaping trigger$/{f=1;next} /^## /{f=0} f' references/pipeline.md)
rubric31=$(awk '/^## The oracle.s plan-review rubric$/{f=1;next} /^## /{f=0} f' references/verification.md)
if [ -n "$arch31" ]; then
  note "pipeline.md carries the '## Architecture-shaping trigger' section"
else
  err "pipeline.md missing the '## Architecture-shaping trigger' section"
fi
while IFS= read -r arm; do
  [ -n "$arm" ] || continue
  if printf '%s\n' "$arch31" | grep -qF -- "$arm"; then
    note "trigger arm in pipeline.md: $arm"
  else
    err "trigger arm missing from pipeline.md section: $arm"
  fi
  if printf '%s\n' "$rubric31" | grep -qF -- "$arm"; then
    note "trigger arm in the plan-review rubric: $arm"
  else
    err "trigger arm missing from the plan-review rubric: $arm"
  fi
  if grep -qF -- "$arm" agents/argus-oracle.md; then
    note "trigger arm in the advisor checklist: $arm"
  else
    err "trigger arm missing from the advisor checklist: $arm"
  fi
done <<'ARMS31'
a new module or subsystem the tree does not already contain
a new public API surface that code outside the diff will call
a new architectural boundary between or around existing modules
ARMS31
for sect31 in arch rubric; do
  body31="$arch31"; [ "$sect31" = "rubric" ] && body31="$rubric31"
  if printf '%s\n' "$body31" | grep -qF "when in doubt, the trigger fires"; then
    note "the $sect31 copy fails toward firing on doubt"
  else
    err "the $sect31 copy does not fail toward firing on doubt"
  fi
done
if printf '%s\n' "$arch31" | grep -qF "Chosen: <n> —"; then
  note "the candidates block shape carries the chosen-rationale line"
else
  err "the candidates block shape missing the chosen-rationale line"
fi
if printf '%s\n' "$arch31" | grep -qF "trade-offs:"; then
  note "the candidates block shape carries per-candidate trade-offs"
else
  err "the candidates block shape missing per-candidate trade-offs"
fi
if printf '%s\n' "$rubric31" | grep -qF "not reviewer discretion"; then
  note "the triggered-plan revise keys off the definition, not discretion"
else
  err "the triggered-plan revise does not exclude reviewer discretion"
fi
if printf '%s\n' "$rubric31" | grep -qF "at least two candidate architectures"; then
  note "the rubric demands at least two candidate architectures"
else
  err "the rubric does not demand at least two candidate architectures"
fi
if printf '%s\n' "$rubric31" | grep -qF "non-triggered plan owes no comparison"; then
  note "the rubric states the zero-ceremony rule for non-triggered plans"
else
  err "the rubric missing the zero-ceremony rule for non-triggered plans"
fi
if printf '%s\n' "$rubric31" | grep -qF "does not substitute for item 1"; then
  note "the candidates block is distinct from the simpler-alternative pass"
else
  err "the rubric does not keep the candidates block distinct from item 1"
fi
for f31 in skills/run/SKILL.md skills/consult/SKILL.md; do
  if grep -qF "architecture-shaping" "$f31"; then
    note "architecture-shaping trigger carried in $f31"
  else
    err "architecture-shaping trigger missing from $f31"
  fi
  if grep -qF "at least two candidate architectures" "$f31"; then
    note "two-candidate floor carried in $f31"
  else
    err "two-candidate floor missing from $f31"
  fi
  if grep -qF "Architecture-shaping trigger" "$f31"; then
    note "the trigger section named by name in $f31"
  else
    err "the trigger section not named by name in $f31"
  fi
done
if grep -rqF "Architecture trigger: none" references/ skills/; then
  err "an absence-line ceremony crept in (Architecture trigger: none)"
else
  note "no absence-line ceremony anywhere (zero cost for non-triggered plans)"
fi
if grep -qF "from a compared field" references/quality.md; then
  note "quality.md principle 2 mirrors the compared-field bar"
else
  err "quality.md principle 2 missing the compared-field mirror"
fi

echo
if [ "$fail" -eq 0 ]; then echo "all checks passed"; else echo "checks failed"; exit 1; fi
