import { render } from "../js/dist/pele.mjs";

const theme = {
  bg: "#ffffff",
  fg: "#1f2328",
  muted: "#59636e",
  line: "#59636e",
  border: "#1f2328",
  surface: "#f6f8fa",
  "surface-alt": "#eaeef2",
  accent: "#0969da",
  critical: "#cf222e",
  "series-1": "#0969da",
  "series-2": "#1a7f37",
  "series-3": "#9a6700",
  "series-4": "#cf222e",
  "series-5": "#8250df",
  "series-6": "#bf3989",
  "series-7": "#0550ae",
  "series-8": "#116329",
  font: "'DejaVu Sans Mono', 'Liberation Mono', monospace",
  stroke: "1.75px",
  radius: "6px",
  "title-weight": "bold",
  "heading-weight": "bold",
  "bold-weight": "bold",
};

const sources = {
  selection: `
graph TD
    A((Start)) --> B[/Input score/]
    B --> C{Score >= 5?}
    C -->|Yes| D[/Output Pass/]
    C -->|No| E[/Output Fail/]
    D --> F((End))
    E --> F
`,
  sequence: `
flowchart TD
    A((Start)) --> B[/INPUT price1/]
    B --> C[/INPUT price2/]
    C --> D[total = price1 + price2]
    D --> E[/Output total/]
    E --> F((End))
`,
  iteration: `
flowchart TD
    A((Start)) --> B[/INPUT password/]
    B --> C{password != ICT123?}
    C -->|Yes| D[/PRINT: Try again/]
    D --> E[/INPUT password/]
    E --> C
    C -->|No| F[/PRINT: Access granted/]
    F --> G((End))
`,
};

for (const [name, source] of Object.entries(sources)) {
  const result = render(source, { maxWidth: 500 }, theme);
  console.log(name, {
    ok: result.ok,
    width: result.width,
    height: result.height,
    type: result.type,
    mermaidType: result.mermaidType,
    hasVar: result.ok && result.svg.includes("var("),
    hasMix: result.ok && result.svg.includes("color-mix("),
    hasCurrent: result.ok && result.svg.includes("currentColor"),
    hasBackground: result.ok && result.svg.includes('fill="#ffffff"'),
    svgLength: result.ok ? result.svg.length : 0,
  });
  if (result.ok) {
    await Bun.write(`/tmp/opencode/${name}.svg`, result.svg);
  } else {
    console.log(result);
  }
}

// Transparent canvases (`background: none`) must keep decorations that Pele paints with
// the canvas colour: treemap leaf labels, pie labels, arrow markers, sequence-number
// halos, and edge-label backgrounds. The sanitizer maps the internal `--_bg` to the
// opaque `label-bg` colour while leaving the page itself transparent.
const transparent = { ...theme, bg: "transparent", "label-bg": "#ffffff" };
const treemap = render(
  `treemap-beta
    "Frontend"
        "Components": 30
        "Styles": 12
    "Backend"
        "API": 40
        "Database": 18
`,
  {},
  transparent,
);

if (!treemap.ok) throw new Error(`treemap failed: ${treemap.message}`);
if (/class="pele-leaves"[^>]*fill="(?:transparent|none)"/.test(treemap.svg)) {
  throw new Error("treemap leaf labels stayed transparent");
}
if (!/class="pele-leaves"[^>]*fill="#ffffff"/.test(treemap.svg)) {
  throw new Error("treemap leaf labels were not repainted with label-bg");
}
if (/<rect x="0" y="0" width="[\d.]+" height="[\d.]+" fill="#ffffff"\/>/.test(treemap.svg)) {
  throw new Error("transparent canvas gained an opaque background rectangle");
}

const pie = render(
  `pie
    "Writing" : 35
    "Review" : 25
`,
  {},
  transparent,
);
if (!pie.ok) throw new Error(`pie failed: ${pie.message}`);
if (/class="pele-slice-labels"[^>]*fill="(?:transparent|none)"/.test(pie.svg)) {
  throw new Error("pie labels stayed transparent");
}

console.log("transparent canvas", { treemap: treemap.ok, pie: pie.ok });
