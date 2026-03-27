# Copyright (c) Simon Niederberger.
# Distributed under the terms of the MIT License.

.onLoad <- function(libname, pkgname) {
  shiny::registerInputHandler("shinycapture", function(value, ...) {
    if (is.null(value)) return(NULL)
    .base64_decode(value)
  }, force = TRUE)
}
