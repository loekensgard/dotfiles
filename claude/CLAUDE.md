# CLAUDE.md

## Hard constraints

- Read and search files with the built-in file tools, not Bash or Python. Bash and Python need my approval for each call.
- When a test fails, explain what it asserts and why it fails. Change or delete the test only after I confirm that the behavior change is intentional.
- Write documentation in ASD-STE100.

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
