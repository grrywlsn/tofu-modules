#!/usr/bin/env bash
# Dry-run semantic-release for one module and write a JSON preview file.
# Expects the repo to already be on a simulated post-merge main branch.
#
# Usage: scripts/preview-semantic-release.sh <module> [output.json]
set -euo pipefail

MODULE="${1:?module name required}"
OUTPUT="${2:-preview.json}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "${OUTPUT}" != /* ]]; then
  OUTPUT="${REPO_ROOT}/${OUTPUT}"
fi

if [[ ! -f "${REPO_ROOT}/${MODULE}/versions.tf" ]]; then
  echo "Module ${MODULE} has no versions.tf" >&2
  exit 1
fi

cd "${REPO_ROOT}/${MODULE}"

bash "${REPO_ROOT}/scripts/prepare-semantic-release.sh"

export SEMANTIC_RELEASE_PACKAGE="${MODULE}"

REPO_URL="https://github.com/${GITHUB_REPOSITORY:-grrywlsn/tofu-modules}.git"

LOG_FILE="$(mktemp)"
trap 'rm -f "${LOG_FILE}"' EXIT

# GitHub Actions cannot override GITHUB_EVENT_NAME / GITHUB_REF for child
# processes. Run semantic-release outside the pull_request CI context while
# keeping credentials for git push dry-run verification.
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  git config --global url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
fi

set +e
env -u GITHUB_ACTIONS -u GITHUB_EVENT_NAME -u GITHUB_EVENT_PATH -u GITHUB_REF -u GITHUB_REF_NAME -u GITHUB_HEAD_REF -u GITHUB_BASE_REF \
  npx semantic-release --dry-run --ci false \
  --branches main \
  -r "${REPO_URL}" \
  --tag-format="${MODULE}-v\${version}" \
  >"${LOG_FILE}" 2>&1
SR_STATUS=$?
set -e

node --input-type=module - "${MODULE}" "${OUTPUT}" "${SR_STATUS}" "${LOG_FILE}" <<'NODE'
import { readFileSync, writeFileSync } from "node:fs";

const [module, output, statusCode, logFile] = process.argv.slice(2);
const prTitle = process.env.SEMANTIC_RELEASE_PR_TITLE?.trim() || null;
const prBody = process.env.SEMANTIC_RELEASE_PR_BODY?.trim() || null;
const log = readFileSync(logFile, "utf8");
const lines = log.split("\n");

const stripAnsi = (s) => s.replace(/\u001b\[[0-9;]*m/g, "");

const matchOne = (pattern) => {
  for (const line of lines) {
    const plain = stripAnsi(line);
    const m = plain.match(pattern);
    if (m) return m;
  }
  return null;
};

const currentTagMatch = matchOne(
  /Found git tag ([^\s]+) associated with version ([0-9]+\.[0-9]+\.[0-9]+)/
);
const nextVersionMatch = matchOne(/The next release version is ([0-9]+\.[0-9]+\.[0-9]+)/);
const firstReleaseMatch = matchOne(
  /There is no previous release, the next release version is ([0-9]+\.[0-9]+\.[0-9]+)/
);
const noRelevantChanges = /no relevant changes, so no new version is released/.test(log);
const wrongBranch = matchOne(
  /configured to only publish from (.+?), therefore a new version won.t be published/
);
const behindRemote = /behind the remote one, therefore a new version won't be published/.test(
  log
);
const prBlocked = /triggered by a pull request and therefore a new version won't be published/.test(
  log
);

const commitsSinceMatch = matchOne(
  /Found ([0-9]+) commits for package .+ since last release/
);
const packageCommits = commitsSinceMatch ? Number(commitsSinceMatch[1]) : null;

const analyzedCommits = [];
for (let i = 0; i < lines.length; i++) {
  const plain = stripAnsi(lines[i]);
  const analyzing =
    plain.match(/Analyzing pull request title: (.+)$/) ||
    plain.match(/Analyzing commit: (.+)$/);
  if (!analyzing) continue;
  const subject = analyzing[1].trim();
  let triggersRelease = true;
  let note = null;
  for (let j = i + 1; j < Math.min(i + 6, lines.length); j++) {
    const next = stripAnsi(lines[j]);
    if (next.includes("The commit should not trigger a release")) {
      triggersRelease = false;
      note = "Does not match semantic-release commit-analyzer rules";
      break;
    }
    const releaseType = next.match(/The release type for the commit is ([a-z]+)/);
    if (releaseType) {
      triggersRelease = true;
      note = `Triggers ${releaseType[1]} bump`;
      break;
    }
  }
  analyzedCommits.push({ subject, triggers_release: triggersRelease, note });
}

const releaseTypes = [];
for (const line of lines) {
  const plain = stripAnsi(line);
  const m = plain.match(/The release type for the commit is ([a-z]+)/);
  if (m) releaseTypes.push(m[1]);
}
const bumpRank = { patch: 1, minor: 2, major: 3 };
const bump = releaseTypes.sort((a, b) => bumpRank[b] - bumpRank[a])[0] ?? null;

const currentTag = currentTagMatch?.[1] ?? null;
const currentVersion = currentTagMatch?.[2] ?? null;
const nextVersion = nextVersionMatch?.[1] ?? firstReleaseMatch?.[1] ?? null;
const nextTag = nextVersion ? `${module}-v${nextVersion}` : null;

let outcome = "skip";
let reason = null;

if (nextVersion) {
  outcome = "release";
} else if (wrongBranch) {
  reason = `semantic-release reported branch mismatch (expected \`main\` after merge simulation). CI branch was \`${wrongBranch[1]}\`.`;
} else if (prBlocked) {
  reason =
    "semantic-release treated this as a pull-request run. This should not happen after --ci false; check preview-semantic-release.sh.";
} else if (behindRemote) {
  reason =
    "Git reported the preview branch is behind origin/main (often a token/auth issue during preview). Re-run checks or verify merge simulation.";
} else if (noRelevantChanges || (packageCommits === 0 && !nextVersion)) {
  if (packageCommits === 0) {
    reason =
      "No commits touching this module since the last release tag. Only changes under the module directory count.";
  } else if (analyzedCommits.length === 0) {
    reason = prTitle
      ? `Module files changed, but the pull request title \`${prTitle}\` did not produce a release type.`
      : "Commits touch this module but none were eligible for version analysis.";
  } else {
    const nonReleasing = analyzedCommits.filter((c) => !c.triggers_release);
    const parts = prTitle
      ? [
          "This module changed, but the **pull request title** does not produce a semver bump:",
          `- \`${prTitle}\``,
        ]
      : [
          "Commit(s) touch this module but none produce a semver bump under the angular preset:",
        ];
    if (!prTitle) {
      for (const c of nonReleasing) {
        parts.push(`- \`${c.subject}\``);
      }
    }
    const hints = [];
    const titleToCheck = prTitle ?? nonReleasing[0]?.subject ?? "";
    if (!/^[a-z]+(\([^)]+\))?(!)?:\s+.+/i.test(titleToCheck)) {
      hints.push(
        prTitle
          ? "PR title must follow Conventional Commits — e.g. `fix: …` (patch), `feat: …` (minor), or a `BREAKING CHANGE:` line in the PR description (major)."
          : "Commit message is not Conventional Commits format — use `fix: …` or `fix(module): …` (patch), `feat: …` (minor), or a `BREAKING CHANGE:` footer (major)."
      );
    } else if (/^feat\([^)]+\)!:/.test(titleToCheck) || /^feat!:/.test(titleToCheck)) {
      hints.push(
        "`feat!:` in the title is not enough with the angular preset — add a `BREAKING CHANGE:` line to the PR description."
      );
    } else if (/^(docs|style|chore|refactor|test|ci|build):/i.test(titleToCheck)) {
      hints.push(
        "Non-releasing types (`docs:`, `style:`, `chore:`, etc.) do not bump versions — use `fix:` (patch) or `feat:` (minor)."
      );
    }
    if (hints.length) {
      parts.push("", "**How to fix:**", ...hints.map((h) => `- ${h}`));
    }
    reason = parts.join("\n");
  }
} else if (statusCode !== 0) {
  outcome = "error";
  const errLine =
    lines
      .map(stripAnsi)
      .find((l) => l.includes("› ✘") || l.toLowerCase().includes("error")) ??
    `semantic-release exited with status ${statusCode}`;
  reason = errLine.replace(/^\[[^\]]+\]\s*/, "").trim();
} else {
  reason = "semantic-release completed without proposing a new version.";
}

const result = {
  module,
  outcome,
  release_message_source: prTitle ? "pull_request_title" : "commit_messages",
  pr_title: prTitle,
  current_version: currentVersion,
  current_tag: currentTag,
  next_version: nextVersion,
  next_tag: nextTag,
  bump,
  package_commits_since_release: packageCommits,
  commits: analyzedCommits,
  reason,
};

writeFileSync(output, `${JSON.stringify(result, null, 2)}\n`);

if (outcome === "error") {
  console.error(log);
}
NODE

echo "Wrote ${OUTPUT}"
