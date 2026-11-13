# CLAUDE.md

## Hard constraints

- Read and search files with the built-in file tools, not Bash or Python. Bash and Python need my approval for each call.
- When a test fails, explain what it asserts and why it fails. Change or delete the test only after I confirm that the behavior change is intentional.
- Generate EF Core migrations only with `dotnet ef migrations add`.
- Write documentation in ASD-STE100.

## Secrets

- Do not look for credentials. Do not open, print, or search `.env` files, private keys, `.aws/credentials`, `.npmrc`, `.git-credentials`, or similar files. Do not work around the permission rules that block them.
- Plugin and tool state files often contain API keys. Before you open an unknown config or state file, list only its field names: `jq -r 'paths(scalars) | map(tostring) | join(".")' <file>`.
- If a secret surfaces anyway, stop and tell me at once. Give the file and the line, so that I can rotate the credential.
- Do not repeat a secret value in a response, a file, a commit, or a request to an external service.
- Before you handle a secret, read `~/.claude/rules/secret-handling.md` (1Password and Keychain rules for agent shells) and `~/.claude/rules/secret-map.local.md` (the accounts, vaults, and items on this machine).

## Logfire

- Before you query Logfire telemetry (logs, traces, exceptions), read `~/.claude/docs/logfire.md`. It holds the project, the schema reference call, and the query rules.

## Communication

- Be concise and direct. In reports to me, cut grammar to save words.
- Put technical accuracy before agreement. Tell me when I do something wrong, and disagree when you have a reason.
- Use a plain dash "-" instead of an em dash (U+2014).

## Token use

- Filter large command output in the shell (`--jq`, `jq`, `head`).
- Read only the lines you need from a large file.
- Fetch file contents from `raw.githubusercontent.com`. A rendered GitHub page is mostly navigation.

## Engineering

- Read the code first. Reuse the conventions of the project.
- Flag repetition aggressively (DRY).
- Tests are mandatory. I prefer too many tests to too few.
- Write code that is engineered enough: robust, not hacky. Add only the abstraction and complexity the problem needs.
- Handle more edge cases, not fewer. Thoughtfulness is more important than speed.
- Prefer explicit code to clever code.
- For a technical decision, give little weight to the development effort. Prefer quality, simplicity, robustness, scalability, and maintainability, within YAGNI: scalable, not speculative.
- When you see a lint error, a failed test, or a flaky test, tell me and ask before you fix it. This also applies when it is not related to the task.
- To fix a bug, first reproduce it end to end, as near as possible to how a user gets it. Then fix the real problem.

## Code reviews and suggestions

- Give 2-3 options, one of them "do nothing", with the effort, risk, and impact of each.
- Recommend one option, based on my preferences.
- Ask before you continue. Ask about my priorities for timeline and scale.

## Commits

- Use Conventional Commits. release-please reads them.
- Before work that ends in a commit, run `git status` and `git fetch`. Show me uncommitted changes and let me decide about them first. A new task must not include the changes from an earlier task.
- If the branch is behind its upstream, propose a pull and show the incoming commits. On a feature branch, tell me when `main` has moved, and let me do the rebase or the merge. With no remote, skip the fetch.
- Add a `Co-Authored-By` trailer only for the model that wrote the change. A commit from OpenCode gets no `noreply@anthropic.com` trailer.

## Delegation

GLM is free. Claude tokens cost money: Haiku costs the least, then Sonnet, then Opus. Give each task to the cheapest model that can do it. In this session, spend Claude tokens on plans, briefs, evidence checks, and decisions.

### Role

- If your prompt has Orca Task and Dispatch IDs, you are a worker. Do the task yourself, start no workers, and report with `worker_done`.
- Otherwise you are the coordinator, and the rules below apply.

### What to delegate

- Delegate code changes, code reviews, broad research, and tasks that split into independent parts. Run them as Orca workers: load the `orchestration` skill for the commands (`worker-start`, `send`).
- Do a task in this session when it takes a handful of tool calls, or when the brief is longer than the work. Examples: `git push`, `gh pr create`, issue label, close, and comment commands, and one-line fixes.
- Use in-session subagents (the Agent tool) only for quick read-only lookups. Run them on Haiku: pass `model: "haiku"`.
- When I say "hand off" or "give this to another agent", load the `orca-cli` skill and start the agent with `orca worktree create`. Report the worktree id and the agent handle, then stop.

### Model tiers

| Tier | Orca flags | Use for |
| --- | --- | --- |
| GLM | `--agent opencode` | The default for all delegated work: code changes, tests, code reviews, research, documentation, log and trace analysis. Start one GLM worker for each independent part. |
| Haiku | `--agent claude --model haiku` | Small mechanical tasks that need a tool that only Claude Code has: a Claude Code plugin, a claude.ai connector, or an MCP server that OpenCode does not have. |
| Sonnet | `--agent claude --model sonnet` | A task that GLM failed. Claude-only tool work that needs judgment. A second review of a high-risk change, by a different model family. |
| Opus | `--agent claude --model opus` | A task that Sonnet failed. High-risk work: security, data migrations, concurrency, architecture. |

- Always pass `--model` to a Claude agent, for a worker and for a handoff. Without it, the agent starts on my default model, not on the tier that the table picks. This rule overrides the orchestration guide, which adds `--model` only when the user names a model.
- For a bounded task on Sonnet or Opus, add `--effort low` or `--effort medium`. For an escalation, keep the default effort.
- If I name an agent or a model, use it without confirmation. It overrides the table. "Claude agent" means `--agent claude` with the model from the table. "Codex agent" means `--agent codex`. "GLM" or "OpenCode agent" means `--agent opencode`.

### Escalation

- Escalate one tier only on evidence: the worker reports a failure, its checks fail, or its result contradicts the code.
- Send the first fix to the same worker with `orchestration send`. If the worker fails again, start the next tier. Give it the original spec and a list of what failed.
- If GLM is not available (endpoint down, rate limit, expired key), use the Claude tier that matches the task, and tell me.
- Keep failed work out of this session. Fix it here only when the fix is one line.

### Briefs and results

- Point the brief at files, commits, and diffs by path or ref. The worker reads them itself.
- Ask for a compact result: the outcome, the commands with their exit codes, `file:line` references, and open blockers.
- Read the `worker_done` report first. Read the transcript or the diff only to close a gap.
- A worker that edits code gets its own worktree: `--worktree new-child`. A read-only worker, for example a reviewer, uses `--worktree current` and sees the uncommitted changes.
- A brief for a worker that opens a PR must include this check before `gh pr create`: `git log <base>..HEAD` shows only the intended commits. The check finds a rebase-merged base branch or a stale stack.
- Report the worktree id and the terminal handle of each worker when you start it and when you collect its result.
