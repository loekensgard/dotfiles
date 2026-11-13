#!/usr/bin/env bash
# install.sh - link this repository's Claude configuration into ~/.claude.
# It also adds the Claude rules glob to the OpenCode instructions array.
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

# Add the Claude rules glob to the OpenCode "instructions" array, so OpenCode
# loads the rule files in ~/.claude/rules. Claude Code loads them on its own.
# The "~" form and the absolute form count as the same entry.
set_opencode_instructions() {
  local file="$HOME/.config/opencode/opencode.json"
  # shellcheck disable=SC2088 # the literal tilde is intentional; OpenCode resolves it
  local entry="~/.claude/rules/*.md"

  # A symlinked config can point at a tracked file in a repository. Edit the
  # target there, not through the link: an mv would replace the link with a
  # regular file.
  if [ -L "$file" ]; then
    warn "$file is a symlink. Add \"$entry\" to the \"instructions\" array in the link target by hand."
    return 0
  fi
  if [ ! -f "$file" ]; then
    warn "$file does not exist. Add \"$entry\" to the \"instructions\" array by hand."
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq is not installed. Add \"$entry\" to the \"instructions\" array in $file by hand."
    return 0
  fi
  # OpenCode also accepts JSONC. jq cannot read it, so the file stays as it is.
  if ! jq empty "$file" >/dev/null 2>&1; then
    warn "$file is not plain JSON. Add \"$entry\" to the \"instructions\" array by hand."
    return 0
  fi
  local kind
  kind=$(jq -r '.instructions // [] | type' "$file")
  if [ "$kind" != "array" ]; then
    warn "\"instructions\" in $file is not an array. Add \"$entry\" by hand."
    return 0
  fi
  if jq -e --arg tilde "$entry" --arg abs "$HOME/.claude/rules/*.md" \
    '(.instructions // []) | any(. == $tilde or . == $abs)' "$file" >/dev/null; then
    info "ok       $file instructions"
    return 0
  fi

  local backup
  backup="$file.bak-$(date +%Y%m%d%H%M%S)"
  if act "copy $file to $backup"; then
    cp -- "$file" "$backup"
    info "backup   $backup"
  fi

  if act "add $entry to the \"instructions\" array in $file"; then
    local tmp
    # The temp file sits next to the target, so the mv stays on one file
    # system and is an atomic rename. mktemp gives it mode 0600, so copy the
    # target's content and mode onto it first.
    tmp=$(mktemp "$file.XXXXXX")
    cp -p -- "$file" "$tmp"
    if ! jq --arg entry "$entry" '.instructions = ((.instructions // []) + [$entry])' "$file" >"$tmp"; then
      rm -f -- "$tmp"
      warn "jq failed to write $file. The file is unchanged."
      return 0
    fi
    mv -- "$tmp" "$file"
    info "updated  $file"
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

info "== opencode config =="
set_opencode_instructions

info "== stale links =="
for dir in $MARKDOWN_DIRS skills; do
  prune_links "$CLAUDE_DIR/$dir"
done
