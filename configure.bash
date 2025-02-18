#!/bin/env bash
set -e

# https://github.com/do-i/lazy
#
# Run this script within chroot
#
# Usage: $0 <hostname> <username> <device> <crypt_partition>
#

# Check argument
hostname=${1}
if [ "$hostname" == "" ]; then
  echo "specify hostname"
  exit 1
fi

username=${2}
if [ "$username" == "" ]; then
  echo "specify username"
  exit 1
fi

device=${3}
if [ "$device" == "" ]; then
  echo "specify device e.g., nvme0n1 or sda"
  exit 1
fi

crypt_partition=${4}
if [ "$crypt_partition" == "" ]; then
  echo "specify device e.g., nvme0n1p2 or sda2"
  exit 1
fi

# Set time zone
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime

# Set hardware clock
hwclock --systohc

# Uncomment en_US.UTF-8 in the /etc/locale.gen file
sed -i '/^#en_US\.UTF-8/s/^#//' /etc/locale.gen

# Generates locale
locale-gen

# Create /etc/locale.conf file
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# Create /etc/hostname file
echo ${hostname} > /etc/hostname

# Enable SSH - daemon
systemctl enable sshd

# Enable DHCP service
systemctl enable dhcpcd

# Create non-root user
groupadd ${username}
useradd -m -g ${username} -s /usr/bin/fish ${username}
usermod -a -G wheel ${username}

# Uncomment `%wheel ALL=(ALL:ALL) ALL` in /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL$/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Update /etc/mkinitcpio.conf
# -> Add encrypt before filesystems hook
sed -i '/^HOOKS=(.*)$/{s/filesystems/encrypt filesystems/g}' /etc/mkinitcpio.conf

# Re-create initramfs image
mkinitcpio -P

# Install bootloader
bootctl --path=/boot install

# Create loader.conf
echo default arch >> /boot/loader/loader.conf
echo timeout 5 >> /boot/loader/loader.conf

# Create a loader file
cat > /boot/loader/entries/arch.conf << EOL
title Arch Linux ${hostname}
linux /vmlinuz-linux
initrd /initramfs-linux.img
options cryptdevice=/dev/${crypt_partition}:crypt-root root=/dev/mapper/crypt-root quiet rw
EOL
