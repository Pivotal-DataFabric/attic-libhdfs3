#!/bin/bash

set -euo pipefail

_main() {
  mkdir build
  pushd build
  ../bootstrap
  make unittest
}

_main "$@"
