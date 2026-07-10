#!/usr/bin/env bash
# Changelog-placement gate for shipped-file changes.
#
# Reproduces the existing CI changelog-gate logic — a PR touching
# skills/, agents/, references/, or .claude-plugin/ must also touch
# CHANGELOG.md — then extends it: a change isn't done just by touching
# the file, it has to land in the right place. The roll-up step at
# release time turns "## [Unreleased]" into a version heading, so
# Unreleased is the only valid landing spot for an in-flight change;
# appending to an already-released heading silently detaches the entry
# from the next release's notes.
#
# Usage: bash tests/changelog-gate.sh [base-ref]
#   base-ref defaults to origin/main. Compares base-ref...HEAD (the
#   same three-dot range the CI job uses) against the current worktree,
#   which is assumed to be checked out at HEAD.
#
# Deliberately strict on bundling: a shipped-file PR whose CHANGELOG
# edits touch released sections or the preamble fails, even when a
# valid Unreleased entry is also present — released notes don't change
# as a side effect of shipping new work; split those edits out.
set -uo pipefail

base_ref="${1:-origin/main}"
changelog_file="CHANGELOG.md"

if ! git rev-parse --verify -q "$base_ref" >/dev/null; then
  printf '::error::changelog-gate: base ref "%s" does not resolve\n' "$base_ref"
  exit 1
fi

changed=$(git diff --name-only "$base_ref"...HEAD)

if ! printf '%s\n' "$changed" | grep -qE '^(skills/|agents/|references/|\.claude-plugin/)'; then
  echo "no shipped files changed against $base_ref — changelog-placement gate does not apply"
  exit 0
fi

if ! printf '%s\n' "$changed" | grep -qx "$changelog_file"; then
  printf '::error::changelog-gate: shipped files changed without a %s change against %s\n' "$changelog_file" "$base_ref"
  exit 1
fi

[ -f "$changelog_file" ] || { printf '::error::changelog-gate: %s not found at HEAD\n' "$changelog_file"; exit 1; }

# (a) HEAD's first top-level "## [" heading must be Unreleased. A change
# that lands under any other heading was appended to an already-released
# section instead of staged for the next one.
first_heading_line=$(grep -n '^## \[' "$changelog_file" | head -1)
unreleased_start=${first_heading_line%%:*}
first_heading=${first_heading_line#*:}
if [ "$first_heading" != "## [Unreleased]" ]; then
  printf '::error::changelog-gate: %s first "## [" heading is "%s", not "## [Unreleased]"\n' \
    "$changelog_file" "${first_heading:-<none found>}"
  exit 1
fi

# (b) Every added line in the CHANGELOG.md diff must fall inside the
# Unreleased section span: the heading line through the line before the
# next top-level "## [" heading, or end of file if Unreleased is last.
# Link-reference lines at the bottom ("[Unreleased]: https://...") are
# exempt — they're rewritten on every release regardless of where the
# content change landed, not evidence of misplaced content.
total_lines=$(wc -l < "$changelog_file")
unreleased_end=$(awk -v s="$unreleased_start" 'NR > s && /^## \[/ { print NR - 1; exit }' "$changelog_file")
[ -n "$unreleased_end" ] || unreleased_end="$total_lines"

violations=$(git diff -U0 "$base_ref"...HEAD -- "$changelog_file" | awk -v start="$unreleased_start" -v end="$unreleased_end" '
  /^@@ / {
    match($0, /\+[0-9]+(,[0-9]+)?/)
    spec = substr($0, RSTART + 1, RLENGTH - 1)
    split(spec, parts, ",")
    newline = parts[1] + 0
    next
  }
  /^\+\+\+/ { next }
  /^---/   { next }
  /^\+/ {
    content = substr($0, 2)
    if (content !~ /^\[[^]]+\]: /) {
      if (newline < start || newline > end) print newline ": " content
    }
    newline++
    next
  }
  /^-/ { next }
')

if [ -n "$violations" ]; then
  printf '::error::changelog-gate: added CHANGELOG.md lines fall outside the Unreleased section (lines %s-%s):\n%s\n' \
    "$unreleased_start" "$unreleased_end" "$violations"
  exit 1
fi

# A deletion-only or link-only CHANGELOG touch records nothing — at
# least one real content line must be added inside the Unreleased span
# before the success message may claim an entry exists.
added_in_span=$(git diff -U0 "$base_ref"...HEAD -- "$changelog_file" | awk -v start="$unreleased_start" -v end="$unreleased_end" '
  /^@@ / {
    match($0, /\+[0-9]+(,[0-9]+)?/)
    spec = substr($0, RSTART + 1, RLENGTH - 1)
    split(spec, parts, ",")
    newline = parts[1] + 0
    next
  }
  /^\+\+\+/ { next }
  /^---/   { next }
  /^\+/ {
    content = substr($0, 2)
    if (content !~ /^\[[^]]+\]: / && content ~ /[^[:space:]]/ && newline >= start && newline <= end) count++
    newline++
    next
  }
  /^-/ { next }
  END { print count + 0 }
')

if [ "${added_in_span:-0}" -eq 0 ]; then
  printf '::error::changelog-gate: shipped files changed but no entry line was added inside the Unreleased section — a deletion-only or link-only %s change records nothing\n' "$changelog_file"
  exit 1
fi

echo "changelog-placement gate satisfied: shipped-file change carries an Unreleased-section CHANGELOG.md entry"
exit 0
