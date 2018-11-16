#!/bin/bash -eu

function setup_progress () {
  local setup_logfile=/boot/teslausb-headless-setup.log
  local headless_setup=${HEADLESS_SETUP:-false}
  if [ $headless_setup = "true" ]
  then
    echo "$( date ) : $1" >> "$setup_logfile"
  fi
    echo $1
}

BACKINGFILES_MOUNTPOINT="$1"
MUTABLE_MOUNTPOINT="$2"

setup_progress "Checking existing partitions..."
DISK_SIZE_BYTES="$(blockdev --getsize64 /dev/mmcblk0)"
BOOT_SIZE_BYTES="$(blockdev --getsize64 /dev/mmcblk0p1)"
ROOT_PARTITION_SIZE_BYTES="$(blockdev --getsize64 /dev/mmcblk0p2)"
USED_PERCENTAGE="$(( ($BOOT_SIZE_BYTES+$ROOT_PARTITION_SIZE_BYTES) * 100 / $DISK_SIZE_BYTES ))"
NEW_START_PERCENTAGE="$(( $USED_PERCENTAGE + 1 ))"

# Per the googles, percentages will align optimal, within an acceptable margin
setup_progress "Modifying partition table for backing files partition..."
parted  -s -m /dev/mmcblk0 mkpart primary ext4 $NEW_START_PERCENTAGE% 85%
setup_progress "Modifying partition table for mutable partition..."
parted  -s -m /dev/mmcblk0 mkpart primary ext4 86% 100% 

ORIGINAL_DISK_IDENTIFIER=$( fdisk -l /dev/mmcblk0 | grep -e "^Disk identifier" | sed "s/Disk identifier: 0x//" )

NEW_DISK_IDENTIFIER=$( fdisk -l /dev/mmcblk0 | grep -e "^Disk identifier" | sed "s/Disk identifier: 0x//" )

setup_progress "Writing updated partitions to fstab and /boot/cmdline.txt"
sed -i "s/${ORIGINAL_DISK_IDENTIFIER}/${NEW_DISK_IDENTIFIER}/g" /etc/fstab
sed -i "s/${ORIGINAL_DISK_IDENTIFIER}/${NEW_DISK_IDENTIFIER}/" /boot/cmdline.txt

setup_progress "Formatting new partitions..."
mkfs.ext4 -F /dev/mmcblk0p3
mkfs.ext4 -F /dev/mmcblk0p4

echo "/dev/mmcblk0p3 $BACKINGFILES_MOUNTPOINT ext4 auto,rw,noatime 0 2" >> /etc/fstab
echo "/dev/mmcblk0p4 $MUTABLE_MOUNTPOINT ext4 auto,rw 0 2" >> /etc/fstab
