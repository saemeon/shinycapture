[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-%3E%3D4.1-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-276DC3?logo=r&logoColor=white)](https://shiny.posit.co/)

# shinycapture

Plotly charts in Shiny are rendered by JavaScript in the user's browser — the R server never holds the chart as pixels. shinycapture solves this by triggering the capture directly in the browser and sending the result back to R, with no server-side Chrome or headless browser required.

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
  plotlyOutput("my_plot"),
  actionButton("capture_btn", "Export PNG")
)

server <- function(input, output, session) {
  output$my_plot <- renderPlotly({
    plot_ly(x = ~rnorm(100), type = "histogram")
  })

  # Step 1: trigger capture in the browser
  observeEvent(input$capture_btn, {
    capture_plotly("my_plot",
      strategy = plotly_strategy(width = 1200, height = 800)
    )
  })

  # Step 2: react when the result arrives (base64 data-URI string)
  observeEvent(input[[".shinycapture.my_plot"]], {
    # Display directly in the UI
    output$preview <- renderUI(
      tags$img(src = input[[".shinycapture.my_plot"]])
    )

    # Or decode to raw bytes for saving / processing
    bytes <- base64_decode(input[[".shinycapture.my_plot"]])
    writeBin(bytes, "export.png")
  })
}

shinyApp(ui, server)
```

## Capture strategies

| Strategy | Target | Method |
|----------|--------|--------|
| `plotly_strategy()` | Plotly charts | `Plotly.toImage()` — exact resolution, supports strip patches |
| `html2canvas_strategy()` | Any HTML element | `html2canvas` — screenshots arbitrary DOM elements |

### High-resolution export with strip patches

```r
capture_plotly("my_plot",
  strategy = plotly_strategy(
    strip_title  = TRUE,   # remove title before capture
    strip_legend = TRUE,   # remove legend before capture
    width  = 2400,
    height = 1600
  )
)
```

Strip patches modify a hidden off-screen clone of the chart — the original is unaffected.

## How it works

1. **Trigger** — R sends a Shiny custom message to the browser
2. **Preprocess** (optional) — JavaScript modifies the element (strip patches, resize)
3. **Capture** — `Plotly.toImage()` or `html2canvas` takes the screenshot and returns a base64 string
4. **Deliver** — `Shiny.setInputValue()` sends the base64 string to the R server as `input[[id]]`

The result is a base64 data-URI string. Use it directly as an `<img>` `src` attribute, or call `base64_decode()` to get raw bytes.

## License

MIT
