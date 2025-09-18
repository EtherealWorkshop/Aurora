#!/bin/sh

# Ran during Aurora's build process to install packages for the booting process

cat <<EOF > /etc/apk/repositories
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

apk add bash e2fsprogs e2fsprogs-extra cloud-utils-growpart util-linux busybox parted grep cgpt coreutils sgdisk pv rsync >/dev/null