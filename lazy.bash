#!/bin/env bash
set -e

# https://github.com/do-i/lazy
#
# Usage: ./lazy.bash <hostname> <username>
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

# Set time zone
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime

# Set hardware clock
hwclock --systohc

# Check time and timezone
date

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
# -> Add encrypt and lvm2 hooks before filesystems hook
sed -i '/^HOOKS=(.*)$/{s/filesystems/encrypt lvm2 filesystems/g}' /etc/mkinitcpio.conf

# Re-create initramfs image
mkinitcpio -P

# Check initramfs image is re-created by comparing md5sum
md5sum /boot/initramfs-linux.img
if [ -f /boot/initramfs-linux.img ]; then
  md5sum /boot/initramfs-linux.img
  echo 'md5sum should be different'
fi

# Install GRUB
default_bootloader_id="${hostname}Linux"
bootloader_id="${BOOT_LOADER_ID:-$default_bootloader_id}"

grub-install --efi-directory=/boot --bootloader-id=${bootloader_id} /dev/sda

# Check
if [ -d "/boot/EFI/${bootloader_id}" ]; then
  echo "/boot/EFI/${bootloader_id} is created"
fi

# Edit /etc/default/grub
#
# Automates the following manutal steps
#
# First obtain both UUIDs of encrypted and decrypted partition using blkid command.
#     blkid -o value -s UUID /dev/${encrypted_device} >> /etc/default/grub
#     blkid -o value -s UUID /dev/mapper/${decrypted_device} >> /etc/default/grub
# Update `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`
#     GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=UUID=<uuid-for-encrypted-fs>:${hostname}sec root=UUID=<uuid-for-decrypted-fs>"
default_mapper_name="${hostname}sec"
encrypted_fs="${ENCRYPTED_FS:-sda2}"
decrypted_fs="${DECRYPTED_FS:-$default_mapper_name}"
echo "encrypted_fs=${encrypted_fs}"
echo "decrypted_fs=${decrypted_fs}"

encrypted_fs_uuid=$(blkid -o value -s UUID /dev/${encrypted_fs})
decrypted_fs_uuid=$(blkid -o value -s UUID /dev/mapper/${decrypted_fs})

if [[ "${encrypted_fs_uuid}" == "" ]]; then
  echo "/dev/${encrypted_fs} not found."
  exit 2
fi
if [[ "${decrypted_fs_uuid}" == "" ]]; then
  echo "/dev/mapper/${decrypted_fs} not found."
  exit 2
fi

echo "/dev/${encrypted_fs} -> ${encrypted_fs_uuid}"
echo "/dev/mapper/${decrypted_fs} -> ${decrypted_fs_uuid}"

sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*\"$/\
GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet \
cryptdevice=UUID=${encrypted_fs_uuid}:${decrypted_fs} \
root=UUID=${decrypted_fs_uuid}\"/" /etc/default/grub

# Generate main GRUB config
grub-mkconfig -o /boot/grub/grub.cfg

# Exist / Umount / Reboot
echo 'Run following commands:'
echo 'passwd'
echo "passwd ${username}"
echo 'exit'
echo 'umount -R /mnt'
echo 'reboot'