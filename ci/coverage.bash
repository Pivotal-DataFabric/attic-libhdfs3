#!/bin/bash

set -euox pipefail
# TODO: remove -x

_main() {
  echo "****** Build libhdfs3 ******"
  mkdir build
  pushd build
  ../bootstrap --enable-debug --enable-coverage # TODO: do we need to enable debug?
  make

  echo "****** Run unit tests to generate coverage data ******"
  make unittest

  echo "****** Generate coverage report ******"
  # TODO: do we need to run make functiontest too to get better coverage?
  make ShowCoverage
}

_main "$@"
