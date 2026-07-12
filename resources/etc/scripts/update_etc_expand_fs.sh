#!/bin/bash

##
## Copyright (c) 2024 Numurus, LLC <https://www.numurus.com>.
##
## This file is part of nepi-engine
## (see https://github.com/nepi-engine).
##
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##

# This script expands the root filesystem partition to fill the
# remaining unallocated space on its disk. It is a safe no-op when
# the drive is already expanded (or has nothing worth expanding),
# so it can run unconditionally on any unit including the master.
#
# Run as root by the nepi_docker service in response to the
# NEPI_EXPAND_FS docker config flag.

if ! [ $(id -u) = 0 ]; then
    echo "EXPAND FS: This script must be run as root user"
    exit 0
fi

MIN_EXPAND_BYTES=$((1024 * 1024 * 1024))  # Require > 1 GiB of free space to act

echo ""
echo "UPDATING ETC EXPAND FS"

#################################
# Derive the root partition and its parent disk. No hardcoded device names.
ROOT_PART_DEV=$(findmnt -no SOURCE /)
if [[ ! -b "$ROOT_PART_DEV" ]]; then
    echo "EXPAND FS: Root source ${ROOT_PART_DEV} is not a block device. Skipping"
    exit 0
fi

ROOT_PART_NAME=$(basename ${ROOT_PART_DEV})
DISK_NAME=$(basename "$(readlink -f /sys/class/block/${ROOT_PART_NAME}/..)")
DISK_DEV=/dev/${DISK_NAME}
PART_NUM=$(cat /sys/class/block/${ROOT_PART_NAME}/partition)

if [[ ! -b "$DISK_DEV" || -z "$PART_NUM" ]]; then
    echo "EXPAND FS: Failed to resolve parent disk for ${ROOT_PART_DEV}. Skipping"
    exit 0
fi

echo "EXPAND FS: Root partition ${ROOT_PART_DEV} is partition ${PART_NUM} on disk ${DISK_DEV}"

#################################
# Safety checks. The root partition must be the last partition on the
# disk (highest start sector), and there must be more than 1 GiB of
# unallocated space after it. Otherwise log and exit 0 without
# touching the partition table. This protects already-expanded units
# and the 128GB master.
DISK_SECTORS=$(cat /sys/block/${DISK_NAME}/size)
ROOT_START=$(cat /sys/block/${DISK_NAME}/${ROOT_PART_NAME}/start)
ROOT_SIZE=$(cat /sys/block/${DISK_NAME}/${ROOT_PART_NAME}/size)
ROOT_END=$((ROOT_START + ROOT_SIZE))

for part_path in /sys/block/${DISK_NAME}/${DISK_NAME}p*/ /sys/block/${DISK_NAME}/${DISK_NAME}[0-9]*/; do
    [[ -d "$part_path" ]] || continue
    part_name=$(basename ${part_path})
    [[ "$part_name" == "$ROOT_PART_NAME" ]] && continue
    part_start=$(cat ${part_path}/start)
    if [[ "$part_start" -gt "$ROOT_START" ]]; then
        echo "EXPAND FS: Partition ${part_name} starts after root partition. Drive is not expandable. Skipping"
        exit 0
    fi
done

FREE_SECTORS=$((DISK_SECTORS - ROOT_END))
FREE_BYTES=$((FREE_SECTORS * 512))
echo "EXPAND FS: Disk ${DISK_SECTORS} sectors, root partition ends at ${ROOT_END}, ${FREE_SECTORS} sectors free after it"

if [[ "$FREE_BYTES" -le "$MIN_EXPAND_BYTES" ]]; then
    echo "EXPAND FS: Less than 1 GiB unallocated after root partition. Drive is already expanded. Nothing to do"
    exit 0
fi

#################################
# Expand. From here on a real failure exits nonzero.
echo "EXPAND FS: Expanding ${ROOT_PART_DEV} to fill ${DISK_DEV}"

# Capture the partition identity so the delete/recreate preserves it.
# The unique GUID (PARTUUID) must survive or boot configs that
# reference it would break.
PART_INFO=$(sgdisk -i ${PART_NUM} ${DISK_DEV})
PART_GUID=$(echo "$PART_INFO" | grep 'Partition unique GUID:' | awk '{print $NF}')
PART_TYPE=$(echo "$PART_INFO" | grep 'Partition GUID code:' | awk '{print $4}')
PART_NAME=$(echo "$PART_INFO" | grep "Partition name:" | sed "s/.*'\(.*\)'.*/\1/")
if [[ -z "$PART_GUID" || -z "$PART_TYPE" ]]; then
    echo "EXPAND FS: Failed to read partition info for ${ROOT_PART_DEV}. Aborting before modification"
    exit 0
fi
echo "EXPAND FS: Preserving partition type ${PART_TYPE}, GUID ${PART_GUID}, name '${PART_NAME}'"

echo "EXPAND FS: Relocating backup GPT header to end of disk"
sgdisk -e ${DISK_DEV}
if [[ "$?" -ne 0 ]]; then
    echo "EXPAND FS: sgdisk -e failed on ${DISK_DEV}"
    exit 1
fi

echo "EXPAND FS: Growing partition ${PART_NUM} to 100% of disk"
sgdisk -d ${PART_NUM} -n ${PART_NUM}:${ROOT_START}:0 -t ${PART_NUM}:${PART_TYPE} -u ${PART_NUM}:${PART_GUID} -c ${PART_NUM}:"${PART_NAME}" ${DISK_DEV}
if [[ "$?" -ne 0 ]]; then
    echo "EXPAND FS: sgdisk partition grow failed on ${DISK_DEV} partition ${PART_NUM}"
    exit 1
fi

echo "EXPAND FS: Re-reading partition table"
partprobe ${DISK_DEV}
NEW_SIZE=$(cat /sys/block/${DISK_NAME}/${ROOT_PART_NAME}/size)
if [[ "$NEW_SIZE" -le "$ROOT_SIZE" ]]; then
    partx -u ${DISK_DEV}
    NEW_SIZE=$(cat /sys/block/${DISK_NAME}/${ROOT_PART_NAME}/size)
fi
if [[ "$NEW_SIZE" -le "$ROOT_SIZE" ]]; then
    echo "EXPAND FS: Kernel did not pick up new partition size (still ${NEW_SIZE} sectors)"
    exit 1
fi
echo "EXPAND FS: Partition now ${NEW_SIZE} sectors"

echo "EXPAND FS: Resizing filesystem on ${ROOT_PART_DEV}"
resize2fs ${ROOT_PART_DEV}
if [[ "$?" -ne 0 ]]; then
    echo "EXPAND FS: resize2fs failed on ${ROOT_PART_DEV}"
    exit 1
fi

echo "EXPAND FS: Expansion complete"
df -h /
exit 0
