// Contrast, font, and series behaviour.
//
// Compile with:
//
//   typst compile tests/theme.typ tests/theme.pdf
//
// Every check is an assertion, so a failing build is the test result. The diagrams at the
// end make sure the derived colours survive a real render.
#import "../lib.typ": build-config, css-font, luminance, mermaid

#set page(width: 21cm, height: 29.7cm, margin: 2cm)
#set text(size: 10pt)

// --- helpers -----------------------------------------------------------------------------

#let channel(value) = {
  if value <= 0.03928 { value / 12.92 } else { calc.pow((value + 0.055) / 1.055, 2.4) }
}

#let wcag(color) = {
  let c = rgb(color).components().map(float)
  0.2126 * channel(c.at(0)) + 0.7152 * channel(c.at(1)) + 0.0722 * channel(c.at(2))
}

#let contrast(a, b) = {
  let x = wcag(a)
  let y = wcag(b)
  (calc.max(x, y) + 0.05) / (calc.min(x, y) + 0.05)
}

#let theme-color(config, name) = rgb(config.theme.at(name))

// --- case A: light text on a dark page, default (auto) base theme ------------------------

#let dark-page = (
  font: "DejaVu Sans",
  size: 10pt,
  fill: rgb("#e6edf3"),
  background: rgb("#0d1117"),
)

#let dark = build-config(document: dark-page)

// The preset follows the page instead of defaulting to the light `modern` palette.
#assert.eq(dark.theme.at("bg"), "#0d1117")
#assert.eq(dark.theme.at("label-bg"), "#0d1117")
#assert.eq(dark.theme.at("fg"), "#e6edf3")

// Surfaces and borders are derived from the page, not left at the preset's light values.
#assert(contrast(theme-color(dark, "surface"), rgb("#0d1117")) < 1.6)
#assert(contrast(theme-color(dark, "surface-alt"), rgb("#0d1117")) < 2.2)
#assert(contrast(theme-color(dark, "fg"), theme-color(dark, "surface")) > 7)
#assert(contrast(theme-color(dark, "fg"), theme-color(dark, "surface-alt")) > 6)
#assert(contrast(theme-color(dark, "fg"), theme-color(dark, "border")) > 2)
#assert(contrast(theme-color(dark, "border"), rgb("#0d1117")) > 3)
#assert(luminance(theme-color(dark, "muted")) > luminance(theme-color(dark, "surface")))

// --- case B: explicit dark preset on a light page ---------------------------------------

#let light-page = (
  font: "Libertinus Serif",
  size: 11pt,
  fill: black,
  background: white,
)

#let explicit = build-config(base-theme: "dark", document: light-page)

// An explicit preset keeps its own palette. The page's black text must not leak in.
#assert.eq(explicit.theme.at("bg"), dark.theme.at("bg"))
#assert.eq(explicit.theme.at("fg"), dark.theme.at("fg"))
#assert(luminance(theme-color(explicit, "bg")) < 0.1)
#assert(luminance(theme-color(explicit, "fg")) > 0.8)
#assert(contrast(theme-color(explicit, "fg"), theme-color(explicit, "surface")) > 7)

// --- case C: dark text on a light page, default base theme --------------------------------

#let light = build-config(document: light-page)

#assert(luminance(theme-color(light, "fg")) < 0.2)
#assert(luminance(theme-color(light, "surface")) > 0.85)
#assert(contrast(theme-color(light, "fg"), theme-color(light, "surface")) > 7)
#assert(contrast(theme-color(light, "border"), white) > 3)

// --- low-contrast document text is ignored ------------------------------------------------

#let low-contrast = (..light-page, fill: rgb("#f4f4f4"))
#let guarded = build-config(document: low-contrast)

#assert(luminance(theme-color(guarded, "fg")) < 0.2)

// --- explicit neutral themes win over derived ones ----------------------------------------

#let explicit-neutral = build-config(
  theme: (surface: rgb("#123456"), border: rgb("#654321")),
  document: dark-page,
)

#assert.eq(explicit-neutral.theme.at("surface"), "#123456")
#assert.eq(explicit-neutral.theme.at("border"), "#654321")

// --- font stacks ---------------------------------------------------------------------------

// Font dictionaries (a family with `covers`) must not reach `str()`.
#assert.eq(
  css-font((name: "Libertinus Serif", covers: regex(".*"))),
  "'Libertinus Serif', sans-serif",
)
#assert.eq(
  css-font(("DejaVu Sans", (name: "Libertinus Serif", covers: regex(".*")))),
  "'DejaVu Sans', 'Libertinus Serif', sans-serif",
)
// Generic families are not duplicated.
#assert.eq(css-font(("DejaVu Sans", "sans-serif")), "'DejaVu Sans', sans-serif")
#assert.eq(css-font("Libre Baskerville", fallback: "serif"), "'Libre Baskerville', serif")
#assert.eq(css-font("monospace", fallback: "monospace"), "monospace")

// --- series palettes -----------------------------------------------------------------------

#let cycle = build-config(series: (rgb("#ff0000"), rgb("#00ff00")))

#for index in range(1, 9) {
  let expected = if calc.odd(index) { "#ff0000" } else { "#00ff00" }
  assert.eq(cycle.theme.at("series-" + str(index)), expected)
}

// --- renders -------------------------------------------------------------------------------

= Contrast cases

== Dark page, default base theme

#[
  #set page(fill: rgb("#0d1117"))
  #set text(fill: rgb("#e6edf3"), font: "DejaVu Sans")
  #mermaid("flowchart LR\n    A[Start] --> B[Finish]", width: 60%)
]

== Explicit dark preset on a light page

#[
  #set page(fill: white)
  #set text(fill: black, font: "Libertinus Serif")
  #mermaid(
    "flowchart LR\n    A[Start] --> B[Finish]",
    width: 60%,
    base-theme: "dark",
  )
]
