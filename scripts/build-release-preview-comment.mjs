#!/usr/bin/env node
/**
 * Build a PR comment body from preview-*.json files.
 * Usage: node scripts/build-release-preview-comment.mjs [directory]
 */
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

const dir = process.argv[2] ?? "previews";
const files = readdirSync(dir)
  .filter((f) => f.endsWith(".json"))
  .sort();

if (files.length === 0) {
  console.log("<!-- release-preview -->\n\n## Release preview\n\n_No releasable module previews were produced._");
  process.exit(0);
}

const previews = files.map((f) =>
  JSON.parse(readFileSync(join(dir, f), "utf8"))
);
previews.sort((a, b) => a.module.localeCompare(b.module));

const lines = [
  "<!-- release-preview -->",
  "",
  "## Release preview",
  "",
  "Predicted **post-merge** module tags from `semantic-release` (dry-run on a simulated merge to `main`).",
  "",
  "| Module | Current | After merge |",
  "| --- | --- | --- |",
];

for (const p of previews) {
  const current = p.current_version ? `\`${p.current_tag ?? `v${p.current_version}`}\`` : "_(none)_";
  let after;
  if (p.outcome === "release" && p.next_version) {
    const bump = p.bump ? ` (${p.bump})` : "";
    after = `**\`${p.next_tag}\`**${bump}`;
  } else if (p.outcome === "error") {
    after = "⚠️ Preview failed";
  } else {
    after = "❌ **No release**";
  }
  lines.push(`| \`${p.module}\` | ${current} | ${after} |`);
}

const skipped = previews.filter((p) => p.outcome !== "release");
if (skipped.length) {
  lines.push("", "### Details");
  for (const p of skipped) {
    lines.push("", `#### \`${p.module}\` — no release`);
    if (p.reason) {
      lines.push("", p.reason);
    }
  }
}

const releasing = previews.filter((p) => p.outcome === "release");
if (releasing.length) {
  lines.push("", "### Releases");
  for (const p of releasing) {
    lines.push(
      "",
      `- **\`${p.module}\`**: \`${p.current_tag ?? "none"}\` → \`${p.next_tag}\`${p.bump ? ` (${p.bump})` : ""}`
    );
  }
}

lines.push(
  "",
  "---",
  "_Update commit messages or PR squash-merge body before merging if the preview is not what you expect._"
);

console.log(lines.join("\n"));
