# Secret handling

## 1Password

- `op` (1Password CLI) does not work from agent shells. Each shell call is a separate process with no `OP_SESSION_*`, and the sandbox blocks the 1Password app-integration socket. Never call `op` from a script or a tool call. Ask the user to run it in their own terminal.
- Multiple `op` accounts are registered. When you give the user an `op` command, include `--account <account>`, or the `op://` reference does not resolve.

## Keychain

- Any secret that an agent-invoked script needs lives in the macOS Keychain, not behind `op read`. `security find-generic-password -s <service> -a "$USER" -w` works non-interactively from agent shells, including hooks.
- To store or rotate a Keychain secret, run `security add-generic-password -s <service> -a "$USER" -U -w` and paste the value at the hidden prompt. `-U` updates in place. Do not put the value on the command line, and never paste a secret into the chat.
- Each `!` command runs in its own shell. `export FOO=...` on one line is gone by the next line. Keep multi-step secret handling in one command or a script.

## Secret map

- The account URLs, vaults, item titles, and Keychain services for this machine live in `~/.claude/rules/secret-map.local.md`. That file holds locations only, never secret values. If those values are missing from the context, read that file. If a value you need is not in it, ask the user. Never guess an account, vault, or item name.

## NuGet restore failures

- .NET builds and tests restore from a private NuGet feed. `~/.zshenv` exports the feed PAT from the Keychain, so every zsh gets it, also non-interactive and agent shells. The secret map names the Keychain service.
- If a build or a test fails with `NuGet.targets ... Value cannot be null or empty string. (Parameter 'password')`, the Keychain item is missing or the shell started before it existed. Ask the user to store or rotate it with the command in the secret map. Then restart the shell or the terminal and retry. A `401` from the feed means the PAT expired: rotate it the same way.
