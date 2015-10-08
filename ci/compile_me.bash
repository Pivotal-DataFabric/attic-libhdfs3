#!/bin/bash

set -euo pipefail

_main() {
  mkdir build
  pushd build
  ../libhdfs3_src/bootstrap
  make
}

_main "$@"
