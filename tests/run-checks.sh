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

echo
if [ "$fail" -eq 0 ]; then echo "all checks passed"; else echo "checks failed"; exit 1; fi
