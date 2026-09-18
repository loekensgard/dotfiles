# Secrets and agent shells

- `op` (1Password CLI) does not work from agent shells. Each shell call is a separate process with no `OP_SESSION_*`, and the sandbox blocks the 1Password app-integration socket. Never call `op` from a script or a tool call. Ask the user to run it in their own terminal.
- Multiple `op` accounts are registered. When you give the user an `op` command, include `--account <account>`, or the `op://` reference does not resolve.
- The account URLs, vaults, item titles, and Keychain services for this machine live in `~/.claude/rules/secret-map.local.md`. That file holds locations only, never secret values. If those values are missing from the context, read that file. If a value you need is not in it, ask the user. Never guess an account, vault, or item name.
- Any secret that an agent-invoked script needs lives in the macOS Keychain, not behind `op read`. `security find-generic-password -s <service> -a "$USER" -w` works non-interactively from agent shells, including hooks.
- To store or rotate a Keychain secret, run `security add-generic-password -s <service> -a "$USER" -U -w` and paste the value at the hidden prompt. `-U` updates in place. Do not put the value on the command line, and never paste a secret into the chat.
- Each `!` command runs in its own shell. `export FOO=...` on one line is gone by the next line. Keep multi-step secret handling in one command or a script.

## NuGet restore failures

- .NET builds and tests restore from a private NuGet feed. `~/.zshrc` populates the feed PAT from 1Password. The secret map names the account and item.
- If a build or a test fails with `NuGet.targets ... Value cannot be null or empty string. (Parameter 'password')`, 1Password is not signed in. Ask the user to run `op signin --account <account>` in their own terminal. After the user confirms sign-in, re-source `~/.zshrc` or open a fresh shell, then retry. If it still fails, the agent shell cannot see the session at all, and the PAT must move to the Keychain.
