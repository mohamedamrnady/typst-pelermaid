// Renders every diagram family Pele 1.12.0 supports, plus a few real-world diagrams.
// Each source is also compiled independently by tests/compile-corpus.sh so a failing
// family is easy to isolate.
#import "../lib.typ": mermaid

#set page(width: 21cm, height: 29.7cm, margin: 1.8cm)
#set text(font: "DejaVu Sans", size: 10pt)

#let corpus = (
  (family: "flowchart", file: "corpus/flowchart.mmd"),
  (family: "sequence", file: "corpus/sequence.mmd"),
  (family: "class", file: "corpus/class.mmd"),
  (family: "state", file: "corpus/state.mmd"),
  (family: "er", file: "corpus/er.mmd"),
  (family: "gantt", file: "corpus/gantt.mmd"),
  (family: "pie", file: "corpus/pie.mmd"),
  (family: "mindmap", file: "corpus/mindmap.mmd"),
  (family: "timeline", file: "corpus/timeline.mmd"),
  (family: "journey", file: "corpus/journey.mmd"),
  (family: "quadrant", file: "corpus/quadrant.mmd"),
  (family: "xychart", file: "corpus/xychart.mmd"),
  (family: "gitgraph", file: "corpus/gitgraph.mmd"),
  (family: "sankey", file: "corpus/sankey.mmd"),
  (family: "architecture", file: "corpus/architecture.mmd"),
  (family: "block", file: "corpus/block.mmd"),
  (family: "kanban", file: "corpus/kanban.mmd"),
  (family: "packet", file: "corpus/packet.mmd"),
  (family: "radar", file: "corpus/radar.mmd"),
  (family: "treemap", file: "corpus/treemap.mmd"), // broken
  (family: "c4", file: "corpus/c4.mmd"),
  (family: "requirement", file: "corpus/requirement.mmd"),
  (family: "info", file: "corpus/info.mmd"),
  (family: "agentflow", file: "corpus/agentflow.mmd"),
  (family: "usecase", file: "corpus/usecase.mmd"),
  (family: "railroad", file: "corpus/railroad.mmd"),
  (family: "treeview", file: "corpus/treeview.mmd"),
  (family: "venn", file: "corpus/venn.mmd"),
  (family: "cynefin", file: "corpus/cynefin.mmd"),
  (family: "wardley", file: "corpus/wardley.mmd"),
  (family: "swimlane", file: "corpus/swimlane.mmd"),
  (family: "ishikawa", file: "corpus/ishikawa.mmd"),
  (family: "eventmodeling", file: "corpus/eventmodeling.mmd"),
  (family: "ci-pipeline (real world)", file: "corpus/real-world/ci-pipeline.mmd"),
  (family: "oauth-login (real world)", file: "corpus/real-world/oauth-login.mmd"),
  (family: "release-schedule (real world)", file: "corpus/real-world/release-schedule.mmd"),
  (family: "shop-schema (real world)", file: "corpus/real-world/shop-schema.mmd"),
)

= Diagram corpus
#linebreak()
#for (family: family, file: file) in corpus {
  grid(columns: (0.6fr,2fr), 
  heading(level: 2, family),
  mermaid(read(file), width: 100%, alt: "Mermaid " + family + " diagram")
  )
}
