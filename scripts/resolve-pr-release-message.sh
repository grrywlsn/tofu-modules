#!/usr/bin/env bash
# Resolve SEMANTIC_RELEASE_PR_TITLE and SEMANTIC_RELEASE_PR_BODY for the commit
# at HEAD (or the given SHA). Uses the linked pull request when present.
set -euo pipefail

COMMIT_SHA="${1:-${GITHUB_SHA:-HEAD}}"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"

if [[ "${COMMIT_SHA}" == "HEAD" ]]; then
  COMMIT_SHA="$(git rev-parse HEAD)"
fi

pr_json=""
if command -v gh >/dev/null 2>&1 && [[ -n "${GITHUB_TOKEN:-}" ]]; then
  pr_json="$(gh api "/repos/${REPO}/commits/${COMMIT_SHA}/pulls" --jq '.[0] // empty' 2>/dev/null || true)"
fi

if [[ -n "${pr_json}" && "${pr_json}" != "null" ]]; then
  SEMANTIC_RELEASE_PR_TITLE="$(jq -r '.title' <<<"${pr_json}")"
  SEMANTIC_RELEASE_PR_BODY="$(jq -r '.body // ""' <<<"${pr_json}")"
else
  SEMANTIC_RELEASE_PR_TITLE="$(git log -1 --format=%s "${COMMIT_SHA}")"
  SEMANTIC_RELEASE_PR_BODY="$(git log -1 --format=%b "${COMMIT_SHA}")"
fi

export SEMANTIC_RELEASE_PR_TITLE
export SEMANTIC_RELEASE_PR_BODY
