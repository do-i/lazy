local hostname=${1}
if [ "$hostname" == "" ]; then
  echo "specify hostname"
  exit 1
fi

### SSH - daemon
systemctl enable sshd

### Clock
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime
hwclock --systohc
date

### Locale
sed -i '/^#en_US\.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

### Hostname
echo ${hostname} > /etc/hostname

### DHCP
systemctl enable dhcpcd
