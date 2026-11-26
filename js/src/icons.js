import { lucideIcons } from "./lucide-icons.js";

// Names from other icon sets, for the Lucide icon that stands in for them. This mirrors
// Pele's website resolver (website/src/lib/icons.ts) at Pele 1.12.0: 31 aliases.
export const lucideAliases = {
  spinner: "loader",
  twitter: "bird",
  home: "house",
  cog: "settings",
  gear: "settings",
  times: "x",
  close: "x",
  edit: "pencil",
  envelope: "mail",
  trash: "trash-2",
  warning: "triangle-alert",
  "exclamation-triangle": "triangle-alert",
  "check-circle": "circle-check",
  question: "circle-question-mark",
  "question-circle": "circle-question-mark",
  "user-circle": "circle-user",
  "info-circle": "info",
  bolt: "zap",
  comment: "message-circle",
  bars: "menu",
  "map-marker": "map-pin",
  refresh: "refresh-cw",
  sync: "refresh-cw",
  "bar-chart": "chart-bar",
  "pie-chart": "chart-pie",
  mobile: "smartphone",
  "file-alt": "file-text",
  "lightbulb-o": "lightbulb",
  cube: "box",
  microchip: "cpu",
  hdd: "hard-drive",
};

// Accept the spellings Mermaid examples use for Font Awesome and Material Design Icons:
// `fa:fa-car`, `fas fa-car`, `fa-car`, and `mdi mdi-skull-outline` all normalize to `car`
// and `skull`.
export function normalizeIconName(name) {
  return String(name)
    .toLowerCase()
    .replace(/^(?:fa[bklrs]?|mdi)[: ]\s*/, "")
    .replace(/^(?:fa|mdi)-/, "")
    .replace(/-(?:outline|bold|solid|regular|retro|alt|o)$/, "");
}

function normalizeOverrides(overrides) {
  const custom = new Map();
  if (overrides === null || typeof overrides !== "object" || Array.isArray(overrides)) {
    return custom;
  }
  for (const [name, markup] of Object.entries(overrides)) {
    if (typeof markup !== "string" || markup === "") continue;
    custom.set(normalizeIconName(name), markup);
  }
  return custom;
}

// Pele asks the host for the inner SVG markup of an icon. Unknown names return undefined,
// which Pele turns into an empty icon frame. Custom entries win over the bundled Lucide set;
// they are written by the document author and Pele inserts them without filtering.
export function createIconResolver(overrides) {
  const custom = normalizeOverrides(overrides);
  return (name) => {
    const key = normalizeIconName(name);
    if (custom.has(key)) return custom.get(key);
    const target = lucideAliases[key];
    if (target !== undefined && custom.has(target)) return custom.get(target);
    return lucideIcons[target ?? key];
  };
}
