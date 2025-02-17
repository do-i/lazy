#!/bin/env bash
set -e

# https://github.com/do-i/lazy
#
# Automante partition creation
# Usage: ./part.bash <device_name>
#
function usage() {
  echo "Usage: ./part.bash <device_name>"
  echo "e.g., ./part.bash nvme0n1 or ./part.bash sda"
}

device_name=${1}
if [ "$device_name" == "" ]; then
  usage
  exit 1
fi

if [[ $device_name =~ ^sd[a-h]$ ]]; then
  echo "SSD"
  boot_partition="/dev/${device_name}1"
  root_partition="/dev/${device_name}2"
elif [[ $device_name =~ ^nvme[0-9]n[1-9]$ ]]; then
  echo "M.2"
  boot_partition="/dev/${device_name}p1"
  root_partition="/dev/${device_name}p2"
else
  usage
  exit 2
fi

device="/dev/${device_name}"

wipefs --all ${device}
sgdisk -g -n 0:0:+512M ${device}
sgdisk -g -n 0:0:0 ${device}

cryptsetup -q luksFormat ${root_partition}
cryptsetup open ${root_partition} crypt-root

mkfs.ext4 /dev/mapper/crypt-root
mkfs.fat -F32 ${boot_partition}

mount /dev/mapper/crypt-root /mnt
mount --mkdir ${boot_partition} /mnt/boot
