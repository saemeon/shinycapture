# Copyright (c) Simon Niederberger.
# Distributed under the terms of the MIT License.

# ---------------------------------------------------------------------------
# Browser integration tests — require Chrome / Playwright + plotly
# Run locally with: devtools::test(filter = "integration")
# ---------------------------------------------------------------------------

skip_if_not_installed("shinytest2")
skip_if_not_installed("plotly")
skip_on_ci()

library(shinytest2)

# ---------------------------------------------------------------------------
# Helper: minimal Shiny app with a Plotly chart and a capture button
# ---------------------------------------------------------------------------

.make_app <- function(strategy = plotly_strategy()) {
  shiny::shinyApp(
    ui = shiny::fluidPage(
      shinycapture_deps(),
      plotly::plotlyOutput("my_plot"),
      shiny::actionButton("capture_btn", "Capture"),
      shiny::verbatimTextOutput("result_info")
    ),
    server = function(input, output, session) {
      output$my_plot <- plotly::renderPlotly({
        plotly::plot_ly(x = 1:3, y = c(1, 2, 3), type = "scatter",
                        mode = "lines")
      })

      shiny::observeEvent(input$capture_btn, {
        capture_plotly("my_plot",
          strategy = strategy,
          session = session
        )
      })

      output$result_info <- shiny::renderText({
        val <- input[[".shinycapture.my_plot"]]
        if (is.null(val)) return("waiting")
        paste0("bytes:", length(val),
               " png:", identical(val[1:4], as.raw(c(0x89, 0x50, 0x4e, 0x47))))
      })
    }
  )
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test_that("capture_plotly delivers raw PNG bytes to input handler", {
  app <- AppDriver$new(.make_app(), name = "capture-basic", timeout = 15000)
  on.exit(app$stop(), add = TRUE)

  # Wait for Plotly to render
  app$wait_for_idle(2000)

  # Trigger capture
  app$click("capture_btn")

  # Wait for result to appear
  app$wait_for_value(output = "result_info",
                     ignore = "waiting",
                     timeout = 10000)

  info <- app$get_value(output = "result_info")

  expect_match(info, "bytes:\\d+")
  expect_match(info, "png:TRUE")  # input is valid PNG
})


test_that("capture_plotly with strip_title still returns valid PNG", {
  app <- AppDriver$new(
    .make_app(strategy = plotly_strategy(strip_title = TRUE)),
    name = "capture-strip",
    timeout = 15000
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(2000)
  app$click("capture_btn")
  app$wait_for_value(output = "result_info",
                     ignore = "waiting",
                     timeout = 10000)

  info <- app$get_value(output = "result_info")
  expect_match(info, "png:TRUE")
})


test_that("capture_plotly with custom resolution returns larger PNG", {
  small_app <- .make_app(strategy = plotly_strategy(width = 400, height = 300))
  large_app <- .make_app(strategy = plotly_strategy(width = 1200, height = 800))

  small <- AppDriver$new(small_app, name = "capture-small", timeout = 15000)
  large <- AppDriver$new(large_app, name = "capture-large", timeout = 15000)
  on.exit({ small$stop(); large$stop() }, add = TRUE)

  for (drv in list(small, large)) {
    drv$wait_for_idle(2000)
    drv$click("capture_btn")
    drv$wait_for_value(output = "result_info",
                       ignore = "waiting",
                       timeout = 10000)
  }

  small_info <- small$get_value(output = "result_info")
  large_info <- large$get_value(output = "result_info")

  small_bytes <- as.integer(sub("bytes:(\\d+).*", "\\1", small_info))
  large_bytes <- as.integer(sub("bytes:(\\d+).*", "\\1", large_info))

  expect_true(large_bytes > small_bytes,
    info = paste("Expected larger PNG for 1200x800 vs 400x300.",
                 "small:", small_bytes, "large:", large_bytes))
})
