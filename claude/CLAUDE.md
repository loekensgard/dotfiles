# CLAUDE.md

## Hard constraints

- Read and search files with the built-in file tools, not Bash or Python. Bash and Python need my approval for each call.
- When a test fails, explain what it asserts and why it fails. Change or delete the test only after I confirm that the behavior change is intentional.
- Write documentation in ASD-STE100.
- If your prompt has Orca Task and Dispatch IDs, you are a dispatched worker. Do the task yourself, start no workers, and report with `worker_done`.

## Secrets

- Do not look for credentials. Do not open, print, or search `.env` files, private keys, `.aws/credentials`, `.npmrc`, `.git-credentials`, or similar files. Do not work around the permission rules that block them.
- Plugin and tool state files often contain API keys. Before you open an unknown config or state file, list only its field names: `jq -r 'paths(scalars) | map(tostring) | join(".")' <file>`.
- If a secret surfaces anyway, stop and tell me at once. Give the file and the line, so that I can rotate the credential.
- Do not repeat a secret value in a response, a file, a commit, or a request to an external service.
- Before you store or rotate a secret, or when a script needs one, read `~/.claude/docs/secrets.md`. It holds the 1Password, Keychain, NuGet, and secret map rules.

## Communication

- Be concise and direct. In reports to me, cut grammar to save words.
- Put technical accuracy before agreement. Tell me when I do something wrong, and disagree when you have a reason.
- Use a plain dash "-" instead of an em dash (U+2014).

## Token use

- Filter large command output in the shell (`--jq`, `jq`, `head`).
- Read only the lines that you need from a large file.
- Fetch file contents from `raw.githubusercontent.com`. A rendered GitHub page is mostly navigation.

## Pointers

- Delegation: before you start a code change, a code review, broad research, or work that splits into independent parts, load the `delegation` skill. GLM workers cost nothing; Claude tokens cost money.
- Commits: before you start work that ends in a commit, load the `commits` skill.
- Logfire: before you query Logfire telemetry (logs, traces, exceptions), read `~/.claude/docs/logfire.md`. It holds the project, the schema reference call, and the query rules.
- Code work: before you write or change code, read `~/.claude/docs/engineering.md`. It holds the engineering rules.
- Reviews and suggestions: when I ask for a code review, options, or a suggestion, read `~/.claude/docs/reviews.md`. It holds the options format.
