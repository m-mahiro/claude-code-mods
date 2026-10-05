#!/usr/bin/env bash
# WorktreeCreate hook: replaces Claude Code's default `git worktree add` so the
# new worktree's branch follows a configurable template instead of the
# built-in `worktree-<name>` pattern.
#
# Input (stdin JSON): { "name": "<slug>", "cwd": "<repo root>", ... }
# Output (stdout): the absolute path of the created worktree (see
# https://code.claude.com/docs/en/hooks#worktreecreate-output).
set -euo pipefail

input="$(cat)"
name="$(printf '%s' "$input" | jq -r '.name')"
cwd="$(printf '%s' "$input" | jq -r '.cwd')"

template="${CLAUDE_PLUGIN_OPTION_BRANCH_TEMPLATE:-}"
if [ -z "$template" ]; then
  template='claude/{name}'
fi
branch="${template//\{name\}/${name}}"

base_ref_mode="${CLAUDE_PLUGIN_OPTION_BASE_REF:-fresh}"
if [ "$base_ref_mode" = "head" ]; then
  base="HEAD"
else
  git -C "$cwd" fetch --quiet origin HEAD >/dev/null 2>&1 || true
  base="$(git -C "$cwd" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -z "$base" ]; then
    base="HEAD"
  fi
fi

dir="$cwd/.claude/worktrees/$name"
mkdir -p "$(dirname "$dir")"

if git -C "$cwd" show-ref --verify --quiet "refs/heads/$branch"; then
  # Branch already exists (e.g. a reused worktree name): reuse it rather
  # than failing. This doesn't replicate Claude Code's built-in reuse
  # heuristics (resetting a clean, merged worktree to the default branch).
  git -C "$cwd" worktree add "$dir" "$branch" >&2
else
  git -C "$cwd" worktree add -b "$branch" "$dir" "$base" >&2
fi

echo "$dir"
