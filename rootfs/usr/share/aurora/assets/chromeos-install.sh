#!/bin/sh -u
# Copyright 2012 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# A script to install from removable media to hard disk.

# Warn folks who try to run the script directly.
#
# We don't pass args to this script, everything is communicated through the env.
# If an arg is provided (if "$*", a string of the args, is non-zero in length)
# or if one of our FLAGS_* variables is unset (`${FLAGS_debug:-} is zero length)
# print a message to point people at the right script.
if [ -n "$*" ] || [ -z "${FLAGS_debug:-}" ]; then
  echo "chromeos-install.sh shouldn't be called directly. Use chromeos-install."
  exit 1
fi

# These will be set as environment variables by the calling rust binary:
# FLAGS_dst
# FLAGS_skip_dst_removable
# FLAGS_skip_rootfs
# FLAGS_yes
# FLAGS_preserve_stateful
# FLAGS_payload_image
# FLAGS_pmbr_code
# FLAGS_target_bios
# FLAGS_debug
# FLAGS_skip_postinstall
# FLAGS_lab_preserve_logs
# FLAGS_storage_diags
# FLAGS_minimal_copy
# FLAGS_skip_gpt_creation
# SRC: The block device we're installing from, e.g. '/dev/sda' or '/dev/loop1'
# ROOT: Location of the root filesystem (i.e. ROOT-A). If installing the
#       currently-running rootfs, this is set to an empty string.
# TMPMNT: Temporary mount point path.
# All the variables under "load_base_vars" in /usr/sbin/partition_vars.json.

# To keep changes minimal, temporarily define these boolean constants which were
# previously supplied by shflags.
FLAGS_TRUE="0"
FLAGS_FALSE="1"

# Load functions and constants for chromeos-install.
# shellcheck source=../chromeos-common-script/share/chromeos-common.sh
. /usr/share/misc/chromeos-common.sh || exit 1
# shellcheck source=../chromeos-common-script/share/lvm-utils.sh
. /usr/share/misc/lvm-utils.sh || exit 1

# Source blocksize
SRC_BLKSIZE=512

# Copy the rootfs in chunks to optimize disk cache usage.
NUM_ROOTFS_CHUNKS=4

# Cached recovery key version read from flashrom.
RECOVERY_KEY_VERSION=

# Helpful constants.
HARDWARE_DIAGNOSTICS_PATH=/tmp/hardware_diagnostics.log

die() {
  echo "$*" >&2
  exit 1
}

fast_dd() {
  # Usage: fast_dd <count> <seek> <skip> other dd args
  # Note: <count> and <seek> are in units of SRC_BLKSIZE, while <skip> is in
  # units of DST_BLKSIZE.
  local user_count="$1"
  local chunk_num="$2"
  local total_chunks="$3"
  shift 3

  if ! "${BUSYBOX_DD_FOUND:?}"; then
    # Provide some simple progress updates to the user.
    # This was made available from coreutils version 8.24.
    set -- "$@" status=progress
  fi
  # Find the largest block size of power of 2 that fits.
  local block_size=$((2 * 1024 * 1024))
  while [ $(((user_count * SRC_BLKSIZE) % block_size)) -ne 0 ]; do
    : $((block_size /= 2))
  done

  # Print a humble info line if the block size is not super, and complain more
  # loudly if it's really small (and the partition is big).
  if [ "${block_size}" -ne $((2 * 1024 * 1024)) ]; then
    echo "DD with block size ${block_size}"
    if [ "${block_size}" -lt $((128 * 1024)) ] && \
        [ $((user_count * SRC_BLKSIZE)) -gt $((128 * 1024 * 1024)) ]; then
      echo
      echo "WARNING: DOING A SLOW MISALIGNED dd OPERATION. PLEASE FIX"
      echo "count=${user_count} SRC_BLKSIZE=${SRC_BLKSIZE} "
      echo "DST_BLKSIZE=${DST_BLKSIZE}"
      echo
    fi
  fi

  # Convert the block counts in their respective sizes into the common block
  # size, and blast off.
  local count_common=$((user_count * SRC_BLKSIZE / block_size))
  local seek_common=0
  local skip_common=0

  if [ "${total_chunks}" -ne 1 ]; then
    # Divide the count by the number of chunks, rounding up.  This is the
    # chunk size.
    local chunk_size=$(((count_common + total_chunks - 1) / total_chunks))

    : $(( seek_common += chunk_size * (chunk_num - 1) ))
    : $(( skip_common += chunk_size * (chunk_num - 1) ))

    if [ "${chunk_num}" -ne "${total_chunks}" ]; then
      count_common="${chunk_size}"
    else
      : $(( count_common -= chunk_size * (chunk_num - 1) ))
    fi
  fi

  dd "$@" bs="${block_size}" seek="${seek_common}" skip="${skip_common}" \
      "count=${count_common}"
}

# Update a specific partition in the destination device.
write_partition() {
  local user_count="$1"
  local src="$2"
  local dst="$3"
  local chunk_num="$4"
  local total_chunks="$5"
  local cache_input="$6"

  if [ "${user_count}" -eq 0 ]; then
    echo "Skipping partition as it does not exist"
    return 0
  fi

  # The "dd" command can be used to advise Linux to drop caches and we use
  # this feature to maximize available cache for future transfers. We deal
  # with the input and output block devices differently. Here's why:
  # - For the input block device there are some cases where we know we'll
  #   want the input to stay in cache (because we're going to use it again)
  #   and other cases where we know we're done with it. Also note that we
  #   are likely running from the input block device, so it's good not to
  #   be too liberal about dropping the cache.
  # - For the output block we never need the cache kept. We won't be reading
  #   it again. We can just tell Linux to drop the cache for the whole
  #   device each time. It should also be noted that it appears most
  #   efficient not to drop the cache on the output as part of the same "dd"
  #   doing the transfer (presumably it makes write buffers less efficient).
  local dd_cache_arg=;
  # The iflag is unsupported in older versions of "dd".
  if ! "${cache_input}" && ! "${BUSYBOX_DD_FOUND:?}"; then
    dd_cache_arg="iflag=nocache"
  fi

  # dd_cache_arg intentionally not quoted to avoid adding empty arg if unset.
  # shellcheck disable=SC2248
  fast_dd "${user_count}" "${chunk_num}" "${total_chunks}" \
    if="${src}" of="${dst}" conv=notrunc ${dd_cache_arg}

  # Incantation to advise the kernel to drop cache on the whole dst.
  #
  # dd_cache_arg intentionally not quoted to avoid adding empty arg if unset.
  # shellcheck disable=SC2248
  dd if="${dst}" ${dd_cache_arg} count=0 status=none
}

# Check for optional payload image
check_payload_image() {
  local partition_num_root_a
  local partition_num_state
  local root_block
  local state_block

  if [ -n "${FLAGS_payload_image}" ]; then
    # Set a loop device for the payload image and one for each of its
    # partitions.
    SRC="$("${LOSETUP_PATH:?}" -f "${FLAGS_payload_image}" --show --partscan)"
    LOOPS="${SRC}${LOOPS:+ }${LOOPS:-}"
    ROOT="$(mktemp -d)"

    partition_num_root_a=$(cgpt find -n -l ROOT-A "${SRC}")
    partition_num_state=$(cgpt find -n -l STATE "${SRC}")

    root_block="$(make_partition_dev "${SRC}" "${partition_num_root_a}")"
    state_block="$(make_partition_dev "${SRC}" "${partition_num_state}")"

    # Mount the source image root and stateful partition.
    tracked_mount -o ro "${root_block}" "${ROOT}"
    tracked_mount -o ro "${state_block}" "${ROOT}/mnt/stateful_partition"
  fi
}

# Like mount but keeps track of the current mounts so that they can be cleaned
# up automatically.
tracked_mount() {
  local last_arg
  eval last_arg=\$$#
  MOUNTS="${last_arg}${MOUNTS:+ }${MOUNTS:-}"
  mount "$@"
}

# Unmount with tracking.
tracked_umount() {
  # dash does not support ${//} expansions.
  local new_mounts
  for mount in ${MOUNTS}; do
    if [ "${mount}" != "$1" ]; then
      new_mounts="${new_mounts:-}${new_mounts+ }${mount}"
    fi
  done
  MOUNTS=${new_mounts:-}

  umount "$1"
}

# Undo all mounts and loops and runs hw diagnostics on failure.
cleanup_on_failure() {
  set +e

  if [ "${FLAGS_storage_diags:?}" -eq "${FLAGS_TRUE}" ]; then
    # Generate the diagnostics log that can be used by a caller.
    echo "Running a hw diagnostics test -- this might take a couple minutes."
    badblocks -e 100 -sv "${DST}" 2>&1 | tee "${HARDWARE_DIAGNOSTICS_PATH}"

    if [ -f /usr/share/misc/storage-info-common.sh ]; then
      # shellcheck source=../storage_info/share/storage-info-common.sh
      . /usr/share/misc/storage-info-common.sh
      # Run a few extra diagnostics with output to stdout. These will
      # be stored as part of the recovery.log for recovery images.
      get_storage_info
    fi
  fi

  cleanup
}

deactivate_volume_group() {
  # Suppress failures and fallback to default value.
  set +e

  local vg="${1}"
  local rc=0
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    vgchange -an "${vg}"
    rc="$?"
    if [ "${rc}" -eq "0" ]; then
      break
    fi
    sleep 1
  done

  # Back to strict.
  set -e

  return "${rc}"
}

# Undo all mounts and loops.
cleanup() {
  set +e

  local mount_point
  for mount_point in ${MOUNTS:-}; do
    umount "${mount_point}" || /bin/true
  done
  MOUNTS=""

  local loop_dev
  for loop_dev in ${LOOPS:-}; do
    "${LOSETUP_PATH:?}" -d "${loop_dev}" || /bin/true
  done
  LOOPS=""

  if [ -n "${ROOT}" ]; then
    rmdir "${ROOT}"
  fi
}

check_removable() {
  if [ "${FLAGS_skip_dst_removable:?}" -eq "${FLAGS_TRUE}" ]; then
    return
  fi

  local removable

  if ! removable="$(cat "/sys/block/${DST#/dev/}/removable")"; then
    die "Error: Invalid destination device (must be whole device): ${DST}"
  fi

  if [ "${removable}" != "0" ]; then
    die "Error: Attempt to install to a removeable device: ${DST}"
  fi
}

mkfs() {
  local fs_sector_count="$1"
  local device="$2"
  local label="$3"
  # We re-use $@ for our custom options below, so reset it.
  set --

  # Check if the kernel we are going to install support ext4 crypto.
  if ext4_dir_encryption_supported; then
    set -- "$@" -O encrypt
  fi

  # Check if the kernel we are going to install support ext4 fs-verity.
  if ext4_fsverity_supported; then
    set -- "$@" -O verity
  fi

  # Calculate the number of 4k sectors for the ext4 partition.
  local num_4k_sectors
  local sector_size=4096
  if [ "${DST_BLKSIZE}" -gt "${sector_size}" ]; then
    num_4k_sectors=$(( fs_sector_count * (DST_BLKSIZE / sector_size) ))
  else
    num_4k_sectors=$(( fs_sector_count / (sector_size / DST_BLKSIZE) ))
  fi

  mkfs.ext4 -F -b "${sector_size}" -L "${label}" "$@" "${device}" \
    "${num_4k_sectors}"

}

wipe_partition() {
  local partition="$1"
  local device="$2"
  local part_dev

  part_dev=$(make_partition_dev "${device}" "${partition}")
  dd if=/dev/zero of="${part_dev}" bs=1M count=1 > /dev/null 2>&1
}


# Wipes and expands the stateful partition.
wipe_stateful() {
  local device

  echo "Clearing the stateful partition..."
  local stateful_size
  # state options are stored in $@.
  set --

  # Zero out the first block of the stateful partition to ensure that
  # mkfs/pvcreate don't get confused by existing state.
  wipe_partition "${PARTITION_NUM_STATE:?}" "${DST}"

  device=$(make_partition_dev "${DST}" "${PARTITION_NUM_STATE:?}")
  stateful_size="$(partsize "${DST}" "${PARTITION_NUM_STATE:?}")"
  mkfs "${stateful_size}" "${device}" "H-STATE"

  # When the stateful partition is wiped the TPM ownership must be reset.
  # This command will not work on Flex devices which do not support it.
  # In that case the result will be ignored.
  if [ "$(crossystem mainfw_type)" != "nonchrome" ]; then
    crossystem clear_tpm_owner_request=1
  else
    crossystem clear_tpm_owner_request=1 || true
  fi
}

# Install the stateful partition content
# Method handles copying data over to the stateful partition. This is done
# differently than other partitions due to the EXPAND option i.e. src partition
# and dst partitions are of different sizes. In addition, there are some special
# tweaks we do for stateful here for various workflows.
install_stateful() {
  # In general, the system isn't allowed to depend on anything
  # being in the stateful partition at startup.  We make some
  # exceptions for dev images + factory installed DLCs, as enumerated below:
  #
  # var_overlay
  #   These are included to support gmerge, and must be kept in
  #   sync with those listed in /etc/init/var-overlay.conf:
  #      db/pkg
  #      lib/portage
  #   These are included to support dlcservice preloading for testing from usb
  #   flash.
  #      cache/dlc-images
  #
  # dev_image
  #   This provides tools specifically chosen to be mounted at
  #   /usr/local as development only tools.
  #
  # dlc-factory-images
  #   Includes the factory installed DLC images. Will be removed post boot as
  #   the dlcservice daemon will move the factory installed images into the DLC
  #   cache directory.
  #
  # unencrypted/dev_image.block
  #   For devices that support dm-default-key stateful, dev_image and
  #   var_overlay is set up as separate filesystem to faciliatate ease of
  #   preseeding during install flows.
  #
  # Every exception added makes the dev image different from
  # the release image, which could mask bugs.  Make sure every
  # item you add here is well justified.
  local loop_dev

  echo "Installing the stateful partition..."
  loop_dev="$(make_partition_dev "${DST}" "${PARTITION_NUM_STATE:?}")"
  tracked_mount -o "nosuid,nodev,rw,noexec,nosymfollow" "${loop_dev}" "${TMPMNT:?}"

  # Move log files listed in FLAGS_lab_preserve_logs from stateful_partition to
  # a dedicated location. This flag is used to enable Autotest to collect log
  # files before reimage deleting all prior logs.
  if crossystem 'cros_debug?1' && [ -n "${FLAGS_lab_preserve_logs}" ]; then
    local gatherme="${TMPMNT}/.gatherme"
    touch "${gatherme}"
    local prior_log_dir="${TMPMNT}/unencrypted/prior_logs"
    mkdir -p "${prior_log_dir}"
    local log_path
    # shellcheck disable=SC2013
    for log_path in $(sed -e '/^#/ d' -e '/^$/ d' "${FLAGS_lab_preserve_logs}"); do
      case "${log_path}" in
        /dev/* | /sys/*)
          ;;
        /*)
          echo "${log_path}" >> "${gatherme}"
          continue
          ;;
        *)
          log_path="${TMPMNT}/${log_path}"
          ;;
      esac
      if [ -d "${log_path}" ]; then
        cp -au -r --parents "${log_path}" "${prior_log_dir}" || true
      elif [ -f "${log_path}" ]; then
        cp -au "${log_path}" "${prior_log_dir}" || true
      fi
    done
  fi

  # Whitelist files to copy onto the stateful partition.
  #
  # When adding to the whitelist, consider the need for related changes in
  # src/platform/init/chromeos_startup, and in src/platform/dev/stateful_update.
  #
  local dirlist="unencrypted/cros-components/offline-demo-mode-resources
    unencrypted/import_extensions
    unencrypted/dlc-factory-images
    unencrypted/flex_config"
  local filelist=""

  if crossystem 'cros_debug?1'; then
    # Install dev_image.block if present, files by files otherwise.
    local dev_image_block="unencrypted/dev_image.block"
    if [ -f "${ROOT}/mnt/stateful_partition/${dev_image_block}" ]; then
      filelist="${filelist} ${dev_image_block}"
    else
      dirlist="${dirlist}
        var_overlay/db/pkg
        var_overlay/lib/portage
        dev_image"

      local metadata_dir="${ROOT}/opt/google/dlc"
      local metadata_cmd="dlc_metadata_util --metadata_dir=${metadata_dir}"
      local dlc_list
      if dlc_list=$(${metadata_cmd} --list --preload_allowed); then
        for dlc_id in $(jq -nr --argjson list "${dlc_list}" '$list[]'); do
          local metadata
          if metadata=$(${metadata_cmd} --get --id="${dlc_id}"); then
            local dlc_pkg
            dlc_pkg="$(jq -nr --argjson metadata "${metadata}" \
              '$metadata."manifest"."package"')"
            if [ -z "${dlc_pkg}" ] || [ "${dlc_pkg}" = "null" ]; then
              dlc_pkg="package"
            fi
            printf 'Preloading DLC=%s\n' "${dlc_id}"
            dirlist="${dirlist}
            var_overlay/cache/dlc-images/${dlc_id}/${dlc_pkg}"
          fi
        done
      fi
    fi
  fi

  if crossystem 'devsw_boot?1' ; then
    # This is a base build, and the dev switch was on when we booted;
    # we assume it will be on for the next boot.  We touch
    # ".developer_mode" to avoid a pointless delay after reboot while
    # chromeos_startup wipes an empty stateful partition.
    #
    # See chromeos_startup for the companion code that checks for this
    # file.
    #
    touch "${TMPMNT}"/.developer_mode
  fi

  if [ -n "${IS_RECOVERY_INSTALL-}" ] ; then
    # This is a recovery install; write some recovery metrics to the stateful
    # partition to be reported after next boot. See:
    # init/upstart/send-recovery-metrics.conf
    local recovery_histograms="${TMPMNT}/.recovery_histograms"
    metrics_client -W "${recovery_histograms}" -e "Installer.Recovery.Reason" \
      "$(crossystem recovery_reason)" 255
  fi

  local dir
  for dir in ${dirlist}; do
    if [ ! -d "${ROOT}/mnt/stateful_partition/${dir}" ]; then
      continue
    fi
    local parent
    parent=$(dirname "${dir}")
    mkdir -p "${TMPMNT}/${parent}"
    # The target directory may already exist (eg. dev_image mounted from a
    # separate volume), use the parent directory as destination for cp.
    cp -au "${ROOT}/mnt/stateful_partition/${dir}" "${TMPMNT}/${parent}"
  done

  local file
  for file in ${filelist}; do
    if [ ! -f "${ROOT}/mnt/stateful_partition/${file}" ]; then
      continue
    fi
    local parent
    parent=$(dirname "${file}")
    cp -au "${ROOT}/mnt/stateful_partition/${file}" "${TMPMNT}/${parent}"
  done

  tracked_umount "${TMPMNT}"
  sync
}

# Get the recovery key version.
# Default value on failure is "1".
get_recovery_key_version() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  local tmpflash="${tmpdir}/flash"
  local tmpflashparsed="${tmpdir}/flashparsed"

  # Suppress failures and fallback to default value.
  set +e

  # Read the flashrom.
  if ! flashrom -i GBB:"${tmpflash}" -r >&2; then
    echo "Failed to read flashrom, defaulting to recovery key version=\"1\"" >&2
    # Default.
    echo "1"
  else
    # If successful, continue to extract the key version.
    futility show "${tmpflash}" > "${tmpflashparsed}"
    local key_version
    key_version="$(grep -A3 'Recovery Key:' "${tmpflashparsed}" \
      | grep 'Key Version:' \
      | grep -Eo '[0-9]+')"
    echo "${key_version}"
  fi

  # Cleanup tmp files and directory.
  for p in "${tmpflash}" "${tmpflashparsed}"; do
    unlink "${p}"
  done
  rmdir "${tmpdir}"

  # Back to strict.
  set -e
}

safety_check_size() {
  local part_num="$1"
  local part_size="$2"
  local dst="$3"

  local src_part_size
  local dst_part_size
  src_part_size="$((part_size * SRC_BLKSIZE))"
  dst_part_size="$(partsize "${dst}" "${part_num}")"
  dst_part_size="$((dst_part_size * DST_BLKSIZE))"
  if [ "${src_part_size}" -ne "${dst_part_size}" ] || \
      [ "${src_part_size}" -le 4096 ]; then
    # We only copy partitions that are equally sized and greater than the
    # min fs block size. This matches the build_image logic.
    return 1
  fi

  return 0
}

# Copy partition from src to dst (figures out partition offsets). Note, this
# has some special casing for rootfs, kernel, and stateful partitions. In
# addition, it only copies partitions that are equally sized over one another.
# $1 - Partition number we are copying to.
# $2 - src image
# $3 - dst image.
# $4 - chunk_num
# $5 - total_chunks
# $6 - cache_input
copy_partition() {
  local part_num="$1"
  local src="$2"
  local dst="$3"
  local chunk_num="$4"
  local total_chunks="$5"
  local cache_input="$6"
  local part_size
  local src_block
  local dst_block

  part_size="$(partsize "${src}" "${part_num}")"
  src_block="$(make_partition_dev "${src}" "${part_num}")"
  dst_block="$(make_partition_dev "${dst}" "${part_num}")"

  local chunk_status=""
  if [ "${total_chunks}" -ne 1 ]; then
    chunk_status=", chunk ${chunk_num} of ${total_chunks}"
  fi

  echo "Installing partition ${part_num} to ${dst}${chunk_status}"

  case "${part_num}" in
  "")
    echo "Error: Empty part_num is passed. Skip copying."
    return
    ;;
  "${PARTITION_NUM_STATE:?}")
    install_stateful
    ;;
  "${PARTITION_NUM_ROOT_A:?}")
    # Always copy from ROOT_A for rootfs partitions.
    part_size=$(partsize "${src}" "${PARTITION_NUM_ROOT_A:?}")
    src_block="$(make_partition_dev "${src}" "${PARTITION_NUM_ROOT_A:?}")"
    write_partition "${part_size}" "${src_block}" "${dst_block}" \
      "${chunk_num}" "${total_chunks}" "${cache_input}"
    ;;
  "${PARTITION_NUM_KERN_A:?}")
    # Use kernel B from the source into both kernel A and B in the destination.
    part_size="$(partsize "${src}" "${PARTITION_NUM_KERN_B:?}")"
    src_block="$(make_partition_dev "${src}" "${PARTITION_NUM_KERN_B:?}")"
    write_partition "${part_size}" "${src_block}" "${dst_block}" \
      "${chunk_num}" "${total_chunks}" "${cache_input}"
    ;;
  # If the disk layout doesn't have minios, these are set to an empty value.
  "${PARTITION_NUM_MINIOS_A:-}"|"${PARTITION_NUM_MINIOS_B:-}")
    # Choose to copy from A or B for miniOS partitions.
    local src_part_num
    if [ -n "${RECOVERY_KEY_VERSION}" ]; then
      echo "Using cached recovery key version=\"${RECOVERY_KEY_VERSION}\""
    else
      RECOVERY_KEY_VERSION=$(get_recovery_key_version)
      echo "Using recovery key version=\"${RECOVERY_KEY_VERSION}\""
    fi
    if [ "${RECOVERY_KEY_VERSION}" -eq "1" ]; then
      src_part_num="${PARTITION_NUM_MINIOS_A:?}"
    else
      src_part_num="${PARTITION_NUM_MINIOS_B:?}"
    fi
    part_size="$(partsize "${src}" "${src_part_num}")"
    src_block="$(make_partition_dev "${src}" "${src_part_num}")"
    write_partition "${part_size}" "${src_block}" "${dst_block}" \
      "${chunk_num}" "${total_chunks}" "${cache_input}"
    ;;
  "${PARTITION_NUM_EFI_SYSTEM:?}")
    # On destination devices with a 4k block size, the vfat filesystem on the
    # EFI-System Partition (ESP) can't be bitwise copied to the destination and
    # then mount successfully. Instead we need to make a new filesystem and
    # copy the files over.
    # Unfortunately, doing that seems to break BIOS/legacy booting. For 512 byte
    # block sizes, continue to do this the way we always have, and for other
    # block sizes, which are unlikely to use legacy boot, use the new method.
    if [ "${DST_BLKSIZE}" -eq 512 ]; then
      if safety_check_size "${part_num}" "${part_size}" "${dst}" ; then
        write_partition "${part_size}" "${src_block}" "${dst_block}" \
          "${chunk_num}" "${total_chunks}" "${cache_input}"
      fi
    else
      # >= 4k block size safe, but legacy-boot unsafe.
      # Implemented in a separate Rust binary.
      /usr/sbin/install-copy-esp \
          --src "${src_block}" \
          --dst "${dst_block}"
    fi
    ;;
  "${PARTITION_NUM_KERN_B:?}"|"${PARTITION_NUM_ROOT_B:?}")
    echo "Blocking updates."
    ;;
  *)
    if safety_check_size "${part_num}" "${part_size}" "${dst}" ; then
      write_partition "${part_size}" "${src_block}" "${dst_block}" \
        "${chunk_num}" "${total_chunks}" "${cache_input}"
    fi
    ;;
  esac
}

# Find our destination device.
# If the user hasn't selected a destination,
# we expect that the disk layout declares it for us.
check_dst() {
  if [ -z "${DST}" ]; then
    die "Error: can not determine destination device. Specify --dst yourself."
  fi

  if [ ! -b "${DST}" ]; then
    die "Error: Unable to find destination block device: ${DST}"
  fi

  if [ "${DST}" = "${SRC}" ]; then
    die "Error: src and dst are the same: ${SRC} = ${DST}"
  fi
}

# Gets the right PMBR (protective master boot record) code (either from
# FLAGS_pmbr_code, source or destination media) by printing the file path
# containing PMBR code in standard out.
get_pmbr_code() {
  local pmbr_code="/tmp/gptmbr.bin"

  if [ -n "${FLAGS_pmbr_code}" ]; then
    echo "${FLAGS_pmbr_code}"
  else
    # Steal the PMBR code from the source MBR to put on the dest MBR, for
    # booting on legacy-BIOS devices.
    dd bs="${DST_BLKSIZE}" count=1 if="${SRC}" of="${pmbr_code}" >/dev/null 2>&1
    echo "${pmbr_code}"
  fi
}

# Reload the system partitions after the partition table was modified (so the
# device nodes like /dev/sda1 can be accessed).
reload_partitions() {
  # Reload the partition table on block devices only.
  #
  # In some cases, we may be racing with udev for access to the
  # device leading to EBUSY when we reread the partition table.  We
  # avoid the conflict by using `udevadm settle`, so that udev goes
  # first.  cf. crbug.com/343681.
  local rc=0

  # Sometimes `udevadm settle` can time out. Log the timeout
  # but still continue.
  # The default timeout is 120s, shorten it to 10s to prevent
  # delaying installation unnecessarily. b/379085243
  udevadm settle --timeout=10 || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "udevadm settle timed out."
  fi

  # Sometimes `blockdev --rereadpt` will fail with "ioctl error on
  # BLKRRPART: Device or resource busy" right after `udevadm settle`
  # completes. If the first attempt fails, sleep for a short time and
  # then retry. b/410051948
  rc=0
  /sbin/blockdev --rereadpt "${DST}" || rc=$?
  if [ "${rc}" -ne 0 ]; then
      sleep 1s
      /sbin/blockdev --rereadpt "${DST}"
  fi
}

# Post partition copying work and special casing
do_post_install() {
  set --
  if [ -n "${FLAGS_target_bios}" ]; then
    set -- "$@" --bios "${FLAGS_target_bios}"
  fi
  local dst_rootfs

  dst_rootfs="$(make_partition_dev "${DST}" "${PARTITION_NUM_ROOT_A:?}")"
  # Now run the postinstall script on one new rootfs.
  if [ "${FLAGS_skip_postinstall:?}" -eq "${FLAGS_FALSE}" ]; then
    # NB: postinst changes its behavior depending on the path it's called with.
    # If `ROOT` is non-empty it will set up additional mounts for the chroot.
    echo "Running postinst from '${ROOT}'."
    IS_INSTALL="1" "${ROOT}/postinst" "${dst_rootfs}" "$@"
  fi
}

main() {
  local dst_stateful
  local vg_name

  # Be aggressive.
  set -eu
  if [ "${FLAGS_debug:?}" = "${FLAGS_TRUE}" ]; then
    set -x
  fi

  # On some systems (e.g. MiniOS or Flexor), we use utils from busybox.
  # Those utils might be at an older version and don't support some
  # flags, so we don't use them. This can be checked by looking at `dd`
  # and `losetup` and whether it is coming from BusyBox or not.
  BUSYBOX_DD_FOUND=false
  if dd --version 2>&1 | grep -q "BusyBox"; then
    BUSYBOX_DD_FOUND=true
  fi
  if losetup --version 2>&1 | grep -q "BusyBox"; then
    LOSETUP_PATH="/bin/losetup"
  else
    LOSETUP_PATH="losetup"
  fi

  check_payload_image

  # We untrap on success and run cleanup ourselves. Otherwise, on any failure,
  # run our custom trap method to gather any diagnostic data before cleaning up.
  # Also, cleanup mounts if install is interrupted.
  trap cleanup_on_failure INT TERM EXIT

  locate_gpt

  # Load the GPT helper functions.
  # shellcheck disable=SC1091
  . "${ROOT}/usr/sbin/write_gpt.sh"

  DST=${FLAGS_dst:-$(get_fixed_dst_drive)}
  check_dst
  check_removable

  DST_BLKSIZE="$(blocksize "${DST}")"

  # Ask for confirmation to be sure.
  echo "This will install from '${SRC}' to '${DST}'."
  echo "This will erase all data at this destination: ${DST}"
  local sure
  if [ "${FLAGS_yes:?}" -eq "${FLAGS_FALSE}" ]; then
    printf "Are you sure (y/N)? "
    read -r sure
    if [ "${sure}" != "y" ]; then
      # Don't run diagnostics if the user explicitly bailed out.
      trap - EXIT
      cleanup
      die "Ok, better safe than sorry; you answered '${sure}'."
    fi
  fi

  # For LVM partitions, the logical volumes/volume groups on the stateful
  # partition may be active. Deactivate the partitions.
  dst_stateful="$(make_partition_dev "${DST}" "${PARTITION_NUM_STATE:?}")"
  vg_name="$(get_volume_group "${dst_stateful}")"
  if [ -n "${vg_name}" ]; then
    vgchange -an --force "${vg_name}" || true
  fi

  # Write the GPT using the board specific script.
  if [ "${FLAGS_skip_gpt_creation:?}" -eq "${FLAGS_FALSE}" ]; then
    write_base_table "${DST}" "$(get_pmbr_code)"
    echo "Reloading system partition information."
    reload_partitions
    echo "Done reloading system partition information."
  fi

  if [ "${FLAGS_minimal_copy:?}" -eq "${FLAGS_TRUE}" ]; then
    echo "\n" # separate from the wall of text
    echo "Blocking system updates"
    if command -v sfdisk >/dev/null 2>&1; then
      sfdisk --delete ${DST} 4 # it fails if one partition doesn't exist
      sfdisk --delete ${DST} 5 # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    elif command -v fdisk >/dev/null 2>&1; then
      fdisk ${DST} <<EOF
d
4

d
5

w
EOF
    fi
    reload_partitions
  fi

  if [ "${FLAGS_skip_rootfs:?}" -eq "${FLAGS_TRUE}" ]; then
    echo "Clearing and reinstalling the stateful partition."
    wipe_stateful
    install_stateful
    cleanup
    echo "Done installing partitions."
    exit 0
  fi

  if [ "${FLAGS_preserve_stateful:?}" -eq "${FLAGS_FALSE}" ] && \
      [ -z "${FLAGS_lab_preserve_logs}" ]; then
    wipe_stateful
  fi

  # Older devices (pre disk_layout_v3.json) don't have these two variables set,
  # but there is a switch case in copy_partition() that requires these be
  # defined. So if they are not defined, we initialize them (to empty string) so
  # the copy_partition() doesn't fail.
  if [ "${PARTITION_NUM_MINIOS_A+set}" != "set" ]; then
    PARTITION_NUM_MINIOS_A=""
  fi
  if [ "${PARTITION_NUM_MINIOS_B+set}" != "set" ]; then
    PARTITION_NUM_MINIOS_B=""
  fi

  # First do the easy ones.  Do so in reverse order to have stateful
  # get installed last. The order shouldn't matter but legacy behavior has
  # us go in reverse order.

  # 12
  copy_partition "${PARTITION_NUM_EFI_SYSTEM:?}" "${SRC}" "${DST}" 1 1 false

  # Version 3 layout doesn't have RWFW partition anymore - it may be used for
  # metadata.
  if [ "${PARTITION_NUM_POWERWASH_DATA+set}" = "set" ]; then               # 11
    wipe_partition "${PARTITION_NUM_POWERWASH_DATA}" "${DST}"
  fi
  if [ "${PARTITION_NUM_RWFW+set}" = "set" ]; then
    copy_partition "${PARTITION_NUM_RWFW}" "${SRC}" "${DST}" 1 1 false     # 11
  fi
  copy_partition "${PARTITION_NUM_OEM:?}" "${SRC}" "${DST}" 1 1 false        # 8
  copy_partition "${PARTITION_NUM_ROOT_C:?}" "${SRC}" "${DST}" 1 1 false     # 7
  copy_partition "${PARTITION_NUM_KERN_C:?}" "${SRC}" "${DST}" 1 1 false     # 6
  # Cache the first read of KERN so the second is read from RAM.
  # This is okay as they read from the same source.
  if [ "${FLAGS_minimal_copy:?}" -eq "${FLAGS_TRUE}" ]; then
    echo "Skipping copy of B kernel partition."
  else
    copy_partition "${PARTITION_NUM_KERN_B:?}" "${SRC}" "${DST}" 1 1 true    # 4
  fi
  copy_partition "${PARTITION_NUM_KERN_A:?}" "${SRC}" "${DST}" 1 1 false     # 2

  # We want to chunk up the root filesystem.  We do this because we're
  # going to read the source once and write it to the destination twice.
  # If the rootfs is big and we don't have extra RAM, we can blow out
  # the amount of free RAM and by the time we write the second
  # destination we won't have the source cached.  Doing it in chunks
  # prevents this.
  local chunk_num
  for chunk_num in $(seq "${NUM_ROOTFS_CHUNKS}"); do
    if [ "${FLAGS_minimal_copy:?}" -eq "${FLAGS_TRUE}" ]; then
      echo "Skipping copy of B root partition."
    else
      copy_partition "${PARTITION_NUM_ROOT_B:?}" "${SRC}" "${DST}" \
         "${chunk_num}" "${NUM_ROOTFS_CHUNKS}" true                        # 5
    fi
    copy_partition "${PARTITION_NUM_ROOT_A:?}" "${SRC}" "${DST}" \
       "${chunk_num}" "${NUM_ROOTFS_CHUNKS}" false                         # 3
  done

  # Second to last is stateful.
  copy_partition "${PARTITION_NUM_STATE:?}" "${SRC}" "${DST}" 1 1 false      # 1

  # We want the MINIOS partitions be last just in case writing to other
  # partitions fail at some point, we don't lose the ability to do recovery.
  if [ -n "${PARTITION_NUM_MINIOS_A}" ]; then
    # Cache the first read of MINIOS so the second is read from RAM.
    # This is okay as they read from the same source.
    copy_partition "${PARTITION_NUM_MINIOS_A}" "${SRC}" "${DST}" 1 1 true  # 9
  fi

  if [ "${FLAGS_minimal_copy:?}" -eq "${FLAGS_TRUE}" ]; then
    echo "Skipping copy of B miniOS partition."
  elif [ -n "${PARTITION_NUM_MINIOS_B}" ]; then
    copy_partition "${PARTITION_NUM_MINIOS_B}" "${SRC}" "${DST}" 1 1 false # 10
  fi

  do_post_install
  wipe_stateful

  # Force data to disk before we declare done.
  sync
  cleanup
  trap - EXIT

  echo "------------------------------------------------------------"
  echo ""
  echo "Installation to '${DST}' complete."
  echo "Please shutdown, remove the USB device, cross your fingers, and reboot."
}

main "$@"
