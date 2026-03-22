# Copyright (c) Simon Niederberger.
# Distributed under the terms of the MIT License.

#' Capture a Plotly chart from the browser
#'
#' Triggers a browser-side capture of a \code{plotlyOutput} element using
#' \code{Plotly.toImage()} with exact pixel dimensions. The result is sent
#' back to R as a base64 string available via \code{input$<input_id>}.
#'
#' @param id The output ID of the \code{plotlyOutput} to capture.
#' @param strategy A \code{capture_strategy} object (default:
#'   \code{plotly_strategy()}).
#' @param input_id The Shiny input ID that will receive the base64 result.
#'   Defaults to \code{".shinycapture.<id>"}.
#' @param session The Shiny session object.
#' @return Invisibly, the \code{input_id} string. Use
#'   \code{observeEvent(input[[input_id]], ...)} to react to the capture.
#'
#' @examples
#' \dontrun{
#' server <- function(input, output, session) {
#'   output$my_plot <- plotly::renderPlotly({ ... })
#'
#'   observeEvent(input$capture_btn, {
#'     capture_plotly("my_plot",
#'       strategy = plotly_strategy(
#'         strip_title = TRUE,
#'         width = 2400, height = 1600
#'       )
#'     )
#'   })
#'
#'   observeEvent(input[[".shinycapture.my_plot"]], {
#'     bytes <- base64_decode(input[[".shinycapture.my_plot"]])
#'     # Process with magick, save, display, etc.
#'   })
#' }
#' }
#' @export
capture_plotly <- function(id,
                           strategy = plotly_strategy(),
                           input_id = NULL,
                           session = shiny::getDefaultReactiveDomain()) {
  if (is.null(input_id)) {
    input_id <- paste0(".shinycapture.", id)
  }

  .ensure_deps(session)

  session$sendCustomMessage("shinycapture-capture", list(
    id = session$ns(id),
    input_id = input_id,
    strategy = strategy$strategy,
    preprocess_js = strategy$preprocess_js,
    opts = strategy$opts
  ))

  invisible(input_id)
}

#' Capture an arbitrary HTML element from the browser
#'
#' Triggers a browser-side capture of any DOM element using html2canvas
#' (default) or another strategy.
#'
#' @inheritParams capture_plotly
#' @param strategy A \code{capture_strategy} object (default:
#'   \code{html2canvas_strategy()}).
#'
#' @export
capture_element <- function(id,
                            strategy = html2canvas_strategy(),
                            input_id = NULL,
                            session = shiny::getDefaultReactiveDomain()) {
  capture_plotly(id, strategy, input_id, session)
}


# Inject JS dependencies once per session
.ensure_deps <- function(session) {
  if (is.null(session$userData$.shinycapture_added) ||
      !session$userData$.shinycapture_added) {
    shiny::insertUI("head", "beforeEnd", immediate = TRUE,
                    ui = shinycapture_deps())
    session$userData$.shinycapture_added <- TRUE
  }
}
