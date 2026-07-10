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
    bhits=$(grep -icE "$branch" tests/fixtures/dirty.md || true)
    if [ "${bhits:-0}" -ge 1 ]; then
      note "lexicon branch '$branch' flags the dirty fixture ($bhits hits)"
    else
      err "lexicon branch '$branch' has zero hits on the dirty fixture"
    fi
  done <<< "$branches"
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

echo
if [ "$fail" -eq 0 ]; then echo "all checks passed"; else echo "checks failed"; exit 1; fi
