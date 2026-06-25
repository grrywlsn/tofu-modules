#!/usr/bin/env bash
# Install semantic-release dependencies and the local PR-title plugin in a module
# directory, then copy .releaserc.json.
set -euo pipefail

MODULE_DIR="$(pwd)"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "${MODULE_DIR}" == "${REPO_ROOT}" ]]; then
  echo "Run prepare-semantic-release.sh from a module directory, not the repo root." >&2
  exit 1
fi

npm install --no-save \
  semantic-release@22 \
  semantic-release-monorepo@8.0.2 \
  @semantic-release/commit-analyzer \
  @semantic-release/release-notes-generator \
  @semantic-release/github@10.3.5 \
  "file:${REPO_ROOT}/scripts/semantic-release-pr-title-analyzer"

cp "${REPO_ROOT}/.releaserc.json" "${MODULE_DIR}/.releaserc.json"
