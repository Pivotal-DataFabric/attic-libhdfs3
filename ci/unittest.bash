#!/bin/bash

set -euo pipefail

_main() {
  local basedir="${1}"
  pushd "${basedir}"
  mkdir build
  pushd build
  ../bootstrap
  make unittest
  popd
  popd
}

_main "$@"
