#!/bin/bash

set -euo pipefail

_main() {
  mkdir build
  pushd build
  ../bootstrap
  make
  make unittest
}

_main "$@"
