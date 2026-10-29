// Embeds SVGs produced directly by Pele's JavaScript renderer, without running CtxJS or
// any JavaScript during Typst compilation.
//
// Regenerate the SVG files and manifest with:
//
//   bun tests/prerender.mjs
//
// The generated files are not committed. Compile after regenerating them:
//
//   typst compile tests/prerendered.typ
#set page(width: 21cm, height: 29.7cm, margin: 1.8cm)
#set text(font: "DejaVu Sans", size: 10pt)

= Pre-rendered corpus

These diagrams were rendered by Pele itself (`bun tests/prerender.mjs`) and embedded as
standalone SVG files. Typst only decodes the generated files; no JavaScript runtime is
involved in this document.

#let entries = json("prerendered/manifest.json")

#for entry in entries [
  #heading(level: 2, entry.name)
  // Cap the width at the text block and the height at 21cm so tall diagrams keep their
  // heading and caption on the same page.
  #let width = calc.min(17.4cm, 21cm * entry.width / entry.height)
  #image(
    read("prerendered/" + entry.file, encoding: none),
    format: "svg",
    width: width,
    alt: "Pre-rendered Mermaid " + entry.type + " diagram",
  )
  #text(size: 9pt, fill: luma(100))[
    Pele #entry.type · #entry.width × #entry.height px · source #entry.source
  ]
]
