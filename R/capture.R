# Copyright (c) Simon Niederberger.
# Distributed under the terms of the MIT License.

#' Capture a Plotly chart from the browser
#'
#' Sends a message to the browser to capture a \code{plotlyOutput} element via
#' \code{Plotly.toImage()}. The result is delivered as a base64 data-URI string
#' to \code{input[[input_id]]}. Use it directly as an \code{<img>} \code{src}
#' for display, or pass it to \code{\link{base64_decode}} to get raw bytes for
#' saving or further processing.
#'
#' @param id The output ID of the \code{plotlyOutput} to capture.
#' @param strategy A \code{capture_strategy} object controlling how the capture
#'   is performed. See \code{\link{plotly_strategy}} for options including
#'   resolution, format, and strip patches. Defaults to
#'   \code{plotly_strategy()}.
#' @param input_id The Shiny input ID that will receive the result as a
#'   base64 data-URI string. Defaults to \code{".shinycapture.<id>"}. Use
#'   \code{observeEvent(input[[input_id]], ...)} to react.
#' @param session The Shiny session object.
#'
#' @return Invisibly returns \code{input_id}. The actual result arrives
#'   asynchronously as a base64 data-URI string in \code{input[[input_id]]}.
#'   Use directly as \code{tags$img(src = input[[id]])} or decode with
#'   \code{\link{base64_decode}} to get raw bytes.
#'
#' @seealso \code{\link{capture_element}}, \code{\link{plotly_strategy}},
#'   \code{\link{base64_decode}}, \code{\link{shinycapture_deps}}
#'
#' @examples
#' \dontrun{
#' server <- function(input, output, session) {
#'   output$my_plot <- plotly::renderPlotly({ ... })
#'
#'   # Trigger capture on button click
#'   observeEvent(input$capture_btn, {
#'     capture_plotly("my_plot",
#'       strategy = plotly_strategy(
#'         strip_title = TRUE,
#'         width = 2400, height = 1600
#'       )
#'     )
#'   })
#'
#'   # React to result — input value is a base64 data-URI string
#'   observeEvent(input[[".shinycapture.my_plot"]], {
#'     # Display directly in the UI
#'     output$preview <- renderUI(
#'       tags$img(src = input[[".shinycapture.my_plot"]])
#'     )
#'
#'     # Or decode to raw bytes for saving / processing
#'     bytes <- base64_decode(input[[".shinycapture.my_plot"]])
#'     writeBin(bytes, "export.png")
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
#' (default) or another strategy. html2canvas is automatically included in
#' the page when \code{html2canvas_strategy()} is used.
#'
#' The result arrives asynchronously as a base64 data-URI string in
#' \code{input[[input_id]]}. Use directly as an \code{<img>} \code{src}
#' for display, or pass to \code{\link{base64_decode}} to get raw bytes.
#'
#' @inheritParams capture_plotly
#' @param strategy A \code{capture_strategy} object. Defaults to
#'   \code{html2canvas_strategy()}. See also \code{\link{plotly_strategy}}.
#'
#' @return Invisibly returns \code{input_id}. The actual result arrives
#'   asynchronously as a base64 data-URI string in \code{input[[input_id]]}.
#'
#' @seealso \code{\link{capture_plotly}}, \code{\link{html2canvas_strategy}},
#'   \code{\link{base64_decode}}, \code{\link{shinycapture_deps}}
#'
#' @examples
#' \dontrun{
#' server <- function(input, output, session) {
#'   observeEvent(input$capture_btn, {
#'     capture_element("my_div",
#'       strategy = html2canvas_strategy(scale = 3)
#'     )
#'   })
#'
#'   observeEvent(input[[".shinycapture.my_div"]], {
#'     png_bytes <- input[[".shinycapture.my_div"]]
#'     writeBin(png_bytes, "screenshot.png")
#'   })
#' }
#' }
#' @export
capture_element <- function(id,
                            strategy = html2canvas_strategy(),
                            input_id = NULL,
                            session = shiny::getDefaultReactiveDomain()) {
  if (identical(strategy$strategy, "html2canvas")) {
    .ensure_html2canvas(session)
  }
  capture_plotly(id, strategy, input_id, session)
}


# Inject html2canvas JS once per session
.ensure_html2canvas <- function(session) {
  if (is.null(session$userData$.html2canvas_added) ||
      !session$userData$.html2canvas_added) {
    shiny::insertUI("head", "beforeEnd", immediate = TRUE,
                    ui = html2canvas_deps())
    session$userData$.html2canvas_added <- TRUE
  }
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
