# CLAUDE.md

## Hard constraints

- Use internal tools to read data instead of Bash or Python, Bash and Python is locked behind ASK permission.
- When a test fails, DO NOT rewrite or delete the test to make it pass. Explain what the test is asserting and why it's failing. Only modify a test if the user explicitly confirms the behavioral change was intentional.
- EF Core migrations MUST be generated via `dotnet ef migrations add`.
- When writing documentation, always use ASD-STE100.

## Secrets

- Do not look for credential material. Never open, cat, grep, or print `.env` files, private keys, `.aws/credentials`, `.npmrc`, `.git-credentials`, or similar files in plain text. Do not work around the permission rules that block them.
- If a secret surfaces anyway, for example a hardcoded API key in code, a token in a log file, or a credential in a config that was already open, stop and tell the user immediately. Name the file and line so the user can rotate the credential.
- Do not echo a secret value back in a response. Do not copy it into another file. Do not commit it. Do not send it to any external service.
- For 1Password, Keychain, and secret locations, follow `~/.claude/rules/secret-handling.md` and `~/.claude/rules/secret-map.local.md`. Read these files before you handle secrets.

## Communication Preferences

- Be concise, direct, and objective - prioritize technical accuracy over validation
- Don't be a yes man - respectfully disagree when necessary and provide honest feedback
- When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.
- Tell me when I'm doing something wrong
- Read the code first, reuse conventions from the project.

- Never use the em dash "—". Use a plain dash "-" instead.

## My engineering preferences (use these to guide your recommendations)

- DRY is important - flag repetition aggressively.
- Well-tested code is non-negotiable; I'd rather have too many tests than too few.
- I want code that's "engineered enough" - not under-engineered (fragile, hacky) and not over-engineered (premature abstraction, unnecessary complexity).
- I err on the side of handling more edge cases, not fewer; thoughtfulness &gt; speed.
- Bias toward explicit over clever.

## Engineering excellence

- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability - within YAGNI: scalable, not speculative.
- Hold the same high standard for engineering hygiene: lint, test failures, and test flakiness. If you spot one - even if it is unrelated to the current task - surface it and ask before fixing. Do not silently expand scope, but do not ignore it either.
- When doing bug fixes, always start by reproducing the bug in an E2E setting as closely aligned with how an end user hits it as possible. This makes sure you find the real problem so the fix actually solves it.

## Agent workflow

- When I ask for a code review, or when work splits into two or more independent tasks, do not run the work in this session. Spawn worker agents with Orca. The default worker agent is OpenCode agent (`--agent opencode`).
- If my request names an agent, spawn that agent instead of the default. "Claude agent" and "Claude Code agent" mean `--agent claude`. "Codex agent" means `--agent codex`. A named agent overrides every default in this file. Spawn it directly, without confirmation.
- Keep this session as the coordinator. Write a self-contained brief for each worker: the repo, the branch or diff to work from, the task, and the result format. Workers do not see this session's context.
- When results must come back, use supervised orchestration: `orca orchestration` tasks and workers, then wait, read the worker output, and synthesize one answer. Use the orca-cli and orchestration skills for the command flow.
- When I say hand off, hand over, or give this to another agent, do a full handoff instead: `orca worktree create --agent <agent> --prompt "<brief>"` (default OpenCode, or the agent I named), report the worktree id and the agent handle, and stop. Do not wait.
- Give a worker that edits code its own worktree. A read-only worker, such as a code review, runs in the current worktree and reads the live files. Uncommitted changes are visible to it with no commit or patch.
- Report every worker's worktree id and terminal handle when you dispatch and when you collect.
- Run mechanical follow-ups directly in this session instead of dispatching workers: `git push`, `gh pr create`, issue label/close/comment commands, and one-line nit applications. Workers are for code changes, reviews, and parallel fan-out.
- Every brief for a worker that opens a PR must include a verification step: `git log <base>..HEAD` shows only the intended commits before `gh pr create`. This catches rebase-merged base branches and stale stacks that would pollute the PR with already-merged changes.
- In-session subagents are for quick read-only lookups only. Do not use them for code reviews or for the parallel work above.

## When Reviewing Code or Suggesting Changes

- Present 2-3 options (including "do nothing") with effort/risk/impact tradeoffs
- Give an opinionated recommendation mapped to my preferences
- Ask before proceeding - don't assume my priorities on timeline or scale

## Commits

- Always use conventional commits (we use them for release please).
- **Check `git status` before starting any work that will produce a commit.** If uncommitted changes exist, surface them and decide before starting - don't let a new task silently bundle a prior task's leftovers.
- **Sync with remote before starting work.** Run `git fetch` alongside `git status`. If behind upstream, propose pulling and show incoming commits. If on a feature branch and `main` has moved, flag it and defer rebase/merge to the user. Skip if no remote.

