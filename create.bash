#!/bin/env bash
set -e

# https://github.com/do-i/lazy
#
# Automante partition creation
# Usage: $0 <device_name> <hostname> <username>
#


#
# Check arguments
#

device_name=${1}
if [ "$device_name" == "" ]; then
  echo "specify device e.g., nvme0n1 or sda"
  exit 1
fi

hostname=${2}
if [ "$hostname" == "" ]; then
  echo "specify hostname"
  exit 1
fi

username=${3}
if [ "$username" == "" ]; then
  echo "specify username"
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

echo 'Create LUKS partition'
cryptsetup -q luksFormat ${root_partition}

echo 'Open LUKS partition'
cryptsetup open ${root_partition} crypt-root

mkfs.ext4 /dev/mapper/crypt-root
mkfs.fat -F32 ${boot_partition}

mount /dev/mapper/crypt-root /mnt
mount --mkdir ${boot_partition} /mnt/boot

pacstrap /mnt base base-devel linux linux-firmware dhcpcd openssh cryptsetup efibootmgr neovim fish python

genfstab -U /mnt >> /mnt/etc/fstab

cp ./configure.bash /mnt/root

arch-chroot /mnt /root/configure.bash ${hostname} ${username} ${device_name} ${root_partition}

#
# Manual Actions
#

echo 'Run following commands:'
echo 'arch-chroot /mnt'
echo 'passwd'
echo "passwd ${username}"
echo 'exit'
echo 'umount -R /mnt'
echo 'shutdown now'