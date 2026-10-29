# Changelog

## 0.1.0

Initial release.

- `mermaid` renders Mermaid diagrams as SVG through Pele, with `mermaid-svg`,
  `mermaid-result`, `mermaid-figure`, and a `show-mermaid-blocks` handler for
  `mermaid` raw blocks.
- Document-aware typography by default: `text.font`, `text.size`, `text.fill`, and
  `page.fill` feed the diagram unless overridden. Explicit `font`, `font-size`,
  `foreground`, `background`, and `theme` values win.
- `measure: "auto"` is the default and uses Pele's per-character width table.
  `measure: "mono"` opts into a flat 0.6 em advance for true monospace fonts.
- Presets `modern` (default), `dark`, and `print`. Theme keys accept canonical
  Pele variables, `--pele-*` spellings, and common aliases; unknown theme keys,
  renderer options passed in `theme`, and unknown `options` keys raise an error.
- `layout` is a validated alias for the layout-related render options.
- `background: none` produces a transparent canvas while keeping canvas-coloured
  decorations opaque through the `label-bg` variable: edge labels and casings, arrow
  markers, pie labels, sequence-number halos, and treemap labels.
- `error-mode` accepts `panic` (default), `placeholder` (highlighted box), and `text`
  (plain text). `mermaid-result` reports structured failures instead.
- Responsive reflow uses the Typst layout width as Pele's `maxWidth`; absolute
  widths skip the layout pass. `document-context: false` disables both document
  typography and the layout pass. Diagram direction is preserved by default:
  Pelermaid disables Pele's `autoDirection`, so `flowchart LR` stays left-to-right;
  enable it with `options: (auto-direction: true)`.
- Links and images are disabled by default; external images are documented as
  unlikely to load through Typst's SVG renderer.
- Generated `alt` text when none is supplied.
- Corpus documents cover every diagram family Pele 1.12.0 supports, plus real-world
  diagrams and a font/measurement matrix. A second document embeds SVGs pre-rendered
  by Pele's JavaScript bundle, and a comparison document renders both ways side by side
  and asserts the SVGs are byte-identical. Each tagged release attaches `corpus.pdf`,
  `prerendered.pdf`, and `compare.pdf`; the README links to the latest versions via
  GitHub's `/releases/latest/download/` redirect.
- Bundle Pele 1.12.0 (MIT) and its Lucide icon (ISC) as `pele.kbc1`; ship the full
  license texts under `LICENSES/` and declare `MIT AND ISC` in the manifest.
