# Copyright (c) Simon Niederberger.
# Distributed under the terms of the MIT License.

test_that("base64_decode handles raw base64", {
  # "hello" in base64 = "aGVsbG8="
  raw <- base64_decode("aGVsbG8=")
  expect_equal(rawToChar(raw), "hello")
})

test_that("base64_decode strips data URI prefix", {
  raw <- base64_decode("data:image/png;base64,aGVsbG8=")
  expect_equal(rawToChar(raw), "hello")
})

test_that("base64_decode strips jpeg data URI", {
  raw <- base64_decode("data:image/jpeg;base64,aGVsbG8=")
  expect_equal(rawToChar(raw), "hello")
})
