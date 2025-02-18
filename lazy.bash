#!/bin/env bash
set -e

# https://github.com/do-i/lazy
#
# Usage: ./lazy.bash [dest_dir]
#
dest_dir=${1}
if [ "$dest_dir" == "" ]; then
  dest_dir="tmp"
fi
echo "destination dir: ${dest_dir}"

mkdir -p ${dest_dir}
cd ${dest_dir}
curl -O https://raw.githubusercontent.com/do-i/lazy/refs/heads/main/create.bash
curl -O https://raw.githubusercontent.com/do-i/lazy/refs/heads/main/configure.bash

chmod +x *.bash
