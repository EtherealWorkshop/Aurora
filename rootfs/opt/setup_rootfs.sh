#!/bin/sh

# Ran during Aurora's build process to install packages for the Aurora partition

cat <<EOF > /etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

apk add --no-cache ncurses jq rsync cgpt unzip fastfetch lsblk wpa_supplicant curl coreutils bash openrc dbus ca-certificates sudo iw sfdisk wget tar xz losetup zstd >/dev/null
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
