#!/usr/bin/env bash
# tests/install_test.sh - test install.sh against a temporary HOME.
#
# Each case writes an opencode.json variant, runs install.sh, and asserts
# the resulting JSON, the backup file, and the output. The script exits
# non-zero when a case fails.

# shellcheck disable=SC2016 # single-quoted jq programs and JSON keys hold $ on purpose
set -euo pipefail

# shellcheck disable=SC2016 # single-quoted jq programs and JSON keys hold $ on purpose
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
INSTALL="$REPO/install.sh"
# shellcheck disable=SC2088 # the literal tilde is the JSON entry; OpenCode resolves it
ENTRY='~/.claude/rules/*.md'
command -v jq >/dev/null 2>&1 || { printf 'install_test.sh: jq is required\n' >&2; exit 1; }

ROOT=$(mktemp -d "${TMPDIR:-/tmp}/install_test.XXXXXX")
trap 'rm -rf -- "$ROOT"' EXIT

PASS=0
FAIL=0
OUT=""
STATUS=0

ok() {
  printf 'ok  : %s\n' "$1"
  PASS=$((PASS + 1))
}

no() {
  printf 'FAIL: %s\n' "$1"
  FAIL=$((FAIL + 1))
}

# assert <description> <command...>: run the command as the assertion.
# The command's stdout is not needed; only its exit status counts.
assert() {
  local desc="$1"
  shift
  if "$@" >/dev/null; then
    ok "$desc"
  else
    no "$desc"
  fi
}

contains() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

# run <home> [argument...]: run install.sh and record OUT and STATUS.
run() {
  local home="$1"
  shift
  OUT=$(HOME="$home" "$INSTALL" "$@" 2>&1) && STATUS=0 || STATUS=$?
}

# count_backups <file>: print the number of <file>.bak-* files.
count_backups() {
  local n=0 b
  for b in "$1".bak-*; do
    [ -e "$b" ] && n=$((n + 1))
  done
  printf '%s' "$n"
}

# file_mode <file>: print the octal mode, on BSD and GNU stat.
file_mode() {
  stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1"
}

# setup <name>: create a fresh HOME with ~/.config/opencode and set $file.
setup() {
  HOME_DIR="$ROOT/$1"
  mkdir -p "$HOME_DIR/.config/opencode"
  file="$HOME_DIR/.config/opencode/opencode.json"
}

HOME_DIR=""
file=""

# Case 1: no opencode.json.
setup no-file
run "$HOME_DIR"
assert "no file: exit 0" test "$STATUS" -eq 0
assert "no file: warning printed" contains "$OUT" "warning:"
assert "no file: no file created" test ! -e "$file"

# Case 2: a file without instructions.
setup no-key
printf '{"$schema": "https://opencode.ai/config.json", "model": "anthropic/claude-sonnet-5-5"}\n' >"$file"
cp -- "$file" "$file.orig"
run "$HOME_DIR"
assert "no key: exit 0" test "$STATUS" -eq 0
assert "no key: entry added" jq -e --arg e "$ENTRY" '.instructions == [$e]' "$file"
assert "no key: other keys kept" jq -e '.model == "anthropic/claude-sonnet-5-5" and ."$schema" == "https://opencode.ai/config.json"' "$file"
assert "no key: updated printed" contains "$OUT" "updated"
assert "no key: backup created" test "$(count_backups "$file")" -eq 1
assert "no key: backup holds the original" cmp -s "$file.orig" "$file".bak-*

# Case 3: a file with other instructions entries.
setup other-entries
printf '{"model": "x", "instructions": ["CONTRIBUTING.md", "docs/*.md"]}\n' >"$file"
run "$HOME_DIR"
assert "other entries: exit 0" test "$STATUS" -eq 0
assert "other entries: kept in order, entry appended" jq -e --arg e "$ENTRY" '.instructions == ["CONTRIBUTING.md", "docs/*.md", $e]' "$file"
assert "other entries: other keys kept" jq -e '.model == "x"' "$file"
assert "other entries: backup created" test "$(count_backups "$file")" -eq 1

# Case 4: a file that already has the tilde entry.
setup tilde-entry
printf '{"instructions": ["%s"], "model": "x"}\n' "$ENTRY" >"$file"
cp -- "$file" "$file.orig"
run "$HOME_DIR"
assert "tilde entry: exit 0" test "$STATUS" -eq 0
assert "tilde entry: ok printed" contains "$OUT" "ok"
assert "tilde entry: file unchanged" cmp -s "$file.orig" "$file"
assert "tilde entry: no backup" test "$(count_backups "$file")" -eq 0

# Case 5: a file that already has the absolute entry.
setup abs-entry
printf '{"instructions": ["%s/.claude/rules/*.md"]}\n' "$HOME_DIR" >"$file"
cp -- "$file" "$file.orig"
run "$HOME_DIR"
assert "absolute entry: exit 0" test "$STATUS" -eq 0
assert "absolute entry: ok printed" contains "$OUT" "ok"
assert "absolute entry: file unchanged" cmp -s "$file.orig" "$file"
assert "absolute entry: no backup" test "$(count_backups "$file")" -eq 0

# Case 6: a file with a JSONC comment.
setup jsonc
printf '{\n  // OpenCode accepts comments.\n  "model": "x"\n}\n' >"$file"
cp -- "$file" "$file.orig"
run "$HOME_DIR"
assert "jsonc: exit 0" test "$STATUS" -eq 0
assert "jsonc: warning printed" contains "$OUT" "warning:"
assert "jsonc: file unchanged" cmp -s "$file.orig" "$file"
assert "jsonc: no backup" test "$(count_backups "$file")" -eq 0

# Case 7: --dry-run changes nothing.
setup dry-run
printf '{"model": "x"}\n' >"$file"
cp -- "$file" "$file.orig"
run "$HOME_DIR" --dry-run
assert "dry run: exit 0" test "$STATUS" -eq 0
assert "dry run: would printed" contains "$OUT" "would:"
assert "dry run: file unchanged" cmp -s "$file.orig" "$file"
assert "dry run: no backup" test "$(count_backups "$file")" -eq 0

# Case 8: a second run adds nothing.
setup second-run
printf '{"model": "x"}\n' >"$file"
run "$HOME_DIR"
run "$HOME_DIR"
assert "second run: exit 0" test "$STATUS" -eq 0
assert "second run: ok printed" contains "$OUT" "ok"
assert "second run: one entry" jq -e --arg e "$ENTRY" '.instructions == [$e]' "$file"
assert "second run: one backup" test "$(count_backups "$file")" -eq 1

# Case 9: a symlinked opencode.json.
setup symlink
printf '{"model": "x"}\n' >"$HOME_DIR/config-in-repo.json"
ln -s "$HOME_DIR/config-in-repo.json" "$file"
cp -- "$HOME_DIR/config-in-repo.json" "$HOME_DIR/config-in-repo.json.orig"
run "$HOME_DIR"
assert "symlink: exit 0" test "$STATUS" -eq 0
assert "symlink: warning printed" contains "$OUT" "warning:"
assert "symlink: still a symlink" test -L "$file"
assert "symlink: link unchanged" test "$(readlink "$file")" = "$HOME_DIR/config-in-repo.json"
assert "symlink: target unchanged" cmp -s "$HOME_DIR/config-in-repo.json.orig" "$HOME_DIR/config-in-repo.json"
assert "symlink: no temp file left" test -z "$(ls "$HOME_DIR"/.config/opencode/opencode.json.?????? 2>/dev/null || true)"

# Case 10: a 0644 file keeps its mode.
setup file-mode
printf '{"model": "x"}\n' >"$file"
chmod 644 "$file"
run "$HOME_DIR"
assert "file mode: exit 0" test "$STATUS" -eq 0
assert "file mode: entry added" jq -e --arg e "$ENTRY" '.instructions == [$e]' "$file"
assert "file mode: still 0644" test "$(file_mode "$file")" = "644"
assert "file mode: no temp file left" test -z "$(ls "$HOME_DIR"/.config/opencode/opencode.json.?????? 2>/dev/null || true)"

printf '%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
