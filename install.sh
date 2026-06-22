#!/usr/bin/env bash
#
# Cross-harness installer for the Solution Ladder skill.
#
# Symlinks skills/solution-ladder into the skills directory of every supported
# coding agent found on this machine, so `git pull` in this repo updates the
# skill everywhere at once.
#
# Supported:
#   - Codex CLI      -> ~/.codex/skills/solution-ladder
#   - OpenCode       -> ~/.config/opencode/skills/solution-ladder
#   - Claude Code    -> ~/.claude/skills/solution-ladder   (opt-in: INSTALL_CLAUDE=1)
#
# For Claude Code the recommended path is the plugin marketplace (see README),
# so it is skipped unless you set INSTALL_CLAUDE=1.
#
# Usage:
#   ./install.sh                   # symlink into Codex and OpenCode if present
#   INSTALL_CLAUDE=1 ./install.sh  # also symlink into ~/.claude/skills
#   FORCE=1 ./install.sh           # replace an existing real folder with a symlink
#   COPY=1 ./install.sh            # copy instead of symlink (no live updates)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="solution-ladder"
SRC="$SCRIPT_DIR/skills/$SKILL_NAME"

if [ ! -f "$SRC/SKILL.md" ]; then
  echo "error: $SRC/SKILL.md not found — run this script from inside the repo" >&2
  exit 1
fi

detected=0
installed=0

install_into() {
  local label="$1" dir="$2"
  local target="$dir/$SKILL_NAME"

  detected=$((detected + 1))
  mkdir -p "$dir"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    if [ "${FORCE:-0}" = "1" ]; then
      rm -rf "$target"
    else
      echo "  [$label] skip: $target exists as a real folder (re-run with FORCE=1 to replace it with a symlink)"
      return
    fi
  fi

  if [ "${COPY:-0}" = "1" ]; then
    rm -rf "$target"
    cp -R "$SRC" "$target"
    echo "  [$label] copied -> $target"
  else
    ln -sfn "$SRC" "$target"
    echo "  [$label] linked -> $target"
  fi
  installed=$((installed + 1))
}

echo "Installing the '$SKILL_NAME' skill from $SRC"

# Codex CLI
if [ -d "$HOME/.codex" ] || command -v codex >/dev/null 2>&1; then
  install_into "codex" "$HOME/.codex/skills"
fi

# OpenCode
if [ -d "$HOME/.config/opencode" ] || command -v opencode >/dev/null 2>&1; then
  install_into "opencode" "$HOME/.config/opencode/skills"
fi

# Claude Code personal skills dir (opt-in; plugin marketplace is preferred)
if [ "${INSTALL_CLAUDE:-0}" = "1" ]; then
  install_into "claude" "$HOME/.claude/skills"
fi

echo
if [ "$detected" -eq 0 ]; then
  echo "No supported agent detected (Codex / OpenCode)."
  echo "Install manually, e.g.:"
  echo "  ln -sfn \"$SRC\" ~/.codex/skills/$SKILL_NAME"
elif [ "$installed" -eq 0 ]; then
  echo "Nothing changed: every target already exists as a real folder."
  echo "Re-run with FORCE=1 to replace them with symlinks so 'git pull' keeps them current."
else
  echo "Done. Start a NEW session in each tool to pick up the skill."
fi
