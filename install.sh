#!/usr/bin/env bash
# install.sh - link this repository's Claude configuration into ~/.claude.
#
# The script is idempotent. Run it again after a pull.
#
# It creates a symlink, so an edit in the repository takes effect at once. An
# existing real file is moved aside to <name>.bak-<timestamp> before the link
# replaces it. An existing correct symlink is left alone.
#
# Usage:
#   ./install.sh            Link the files.
#   ./install.sh --dry-run  Report the actions and change nothing.

set -euo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
CLAUDE_DIR="$HOME/.claude"

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

warn() { printf 'warning: %s\n' "$1" >&2; }

# The status line parses JSON and formats token counts.
for tool in jq bc; do
  command -v "$tool" >/dev/null 2>&1 || warn "$tool is not installed. The status line needs it."
done

info() { printf '%s\n' "$1"; }
act() {
  if [ "$DRY_RUN" = "1" ]; then
    printf 'would: %s\n' "$1"
    return 1
  fi
  return 0
}

link_file() {
  local src="$REPO/$1" dest="$2"

  if [ ! -e "$src" ]; then
    printf 'install: missing source %s\n' "$src" >&2
    exit 1
  fi

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    info "ok       $dest"
    return 0
  fi

  if act "create the directory $(dirname "$dest")"; then
    mkdir -p -- "$(dirname "$dest")"
  fi

  # A real file must never be lost. A stale symlink can go without a backup.
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    local backup
    backup="$dest.bak-$(date +%Y%m%d%H%M%S)"
    if act "move $dest to $backup"; then
      mv -- "$dest" "$backup"
      info "backup   $backup"
    fi
  fi

  if act "link $dest to $src"; then
    ln -sfn -- "$src" "$dest"
    info "linked   $dest"
  fi
}

# Remove a symlink in $dir that points into this repository at a file that
# no longer exists. A link that points elsewhere is left alone.
prune_links() {
  local dir="$1" link target
  [ -d "$dir" ] || return 0
  for link in "$dir"/*; do
    [ -L "$link" ] || continue
    target=$(readlink "$link")
    case "$target" in "$REPO"/*) ;; *) continue ;; esac
    [ -e "$target" ] && continue
    if act "remove the stale link $link"; then
      rm -- "$link"
      info "removed  $link"
    fi
  done
}

info "== links =="
link_file claude/CLAUDE.md "$CLAUDE_DIR/CLAUDE.md"
link_file claude/statusline.sh "$CLAUDE_DIR/statusline.sh"
link_file claude/CLAUDE.md "$HOME/.config/opencode/AGENTS.md"

for style in "$REPO"/claude/output-styles/*.md; do
  [ -e "$style" ] || continue
  link_file "claude/output-styles/$(basename "$style")" "$CLAUDE_DIR/output-styles/$(basename "$style")"
done

for rule in "$REPO"/claude/rules/*.md; do
  [ -e "$rule" ] || continue
  link_file "claude/rules/$(basename "$rule")" "$CLAUDE_DIR/rules/$(basename "$rule")"
done

for skill_dir in "$REPO"/claude/skills/*/; do
  [ -d "$skill_dir" ] || continue
  link_file "claude/skills/$(basename "$skill_dir")" "$CLAUDE_DIR/skills/$(basename "$skill_dir")"
done

info "== stale links =="
prune_links "$CLAUDE_DIR/output-styles"
prune_links "$CLAUDE_DIR/rules"
prune_links "$CLAUDE_DIR/skills"
