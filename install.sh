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

  local dest_dir
  dest_dir=$(dirname "$dest")
  if [ ! -d "$dest_dir" ] && act "create the directory $dest_dir"; then
    mkdir -p -- "$dest_dir"
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

# Link each Markdown file in claude/<dir> to ~/.claude/<dir>.
link_markdown_dir() {
  local dir="$1" file
  for file in "$REPO/claude/$dir"/*.md; do
    [ -e "$file" ] || continue
    link_file "claude/$dir/$(basename "$file")" "$CLAUDE_DIR/$dir/$(basename "$file")"
  done
}

# rules/ loads in every Claude Code session. docs/ loads only when CLAUDE.md
# points the agent at a file.
MARKDOWN_DIRS="output-styles rules docs"

info "== links =="
link_file claude/CLAUDE.md "$CLAUDE_DIR/CLAUDE.md"
link_file claude/statusline.sh "$CLAUDE_DIR/statusline.sh"
link_file claude/CLAUDE.md "$HOME/.config/opencode/AGENTS.md"

for dir in $MARKDOWN_DIRS; do
  link_markdown_dir "$dir"
done

for skill_dir in "$REPO"/claude/skills/*/; do
  [ -d "$skill_dir" ] || continue
  link_file "claude/skills/$(basename "$skill_dir")" "$CLAUDE_DIR/skills/$(basename "$skill_dir")"
done

info "== stale links =="
for dir in $MARKDOWN_DIRS skills; do
  prune_links "$CLAUDE_DIR/$dir"
done
