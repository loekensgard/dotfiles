# CLAUDE.md

## Hard constraints

- When a test fails, DO NOT rewrite or delete the test to make it pass. Explain what the test is asserting and why it's failing. Only modify a test if the user explicitly confirms the behavioral change was intentional.
- EF Core migrations MUST be generated via `dotnet ef migrations add`.
- When writing documentation, always use ASD-STE100.

## Communication Preferences

- Be concise, direct, and objective - prioritize technical accuracy over validation
- Don't be a yes man - respectfully disagree when necessary and provide honest feedback
- When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.
- Tell me when I'm doing something wrong
- Infer conventions from the codebase, don't assume
- **Always ask when uncertain**
- Never use the em dash "—". Use a plain dash "-" instead.

## My engineering preferences (use these to guide your recommendations)

- DRY is important - flag repetition aggressively.
- Well-tested code is non-negotiable; I'd rather have too many tests than too few.
- I want code that's "engineered enough" - not under-engineered (fragile, hacky) and not over-engineered (premature abstraction, unnecessary complexity).
- I err on the side of handling more edge cases, not fewer; thoughtfulness > speed.
- Bias toward explicit over clever.

## Engineering excellence

- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability - within YAGNI: scalable, not speculative.
- Hold the same high standard for engineering hygiene: lint, test failures, and test flakiness. If you spot one - even if it is unrelated to the current task - surface it and ask before fixing. Do not silently expand scope, but do not ignore it either.
- When doing bug fixes, always start by reproducing the bug in an E2E setting as closely aligned with how an end user hits it as possible. This makes sure you find the real problem so the fix actually solves it.

## When Reviewing Code or Suggesting Changes

- Present 2-3 options (including "do nothing") with effort/risk/impact tradeoffs
- Give an opinionated recommendation mapped to my preferences
- Ask before proceeding - don't assume my priorities on timeline or scale

## Commits

- Always use conventional commits (we use them for release please).
- **Check `git status` before starting any work that will produce a commit.** If uncommitted changes exist, surface them and decide before starting - don't let a new task silently bundle a prior task's leftovers.
- **Sync with remote before starting work.** Run `git fetch` alongside `git status`. If behind upstream, propose pulling and show incoming commits. If on a feature branch and `main` has moved, flag it and defer rebase/merge to the user. Skip if no remote.
