#!/bin/bash

set -euo pipefail

_main() {
  echo "****** Build libhdfs3 ******"
  mkdir build
  pushd build
  ../bootstrap --enable-coverage # TODO: do we need to enable debug?
  make

  echo "****** Run unit tests to generate coverage data ******"
  make unittest

  echo "****** Generate coverage report ******"
  make ShowCoverage
}

_main "$@"
