#!/usr/bin/env bash
# Self-checks for the argus-mode plugin. Run from the repo root:
#   bash tests/run-checks.sh
# CI runs this on every push and pull request.
set -uo pipefail
fail=0
note() { printf 'ok:   %s\n' "$*"; }
err()  { printf 'FAIL: %s\n' "$*"; fail=1; }

# 1. Lexicon check — the pattern shipped in git-conventions.md must flag
#    the seeded dirty fixture and pass the clean one (which carries the
#    known false-positive traps: Oracle DB, green environments, WAL
#    checkpoints, rollout stages).
pattern=$(grep -o "grep -inE '[^']*'" references/git-conventions.md | head -1 | sed "s/^grep -inE '//; s/'\$//")
if [ -z "$pattern" ]; then
  err "lexicon pattern not found in references/git-conventions.md"
else
  hits=$(grep -icE "$pattern" tests/fixtures/dirty.md || true)
  if [ "${hits:-0}" -ge 5 ]; then note "lexicon flags the dirty fixture ($hits hits)"; else err "lexicon: expected >=5 hits on dirty fixture, got ${hits:-0}"; fi
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
  grep -q "\`$n\`" README.md && note "README lists agent $n" || err "README does not list agent $n"
  grep -qE "\`$n\`.*$m" README.md && note "README carries model $m for $n" || err "README missing model $m for agent $n"
done

echo
if [ "$fail" -eq 0 ]; then echo "all checks passed"; else echo "checks failed"; exit 1; fi
