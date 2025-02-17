#!/bin/env bash
set -e

# https://github.com/do-i/lazy
#
# Usage: ./lazy.bash <dest_dir>
#
dest_dir=${1}
if [ "$dest_dir" == "" ]; then
  echo "specify destination dir"
  exit 1
fi

mkdir -p ${dest_dir}
cd ${dest_dir}
curl -O https://raw.githubusercontent.com/do-i/lazy/refs/heads/main/part.bash
curl -O https://raw.githubusercontent.com/do-i/lazy/refs/heads/main/scratch.bash
curl -O https://raw.githubusercontent.com/do-i/lazy/refs/heads/main/boot.bash

chmod +x *.bash
