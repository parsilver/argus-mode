#!/usr/bin/env bash
# Scenario tests for tests/changelog-gate.sh release mode (issue #63).
#
# Each scenario scaffolds a throwaway git repo — a base commit and a HEAD
# commit standing in for a release roll-up — and asserts the gate's exit
# code. The roll-up must move every "## [Unreleased]" entry into the new
# version's section verbatim: a dropped or altered entry must fail, a
# lossless roll-up must pass. The scratch CHANGELOGs mirror the real
# Keep-a-Changelog shape (### Added / ### Fixed subsections and a bullet
# whose description wraps onto a second physical line) so the check is
# exercised against the structure it runs against in production.
#
# Run from anywhere: bash tests/changelog-gate.test.sh
set -u

repo_root=$(cd "$(dirname "$0")/.." && pwd)
gate="$repo_root/tests/changelog-gate.sh"
fail=0

# Release mode is jq-guarded (changelog-gate.sh); without jq the scenarios
# would exercise nothing, so skip rather than false-pass. CI carries jq.
if ! command -v jq >/dev/null 2>&1; then
  echo "skip: jq not available — changelog-gate release mode is jq-guarded, cannot exercise scenarios"
  exit 0
fi

# Throwaway commits need an identity and no signing: GitHub's runners set
# neither, so a bare `git commit` there fails "Author identity unknown".
git_c() { git -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false "$@"; }

# run_scenario NAME EXPECTED_EXIT BASE_VERSION HEAD_VERSION BASE_CHANGELOG HEAD_CHANGELOG
run_scenario() {
  local name="$1" expected="$2" base_ver="$3" head_ver="$4" base_cl="$5" head_cl="$6"
  local dir actual base_sha
  dir=$(mktemp -d)
  (
    cd "$dir" || exit 99
    git -c init.defaultBranch=main init -q . || exit 98
    mkdir -p .claude-plugin references
    printf '{"name":"x","version":"%s","description":"d"}\n' "$base_ver" > .claude-plugin/plugin.json
    printf '%s\n' "$base_cl" > CHANGELOG.md
    echo seed > references/seed.md
    git add -A && git_c commit -qm base || exit 97
    base_sha=$(git rev-parse HEAD)
    printf '{"name":"x","version":"%s","description":"d"}\n' "$head_ver" > .claude-plugin/plugin.json
    printf '%s\n' "$head_cl" > CHANGELOG.md
    echo changed >> references/seed.md   # a shipped-file touch so the gate applies
    git add -A && git_c commit -qm head || exit 96
    bash "$gate" "$base_sha" >/dev/null 2>&1
    exit $?
  )
  actual=$?
  rm -rf "$dir"
  if [ "$actual" -eq "$expected" ]; then
    printf 'ok:   %s (exit %s)\n' "$name" "$actual"
  else
    printf 'FAIL: %s — expected exit %s, got %s\n' "$name" "$expected" "$actual"
    fail=1
  fi
}

# Base CHANGELOG with entries staged under Unreleased (s1, s2, s3, s5).
base_cl=$(cat <<'CL'
# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Added

- Alpha feature that does a thing (#1)
- Beta feature with a longer description that wraps
  onto a second physical line for realism (#2)

### Fixed

- Gamma bugfix (#3)

## [0.1.0] - 2026-01-01

### Added

- Initial release (#0)

[Unreleased]: https://example.com/compare/v0.1.0...HEAD
[0.1.0]: https://example.com/releases/tag/v0.1.0
CL
)

# Lossless roll-up: every subsection heading and the wrapped bullet move
# verbatim into ## [0.2.0]. Must pass.
head_lossless=$(cat <<'CL'
# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [0.2.0] - 2026-07-15

### Added

- Alpha feature that does a thing (#1)
- Beta feature with a longer description that wraps
  onto a second physical line for realism (#2)

### Fixed

- Gamma bugfix (#3)

## [0.1.0] - 2026-01-01

### Added

- Initial release (#0)

[Unreleased]: https://example.com/compare/v0.2.0...HEAD
[0.2.0]: https://example.com/releases/tag/v0.2.0
[0.1.0]: https://example.com/releases/tag/v0.1.0
CL
)

# Dropped entry: the Beta bullet (both physical lines) never arrives in
# ## [0.2.0]. Must fail.
head_dropped=$(cat <<'CL'
# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [0.2.0] - 2026-07-15

### Added

- Alpha feature that does a thing (#1)

### Fixed

- Gamma bugfix (#3)

## [0.1.0] - 2026-01-01

### Added

- Initial release (#0)

[Unreleased]: https://example.com/compare/v0.2.0...HEAD
[0.2.0]: https://example.com/releases/tag/v0.2.0
[0.1.0]: https://example.com/releases/tag/v0.1.0
CL
)

# Altered entry: the Gamma bullet is reworded during roll-up, so the
# original line is missing downstream. Must fail.
head_altered=$(cat <<'CL'
# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [0.2.0] - 2026-07-15

### Added

- Alpha feature that does a thing (#1)
- Beta feature with a longer description that wraps
  onto a second physical line for realism (#2)

### Fixed

- Gamma bugfix, reworded during roll-up (#3)

## [0.1.0] - 2026-01-01

### Added

- Initial release (#0)

[Unreleased]: https://example.com/compare/v0.2.0...HEAD
[0.2.0]: https://example.com/releases/tag/v0.2.0
[0.1.0]: https://example.com/releases/tag/v0.1.0
CL
)

# Stranded line: a content line is left under Unreleased at HEAD. The
# existing empty-Unreleased assertion must still catch it (proving the new
# block removes no coverage).
head_stranded=$(cat <<'CL'
# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

- A line left stranded under Unreleased

## [0.2.0] - 2026-07-15

### Added

- Alpha feature that does a thing (#1)
- Beta feature with a longer description that wraps
  onto a second physical line for realism (#2)

### Fixed

- Gamma bugfix (#3)

## [0.1.0] - 2026-01-01

### Added

- Initial release (#0)

[Unreleased]: https://example.com/compare/v0.2.0...HEAD
[0.2.0]: https://example.com/releases/tag/v0.2.0
[0.1.0]: https://example.com/releases/tag/v0.1.0
CL
)

# Fresh-notes control: base Unreleased is empty, HEAD writes notes straight
# into ## [0.2.0]. Nothing left Unreleased, so nothing can be dropped — the
# arriving-only lines must not false-fail the leaving-subset-of-arriving check.
base_empty=$(cat <<'CL'
# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [0.1.0] - 2026-01-01

### Added

- Initial release (#0)

[Unreleased]: https://example.com/compare/v0.1.0...HEAD
[0.1.0]: https://example.com/releases/tag/v0.1.0
CL
)

head_fresh=$(cat <<'CL'
# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [0.2.0] - 2026-07-15

### Added

- Fresh note authored at release time (#9)

## [0.1.0] - 2026-01-01

### Added

- Initial release (#0)

[Unreleased]: https://example.com/compare/v0.2.0...HEAD
[0.2.0]: https://example.com/releases/tag/v0.2.0
[0.1.0]: https://example.com/releases/tag/v0.1.0
CL
)

# Duplicate-sibling drop: the base holds two byte-identical bullets and the
# roll-up keeps only one. A set (sort -u) collapses both to a single line and
# misses the loss; the multiset comparison must still catch the dropped copy.
base_dup=$(cat <<'CL'
# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Added

- Alpha feature that does a thing (#1)
- Alpha feature that does a thing (#1)

### Fixed

- Gamma bugfix (#3)

## [0.1.0] - 2026-01-01

### Added

- Initial release (#0)

[Unreleased]: https://example.com/compare/v0.1.0...HEAD
[0.1.0]: https://example.com/releases/tag/v0.1.0
CL
)

head_dup_dropped=$(cat <<'CL'
# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [0.2.0] - 2026-07-15

### Added

- Alpha feature that does a thing (#1)

### Fixed

- Gamma bugfix (#3)

## [0.1.0] - 2026-01-01

### Added

- Initial release (#0)

[Unreleased]: https://example.com/compare/v0.2.0...HEAD
[0.2.0]: https://example.com/releases/tag/v0.2.0
[0.1.0]: https://example.com/releases/tag/v0.1.0
CL
)

run_scenario s1_dropped_entry_fails       1 0.1.0 0.2.0 "$base_cl"    "$head_dropped"
run_scenario s2_altered_entry_fails       1 0.1.0 0.2.0 "$base_cl"    "$head_altered"
run_scenario s3_lossless_roll_up_passes   0 0.1.0 0.2.0 "$base_cl"    "$head_lossless"
run_scenario s4_fresh_notes_only_pass     0 0.1.0 0.2.0 "$base_empty" "$head_fresh"
run_scenario s5_stranded_line_still_fails 1 0.1.0 0.2.0 "$base_cl"    "$head_stranded"
run_scenario s6_dropped_duplicate_fails   1 0.1.0 0.2.0 "$base_dup"   "$head_dup_dropped"

echo
if [ "$fail" -eq 0 ]; then echo "all changelog-gate scenarios passed"; else echo "changelog-gate scenarios failed"; exit 1; fi
