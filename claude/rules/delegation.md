# Delegation

GLM is free. Claude tokens cost money: Haiku costs the least, then Sonnet, then Opus. Give each task to the cheapest model that can do it. In this session, spend Claude tokens on plans, briefs, evidence checks, and decisions.

## Role

- If your prompt has Orca Task and Dispatch IDs, you are a worker. Do the task yourself, start no workers, and report with `worker_done`. Otherwise you are the coordinator, and the rules below apply.

## What to delegate

- Delegate code changes, code reviews, broad research, and tasks that split into independent parts. Run them as Orca workers: load the `orchestration` skill for the commands (`worker-start`, `send`).
- Do a task in this session when it takes a handful of tool calls, or when the brief is longer than the work. Examples: `git push`, `gh pr create`, issue label, close, and comment commands, and one-line fixes.
- Use in-session subagents (the Agent tool) only for quick read-only lookups. Run them on Haiku: pass `model: "haiku"`.
- When I say "hand off" or "give this to another agent", load the `orca-cli` skill and start the agent with `orca worktree create`. Report the worktree id and the agent handle, then stop.

## Model tiers

| Tier | Orca flags | Use for |
| --- | --- | --- |
| GLM | `--agent opencode` | The default for all delegated work: code changes, tests, code reviews, research, documentation, log and trace analysis. Start one GLM worker for each independent part. |
| Haiku | `--agent claude --model haiku` | Small mechanical tasks that need a tool that only Claude Code has: a Claude Code plugin, a claude.ai connector, or an MCP server that OpenCode does not have. |
| Sonnet | `--agent claude --model sonnet` | A task that GLM failed. Claude-only tool work that needs judgment. A second review of a high-risk change, by a different model family. |
| Opus | `--agent claude --model opus` | A task that Sonnet failed. High-risk work: security, data migrations, concurrency, architecture. |

- Always pass `--model` to a Claude agent, for a worker and for a handoff. Without it, the agent starts on my default model, not on the tier that the table picks. This rule overrides the orchestration guide, which adds `--model` only when the user names a model.
- For a bounded task on Sonnet or Opus, add `--effort low` or `--effort medium`. For an escalation, keep the default effort.
- If I name an agent or a model, use it without confirmation. It overrides the table. "Claude agent" means `--agent claude` with the model from the table. "Codex agent" means `--agent codex`. "GLM" or "OpenCode agent" means `--agent opencode`.

## Escalation

- Escalate one tier only on evidence: the worker reports a failure, its checks fail, or its result contradicts the code.
- Send the first fix to the same worker with `orchestration send`. If the worker fails again, start the next tier. Give it the original spec and a list of what failed.
- If GLM is not available (endpoint down, rate limit, expired key), use the Claude tier that matches the task, and tell me.
- Keep failed work out of this session. Fix it here only when the fix is one line.

## Briefs and results

- Point the brief at files, commits, and diffs by path or ref. The worker reads them itself.
- Ask for a compact result: the outcome, the commands with their exit codes, `file:line` references, and open blockers.
- Read the `worker_done` report first. Read the transcript or the diff only to close a gap.
- A worker that edits code gets its own worktree: `--worktree new-child`. A read-only worker, for example a reviewer, uses `--worktree current` and sees the uncommitted changes.
- A brief for a worker that opens a PR must include this check before `gh pr create`: `git log <base>..HEAD` shows only the intended commits. The check finds a rebase-merged base branch or a stale stack.
- Report the worktree id and the terminal handle of each worker when you start it and when you collect its result.
