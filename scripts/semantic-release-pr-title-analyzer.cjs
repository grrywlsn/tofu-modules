/**
 * semantic-release plugin: version bump from PR title (+ optional body), not
 * individual commit messages. Falls back to @semantic-release/commit-analyzer
 * when SEMANTIC_RELEASE_PR_TITLE is unset.
 */
const { analyzeCommits: defaultAnalyzeCommits } = require("@semantic-release/commit-analyzer");

async function analyzeCommits(pluginConfig, context) {
  const { commits, logger } = context;
  const title = process.env.SEMANTIC_RELEASE_PR_TITLE?.trim();

  if (!title) {
    return defaultAnalyzeCommits(pluginConfig, context);
  }

  if (!commits?.length) {
    logger.log("No commits touch this package since the last release.");
    return null;
  }

  const body = process.env.SEMANTIC_RELEASE_PR_BODY?.trim() || "";
  const message = body ? `${title}\n\n${body}` : title;

  logger.log("Analyzing pull request title: %s", title);

  return defaultAnalyzeCommits(pluginConfig, {
    ...context,
    commits: [
      {
        message,
        hash: "pr-title",
        commit: { long: message, short: "pr-title" },
      },
    ],
  });
}

module.exports = { analyzeCommits };
