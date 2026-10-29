// Typography and measurement matrix.
//
// Verifies that diagrams pick up the document font, size, foreground, and page fill in
// both measurement modes, including a font that is not installed. Compile with:
//
//   typst compile tests/fonts.typ tests/fonts.pdf
//
// `typst fonts` should list DejaVu Sans, DejaVu Sans Mono, and Libertinus Serif. The
// "missing font" section intentionally requests a family that is not installed; Typst
// prints a warning and falls back to its default, which is the behaviour under test.
#import "../lib.typ": mermaid, mermaid-result

#set page(width: 21cm, height: 29.7cm, margin: 2cm, fill: rgb("#f7f7f5"))
#set text(size: 10pt)

#let source = "
flowchart LR
    A[Start] --> B[Measure this label]
"

= Font matrix

Each face is rendered in both measurement modes. `measure: "auto"` is tuned for
proportional text; with a monospace face it can underestimate widths, which is the
documented trade-off and is visible in the "DejaVu Sans Mono, measure: auto" row.

#for font in ("DejaVu Sans", "Libertinus Serif", "DejaVu Sans Mono") {
  for measure in ("auto", "mono") {
    set text(font: font)
    heading(level: 2)[#font, measure: #measure]
    mermaid(source, width: 100%, measure: measure, document-context: true)
  }
}

== Missing font

A missing family should warn and fall back, not crash or produce empty text.

#[
  #set text(font: ("Pelermaid Font That Does Not Exist", "DejaVu Sans"))
  #mermaid(source, width: 100%, measure: "auto", document-context: true)
]

== Explicit font and size override the document

#[
  #set text(font: "Libertinus Serif", size: 18pt)
  // A monospace face with `measure: "mono"` uses exact 0.6em advances.
  #mermaid(source, width: 100%, font: ("DejaVu Sans Mono",), font-size: 13pt, measure: "mono")
]

== Page fill becomes the diagram background

#[
  #set page(fill: rgb("#101820"))
  #set text(fill: rgb("#f2f2f2"))
  #mermaid(source, width: 100%, document-context: true)
  #pagebreak()
  #set page(fill: auto)
  #set text(fill: black)
]

== Measurements

#for measure in ("auto", "mono") [
  #let result = mermaid-result(source, measure: measure)
  #measure: #if result.ok [#result.width × #result.height] else [#result.message] \
]
