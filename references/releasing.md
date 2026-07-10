# Releasing

How merged work becomes a shipped version, on repos that version.
Detection first, discipline second: this file applies when the target
repo has a `CHANGELOG.md`, a version field in a manifest
(`package.json`, `plugin.json`, `Cargo.toml`, `pyproject.toml`, …), or
existing `v*` tags. Repos with none of these end at merge — say so in
the final report and stop here.

## Record as you merge

Every PR that changes shipped behavior records the change under a
`## [Unreleased]` heading in the changelog, in that same PR — not in a
later batch. On repos whose users receive updates by version
comparison (plugins, packages), an unrecorded merged change is
invisible until somebody notices; the Unreleased section is what makes
batching deliberate instead of accidental.

- Refusal condition: merging a shipped-behavior PR without its
  changelog line is silent release debt — treat it like merging over a
  missing test.

## The release task

Releasing is its own pipeline-eligible task, not a tail command on the
last feature merge:

1. Derive the version from the Conventional Commits types since the
   last tag: a breaking change → major, `feat` → minor, everything
   else → patch.
2. Move the Unreleased entries into a new `## [x.y.z] - <date>`
   section; add the compare link.
3. Bump the manifest version to match — the two move together in one
   release PR, never separately.
4. Merge, then tag `v<version>` on the merge commit, then publish the
   release notes matching the changelog section.

- Refusal condition: tagging or announcing content whose manifest
  version was not bumped, or whose changelog heading disagrees with
  the tag — version, heading, and tag are one fact in three places;
  they never move apart.

## How this document is used

- **Stage 5 (Review & deliver)** — the merge step checks the target
  repo for versioning and records under Unreleased in the same PR.
- **A release** — runs as its own task through the pipeline; the
  triviality hatch never covers it, because a release changes what
  users receive.
