// Renders one corpus diagram selected with `--input file=tests/corpus/<name>.mmd`.
// Used by tests/compile-corpus.sh to compile each family in isolation.
#import "../lib.typ": mermaid

#let file = sys.inputs.at("file", default: "/tests/corpus/flowchart.mmd")

#set page(width: 21cm, height: 29.7cm, margin: 2cm)
#set text(font: "Libertinus Serif", size: 10pt)

#mermaid(read(file), width: 100%, alt: "Mermaid diagram from " + file)
