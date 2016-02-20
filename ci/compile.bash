#!/bin/bash

set -euxo pipefail

get_libhdfs3_version() {
  local dir_to_tar
  dir_to_tar="$1"
  cat "${dir_to_tar}/lib/pkgconfig/libhdfs3.pc" | grep Version | cut -d ' ' -f2
}

get_git_hash() {
  local git_root_dir="$1"
  local git_hash

  pushd "$git_root_dir" &>/dev/null
    git_hash="$(git log -1 --oneline | cut -d ' ' -f1)"
  popd &>/dev/null

  echo "$git_hash"
}

generate_package_name() {
  local version_number="$1"
  local git_hash="$2"
  echo "libhdfs3_install_pkg_${version_number}_${git_hash}.tgz"
}

_main() {
  #Concourse mounts a volume at the output directory, so we expect that 'build' is already here
  local output_dir="$1"
  local install_destination="${output_dir}/package"

  mkdir -p "$install_destination"

  local src_dir
  #Providing the full expanded path here because it's going to be concatenated in an ugly way later
  src_dir="$(pwd)/libhdfs3_src"

  pushd "$output_dir"
    "$src_dir"/bootstrap
    make DESTDIR="../$install_destination" install
  popd

  # the bootstrap script will have copied over many files deep into the 'package' directory
  # recreating the full src_dir directory structure
  # and then dir_to_tar's root should be 'dist' because make puts the compiled parts into 'dist'
  local dir_to_tar
  dir_to_tar="${install_destination}${src_dir}/dist"

  local version_number
  version_number=$(get_libhdfs3_version "${dir_to_tar}")

  local git_hash
  git_hash=$(get_git_hash "${src_dir}")

  local s3_package
  s3_package=$(generate_package_name "${version_number}" "$git_hash")

  # make the tarball from the perspective of the dist directory
  # put it in the mounted output directory that concourse provided
  tar -cvzf "${output_dir}/${s3_package}" -C "${dir_to_tar}" .
}

_main $OUTPUT_PATH "$@"
