// Converts Pele's themeable SVG into SVG that Typst's usvg renderer understands.
//
// Pele emits `var(--pele-*)`, private `var(--_*)` aliases, `color-mix()`, and CSS
// geometry properties. usvg does not implement custom properties or `color-mix`, so
// variables are resolved to literals, rounded-corner geometry is moved to attributes,
// and the selected background is written as a real rectangle.

const ATTRIBUTE_NAMES = ["style", "width", "height", "rx", "ry", "stroke-width"];
const attributePatterns = new Map(
  ATTRIBUTE_NAMES.map((name) => [
    name,
    new RegExp(`(?:^|[\\s<])${name}\\s*=\\s*(?:"([^"]*)"|'([^']*)')`),
  ]),
);
const replacePatterns = new Map(
  ATTRIBUTE_NAMES.map((name) => [
    name,
    new RegExp(`(^|[\\s<])${name}\\s*=\\s*(?:"[^"]*"|'[^']*')`),
  ]),
);

function rootTag(svg) {
  const start = svg.indexOf("<svg");
  if (start < 0) return null;
  const close = svg.indexOf(">", start);
  if (close < 0) return null;
  return { start, close, tag: svg.slice(start, close), end: close + 1 };
}

function attribute(tag, name) {
  const match = attributePatterns.get(name)?.exec(tag);
  return match ? (match[1] ?? match[2]) : undefined;
}

function replaceAttribute(tag, name, replacement) {
  const re = replacePatterns.get(name);
  return re === undefined ? tag : tag.replace(re, (_match, before) => before + replacement);
}

function readDeclarations(text, out, custom = true) {
  for (const declaration of text.split(";")) {
    const at = declaration.indexOf(":");
    if (at < 0) continue;
    const name = declaration.slice(0, at).trim();
    if (!name || (custom !== name.startsWith("--"))) continue;
    out[name] = declaration.slice(at + 1).trim();
  }
}

function fixpoint(vars) {
  const current = { ...vars };
  for (let round = 0; round < 24; round++) {
    const snapshot = { ...current };
    let changed = false;
    for (const name of Object.keys(current)) {
      const next = resolve(current[name], snapshot, 0);
      if (next !== current[name]) {
        current[name] = next;
        changed = true;
      }
    }
    if (!changed) break;
  }
  return current;
}

function rewriteAttributes(svg, vars) {
  let out = "";
  let pos = 0;
  while (true) {
    const open = svg.indexOf('"', pos);
    if (open < 0) {
      out += svg.slice(pos);
      return out;
    }
    const close = svg.indexOf('"', open + 1);
    if (close < 0) {
      out += svg.slice(pos);
      return out;
    }
    out += svg.slice(pos, open + 1);
    const value = svg.slice(open + 1, close);
    out +=
      value.indexOf("var(") < 0 &&
      value.indexOf("color-mix(") < 0 &&
      value.indexOf("currentColor") < 0
        ? value
        : resolve(value, vars, 0);
    out += '"';
    pos = close + 1;
  }
}

function rewriteRootStyle(svg, vars) {
  const root = rootTag(svg);
  if (!root) return svg;
  const style = attribute(root.tag, "style");
  if (style === undefined) return svg;

  let declarations = "";
  for (const declaration of style.split(";")) {
    const at = declaration.indexOf(":");
    if (at < 0) continue;
    const name = declaration.slice(0, at).trim();
    if (!name || name.startsWith("--")) continue;
    declarations += name + ":" + declaration.slice(at + 1).trim() + ";";
  }

  const replacement = `style="${declarations}"`;
  return svg.slice(0, root.start) + replaceAttribute(root.tag, "style", replacement) + svg.slice(root.close);
}

function hoistGeometry(svg) {
  let out = "";
  let rest = svg;
  while (true) {
    const at = rest.indexOf("<rect");
    if (at < 0) {
      out += rest;
      return out;
    }
    out += rest.slice(0, at);
    const close = rest.indexOf(">", at);
    if (close < 0) {
      out += rest.slice(at);
      return out;
    }
    out += hoistRect(rest.slice(at, close + 1));
    rest = rest.slice(close + 1);
  }
}

function hoistRect(tag) {
  const style = attribute(tag, "style");
  if (style === undefined) return tag;

  const geometry = [];
  let rest = "";
  for (const declaration of style.split(";")) {
    const at = declaration.indexOf(":");
    if (at < 0) continue;
    const name = declaration.slice(0, at).trim();
    const value = declaration.slice(at + 1).trim();
    if (name === "rx" || name === "ry") {
      geometry.push([name, value]);
    } else if (name) {
      rest += name + ":" + value + ";";
    }
  }
  if (geometry.length === 0) return tag;

  let out = replaceAttribute(tag, "style", `style="${rest}"`);
  for (const [name, value] of geometry) {
    if (attribute(tag, name) !== undefined) continue;
    const addition = ` ${name}="${value}"`;
    const slash = out.lastIndexOf("/>");
    const close = out.lastIndexOf(">");
    if (slash >= 0) out = out.slice(0, slash) + addition + out.slice(slash);
    else if (close >= 0) out = out.slice(0, close) + addition + out.slice(close);
  }
  return out;
}

// Pele paints several decorations with the canvas colour (`--_bg`): edge labels,
// casings, arrow markers, sequence-number halos, pie labels, treemap leaf text, and node
// interiors. A transparent canvas would make all of those disappear, so when the page is
// transparent they fall back to the opaque `label-bg` colour, which defaults to the preset
// background and can be overridden in the theme. The rest of the drawing stays transparent.
function opaqueCanvas(vars) {
  const background = vars["--pele-bg"] ?? vars["--_bg"];
  if (background === undefined) return vars;
  if (!/^(transparent|none)$/i.test(String(background).trim())) return vars;
  const label = vars["--pele-label-bg"];
  if (label === undefined || /^(transparent|none)$/i.test(String(label).trim())) return vars;

  return { ...vars, "--_bg": label };
}

function addBackground(svg, vars) {
  // Check the user-facing background, not `--_bg`: `opaqueCanvas` may have repointed
  // `--_bg` at `label-bg` while the page itself stays transparent.
  const background = vars["--pele-bg"] ?? vars["--_bg"];
  if (!background) return svg;
  if (/^(transparent|none)$/i.test(background.trim())) return svg;

  const root = rootTag(svg);
  if (!root) return svg;
  const width = attribute(root.tag, "width");
  const height = attribute(root.tag, "height");
  if (width === undefined || height === undefined) return svg;

  const rect = `<rect x="0" y="0" width="${width}" height="${height}" fill="${background}"/>`;
  return svg.slice(0, root.end) + rect + svg.slice(root.end);
}

function addStrokeWidth(svg, vars) {
  const value = vars["--pele-stroke-width"];
  if (!value) return svg;
  if (/^(none|0)$/i.test(value.trim())) return svg;

  const root = rootTag(svg);
  if (!root) return svg;
  if (attribute(root.tag, "stroke-width") !== undefined) return svg;

  const width = value.trim().replace(/px$/i, "");
  const addition = ` stroke-width="${width}"`;
  const tag = root.tag.endsWith("/")
    ? root.tag.slice(0, -1) + addition + "/"
    : root.tag + addition;
  return svg.slice(0, root.start) + tag + svg.slice(root.close);
}

function matchingParen(text) {
  let depth = 1;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === "(") depth++;
    else if (c === ")") {
      depth--;
      if (depth === 0) return i;
    }
  }
  return -1;
}

function splitComma(text) {
  let depth = 0;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === "(") depth++;
    else if (c === ")") depth = Math.max(0, depth - 1);
    else if (c === "," && depth === 0) return [text.slice(0, i), text.slice(i + 1)];
  }
  return [text, undefined];
}

function resolve(text, vars, depth) {
  if (
    depth > 24 ||
    (!text.includes("var(") && !text.includes("color-mix(") && !text.includes("currentColor"))
  ) {
    return text;
  }

  let out = "";
  let rest = text;
  while (rest.length) {
    if (rest.startsWith("var(")) {
      const after = rest.slice(4);
      const quickClose = after.indexOf(")");
      const quickComma = after.indexOf(",");
      if (quickClose >= 0 && (quickComma < 0 || quickComma > quickClose)) {
        const key = after.slice(0, quickClose).trim();
        out += Object.prototype.hasOwnProperty.call(vars, key)
          ? resolve(vars[key], vars, depth + 1)
          : "";
        rest = after.slice(quickClose + 1);
        continue;
      }
      const close = matchingParen(after);
      if (close < 0) {
        out += rest;
        break;
      }
      const inner = after.slice(0, close);
      const [name, fallback] = splitComma(inner);
      const key = name.trim();
      out += Object.prototype.hasOwnProperty.call(vars, key)
        ? resolve(vars[key], vars, depth + 1)
        : (fallback ?? "").trim();
      rest = after.slice(close + 1);
      continue;
    }

    if (rest.startsWith("color-mix(")) {
      const after = rest.slice(10);
      const close = matchingParen(after);
      if (close < 0) {
        out += rest;
        break;
      }
      out += mix(after.slice(0, close), vars, depth + 1);
      rest = after.slice(close + 1);
      continue;
    }

    if (rest.startsWith("currentColor")) {
      out += vars["--_fg"] ?? vars["--pele-fg"] ?? "#000";
      rest = rest.slice("currentColor".length);
      continue;
    }

    out += rest[0];
    rest = rest.slice(1);
  }
  return out;
}

function mix(text, vars, depth) {
  const parts = [];
  let rest = text;
  while (true) {
    const [part, tail] = splitComma(rest);
    parts.push(part);
    if (tail === undefined) break;
    rest = tail;
  }
  if (parts.length === 0) return text;

  const start = parts[0].trim().toLowerCase().startsWith("in ") ? 1 : 0;
  const first = parts[start];
  const second = parts[start + 1];
  if (first === undefined) return text;
  if (second === undefined) return resolve(first, vars, depth);

  const [firstColor, firstWeight] = colorAndWeight(first);
  const [secondColor, secondWeight] = colorAndWeight(second);
  const weightA = firstWeight ?? (secondWeight === undefined ? 50 : 100 - secondWeight);
  const weightB = secondWeight ?? 100 - weightA;

  const a = parseColor(resolve(firstColor, vars, depth));
  if (!a) return resolve(firstColor, vars, depth);
  const b = parseColor(resolve(secondColor, vars, depth));
  if (!b) return resolve(secondColor, vars, depth);
  return formatColor(blend(a, b, weightA, weightB));
}

function colorAndWeight(text) {
  const value = text.trim();
  let weight;
  let end = value.length;
  const percent = value.lastIndexOf("%");
  if (percent >= 0) {
    const prefix = value.slice(0, percent);
    const space = Math.max(prefix.lastIndexOf(" "), prefix.lastIndexOf("\t"), prefix.lastIndexOf("\n"));
    if (space >= 0) {
      const number = Number(prefix.slice(space + 1).trim());
      if (Number.isFinite(number)) {
        weight = number;
        end = space;
      }
    }
  }
  return [value.slice(0, end).trim(), weight];
}

function blend(a, b, aWeight, bWeight) {
  const total = aWeight + bWeight;
  if (total <= 0) return a;
  const aShare = aWeight / total;
  const bShare = bWeight / total;
  const alpha = a.alpha * aShare + b.alpha * bShare;
  if (alpha <= Number.EPSILON) return { red: 0, green: 0, blue: 0, alpha: 0 };
  return {
    red: (a.red * a.alpha * aShare + b.red * b.alpha * bShare) / alpha,
    green: (a.green * a.alpha * aShare + b.green * b.alpha * bShare) / alpha,
    blue: (a.blue * a.alpha * aShare + b.blue * b.alpha * bShare) / alpha,
    alpha,
  };
}

function parseColor(text) {
  const value = text.trim().toLowerCase();
  if (!value || value === "none" || value === "inherit" || value === "initial") return null;
  if (value === "transparent") return { red: 0, green: 0, blue: 0, alpha: 0 };
  if (value.startsWith("#")) return parseHex(value.slice(1));

  const rgb = /^rgba?\((.*)\)$/.exec(value);
  if (rgb) return parseRgb(rgb[1]);
  return namedColor(value);
}

function parseHex(hex) {
  if (!/^[0-9a-f]+$/.test(hex)) return null;
  const channel = (at, width) => {
    const value = width === 1 ? parseInt(hex[at] ?? "0", 16) * 17 : parseInt(hex.slice(at, at + 2) || "0", 16);
    return value / 255;
  };
  if (hex.length === 3 || hex.length === 4) {
    return {
      red: channel(0, 1),
      green: channel(1, 1),
      blue: channel(2, 1),
      alpha: hex.length === 4 ? channel(3, 1) : 1,
    };
  }
  if (hex.length === 6 || hex.length === 8) {
    return {
      red: channel(0, 2),
      green: channel(2, 2),
      blue: channel(4, 2),
      alpha: hex.length === 8 ? channel(6, 2) : 1,
    };
  }
  return null;
}

function parseRgb(inner) {
  const parts = inner.split(",").map((part) => part.trim());
  if (parts.length < 3) return null;
  const channel = (text) => {
    const value = text.endsWith("%") ? Number(text.slice(0, -1)) / 100 : Number(text) / 255;
    return Number.isFinite(value) ? Math.min(1, Math.max(0, value)) : null;
  };
  const red = channel(parts[0]);
  const green = channel(parts[1]);
  const blue = channel(parts[2]);
  if (red === null || green === null || blue === null) return null;
  const alpha = parts[3] === undefined ? 1 : Math.min(1, Math.max(0, Number(parts[3]) || 0));
  return { red, green, blue, alpha };
}

const NAMED_COLORS = {
  black: "000000",
  silver: "c0c0c0",
  gray: "808080",
  grey: "808080",
  white: "ffffff",
  maroon: "800000",
  red: "ff0000",
  purple: "800080",
  fuchsia: "ff00ff",
  green: "008000",
  lime: "00ff00",
  olive: "808000",
  yellow: "ffff00",
  navy: "000080",
  blue: "0000ff",
  teal: "008080",
  aqua: "00ffff",
  cyan: "00ffff",
  orange: "ffa500",
  rebeccapurple: "663399",
};

function namedColor(text) {
  const hex = NAMED_COLORS[text];
  return hex ? parseHex(hex) : null;
}

function formatColor(color) {
  const channel = (value) => Math.round(Math.min(1, Math.max(0, value)) * 255);
  if (color.alpha >= 0.999) {
    return (
      "#" +
      channel(color.red).toString(16).padStart(2, "0") +
      channel(color.green).toString(16).padStart(2, "0") +
      channel(color.blue).toString(16).padStart(2, "0")
    );
  }
  const alpha = Math.round(color.alpha * 1000) / 1000;
  return `rgba(${channel(color.red)},${channel(color.green)},${channel(color.blue)},${alpha})`;
}

export function sanitize(svg, theme = {}) {
  const vars = {};

  const root = rootTag(svg);
  if (root) {
    const style = attribute(root.tag, "style");
    if (style !== undefined) readDeclarations(style, vars, true);
  }

  for (const [key, value] of Object.entries(theme || {})) {
    if (value === null || value === undefined) continue;
    const text = String(value);
    if (key === "stroke") {
      vars["--pele-stroke-width"] = text;
    } else {
      vars[key.startsWith("--") ? key : "--pele-" + key] = text;
    }
  }
  if (!vars["--pele-font-mono"] && vars["--pele-font"]) {
    vars["--pele-font-mono"] = vars["--pele-font"];
  }

  const resolved = opaqueCanvas(fixpoint(vars));
  let out = rewriteAttributes(svg, resolved);
  out = rewriteRootStyle(out, resolved);
  out = hoistGeometry(out);
  out = addStrokeWidth(out, resolved);
  return addBackground(out, resolved);
}
