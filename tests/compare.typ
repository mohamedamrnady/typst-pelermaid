// Side-by-side comparison of the two corpora: diagrams rendered at Typst compile time
// through CtxJS, and the SVGs that Pele itself generated ahead of time with
// `bun tests/prerender.mjs`.
//
// Each row uses the same source, font, and colours, so the images should be identical.
// The caption also compares the two SVG strings byte for byte.
//
//   typst compile --root . tests/compare.typ
#import "/lib.typ": mermaid-svg

#set page(width: 21cm, height: 29.7cm, margin: 1.8cm)
#set text(font: "DejaVu Sans", size: 10pt)
#set par(justify: false)
#set heading(numbering: none)

#let entries = json("prerendered/manifest.json")

// Runtime rendering: the same configuration as `tests/prerender.mjs`.
#let runtime-svgs = entries.map(entry => mermaid-svg(
  read(entry.source),
  base-theme: "modern",
  font: ("Libertinus Serif",),
  background: rgb("#ffffff"),
  foreground: rgb("#1f2328"),
  measure: "auto",
))

#let stored-svgs = entries.map(entry => read("prerendered/" + entry.file))
#let matches = range(entries.len()).filter(i => runtime-svgs.at(i) == stored-svgs.at(i))
#let differing = range(entries.len()).filter(i => runtime-svgs.at(i) != stored-svgs.at(i))

= Runtime vs. pre-rendered

Both corpora draw the same 37 diagrams from the same sources. The left column is rendered
inside Typst by CtxJS; the right column embeds the SVGs generated ahead of time under
`tests/prerendered/`. Those files come from Pele's own JavaScript bundle
(`bun tests/prerender.mjs`), so this document checks that the Typst package and the
standalone renderer agree.

#let identical = matches.len()
#let total = entries.len()
#block(
  inset: 8pt,
  radius: 4pt,
  fill: if identical == total { rgb("#f0fdf4") } else { rgb("#fff5f5") },
  stroke: 0.5pt + if identical == total { rgb("#1a7f37") } else { rgb("#cf222e") },
)[
  *#identical of #total SVGs are byte-identical.*
  #if differing.len() > 0 [
    Differing: #differing.map(i => entries.at(i).name).join(", ").
  ]
]

// Machine-readable summary so CI can fail when the two renderers drift apart.
#context [#metadata((
  total: total,
  identical: identical,
  differing: differing.map(i => entries.at(i).name),
)) <comparison>]

#let cell(entry, svg, label) = {
  let width = calc.min(7.9cm, 7.0cm * entry.width / entry.height)
  [
    #align(center)[
      #text(size: 8pt, fill: luma(110))[#label]
      #block(height: 0.2cm)
      #image(
        bytes(svg),
        format: "svg",
        width: width,
        alt: label + " rendering of the " + entry.type + " diagram " + entry.name,
      )
    ]
  ]
}

#for (index, entry) in entries.enumerate() [
  #heading(level: 2, entry.name)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 0.6cm,
    cell(entry, runtime-svgs.at(index), "Runtime (CtxJS)"),
    cell(entry, stored-svgs.at(index), "Pre-rendered (Pele)"),
  )
  #v(0.15cm)
  #text(size: 8.5pt, fill: luma(90))[
    Pele #entry.type · #entry.width × #entry.height px · source #raw(entry.source) ·
    #if runtime-svgs.at(index) == stored-svgs.at(index) [
      #text(fill: rgb("#1a7f37"))[identical]
    ] else [
      #text(fill: rgb("#cf222e"))[differs]
    ]
  ]
]
