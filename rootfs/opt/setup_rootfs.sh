#!/bin/sh

# Ran during Aurora's build process to install packages for the Aurora partition

cat <<EOF > /etc/apk/repositories
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF
apk add jq debootstrap rsync cgpt file unzip dhcpcd pcre-tools tzdata fastfetch figlet syslog-ng e2fsprogs fish lsblk cfdisk wpa_supplicant vboot-utils curl tpm2-tools cryptsetup coreutils bash openrc dbus ca-certificates eudev udev-init-scripts ncurses udisks2 sudo zram-init iw wpa_supplicant cloud-utils-growpart nano sfdisk sgdisk wget gnupg tar xz zstd losetup seatd >/dev/null

modules="$(ls /etc/modules-load.d)"
for module in $modules; do
  cat "/etc/modules-load.d/$module" >> /etc/modules
  echo >> /etc/modules
done
echo "Aurora" > /etc/hostname
echo "127.0.0.1 localhost Aurora" >> /etc/hosts
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
echo root:root | chpasswd 2>/dev/null
sed -i 's/setup=0/setup=1/' /etc/aurora
