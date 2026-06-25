#!/usr/bin/env bash
# Copy shared semantic-release config and install the local PR-title plugin.
# Run from <module>/ after the core semantic-release packages are installed.
set -euo pipefail

MODULE_DIR="$(pwd)"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "${MODULE_DIR}" == "${REPO_ROOT}" ]]; then
  echo "Run prepare-semantic-release.sh from a module directory, not the repo root." >&2
  exit 1
fi

cp "${REPO_ROOT}/.releaserc.json" "${MODULE_DIR}/.releaserc.json"
npm install --no-save "file:${REPO_ROOT}/scripts/semantic-release-pr-title-analyzer"
