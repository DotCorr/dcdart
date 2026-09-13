import { existsSync, readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
const site = fileURLToPath(new URL("../", import.meta.url));
const read = (p) => readFileSync(site + p, "utf8");
const release = JSON.parse(read("release.json"));
const registry = read("../core/backend/lib/targets.dart");
const aliases = [...registry.matchAll(/alias: '([^']+)'/g)].map((m) => m[1]);
assert.deepEqual(
  release.targets,
  aliases,
  "Release snapshot must match the target registry",
);
assert.ok(
  read("../core/dcc/bin/dcc.dart").includes(`dcc ${release.version}`),
  "CLI version drift",
);
assert.ok(
  read("../core/dcc/pubspec.yaml").includes(`version: ${release.version}`),
  "Package version drift",
);
for (const page of ["index.html", "docs.html"]) {
  const html = read(page);
  assert.ok(
    html.includes(release.tag),
    `${page} is missing the current release`,
  );
  for (const match of html.matchAll(/https:\/\/github\.com\/DotCorr\/dcdart\/blob\/([^/]+)\/([^"#?<>]+)/g)) {
    if (match[1] === release.tag) {
      assert.ok(existsSync(site + "../" + match[2]),
        `${page} links to a missing release file: ${match[2]}`);
    }
  }
  for (const version of html.matchAll(/v0\.\d+\.\d+/g))
    assert.equal(version[0], release.tag, `${page} has a stale release`);
}
for (const alias of aliases)
  assert.ok(
    read("docs.html").includes(`<code>${alias}</code>`),
    `Docs omit target ${alias}`,
  );
for (const match of registry.matchAll(/triple: '([^']+)'/g)) {
  assert.ok(
    read("docs.html").includes(`<code>${match[1]}</code>`),
    `Docs omit or misstate platform triple ${match[1]}`,
  );
}
for (const match of read("docs.html").matchAll(
  /<code>([a-z]+-(?:x86_64|arm64|aarch64|simulator-arm64))<\/code>/g,
)) {
  assert.ok(
    aliases.includes(match[1]),
    `Docs advertise an unknown target alias ${match[1]}`,
  );
}
if (process.argv.includes("--live")) {
  const gh = (...args) =>
    JSON.parse(
      execFileSync("gh", args, {
        encoding: "utf8",
        maxBuffer: 8 * 1024 * 1024,
      }),
    );
  const latest = gh("api", "repos/DotCorr/dcdart/releases/latest");
  assert.equal(
    latest.tag_name,
    release.tag,
    "A newer GitHub release exists: update the website",
  );
  assert.deepEqual(
    latest.assets
      .filter((a) => /^dcdart-v.*\.(tar\.gz|zip)$/.test(a.name))
      .map((a) => a.name)
      .sort(),
    [...release.releaseAssets].sort(),
    "Native release assets changed: update installation availability",
  );
  for (const name of release.releaseAssets)
    assert.ok(
      latest.assets.some((a) => a.name === name),
      `Published asset missing: ${name}`,
    );
  const content = (repo, p, ref) =>
    Buffer.from(
      gh("api", `repos/DotCorr/${repo}/contents/${p}?ref=${ref}`).content,
      "base64",
    ).toString();
  const publishedRegistry = content(
    "dcdart",
    "core/backend/lib/targets.dart",
    release.tag,
  );
  assert.equal(
    registry,
    publishedRegistry,
    "Local target registry differs from the published release",
  );
  const tap = content("homebrew-tap", "Formula/dcdart.rb", "main");
  assert.ok(
    tap.includes(`version "${release.homebrewVersion}"`),
    "Live Homebrew formula version differs",
  );
  assert.equal(
    release.homebrewVersion,
    release.version,
    "Homebrew update is outstanding",
  );
  const scoop = JSON.parse(
    content("scoop-bucket", "bucket/dcdart.json", "main"),
  );
  assert.equal(scoop.version, release.version, "Live Scoop version differs");
  for (const data of Object.values(scoop.architecture)) {
    const asset = latest.assets.find(
      (a) => a.browser_download_url === data.url,
    );
    assert.ok(asset, "Scoop references a missing asset");
    assert.equal(
      asset.digest,
      `sha256:${data.hash}`,
      "Scoop checksum differs from release asset",
    );
  }
  for (const match of tap.matchAll(/sha256 cellar: :\w+,\s+(\w+): "([^"]+)"/g)) {
    const name = `dcdart-${release.version}.${match[1]}.bottle.tar.gz`;
    const asset = latest.assets.find(a => a.name === name);
    assert.ok(asset, `Homebrew bottle missing: ${name}`);
    assert.equal(asset.digest, `sha256:${match[2]}`, 'Homebrew bottle checksum differs');
  }
  for (const match of tap.matchAll(/url "([^"]+)"\s+sha256 "([^"]+)"/g)) {
    const asset = latest.assets.find(
      (a) => a.browser_download_url === match[1],
    );
    assert.ok(asset, "Homebrew references a missing asset");
    assert.equal(
      asset.digest,
      `sha256:${match[2]}`,
      "Homebrew checksum differs from release asset",
    );
  }
}
console.log(
  `Release ${release.tag}: CLI, ${aliases.length} targets, website${process.argv.includes("--live") ? ", GitHub assets, Homebrew and Scoop" : ""} agree.`,
);
