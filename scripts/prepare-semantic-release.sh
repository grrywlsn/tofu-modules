#!/usr/bin/env bash
# Copy shared semantic-release config into the current module directory.
# Run from <module>/ after npm install so the local plugin can resolve deps.
set -euo pipefail

MODULE_DIR="$(pwd)"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "${MODULE_DIR}" == "${REPO_ROOT}" ]]; then
  echo "Run prepare-semantic-release.sh from a module directory, not the repo root." >&2
  exit 1
fi

cp "${REPO_ROOT}/.releaserc.json" "${MODULE_DIR}/.releaserc.json"
cp "${REPO_ROOT}/scripts/semantic-release-pr-title-analyzer.mjs" \
  "${MODULE_DIR}/semantic-release-pr-title-analyzer.mjs"
