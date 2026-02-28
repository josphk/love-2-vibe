# Project Rules

## Worktree Safety

When working in a git worktree, commit progress after completing each file or batch of files. Never leave large amounts of work uncommitted in a worktree — untracked files are lost if the worktree is cleaned up.

## Git Commits

Never add "Co-Authored-By" lines to commit messages.

## Subagents

**For batch content generation** (wiki modules, documentation series, multi-file prose): the main thread writes files. Use the `/batch-write` skill. Subagents should not be used for content generation — they add complexity without meaningful speed gains.

**For code generation and refactoring**: subagents can write files directly (including via worktree isolation). Code files are smaller and benefit from parallel exploration.
