#!/usr/bin/env bash
# Simulate the post-merge semantic-release job for one module (default: scaleway-kubernetes).
# Requires Docker. Does not create tags or GitHub releases (dry-run only).
set -euo pipefail

MODULE="${1:-scaleway-kubernetes}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

docker run --rm \
  -v "${REPO_ROOT}:/repo" \
  -w "/repo/${MODULE}" \
  -e "MODULE=${MODULE}" \
  -e "GITHUB_TOKEN=${GITHUB_TOKEN:-dry-run-token}" \
  node:22-bookworm \
  bash -ec '
    set -euo pipefail
    git config --global --add safe.directory /repo

    npm install --no-save \
      semantic-release@22 \
      semantic-release-monorepo@8.0.2 \
      @semantic-release/commit-analyzer \
      @semantic-release/release-notes-generator

    cp ../.releaserc.json .releaserc.json

    export SEMANTIC_RELEASE_PACKAGE="${MODULE}"
    export CI=true

    echo "Running semantic-release dry-run for ${MODULE} on branch $(git -C /repo rev-parse --abbrev-ref HEAD)"
    npx semantic-release --dry-run --tag-format="${MODULE}-v\${version}"
  '
