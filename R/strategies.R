# Copyright (c) Simon Niederberger.
# Distributed under the terms of the MIT License.

#' Create a Plotly capture strategy with optional strip patches
#'
#' Generates a strategy that uses \code{Plotly.toImage()} for capture.
#' Strip flags produce JS preprocess code that removes decorations from the
#' figure before capture (title, legend, margins, etc.).
#'
#' The strip-patch JS fragments are kept in sync with the Python version
#' in \code{packages/dash-capture/src/dash_capture/strategies.py}.
#'
#' @param strip_title Remove the figure title before capture.
#' @param strip_legend Hide the legend before capture.
#' @param strip_annotations Remove all annotations before capture.
#' @param strip_axis_titles Remove x/y axis titles before capture.
#' @param strip_colorbar Hide colorbars on all traces before capture.
#' @param strip_margin Zero all figure margins before capture.
#' @param width Capture width in pixels (NULL = use displayed size).
#' @param height Capture height in pixels (NULL = use displayed size).
#' @param format Output format: \code{"png"}, \code{"jpeg"}, \code{"webp"},
#'   \code{"svg"}.
#' @return A list with class \code{"capture_strategy"}.
#' @export
plotly_strategy <- function(strip_title = FALSE,
                            strip_legend = FALSE,
                            strip_annotations = FALSE,
                            strip_axis_titles = FALSE,
                            strip_colorbar = FALSE,
                            strip_margin = FALSE,
                            width = NULL,
                            height = NULL,
                            format = "png") {
  patches <- character(0)

  if (strip_title) {
    patches <- c(patches,
      "layout.title = {text: ''};",
      "layout.margin = {...(layout.margin || {}), t: 20};"
    )
  }
  if (strip_legend) {
    patches <- c(patches, "layout.showlegend = false;")
  }
  if (strip_annotations) {
    patches <- c(patches, "layout.annotations = [];")
  }
  if (strip_axis_titles) {
    patches <- c(patches, paste0(
      "Object.keys(layout).forEach(k => {",
      " if (/^[xy]axis/.test(k))",
      " layout[k] = {...(layout[k]||{}), title: {text: ''}}; });"
    ))
  }
  if (strip_colorbar) {
    patches <- c(patches, "data = data.map(t => ({...t, showscale: false}));")
  }
  if (strip_margin) {
    patches <- c(patches, "layout.margin = {l:0, r:0, t:0, b:0, pad:0};")
  }

  preprocess_js <- NULL
  if (length(patches) > 0) {
    dim_w <- if (!is.null(width)) as.character(width) else "graphDiv.offsetWidth"
    dim_h <- if (!is.null(height)) as.character(height) else "graphDiv.offsetHeight"

    preprocess_js <- paste0(
      "var layout = JSON.parse(JSON.stringify(graphDiv.layout || {}));\n",
      "var data = graphDiv.data;\n",
      paste(patches, collapse = "\n"), "\n",
      "var tmp = document.createElement('div');\n",
      "tmp.style.cssText = 'position:fixed;left:-9999px;width:'",
      " + (", dim_w, ") + 'px;height:' + (", dim_h, ") + 'px';\n",
      "document.body.appendChild(tmp);\n",
      "await Plotly.newPlot(tmp, data, layout);\n",
      "el._scap_tmp = tmp;"
    )
  }

  opts <- list(format = format)
  if (!is.null(width)) opts$width <- width
  if (!is.null(height)) opts$height <- height

  structure(
    list(
      strategy = "plotly",
      preprocess_js = preprocess_js,
      opts = opts
    ),
    class = "capture_strategy"
  )
}

#' Create an html2canvas capture strategy
#'
#' Captures arbitrary DOM elements using the html2canvas library.
#' Requires html2canvas to be loaded in the page (e.g. via
#' \code{tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.0/html2canvas.min.js")}).
#'
#' @param scale Resolution multiplier (default 2).
#' @param format Output format: \code{"png"}, \code{"jpeg"}/\code{"jpg"}.
#' @return A list with class \code{"capture_strategy"}.
#' @export
html2canvas_strategy <- function(scale = 2, format = "png") {
  structure(
    list(
      strategy = "html2canvas",
      preprocess_js = NULL,
      opts = list(scale = scale, format = format)
    ),
    class = "capture_strategy"
  )
}
