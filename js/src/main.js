import { render as peleRender } from "pele";
import { sanitize } from "./sanitize.js";

// Monospace advance is 0.6em for regular text and 1.2em for CJK/wide glyphs. This is only
// accurate for a true monospace face; `measure: "auto"` uses Pele's built-in width table.
const MONO_FONT = "'DejaVu Sans Mono', 'Liberation Mono', monospace";
const PROPORTIONAL_FONT = "'Liberation Sans', 'DejaVu Sans', sans-serif";

function isWide(code) {
  return (
    (code >= 0x1100 && code <= 0x115f) ||
    (code >= 0x2e80 && code <= 0xa4cf) ||
    (code >= 0xac00 && code <= 0xd7a3) ||
    (code >= 0xf900 && code <= 0xfaff) ||
    (code >= 0xfe30 && code <= 0xfe4f) ||
    (code >= 0xff00 && code <= 0xff60) ||
    (code >= 0xffe0 && code <= 0xffe6)
  );
}

function isZeroWidth(code) {
  return (
    (code >= 0x0300 && code <= 0x036f) ||
    (code >= 0x1ab0 && code <= 0x1aff) ||
    (code >= 0x1dc0 && code <= 0x1dff) ||
    (code >= 0x20d0 && code <= 0x20ff) ||
    (code >= 0xfe00 && code <= 0xfe0f) ||
    (code >= 0xfe20 && code <= 0xfe2f) ||
    (code >= 0x200b && code <= 0x200f) ||
    (code >= 0x202a && code <= 0x202e) ||
    (code >= 0x2060 && code <= 0x206f) ||
    code === 0xfeff ||
    code === 0x200d
  );
}

const monoMeasurer = {
  width(text, size) {
    let width = 0;
    for (const character of String(text)) {
      const code = character.codePointAt(0);
      if (isZeroWidth(code) || code < 0x20) continue;
      width += isWide(code) ? 1.2 * size : 0.6 * size;
    }
    return width;
  },
};

function finiteNumber(value, fallback) {
  const number = typeof value === "number" ? value : Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function normalizeOptions(options, theme) {
  const out = { ...(options || {}) };
  const measure = out.measure === "mono" ? "mono" : "auto";
  delete out.measure;

  const themeFont = typeof theme?.font === "string" ? theme.font : undefined;
  const themeMono =
    typeof theme?.["font-mono"] === "string"
      ? theme["font-mono"]
      : typeof theme?.fontMono === "string"
        ? theme.fontMono
        : MONO_FONT;

  out.fontSize = finiteNumber(out.fontSize, 16);
  if (out.fontSize <= 0) out.fontSize = 16;
  out.responsive = out.responsive !== true ? false : true;
  out.links = out.links === true;
  out.images = out.images === true;

  if (measure === "mono") {
    out.measurer = monoMeasurer;
    out.fontFamily = out.fontFamily || themeFont || MONO_FONT;
    out.fontFamilyMono = out.fontFamilyMono || themeMono || MONO_FONT;
  } else {
    delete out.measurer;
    out.fontFamily = out.fontFamily || themeFont || PROPORTIONAL_FONT;
    out.fontFamilyMono = out.fontFamilyMono || themeMono || MONO_FONT;
  }

  if (out.maxWidth !== undefined) {
    out.maxWidth = finiteNumber(out.maxWidth, 0);
    if (!(out.maxWidth > 0)) delete out.maxWidth;
  }
  if (out.directionBreakpoint !== undefined) {
    out.directionBreakpoint = finiteNumber(out.directionBreakpoint, 640);
  }
  if (out.padding !== undefined) out.padding = finiteNumber(out.padding, 0);
  if (out.limit !== undefined) out.limit = finiteNumber(out.limit, 0);
  if (out.outputLimit !== undefined) out.outputLimit = finiteNumber(out.outputLimit, 0);
  if (out.maxEdges !== undefined) out.maxEdges = finiteNumber(out.maxEdges, 0);
  if (out.now === null || out.now === undefined) delete out.now;
  return out;
}

function errorResult(error) {
  const message =
    error && typeof error.message === "string" && error.message
      ? error.message
      : String(error || "unknown render error");
  return {
    ok: false,
    code: typeof error?.code === "string" ? error.code : "error",
    message,
    line: Number.isFinite(error?.line) ? error.line : 0,
    column: Number.isFinite(error?.column) ? error.column : 0,
    snippet: typeof error?.snippet === "string" ? error.snippet : "",
    type: typeof error?.type === "string" ? error.type : null,
    mermaidType: typeof error?.mermaidType === "string" ? error.mermaidType : null,
  };
}

export function render(source, options = {}, theme = {}) {
  const text = String(source ?? "");

  try {
    const opts = normalizeOptions(options, theme);
    const result = peleRender(text, opts);
    const svg = sanitize(result.svg, theme);
    return {
      ok: true,
      svg,
      width: result.width,
      height: result.height,
      type: result.type,
      mermaidType: result.mermaidType,
      links: Array.isArray(result.links) ? result.links.length : 0,
    };
  } catch (error) {
    return errorResult(error);
  }
}
