// Expected to fail: `series` accepts at most eight colours. tests/theme.sh checks that this
// build fails with the documented message, then deletes the output.
#import "../lib.typ": build-config

#let _ = build-config(series: (
  rgb("#ff0000"),
  rgb("#00ff00"),
  rgb("#0000ff"),
  rgb("#ffff00"),
  rgb("#ff00ff"),
  rgb("#00ffff"),
  rgb("#111111"),
  rgb("#222222"),
  rgb("#333333"),
))
