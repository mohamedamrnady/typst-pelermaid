// Icon resolution through the bundled Lucide subset and the `icons` dictionary.
//
// Compile with:
//
//   typst compile tests/icons.typ tests/icons.pdf
//
// Every check is an assertion, so a failing build is the test result.
#import "../lib.typ": mermaid, mermaid-figure, mermaid-svg

#set page(width: 16cm, height: auto, margin: 1cm)
#set text(font: "DejaVu Sans", size: 10pt)

// --- bundled icons -------------------------------------------------------------------------

#let user = mermaid-svg("flowchart LR\n    a@{ icon: \"fa:user\", form: \"square\", label: \"User\" }")
#assert(user.contains("data-icon=\"fa:user\""))
#assert(user.contains("M19 21v-2a4 4 0 0 0-4-4H9"))

#let twitter = mermaid-svg("flowchart LR\n    a@{ icon: \"fas fa-twitter\", form: \"square\" }")
#assert(twitter.contains("data-icon=\"fas fa-twitter\""))
#assert(twitter.contains("M16 7h.01"))

#let skull = mermaid-svg("flowchart LR\n    a@{ icon: \"mdi mdi-skull-outline\", form: \"square\" }")
#assert(skull.contains("data-icon=\"mdi mdi-skull-outline\""))
#assert(skull.contains("m12.5 17-.5-1"))

#let unknown = mermaid-svg("flowchart LR\n    a@{ icon: \"unknown:icon\", form: \"square\" }")
#assert(unknown.contains("data-icon=\"unknown:icon\""))

// --- custom icons --------------------------------------------------------------------------

#let custom = mermaid-svg(
  "flowchart LR\n    a@{ icon: \"acme:database\", form: \"square\" }",
  icons: ("acme:database": "<ellipse cx=\"12\" cy=\"5\" rx=\"9\" ry=\"3\"/>"),
)
#assert(custom.contains("data-icon=\"acme:database\""))
#assert(custom.contains("ellipse cx=\"12\" cy=\"5\" rx=\"9\" ry=\"3\""))

// Custom entries win over the bundled glyph, including when the requested name goes through
// an alias (`fa:home` -> house).
#let overridden = mermaid-svg(
  "flowchart LR\n    a@{ icon: \"fa:home\", form: \"square\" }",
  icons: ("house": "<path id=\"custom-house\"/>"),
)
#assert(overridden.contains("id=\"custom-house\""))

// The dictionary is also accepted through `options`, for parity with the named argument.
#let via-options = mermaid-svg(
  "flowchart LR\n    a@{ icon: \"acme:thing\", form: \"square\" }",
  options: (icons: ("acme:thing": "<circle id=\"custom-thing\" r=\"9\"/>")),
)
#assert(via-options.contains("id=\"custom-thing\""))

= Icons

#mermaid("flowchart LR\n    a@{ icon: \"fa:user\", form: \"square\", label: \"User\" } --> b[Next]")

// `mermaid-figure` forwards the dictionary through its trailing arguments. The custom icon
// has visible geometry so the figure is not an empty frame.
#mermaid-figure(
  "flowchart LR\n    a@{ icon: \"acme:figure\", form: \"square\", label: \"Figure\" }",
  icons: (
    "acme:figure": "<circle cx=\"12\" cy=\"12\" r=\"8\"/><path d=\"M8 12h8M12 8v8\"/>",
  ),
  caption: [An icon inside a figure],
)
