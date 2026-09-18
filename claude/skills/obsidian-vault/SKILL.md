---
name: obsidian-vault
description: Work in the Obsidian "work" vault at ~/Obsidian/work - write dev logs, ingest Inbox drops, answer questions against the vault, lint, maintain wiki/index/log. Use when the user says "dev log", "write to Obsidian", "ingest", "lint the vault", or asks a question that the vault would answer.
---

# Obsidian Vault

## Vault location

`~/Obsidian/work` (only vault registered in Obsidian on this Mac). Git repo. Never push.

**Read `~/Obsidian/work/CLAUDE.md` first.** It is the schema: three layers (inputs you read, `wiki/` you own, `index.md` + `log.md` you maintain), ownership rules, operations (ingest, query, lint), commit conventions. This skill is only the entry point.

## Layout

```
Inbox/        capture buffer, user-owned
Meetings/     frozen after the date
Personal/     user-owned
Projects/     specs, plans, MOCs (_<Topic> MOC.md), dev logs
Reference/    tips, snippets, prompts
wiki/         Claude-maintained synthesis, full-path wikilinks only
index.md      one line per page, grouped by folder
log.md        append-only: ## [YYYY-MM-DD] <op> | <title>
```

## Dev log ("write dev log")

Event-triggered, one per project. Frozen after the day.

- Single repo: `Projects/<Project>/<repo>/Dev log/<YYYY-MM-DD>.md`, e.g. `Projects/Example/example-api/Dev log/2026-09-18.md`.
- Cross-repo (2+ repos): `Projects/<Project>/Dev log/<YYYY-MM-DD>.md`.
- Format: one-sentence topline with PR refs and test count. Then flat `-` bullets of concrete changes. `## PR #N - <title>` sections only when multiple PRs land the same day. `## Follow-ups` only when there is real backlog. No H1. Inline refs: `closes #N`, PR/commit SHAs and file paths in backticks. Language: match the latest entry in that folder (technical entries are usually English, index/log lines Norwegian).
- Steps:
  1. Read the newest file in the target `Dev log/` folder for style.
  2. Write the entry.
  3. Add one line to `index.md` next to that project's previous dev-log line: `- [[Projects/.../Dev log/<date>]] — <d. month yyyy> single-repo|cross-repo: <summary>`.
  4. Append to the END of `log.md`: `## [<date>] edit | <repo> dev log <date>` plus 2-4 lines.
  5. `git add` only the files you touched (entry, `index.md`, `log.md`); the user's Inbox changes stay unstaged. Commit `chore: edit <repo> dev log <date> → <topic>`.

## Search

```bash
grep -rl "keyword" ~/Obsidian/work --include="*.md" --exclude-dir=.obsidian
find ~/Obsidian/work -name "*.md" -not -path "*/.obsidian/*" | grep -i "keyword"
```

Or use Grep/Glob on the vault path. For a question, start from `index.md`.

## Do not

- Rewrite `Meetings/`, `Personal/`, `Reference/` without explicit request.
- Delete files. Move-to-archive on request only.
- Push.
- Apply this schema to other vaults.
