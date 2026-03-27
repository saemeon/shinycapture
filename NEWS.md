# shinycapture 0.1.0

* Initial release.
* Three-stage pluggable capture pipeline (preprocess, capture, postprocess) for Shiny applications.
* `capture_plotly()` — captures Plotly charts at exact resolution via `Plotly.toImage()`.
* `capture_element()` — captures arbitrary HTML elements via `html2canvas`.
* `plotly_strategy()` and `html2canvas_strategy()` — built-in strategy constructors.
* `shinycapture_deps()` / `html2canvas_deps()` — register JavaScript dependencies.
