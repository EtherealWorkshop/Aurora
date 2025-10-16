#!/bin/sh

# Ran during Aurora's build process to install packages for the booting process

cat <<EOF > /etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

apk update --no-cache >/dev/null 2>&1
apk add --no-cache e2fsprogs e2fsprogs-extra parted >/dev/null 2>&1

rm -rf /var/cache/apk/* || true