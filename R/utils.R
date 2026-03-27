# Copyright (c) Simon Niederberger.
# Distributed under the terms of the MIT License.

#' Decode a base64 data-URI or raw base64 string to raw bytes
#'
#' Strips the \code{data:image/...;base64,} prefix if present, then decodes
#' the remaining base64 payload to a \code{raw} vector.
#'
#' The result of \code{\link{capture_plotly}} and \code{\link{capture_element}}
#' arrives in \code{input[[id]]} as a base64 string (with data-URI prefix).
#' Use this function to convert it to raw bytes for saving, processing, or
#' passing to other functions.
#'
#' @param b64_string A base64-encoded string, optionally with a
#'   \code{data:image/...;base64,} prefix.
#' @return A \code{raw} vector containing the decoded bytes.
#'
#' @seealso \code{\link{capture_plotly}}, \code{\link{capture_element}}
#'
#' @examples
#' \dontrun{
#' server <- function(input, output, session) {
#'   observeEvent(input[[".shinycapture.my_plot"]], {
#'     # Display in UI — use the base64 string directly as img src
#'     output$preview <- renderUI(
#'       tags$img(src = input[[".shinycapture.my_plot"]])
#'     )
#'
#'     # Save to disk — decode to raw bytes first
#'     bytes <- base64_decode(input[[".shinycapture.my_plot"]])
#'     writeBin(bytes, "export.png")
#'   })
#' }
#' }
#' @export
base64_decode <- function(b64_string) {
  if (grepl("^data:", b64_string)) {
    b64_string <- sub("^data:[^;]+;base64,", "", b64_string)
  }
  jsonlite::base64_dec(b64_string)
}


#' HTML dependency for shinycapture JavaScript
#'
#' Returns an \code{htmltools::htmlDependency} that loads the shinycapture
#' JavaScript into the Shiny page. This is called automatically by
#' \code{\link{capture_plotly}} and \code{\link{capture_element}}, so you
#' only need to call it manually if you want to place the dependency at a
#' specific point in your UI (e.g. before other scripts that depend on it).
#'
#' @return An \code{htmlDependency} object. Include it in your UI with
#'   \code{tags$head(shinycapture_deps())} or simply add it anywhere in
#'   \code{fluidPage()} / \code{tagList()}.
#'
#' @seealso \code{\link{html2canvas_deps}}, \code{\link{capture_plotly}}
#'
#' @examples
#' \dontrun{
#' # Manual placement (optional — auto-included when you call capture_plotly)
#' ui <- fluidPage(
#'   shinycapture_deps(),
#'   plotly::plotlyOutput("my_plot"),
#'   actionButton("btn", "Export")
#' )
#' }
#' @export
shinycapture_deps <- function() {
  htmltools::htmlDependency(
    name = "shinycapture",
    version = as.character(utils::packageVersion("shinycapture")),
    package = "shinycapture",
    src = "shinycapture",
    script = "shinycapture.js"
  )
}


#' HTML dependency for vendored html2canvas
#'
#' Returns an \code{htmltools::htmlDependency} that loads the bundled
#' html2canvas 1.4.1 library. This is called automatically by
#' \code{\link{capture_element}} when \code{\link{html2canvas_strategy}} is
#' used, so you rarely need to call it directly.
#'
#' Call it manually only if you use \code{\link{capture_plotly}} with a
#' custom strategy that relies on \code{window.html2canvas}.
#'
#' @return An \code{htmlDependency} object.
#'
#' @seealso \code{\link{shinycapture_deps}}, \code{\link{capture_element}},
#'   \code{\link{html2canvas_strategy}}
#'
#' @examples
#' \dontrun{
#' # Only needed when using html2canvas outside of capture_element()
#' ui <- fluidPage(
#'   html2canvas_deps(),
#'   div(id = "my_div", "Content to capture")
#' )
#' }
#' @export
html2canvas_deps <- function() {
  htmltools::htmlDependency(
    name = "html2canvas",
    version = "1.4.1",
    package = "shinycapture",
    src = "shinycapture",
    script = "html2canvas.min.js"
  )
}
