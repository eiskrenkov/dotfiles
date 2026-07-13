#!/bin/bash

# Matt Pocock's skills, installed via the skills.sh CLI instead of as chezmoi
# externals. Source pinned to a tag for reproducibility (matches how the other
# externals are pinned).
#
# A global install writes the canonical skill copies to ~/.agents/skills/<name>
# (the CLI's global canonical dir happens to be exactly where our skills live);
# targeting claude-code then symlinks ~/.claude/skills/<name> -> canonical, which
# is a no-op because ~/.claude/skills is already our dir symlink to
# ~/.agents/skills. No lockfile is written for global installs.
#
# The CLI has no dependency resolution, so every skill is listed explicitly: the
# four user-invoked skills plus the model-invoked ones they reach for via
# `/skill` prose (grill-with-docs -> grilling, domain-modeling; implement -> tdd,
# code-review; improve-codebase-architecture -> codebase-design; wayfinder ->
# prototype). grill-me and handoff are kept from the old external set.
#
# The CLI can't namespace on install, so everything is prefixed with `matt-`
# after the fact (see the rename step below). This groups them in the skill list
# and avoids collisions with same-named skills (e.g. the built-in /code-review).
#
# run_onchange_ re-runs this whenever the text below changes, so bump the tag or
# edit the skill list to reinstall.

set -euo pipefail

# Upstream skill names (unprefixed). Editing this list re-triggers the script.
skills=(
  grill-with-docs
  implement
  improve-codebase-architecture
  wayfinder
  grilling
  domain-modeling
  tdd
  code-review
  codebase-design
  prototype
  handoff
  grill-me
)

if ! command -v npx >/dev/null 2>&1; then
  echo "npx not found on PATH; skipping Matt Pocock skills install." >&2
  exit 0
fi

# Install under upstream names into ~/.agents/skills/<name>.
add_args=()
for s in "${skills[@]}"; do add_args+=(--skill "$s"); done
npx --yes skills@latest add \
  "https://github.com/mattpocock/skills/tree/v1.1.0" \
  --global --agent claude-code --yes \
  "${add_args[@]}"

dir="$HOME/.agents/skills"

# Prefix each skill with `matt-`: rename the dir and rewrite its frontmatter
# `name:` (Claude Code keys the skill off it and expects it to match the dir).
for s in "${skills[@]}"; do
  [ -d "$dir/$s" ] || { echo "warn: $s not installed; skipping rename." >&2; continue; }
  rm -rf "${dir:?}/matt-$s"
  mv "$dir/$s" "$dir/matt-$s"
  name="$s" perl -pi -e 's{^name:[ \t]*["\x27]?\Q$ENV{name}\E["\x27]?[ \t]*$}{name: matt-$ENV{name}}' "$dir/matt-$s/SKILL.md"
done

# Rewrite the `/skill` prose references between them so the renamed skills still
# resolve to each other (e.g. grill-with-docs's "/grilling" -> "/matt-grilling").
# Only names we installed are rewritten; pointers to uninstalled skills are left
# alone. The negative lookahead keeps prefixes distinct (/grill-me vs /grill-*).
for s in "${skills[@]}"; do
  name="$s" find "$dir" -type f -name '*.md' -path '*/matt-*/*' \
    -exec perl -pi -e 's{/\Q$ENV{name}\E(?![A-Za-z0-9_-])}{/matt-$ENV{name}}g' {} +
done
