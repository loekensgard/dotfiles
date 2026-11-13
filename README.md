# dotfiles

Personal Claude Code configuration.

## Contents

| Path | Installs to | Role |
| --- | --- | --- |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions for every project. Holds the rules both agents need in every session. Personal. |
| `claude/CLAUDE.md` | `~/.config/opencode/AGENTS.md` | Same instructions for OpenCode, which reads `AGENTS.md` first. |
| `claude/statusline.sh` | `~/.claude/statusline.sh` | The Claude Code status line. Referenced by `settings.json`. |
| `claude/output-styles/*.md` | `~/.claude/output-styles/` | Output styles for Claude Code. Switch with `/output-style`. |
| `claude/rules/*.md` | `~/.claude/rules/` | Topic rules, one topic per file. Claude Code loads every file each session. A file with `paths:` frontmatter loads only when Claude Code works with a file that matches a glob. OpenCode reads the files through `instructions` (see below). `secret-map.local.md` is gitignored. It names the accounts, vaults, and items, and holds no secret values. |
| `claude/docs/*.md` | `~/.claude/docs/` | Reference docs. They do not load every session. An agent reads a doc only when `CLAUDE.md` points it there. |
| `claude/skills/*` | `~/.claude/skills/` | Personal skills. Loaded on demand by Claude Code and OpenCode. |
| `tests/install_test.sh` | not installed | Tests for `install.sh`. Run it after a change to the installer. |

## Prerequisites

- `jq` for the status line and the OpenCode config step: `brew install jq`. macOS ships `bc` and `git`.

## Install

```bash
./install.sh --dry-run   # report the actions
./install.sh             # link the files
```

The script creates a symlink, so an edit in this repository takes effect at
once. An existing real file moves to `<name>.bak-<timestamp>` first. The
script is idempotent, so run it again after a pull. A link that points at a
file this repository no longer has is removed.

After a fresh clone, create the personal secret map. The copy is gitignored:

```bash
cp claude/rules/secret-map.local.md.example claude/rules/secret-map.local.md
```

OpenCode does not read `~/.claude/rules/` on its own. `install.sh` adds the
rules glob to the `instructions` array in `~/.config/opencode/opencode.json`,
so OpenCode loads every rule file, also the gitignored secret map. OpenCode
resolves `~/` in an entry against the home directory. The script warns and
changes nothing when the file is a symlink, does not exist, when `jq` is
missing, or when the file is JSONC or its `instructions` key is not an array.
In that case, add the entry by hand:

```json
"instructions": ["~/.claude/rules/*.md"]
```

Test the installer:

```bash
tests/install_test.sh
```
