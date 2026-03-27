# Copyright (c) Simon Niederberger.
# Distributed under the terms of the MIT License.

#' Create a Plotly capture strategy
#'
#' Generates a \code{capture_strategy} object that uses \code{Plotly.toImage()}
#' for browser-side capture. Pass it to \code{\link{capture_plotly}}.
#'
#' Strip flags inject JavaScript that modifies the figure \emph{before}
#' capture — removing decorations that look good interactively but clutter
#' a static export (titles, legends, margins). The original figure is
#' unaffected; modifications happen in a hidden off-screen clone.
#'
#' @param strip_title Remove the figure title before capture.
#' @param strip_legend Hide the legend before capture.
#' @param strip_annotations Remove all annotations before capture.
#' @param strip_axis_titles Remove x/y axis titles before capture.
#' @param strip_colorbar Hide colorbars on all traces before capture.
#' @param strip_margin Zero all figure margins before capture, maximising
#'   the plot area.
#' @param width Capture width in pixels. \code{NULL} (default) uses the
#'   element's current rendered width.
#' @param height Capture height in pixels. \code{NULL} uses rendered height.
#'   For publication-quality output use e.g. \code{width = 2400, height = 1600}.
#' @param format Output image format: \code{"png"} (default), \code{"jpeg"},
#'   \code{"webp"}, or \code{"svg"}.
#'
#' @return A list of class \code{"capture_strategy"} with fields
#'   \code{strategy}, \code{preprocess_js}, and \code{opts}.
#'   Pass to \code{\link{capture_plotly}}.
#'
#' @seealso \code{\link{capture_plotly}}, \code{\link{html2canvas_strategy}}
#'
#' @examples
#' # Default — no stripping, native resolution, PNG
#' s <- plotly_strategy()
#'
#' # High-resolution export without title or legend
#' s <- plotly_strategy(
#'   strip_title  = TRUE,
#'   strip_legend = TRUE,
#'   width  = 2400,
#'   height = 1600
#' )
#'
#' # SVG output
#' s <- plotly_strategy(format = "svg")
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
  if (!is.null(width))  opts$width  <- width
  if (!is.null(height)) opts$height <- height

  structure(
    list(strategy = "plotly", preprocess_js = preprocess_js, opts = opts),
    class = "capture_strategy"
  )
}


#' Create an html2canvas capture strategy
#'
#' Generates a \code{capture_strategy} object that uses the
#' \href{https://html2canvas.hertzen.com/}{html2canvas} library to screenshot
#' any DOM element. Pass it to \code{\link{capture_element}}.
#'
#' html2canvas is bundled with this package and loaded automatically when
#' using \code{\link{capture_element}} with this strategy.
#'
#' @param scale Resolution multiplier. \code{2} (default) captures at double
#'   the CSS pixel density, producing a sharper image on high-DPI screens.
#'   Use \code{3} or higher for print-quality output.
#' @param format Output format: \code{"png"} (default) or \code{"jpeg"}.
#'
#' @return A list of class \code{"capture_strategy"} with fields
#'   \code{strategy}, \code{preprocess_js}, and \code{opts}.
#'   Pass to \code{\link{capture_element}}.
#'
#' @seealso \code{\link{capture_element}}, \code{\link{plotly_strategy}}
#'
#' @examples
#' # Default — 2× resolution, PNG
#' s <- html2canvas_strategy()
#'
#' # High-resolution JPEG
#' s <- html2canvas_strategy(scale = 3, format = "jpeg")
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
