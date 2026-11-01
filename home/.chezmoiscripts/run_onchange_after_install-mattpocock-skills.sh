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
# user-invoked skills plus the model-invoked ones they reach for
# (grill-with-docs -> grilling, domain-modeling; implement, implement-spec ->
# tdd, code-review; improve-codebase-architecture -> codebase-design; wayfinder
# -> prototype, research; retro -> writing-for-agents). pr is model-invoked and
# stands alone. grill-me and handoff are kept from the old external set.
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
  implement-spec
  improve-codebase-architecture
  wayfinder
  retro
  pr
  grilling
  domain-modeling
  tdd
  code-review
  codebase-design
  prototype
  research
  writing-for-agents
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
  "https://github.com/mattpocock/skills/tree/v1.3.1" \
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

# Rewrite the references between them so the renamed skills still resolve to
# each other. Upstream names a dependency as `Call the Skill tool with "grilling"`
# (or `tdd` in backticks) since v1.3.0, and as `/grilling` prose before that and
# in a few places still, so all three spellings are rewritten:
# "grilling" -> "matt-grilling", `tdd` -> `matt-tdd`, /tdd -> /matt-tdd. Only names
# we installed are rewritten; pointers to uninstalled skills are left alone. The
# lookarounds keep prefixes distinct (/grill-me vs /grill-*) and leave paths like
# skills/engineering/tdd/ alone. A quoted name is only a skill reference as a
# "double-quoted" name on a "Skill tool" line, a `backticked` one straight after
# "Skill tool with", or either right before the word "skill". Elsewhere it is
# something else (wayfinder's `research`/`prototype` ticket labels), so it stays.
for s in "${skills[@]}"; do
  name="$s" find "$dir" -type f -name '*.md' -path '*/matt-*/*' \
    -exec perl -pi -e '
      my $n = quotemeta $ENV{name}; my $m = "matt-$ENV{name}";
      s{(?<![A-Za-z0-9_.-])/$n(?![A-Za-z0-9_/-])}{/$m}g;
      s{"$n"}{"$m"}g if /Skill tool/;
      s{(Skill tool with )`$n`}{$1`$m`}g;
      s{(["`])$n\1(?=\s+skill\b)}{$1$m$1}g;
    ' {} +
done
