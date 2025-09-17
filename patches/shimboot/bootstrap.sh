#!/bin/busybox sh

invoke_terminal() {
  local tty="$1"
  local title="$2"
  shift
  shift
  echo "${title}" >>${tty}
  setsid sh -c "exec script -afqc '$*' /dev/null <${tty} >>${tty} 2>&1 &"
}

enable_debug_console() {
  local tty="$1"
  echo -e "debug console enabled on ${tty}"
  invoke_terminal "${tty}" "[Bootstrap Debug Console]" "/bin/busybox sh"
}

get_part_dev() {
  local disk="$1"
  local partition="$2"
  last_char="$(echo -n "$disk" | tail -c 1)"
  if [ "$last_char" -eq "$last_char" ] 2>/dev/null; then
    echo "${disk}p${partition}"
  else
    echo "${disk}${partition}"
  fi
}

find_rootfs_partitions() {
  for dev in /dev/*; do
    if [ -b "$dev" ] && cgpt show "$dev" >/dev/null 2>&1; then
      for i in $(seq 1 128); do
        label=$(cgpt show -i "$i" -l "$dev" 2>/dev/null)
        if [ -n "$label" ] && printf "%s" "$label" | grep -q '^shimboot'; then
          case "$dev" in
            *[0-9]) part="${dev}p$i" ;;
            *)      part="${dev}$i"  ;;
          esac
          echo "$part:$label"
        fi
      done
    fi
  done
}

find_chromeos_partitions() {
  local roota_partitions="$(cgpt find -l ROOT-A)"
  local rootb_partitions="$(cgpt find -l ROOT-B)"

  if [ "$roota_partitions" ]; then
    for partition in $roota_partitions; do
      echo "${partition}:ChromeOS_ROOT-A:CrOS"
    done
  fi
  
  if [ "$rootb_partitions" ]; then
    for partition in $rootb_partitions; do
      echo "${partition}:ChromeOS_ROOT-B:CrOS"
    done
  fi
}

find_all_partitions() {
  echo "$(find_chromeos_partitions)"
  echo "$(find_rootfs_partitions)"
}

move_mounts() {
  local base_mounts="/sys /proc /dev"
  local newroot_mnt="$1"
  for mnt in $base_mounts; do
    mkdir -p "$newroot_mnt$mnt"
    mount -n -o move "$mnt" "$newroot_mnt$mnt"
  done
}

print_license() {
  local shimboot_version="$(cat /opt/.shimboot_version)"
  if [ -f "/opt/.shimboot_version_dev" ]; then
    local git_hash="$(cat /opt/.shimboot_version_dev)"
    local suffix="-dev-$git_hash"
  fi
  cat << EOF 
Shimboot ${shimboot_version}${suffix}

ading2210/shimboot: Boot desktop Linux from a Chrome OS RMA shim.
Copyright (C) 2023 ading2210

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
EOF
}

print_selector() {
  local rootfs_partitions="$1"
  local i=1

  echo "┌──────────────────────┐"
  echo "│ Shimboot OS Selector │"
  echo "└──────────────────────┘"

  if [ "${rootfs_partitions}" ]; then
    for rootfs_partition in $rootfs_partitions; do
      local part_path=$(echo $rootfs_partition | cut -d ":" -f 1)
      local part_name=$(echo $rootfs_partition | cut -d ":" -f 2)
      echo "${i}) ${part_name} on ${part_path}"
      i=$((i+1))
    done
  else
    echo "no bootable partitions found. please see the shimboot documentation to mark a partition as bootable."
  fi
  echo "a) boot aurora"
  echo "q) reboot"
  echo "s) enter a shell"
  echo "l) view license"
}

auroraselected() {
    echo "Moving mounts to /auroraroot"
    mkdir -p "/auroraroot/sys"
    mount -n -o move "/sys" "/auroraroot/sys"
    mkdir -p "/auroraroot/proc"
    mount -n -o move "/proc" "/auroraroot/proc"
    mkdir -p "/auroraroot/dev"
    mount -n -o move "/dev" "/auroraroot/dev"
    mkdir -p /auroraroot/initramfs
    chmod +x /auroraroot/sbin/init
    pivot_root /auroraroot /auroraroot/initramfs
    umount -l /initramfs
    exec /sbin/init < "$TTY1" >> "$TTY1" 2>&1
}

get_selection() {
  local rootfs_partitions="$1"
  local i=1

  read -p "Your selection: " selection
  if [ "$selection" = "q" ]; then
    echo "rebooting now."
    reboot -f
  elif [ "$selection" = "s" ]; then
    script -qfc 'stty sane && stty erase '^H' && exec busybox sh -l' /dev/null
  elif [ "$selection" = "a" ]; then
    auroraselected
  elif [ "$selection" = "l" ]; then
    clear
    print_license
    echo
    read -p "press [enter] to return to the bootloader menu"
    return 1
  fi

  local selection_cmd="$(echo "$selection" | cut -d' ' -f1)"
  if [ "$selection_cmd" = "rescue" ]; then
    selection="$(echo "$selection" | cut -d' ' -f2-)"
    rescue_mode="1"
  else
    rescue_mode=""
  fi

  for rootfs_partition in $rootfs_partitions; do
    local part_path=$(echo $rootfs_partition | cut -d ":" -f 1)
    local part_name=$(echo $rootfs_partition | cut -d ":" -f 2)
    local part_flags=$(echo $rootfs_partition | cut -d ":" -f 3)

    if [ "$selection" = "$i" ]; then
      echo "selected $part_path"
      if [ "$part_flags" = "CrOS" ]; then
        echo "booting chrome os partition"
        print_donor_selector "$rootfs_partitions"
        get_donor_selection "$rootfs_partitions" "$part_path"
      else
        boot_target "$part_path"
      fi
      return 1
    fi

    i=$((i+1))
  done
  
  echo "invalid selection"
  sleep 1
  return 1
}

copy_progress() {
  local source="$1"
  local destination="$2"
  mkdir -p "$destination"
  tar -cf - -C "${source}" . | pv -f | tar -xf - -C "${destination}"
}

print_donor_selector() {
  local rootfs_partitions="$1"
  local i=1;

  echo "Choose a partition to copy firmware and modules from:";

  for rootfs_partition in $rootfs_partitions; do
    local part_path=$(echo $rootfs_partition | cut -d ":" -f 1)
    local part_name=$(echo $rootfs_partition | cut -d ":" -f 2)
    local part_flags=$(echo $rootfs_partition | cut -d ":" -f 3)

    if [ "$part_flags" = "CrOS" ]; then
      continue;
    fi

    echo "${i}) ${part_name} on ${part_path}"
    i=$((i+1))
  done
}

yes_no_prompt() {
  local prompt="$1"
  local var_name="$2"

  while true; do
    read -p "$prompt" temp_result

    if [ "$temp_result" = "y" ] || [ "$temp_result" = "n" ]; then
      eval "$var_name='$temp_result'"
      return 0
    else
      echo "invalid selection"
    fi
  done
}

get_donor_selection() {
  local rootfs_partitions="$1"
  local target="$2"
  local i=1;
  read -p "Your selection: " selection

  for rootfs_partition in $rootfs_partitions; do
    local part_path=$(echo $rootfs_partition | cut -d ":" -f 1)
    local part_name=$(echo $rootfs_partition | cut -d ":" -f 2)
    local part_flags=$(echo $rootfs_partition | cut -d ":" -f 3)

    if [ "$part_flags" = "CrOS" ]; then
      continue;
    fi

    if [ "$selection" = "$i" ]; then
      echo "selected $part_path as the donor partition"
      yes_no_prompt "would you like to spoof verified mode? this is useful if you're planning on using chrome os while enrolled. (y/n): " use_crossystem
      yes_no_prompt "would you like to spoof an invalid hwid? this will forcibly prevent the device from being enrolled. (y/n): " invalid_hwid
      boot_chromeos "$target" "$part_path" "$use_crossystem" "$invalid_hwid"
    fi

    i=$((i+1))
  done

  echo "invalid selection"
  sleep 1
  return 1
}

exec_init() {
  if [ "$rescue_mode" = "1" ]; then
    echo "entering a rescue shell instead of starting init"
    echo "once you are done fixing whatever is broken, run 'exec /sbin/init' to continue booting the system normally"
    
    if [ -f "/bin/bash" ]; then
      exec /bin/bash < "$TTY1" >> "$TTY1" 2>&1
    else
      exec /bin/sh < "$TTY1" >> "$TTY1" 2>&1
    fi
  else
    exec /sbin/init < "$TTY1" >> "$TTY1" 2>&1
  fi
}

boot_target() {
  local target="$1"

  echo "moving mounts to newroot"
  mkdir -p /newroot
  mount $target /newroot
  mkdir -p /newroot/bootloader
  mkdir -p  /newroot/auroraroot
  mount --move /auroraroot /newroot/auroraroot
  if [ -f "/bin/frecon-lite" ]; then 
    rm -f /dev/console
    touch /dev/console
    mount -o bind "$TTY1" /dev/console
  fi
  move_mounts /newroot

  echo "switching root"
  pivot_root /newroot /newroot/bootloader
  exec_init
}

boot_chromeos() {
  local target="$1"
  local donor="$2"
  local use_crossystem="$3"
  local invalid_hwid="$4"
  
  echo "mounting target"
  mkdir /newroot
  mount -o ro $target /newroot

  echo "mounting tmpfs"
  mount -t tmpfs -o mode=1777 none /newroot/tmp
  mount -t tmpfs -o mode=0555 run /newroot/run
  mkdir -p -m 0755 /newroot/run/lock

  echo "mounting donor partition"
  local donor_mount="/newroot/tmp/donor_mnt"
  local donor_files="/newroot/tmp/donor"
  mkdir -p $donor_mount
  mount -o ro $donor $donor_mount

  echo "copying modules and firmware to tmpfs (this may take a while)"
  copy_progress $donor_mount/lib/modules $donor_files/lib/modules
  copy_progress $donor_mount/lib/firmware $donor_files/lib/firmware
  mount -o bind $donor_files/lib/modules /newroot/lib/modules
  mount -o bind $donor_files/lib/firmware /newroot/lib/firmware
  umount $donor_mount
  rm -rf $donor_mount

  if [ -e "/newroot/etc/init/tpm-probe.conf" ]; then
    echo "applying chrome os flex patches"
    mkdir -p /newroot/tmp/empty
    mount -o bind /newroot/tmp/empty /sys/class/tpm

    cat /newroot/etc/lsb-release | sed "s/DEVICETYPE=OTHER/DEVICETYPE=CHROMEBOOK/" > /newroot/tmp/lsb-release
    mount -o bind /newroot/tmp/lsb-release /newroot/etc/lsb-release
  fi

  echo "patching chrome os rootfs"
  cat /newroot/etc/ui_use_flags.txt | sed "/reven_branding/d" | sed "/os_install_service/d" > /newroot/tmp/ui_use_flags.txt
  mount -o bind /newroot/tmp/ui_use_flags.txt /newroot/etc/ui_use_flags.txt

  cp /opt/mount-encrypted /newroot/tmp/mount-encrypted
  cp /newroot/usr/sbin/mount-encrypted /newroot/tmp/mount-encrypted.real
  mount -o bind /newroot/tmp/mount-encrypted /newroot/usr/sbin/mount-encrypted
  
  cat /newroot/etc/init/boot-splash.conf | sed '/^script$/a \  pkill frecon-lite || true' > /newroot/tmp/boot-splash.conf
  mount -o bind /newroot/tmp/boot-splash.conf /newroot/etc/init/boot-splash.conf
  
  if [ "$use_crossystem" = "y" ]; then
    echo "patching crossystem"
    cp /opt/crossystem /newroot/tmp/crossystem
    if [ "$invalid_hwid" = "y" ]; then
      sed -i 's/block_devmode/hwid/' /newroot/tmp/crossystem
    fi

    cp /newroot/usr/bin/crossystem /newroot/tmp/crossystem_old
    mount -o bind /newroot/tmp/crossystem /newroot/usr/bin/crossystem
  fi

  echo "moving mounts"
  move_mounts /newroot

  echo "switching root"
  mkdir -p /newroot/tmp/bootloader
  pivot_root /newroot /newroot/tmp/bootloader

  echo "starting init"
  /sbin/modprobe zram
  exec_init
}

echo "starting the shimboot bootloader"
enable_debug_console "$TTY2"
valid_partitions="$(find_all_partitions)"
while true; do
    clear
    print_selector "${valid_partitions}"
    if get_selection "${valid_partitions}"; then
        break
    fi
done
sleep 1d
