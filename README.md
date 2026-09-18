# dotfiles

Personal Claude Code configuration.

## Contents

| Path | Installs to | Role |
| --- | --- | --- |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions for every project. Personal. |
| `claude/CLAUDE.md` | `~/.config/opencode/AGENTS.md` | Same instructions for OpenCode, which reads `AGENTS.md` first. |
| `claude/statusline.sh` | `~/.claude/statusline.sh` | The Claude Code status line. Referenced by `settings.json`. |
| `claude/output-styles/*.md` | `~/.claude/output-styles/` | Output styles for Claude Code. Switch with `/output-style`. |
| `claude/rules/*.md` | `~/.claude/rules/` | Rules that load every session. `secret-handling.md` is generic. `secret-map.local.md` names the accounts, vaults, and items. It holds no secret values and is gitignored. |

## Prerequisites

- `jq` for the status line: `brew install jq`. macOS ships `bc` and `git`.

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

OpenCode does not read `~/.claude/rules/`. Point `instructions` in
`~/.config/opencode/opencode.json` at both rule files:

```json
"instructions": ["~/.claude/rules/secret-handling.md", "~/.claude/rules/secret-map.local.md"]
```
