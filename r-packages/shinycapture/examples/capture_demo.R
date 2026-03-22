# shinycapture demo — run with: Rscript examples/capture_demo.R
#
# Demonstrates:
#   1. Plotly chart capture at exact resolution
#   2. Plotly capture with strip patches (title/legend removed)
#   3. Table capture via html2canvas
#   4. Multiple captures on one page
#   5. Server-side post-processing with magick (if installed)

library(shiny)
library(plotly)
library(DT)

# Load shinycapture from the local package source
devtools::load_all(".")

# --- UI ---
ui <- fluidPage(
  # html2canvas from CDN (needed for table capture)
  tags$head(tags$script(
    src = "https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.0/html2canvas.min.js"
  )),

  titlePanel("shinycapture demo"),

  h4("1. Plotly chart — capture at exact resolution"),
  p("Click the button to capture the chart at 1200x800px, regardless of browser size."),
  plotlyOutput("scatter_plot", width = "600px", height = "400px"),
  actionButton("cap_plot", "Capture chart (1200x800)"),
  uiOutput("preview_plot"),
  hr(),

  h4("2. Plotly chart — strip title + legend before capture"),
  p("Same chart, but Plotly decorations are removed in the preprocess stage."),
  actionButton("cap_stripped", "Capture (stripped)"),
  uiOutput("preview_stripped"),
  hr(),

  h4("3. Table — capture via html2canvas"),
  p("Uses capture_element() with html2canvas strategy to capture a DT::datatable."),
  DTOutput("demo_table"),
  br(),
  actionButton("cap_table", "Capture table"),
  uiOutput("preview_table"),
  hr(),

  h4("4. Download captured image"),
  p("Captures the chart and offers a download."),
  actionButton("cap_download", "Capture for download"),
  uiOutput("download_ui"),
)

# --- Server ---
server <- function(input, output, session) {

  # Plotly chart
  output$scatter_plot <- renderPlotly({
    plot_ly(
      x = c(1, 2, 3, 4, 5),
      y = c(2, 5, 3, 8, 4),
      type = "scatter",
      mode = "lines+markers",
      name = "Series A"
    ) %>%
      add_trace(y = c(1, 3, 6, 4, 7), name = "Series B") %>%
      layout(
        title = "Sample Chart",
        xaxis = list(title = "X"),
        yaxis = list(title = "Y")
      )
  })

  # Table
  output$demo_table <- DT::renderDT({
    data.frame(
      Country = c("Switzerland", "Germany", "France", "Italy", "Austria"),
      Population_M = c(8.7, 83.2, 67.4, 59.6, 9.0),
      GDP_per_capita = c(93720, 51380, 44850, 35550, 53640)
    )
  }, options = list(pageLength = 5, dom = "t"))

  # --- 1. Capture chart at exact resolution ---
  observeEvent(input$cap_plot, {
    capture_plotly(
      "scatter_plot",
      strategy = plotly_strategy(width = 1200, height = 800)
    )
  })

  observeEvent(input[[".shinycapture.scatter_plot"]], {
    b64 <- input[[".shinycapture.scatter_plot"]]
    output$preview_plot <- renderUI({
      tagList(
        p(strong("Preview (1200x800):")),
        tags$img(src = b64, style = "max-width:600px; border:1px solid #ccc;")
      )
    })
  })

  # --- 2. Capture with strip patches ---
  observeEvent(input$cap_stripped, {
    capture_plotly(
      "scatter_plot",
      strategy = plotly_strategy(
        strip_title = TRUE,
        strip_legend = TRUE,
        width = 1200, height = 800
      ),
      input_id = ".shinycapture.stripped"
    )
  })

  observeEvent(input[[".shinycapture.stripped"]], {
    b64 <- input[[".shinycapture.stripped"]]
    output$preview_stripped <- renderUI({
      tagList(
        p(strong("Preview (title + legend stripped):")),
        tags$img(src = b64, style = "max-width:600px; border:1px solid #ccc;")
      )
    })
  })

  # --- 3. Table capture ---
  observeEvent(input$cap_table, {
    capture_element(
      "demo_table",
      strategy = html2canvas_strategy(scale = 2)
    )
  })

  observeEvent(input[[".shinycapture.demo_table"]], {
    b64 <- input[[".shinycapture.demo_table"]]
    output$preview_table <- renderUI({
      tagList(
        p(strong("Table capture preview:")),
        tags$img(src = b64, style = "max-width:600px; border:1px solid #ccc;")
      )
    })
  })

  # --- 4. Capture + download ---
  captured_bytes <- reactiveVal(NULL)

  observeEvent(input$cap_download, {
    capture_plotly(
      "scatter_plot",
      strategy = plotly_strategy(width = 2400, height = 1600),
      input_id = ".shinycapture.for_download"
    )
  })

  observeEvent(input[[".shinycapture.for_download"]], {
    bytes <- base64_decode(input[[".shinycapture.for_download"]])
    captured_bytes(bytes)
    output$download_ui <- renderUI({
      downloadButton("download_btn", "Download PNG")
    })
  })

  output$download_btn <- downloadHandler(
    filename = function() "chart.png",
    content = function(file) {
      writeBin(captured_bytes(), file)
    }
  )
}

shinyApp(ui, server)
