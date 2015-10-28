#!/bin/bash

set -euo pipefail

get_libhdfs3_version() {
  local dir_to_tar
  dir_to_tar="$1"
  cat "${dir_to_tar}/lib/pkgconfig/libhdfs3.pc" | grep Version | cut -d ' ' -f2
}

generate_package_name() {
  local git_hash
  git_hash=$(git log -1 --oneline | head -1 | cut -d ' ' -f1)
  echo "libhdfs3_install_pkg_${1}_${git_hash}.tgz"
}

_main() {
  mkdir build
  pushd build
  ../bootstrap
  local parent_dir
  parent_dir=$(dirname "$(pwd)")
  local dest="package"
  mkdir ${dest}
  make DESTDIR=${dest} install

  # dir_to_tar's root should be dist 
  local dir_to_tar
  dir_to_tar="${dest}${parent_dir}/dist"

  local version_number
  version_number=$(get_libhdfs3_version "${dir_to_tar}")

  local s3_package
  s3_package=$(generate_package_name "${version_number}")

  echo "${s3_package}"
  tar -cvzf "${s3_package}" -C "${dir_to_tar}" .
}

_main "$@"
