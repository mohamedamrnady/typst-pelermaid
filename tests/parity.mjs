// Renders every corpus diagram twice: once through the Typst package (CtxJS) and once with
// Pele's JavaScript bundle, using the config that `build-config()` resolves. Fails unless
// the SVGs are byte-identical.
//
//   cd js && bun install --frozen-lockfile && bun run build
//   bun tests/parity.mjs
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const tests = path.dirname(fileURLToPath(import.meta.url));
const root = path.dirname(tests);
const bundle = path.join(root, "js", "dist", "pele.mjs");

if (!fs.existsSync(bundle)) {
  throw new Error("js/dist/pele.mjs is missing; run `cd js && bun install && bun run build`");
}

const { render } = await import(pathToFileURL(bundle).href);

function typst(expression, inputs = {}) {
  const args = ["eval", "--root", root, "--format", "json"];
  for (const [key, value] of Object.entries(inputs)) {
    args.push("--input", `${key}=${value}`);
  }
  args.push(expression);
  const output = execFileSync("typst", args, {
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
  });
  return JSON.parse(output);
}

// The extension is the source of truth for the preconfigured theme and render options.
const config = typst('{ import "/lib.typ": build-config; build-config() }');

const files = [];
function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full);
    } else if (entry.name.endsWith(".mmd")) {
      files.push(full);
    }
  }
}
walk(path.join(tests, "corpus"));
files.sort();

let failures = 0;

for (const file of files) {
  const rel = "/" + path.relative(root, file).split(path.sep).join("/");
  const source = fs.readFileSync(file, "utf8");
  const expected = render(source, config.options, config.theme);

  if (!expected.ok) {
    console.error(`FAIL ${rel}: Pele: ${expected.message}`);
    failures++;
    continue;
  }

  let actual;
  try {
    actual = typst(
      '{ import "/lib.typ": mermaid-svg; mermaid-svg(read(sys.inputs.file)) }',
      { file: rel },
    );
  } catch (error) {
    const message = error?.stderr ? String(error.stderr).trim() : String(error);
    console.error(`FAIL ${rel}: Typst: ${message}`);
    failures++;
    continue;
  }

  if (actual !== expected.svg) {
    let offset = 0;
    while (offset < actual.length && actual[offset] === expected.svg[offset]) offset++;
    console.error(
      `DIFF ${rel}: first difference at byte ${offset} ` +
        `(package ${actual.length} bytes, Pele ${expected.svg.length} bytes)`,
    );
    failures++;
  } else {
    console.log(`ok   ${rel}`);
  }
}

if (failures > 0) {
  console.error(`${failures} of ${files.length} corpus diagrams differ from Pele`);
  process.exit(1);
}
console.log(`${files.length}/${files.length} corpus diagrams are byte-identical to Pele`);
