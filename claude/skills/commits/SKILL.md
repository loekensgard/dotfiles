---
name: commits
description: Commit rules for this user: git status and git fetch before the work starts, show uncommitted changes first, Conventional Commits, Co-Authored-By trailers. Use before you start work that ends in a commit, and before each commit.
---

# Commits

- Before work that ends in a commit, run `git status` and `git fetch`. Show me uncommitted changes and let me decide about them first. A new task must not include the changes from an earlier task.
- If the branch is behind its upstream, propose a pull and show the incoming commits. On a feature branch, tell me when `main` has moved, and let me do the rebase or the merge. With no remote, skip the fetch.
- Use Conventional Commits. release-please reads them.
- Add a `Co-Authored-By` trailer only for the model that wrote the change. A commit from OpenCode gets no `noreply@anthropic.com` trailer.
