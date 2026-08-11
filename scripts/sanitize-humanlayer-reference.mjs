import { readFile, writeFile } from "node:fs/promises";

const referenceUrl = new URL("../humanlayer-task-reference.html", import.meta.url);
const replacementsUrl = new URL("./private-replacements.tsv", import.meta.url);
let html = await readFile(referenceUrl, "utf8");

try {
  const replacements = await readFile(replacementsUrl, "utf8");

  for (const [index, line] of replacements.split(/\r?\n/).entries()) {
    if (line.trim() === "" || line.trimStart().startsWith("#")) continue;

    const separator = line.indexOf("\t");
    if (separator < 1) {
      throw new Error(`Invalid private replacement on line ${index + 1}`);
    }

    const source = line.slice(0, separator);
    const replacement = line.slice(separator + 1);
    html = html.replaceAll(source, replacement);
  }
} catch (error) {
  if (error?.code !== "ENOENT") throw error;
}

const uuidMap = new Map();
const uuidPattern = /\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi;
html = html.replace(uuidPattern, (uuid) => {
  if (uuid.startsWith("00000000-0000-4000-8000-")) return uuid;

  if (!uuidMap.has(uuid)) {
    const sequence = String(uuidMap.size + 1).padStart(12, "0");
    uuidMap.set(uuid, `00000000-0000-4000-8000-${sequence}`);
  }

  return uuidMap.get(uuid);
});

html = html.replace(
  /<!-- Static HumanLayer capture\.[\s\S]*? -->/,
  "<!-- Sanitized HumanLayer task fixture. Production DOM and CSS; neutral mock content; no application scripts. -->",
);
html = html.replace(/(<a\b[^>]*?\bhref=)["'][^"']*["']/gi, '$1"#"');
html = html.replace(/[ \t]+$/gm, "");

const blockedPatterns = [
  ["email address", /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i],
  ["macOS home path", /\/Users\/[^/\s"'<>]+/i],
  ["Linux home path", /\/home\/[^/\s"'<>]+/i],
  ["live HumanLayer navigation URL", /app\.humanlayer\.com\/(?:tasks|sessions)\//i],
  ["external resource URL", /(?:src|href)=["']https?:\/\//i],
  ["non-demo ticket identifier", /\b(?!(?:DEMO|UTF)-\d+\b)[A-Z][A-Z0-9]{1,9}-\d+\b/],
  [
    "credential-like value",
    /(github_pat_|gh[pousr]_|AKIA[0-9A-Z]{16}|sk-(?:live|test|proj|ant)-|xox[baprs]-|-----BEGIN [A-Z ]*PRIVATE KEY-----)/i,
  ],
];

const remaining = blockedPatterns
  .filter(([, pattern]) => pattern.test(html))
  .map(([label]) => label);
if (remaining.length > 0) {
  throw new Error(`Potential private capture data remains: ${remaining.join(", ")}`);
}

await writeFile(referenceUrl, html);
console.log(
  `Sanitized HumanLayer reference: ${uuidMap.size} identifiers replaced and all navigation links disabled.`,
);
