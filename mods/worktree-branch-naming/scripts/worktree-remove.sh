#!/usr/bin/env bash
# WorktreeRemove hook: cleanup counterpart to worktree-create.sh. Because a
# WorktreeCreate hook is configured, Claude Code's own `git worktree remove`
# fallback no longer deletes the branch it created (it only knows the path),
# so this hook removes the worktree and its branch itself.
#
# Input (stdin JSON): { "worktree_path": "<absolute path>", ... }
# Exit code (not stdout) decides the outcome: non-zero fails the removal if
# the directory still exists afterward. See
# https://code.claude.com/docs/en/hooks#worktreeremove-input.
set -uo pipefail

input="$(cat)"
path="$(printf '%s' "$input" | jq -r '.worktree_path')"

repo_root=""
branch=""
if git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  common_dir="$(git -C "$path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [ -n "$common_dir" ]; then
    repo_root="$(cd "$common_dir/.." && pwd)"
  fi
  branch="$(git -C "$path" branch --show-current 2>/dev/null || true)"
fi

if [ -n "$repo_root" ]; then
  git -C "$repo_root" worktree remove --force "$path" >&2 2>&1
  status=$?
else
  rm -rf -- "$path"
  status=$?
fi

if [ "$status" -eq 0 ] && [ -n "$branch" ] && [ -n "$repo_root" ]; then
  git -C "$repo_root" branch -D "$branch" >/dev/null 2>&1 || true
fi

exit "$status"
