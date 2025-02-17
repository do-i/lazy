#!/bin/env bash
set -e

# https://github.com/do-i/lazy
#
# Install essential packages from scratch
# Usage: ./scratch.bash
#
function usage() {
  echo "Usage: ./scratch.bash"
}

pacstrap /mnt base base-devel linux linux-firmware dhcpcd openssh cryptsetup efibootmgr neovim fish python

genfstab -U /mnt >> /mnt/etc/fstab
