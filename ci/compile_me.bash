#!/bin/bash

set -euo pipefail

_main() {
  mkdir build
  pushd build
  ../libhdfs3_src/bootstrap # why is this not ../bootstrap???
  make
}

_main "$@"
