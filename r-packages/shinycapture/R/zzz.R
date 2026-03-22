# Copyright (c) Simon Niederberger.
# Distributed under the terms of the MIT License.

.onLoad <- function(libname, pkgname) {
  # No input handler needed — we use Shiny.setInputValue() directly
  # and let the user decode base64 with base64_decode() on demand.
}
