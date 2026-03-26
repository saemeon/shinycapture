[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-%3E%3D4.1-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-276DC3?logo=r&logoColor=white)](https://shiny.posit.co/)

# shinycapture

Three-stage pluggable capture pipeline for Shiny applications. Captures Plotly charts at exact resolution via `Plotly.toImage()` and arbitrary HTML elements via `html2canvas`.

## Installation

```r
# install.packages("remotes")
remotes::install_github("saemeon/shinycapture")
```

## Usage

```r
library(shinycapture)
library(plotly)

ui <- fluidPage(
  shinycapture_deps(),
  plotlyOutput("my_plot"),
  actionButton("capture_btn", "Export PNG")
)

server <- function(input, output, session) {
  output$my_plot <- renderPlotly({
    plot_ly(x = ~rnorm(100), type = "histogram")
  })

  observeEvent(input$capture_btn, {
    capture_plotly("my_plot", session, callback = function(png_bytes) {
      # Post-process the captured image (e.g. add corporate frame)
      writeBin(png_bytes, "export.png")
    })
  })
}

shinyApp(ui, server)
```

## Pipeline stages

1. **Preprocess** — modify the target element before capture (e.g. strip titles, resize)
2. **Capture** — take the screenshot (`Plotly.toImage` or `html2canvas`)
3. **Postprocess** — process the result server-side (e.g. corporate framing, format conversion)

## Capture strategies

| Strategy | Target | Method |
|----------|--------|--------|
| `plotly_strategy` | Plotly charts | `Plotly.toImage()` — exact resolution |
| `html2canvas_strategy` | Any HTML element | `html2canvas` library |

## License

MIT
