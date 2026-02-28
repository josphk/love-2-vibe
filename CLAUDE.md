# Project Rules

## Worktree Safety

When working in a git worktree, commit progress after completing each file or batch of files. Never leave large amounts of work uncommitted in a worktree — untracked files are lost if the worktree is cleaned up.

## Git Commits

Never add "Co-Authored-By" lines to commit messages.

## Subagents

Subagents can be used for research (searching, reading files, web fetches) and for generating content in their response, but the main thread should be the one that actually writes files to disk. This avoids subagents getting blocked on permissions silently and burning through usage limits.
