#!/usr/bin/env bash
# Run semantic-release, retrying transient GitHub pushes.
#
# semantic-release pushes the version tag and then refs/notes/semantic-release,
# and only then creates the GitHub release. A notes push can fail after the tag
# exists. Drop that unpublished tag before the next attempt so the rerun can
# publish instead of treating the tag as an already-completed release.
set -euo pipefail

module="${1:?module name required}"
max_attempts=3

rollback_unpublished_tags() {
  local tag
  while IFS= read -r tag; do
    [[ -n "${tag}" ]] || continue
    [[ "${tag}" == "${module}-v"* ]] || continue
    if gh release view "${tag}" >/dev/null 2>&1; then
      continue
    fi
    echo "Removing unpublished tag ${tag} before retry"
    git tag -d "${tag}" || true
    git push origin ":refs/tags/${tag}" || true
  done < <(git tag -l --points-at HEAD "${module}-v*")
}

attempt=1
while true; do
  if npx semantic-release --tag-format="${module}-v\${version}"; then
    exit 0
  fi
  if [[ "${attempt}" -ge "${max_attempts}" ]]; then
    echo "semantic-release failed after ${max_attempts} attempts" >&2
    exit 1
  fi
  echo "semantic-release failed (attempt ${attempt}/${max_attempts})"
  rollback_unpublished_tags
  sleep $((attempt * 15))
  attempt=$((attempt + 1))
done
