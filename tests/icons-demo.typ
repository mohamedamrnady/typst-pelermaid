// Icon rendering, using the diagram from the "Icons not displaying on flowchart" issue.
//
//   typst compile --root . tests/icons-demo.typ tests/icons-demo.pdf
//
// Pele asks the host for the SVG markup of names like `fa:user`. Pelermaid answers with
// the Lucide subset that pele.run uses, so the User node draws a person glyph instead of
// an empty square. The second diagram shows the other supported spellings and a custom
// icon supplied through the `icons` dictionary.
#import "../lib.typ": mermaid, mermaid-figure

#set page(width: 24cm, height: auto, margin: 1.5cm)
#set text(font: ("DejaVu Sans",), size: 11pt)

= Icons

== The diagram from the issue

#mermaid("
flowchart LR
    a@{ icon: \"fa:user\", form: \"square\", label: \"User\", pos: \"t\", h: 60 }
    subgraph Platform
    frontend
    backend
    frontend --> |/GET| backend
    end
    c[Rust Vercel\\nEdge Function]
    d[(Supabase)]
    e[Gemini]

    a --> Platform
    backend --> |fetch data| d
    backend --> |auth| d
    backend --> |generate pdf| c
    backend --> |fetch AI responses| e
", width: 100%)

The `User` node uses `icon: "fa:user"`. The icon frame is no longer empty.

== Name spellings and custom icons

#mermaid("
flowchart LR
    a@{ icon: \"fa:user\", form: \"square\", label: \"fa:user\" }
    b@{ icon: \"fas fa-user\", form: \"circle\", label: \"fas fa-user\" }
    c@{ icon: \"mdi mdi-skull-outline\", form: \"square\", label: \"mdi mdi-skull-outline\" }
    d@{ icon: \"fa:home\", form: \"square\", label: \"fa:home → house\" }
    e@{ icon: \"acme:database\", form: \"square\", label: \"custom icon\" }
    a ~~~ b ~~~ c ~~~ d ~~~ e
", width: 100%, icons: (
  // Inner SVG markup, drawn on Pele's 24×24 icon frame. Only pass trusted markup.
  "acme:database": "<ellipse cx=\"12\" cy=\"5\" rx=\"9\" ry=\"3\"/><path d=\"M3 5v14a9 3 0 0 0 18 0V5\"/><path d=\"M3 12a9 3 0 0 0 18 0\"/>",
))

The first four nodes resolve through the bundled Lucide set: `fa:` and `fas ` prefixes are
stripped, and `home` is an alias for `house`. The last node comes from the `icons`
dictionary.
