#!/usr/bin/env bash
# Simulate a squash merge to main using the PR title and body as the commit message.
set -euo pipefail

BASE_SHA="${1:?base sha required}"
HEAD_SHA="${2:?head sha required}"
TITLE="${SEMANTIC_RELEASE_PR_TITLE:?SEMANTIC_RELEASE_PR_TITLE is required}"
BODY="${SEMANTIC_RELEASE_PR_BODY:-}"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git fetch origin "${BASE_SHA}"
git checkout -B main "${BASE_SHA}"
git merge --squash "${HEAD_SHA}"

if [[ -n "${BODY}" ]]; then
  git commit -m "${TITLE}" -m "${BODY}"
else
  git commit -m "${TITLE}"
fi
