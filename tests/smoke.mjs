import { render } from "../js/dist/pele.mjs";
import { createIconResolver, lucideAliases, normalizeIconName } from "../js/src/icons.js";
import { lucideIcons } from "../js/src/lucide-icons.js";

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

// Icons. Pele resolves custom names through the host; the wrapper supplies the same Lucide
// subset as pele.run, with Font Awesome and MDI spellings, and accepts overrides.
if (Object.keys(lucideIcons).length !== 79) {
  throw new Error(`expected 79 bundled icons, found ${Object.keys(lucideIcons).length}`);
}
if (Object.keys(lucideAliases).length !== 31) {
  throw new Error(`expected 31 icon aliases, found ${Object.keys(lucideAliases).length}`);
}

const resolveIcon = createIconResolver();
for (const [name, markup] of Object.entries(lucideIcons)) {
  if (resolveIcon(name) !== markup) throw new Error(`icon ${name} does not resolve`);
}
for (const [alias, target] of Object.entries(lucideAliases)) {
  // `file-alt` is shadowed by the `-alt` variant suffix in the normalization order Pele
  // uses, so it resolves like `file`, not `file-text`.
  if (normalizeIconName(alias) !== alias) continue;
  if (resolveIcon(alias) !== lucideIcons[target]) {
    throw new Error(`icon alias ${alias} does not resolve to ${target}`);
  }
}
if (normalizeIconName("mdi mdi-skull-outline") !== "skull") {
  throw new Error("icon name normalization changed");
}

const iconSource = `
flowchart LR
    a@{ icon: "fa:user", form: "square", label: "User" }
    b@{ icon: "fas fa-twitter", form: "square" }
    c@{ icon: "mdi mdi-skull-outline", form: "square" }
    d@{ icon: "unknown:icon", form: "square" }
    a --> b --> c --> d
`;
const icons = render(iconSource, {}, theme);
if (!icons.ok) throw new Error(`icons failed: ${icons.message}`);

function iconBody(svg, name) {
  const match = new RegExp(
    `<svg class="pele-icon" data-icon="${name}"[^>]*>([\\s\\S]*?)</svg>`,
  ).exec(svg);
  if (match === null) throw new Error(`missing icon ${name}`);
  return match[1];
}

if (!iconBody(icons.svg, "fa:user").startsWith('<path d="M19 21v-2')) {
  throw new Error("fa:user did not resolve to the Lucide user icon");
}
if (!iconBody(icons.svg, "fas fa-twitter").startsWith('<path d="M16 7h.01"')) {
  throw new Error("fas fa-twitter did not resolve to the bird alias");
}
if (!iconBody(icons.svg, "mdi mdi-skull-outline").startsWith('<path d="m12.5 17')) {
  throw new Error("mdi mdi-skull-outline did not resolve to the skull icon");
}
if (iconBody(icons.svg, "unknown:icon") !== "") {
  throw new Error("unknown icon should leave Pele's frame empty");
}

const customIcons = render(
  iconSource,
  {
    icons: {
      "fa:user": '<path id="custom-user"/>',
      house: '<path id="custom-house"/>',
      "acme:thing": '<circle id="custom-thing"/>',
    },
  },
  theme,
);
if (!customIcons.ok) throw new Error(`custom icons failed: ${customIcons.message}`);
if (!iconBody(customIcons.svg, "fa:user").includes('id="custom-user"')) {
  throw new Error("custom icon override was not used");
}
if (!iconBody(customIcons.svg, "fas fa-twitter").startsWith('<path d="M16 7h.01"')) {
  throw new Error("custom icons should not replace unrelated built-ins");
}
const aliasOverride = render(
  'flowchart LR\n    a@{ icon: "fa:home", form: "square" }',
  { icons: { house: '<path id="custom-house"/>' } },
  theme,
);
if (!aliasOverride.ok) throw new Error(`alias override failed: ${aliasOverride.message}`);
if (!iconBody(aliasOverride.svg, "fa:home").includes('id="custom-house"')) {
  throw new Error("override for a canonical name did not win through an alias");
}

console.log("icons", { builtin: icons.ok, custom: customIcons.ok, alias: aliasOverride.ok });
