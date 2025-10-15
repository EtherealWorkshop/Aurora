#!/bin/sh

# Ran during Aurora's build process to install packages for the booting process

cat <<EOF > /etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

apk add --no-cache e2fsprogs e2fsprogs-extra parted

rm -rf /var/cache/apk/* || true