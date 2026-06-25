#!/usr/bin/env bash
# Simulate the post-merge semantic-release job for one module (default: scaleway-kubernetes).
# Requires Docker. Does not create tags or GitHub releases (dry-run only).
#
# Usage:
#   ./scripts/test-semantic-release.sh [module]
#   ./scripts/test-semantic-release.sh scaleway-kubernetes --simulate-main
#
# The script copies the repo into a container workspace so git state on the host
# is never modified. Without GITHUB_TOKEN, a dry-run on main may fail at the git
# push verification step; that still confirms config and package.json are correct.
set -euo pipefail

MODULE="${1:-scaleway-kubernetes}"
SIMULATE_MAIN=false
if [[ "${2:-}" == "--simulate-main" ]]; then
  SIMULATE_MAIN=true
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_BRANCH="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD)"

docker run --rm \
  -v "${REPO_ROOT}:/src:ro" \
  -e "MODULE=${MODULE}" \
  -e "SIMULATE_MAIN=${SIMULATE_MAIN}" \
  -e "SOURCE_BRANCH=${SOURCE_BRANCH}" \
  -e "GITHUB_TOKEN=${GITHUB_TOKEN:-dry-run-token}" \
  node:24-bookworm \
  bash -ec '
    set -euo pipefail
    cp -a /src /repo
    cd /repo
    git config --global --add safe.directory /repo

    if [[ "${SIMULATE_MAIN}" == "true" ]]; then
      git checkout -f main -q
      git show "${SOURCE_BRANCH}:.releaserc.json" > .releaserc.json
      git show "${SOURCE_BRANCH}:${MODULE}/package.json" > "${MODULE}/package.json"
      TARGET_BRANCH=main
    else
      TARGET_BRANCH="${SOURCE_BRANCH}"
    fi

    cd "${MODULE}"
    npm install --no-save \
      semantic-release@22 \
      semantic-release-monorepo@8.0.2 \
      @semantic-release/commit-analyzer \
      @semantic-release/release-notes-generator \
      @semantic-release/github@10.3.5

    bash ../scripts/prepare-semantic-release.sh

    export SEMANTIC_RELEASE_PACKAGE="${MODULE}"
    export CI=true

    echo "Running semantic-release dry-run for ${MODULE} (branch: ${TARGET_BRANCH})"
    set +e
    OUTPUT=$(npx semantic-release --dry-run --tag-format="${MODULE}-v\${version}" 2>&1)
    STATUS=$?
    set -e
    printf "%s\n" "${OUTPUT}"

    if grep -q "ReferenceError: name is not defined" <<< "${OUTPUT}"; then
      echo "FAIL: invalid tagFormat in .releaserc.json" >&2
      exit 1
    fi
    if grep -q "ENOENT: no such file or directory, open .*package.json" <<< "${OUTPUT}"; then
      echo "FAIL: module package.json missing" >&2
      exit 1
    fi
    if grep -q "Cannot find module '\''semantic-release-monorepo'\''" <<< "${OUTPUT}"; then
      echo "FAIL: semantic-release-monorepo not installed/resolvable" >&2
      exit 1
    fi
    if grep -q "only publish from main" <<< "${OUTPUT}"; then
      echo "OK: config loaded; skipped because not on main (expected without --simulate-main)"
      exit 0
    fi
    if grep -q "EGITNOPERMISSION" <<< "${OUTPUT}"; then
      echo "OK: release pipeline reached git push verification (set GITHUB_TOKEN to go further)"
      exit 0
    fi
    if grep -q "Run automated release from branch main" <<< "${OUTPUT}"; then
      echo "OK: release pipeline started on main"
      exit 0
    fi

    exit "${STATUS}"
  '
