#!/bin/bash -eu

BACKINGFILES_MOUNTPOINT="$1"
MUTABLE_MOUNTPOINT="$2"

setup_progress "Checking existing partitions..."
PARTITION_TABLE=$(parted -m /dev/mmcblk0 unit B print)
DISK_LINE=$(echo "$PARTITION_TABLE" | grep -e "^/dev/mmcblk0:")
DISK_SIZE=$(echo "$DISK_LINE" | cut -d ":" -f 2 | sed 's/B//' )

ROOT_PARTITION_LINE=$(echo "$PARTITION_TABLE" | grep -e "^2:")
LAST_ROOT_PARTITION_BYTE=$(echo "$ROOT_PARTITION_LINE" | sed 's/B//g' | cut -d ":" -f 3)

FIRST_BACKINGFILES_PARTITION_BYTE="$(( $LAST_ROOT_PARTITION_BYTE + 1 ))"
LAST_BACKINGFILES_PARTITION_DESIRED_BYTE="$(( $DISK_SIZE - (100 * (2 ** 20)) - 1))"

ORIGINAL_DISK_IDENTIFIER=$( fdisk -l /dev/mmcblk0 | grep -e "^Disk identifier" | sed "s/Disk identifier: 0x//" )

setup_progress "Modifying partition table for backing files partition..."
BACKINGFILES_PARTITION_END_SPEC="$(( $LAST_BACKINGFILES_PARTITION_DESIRED_BYTE / 1000000 ))M"
parted -a optimal -m /dev/mmcblk0 unit B mkpart primary btrfs "$FIRST_BACKINGFILES_PARTITION_BYTE" "$BACKINGFILES_PARTITION_END_SPEC"

setup_progress "Modifying partition table for mutable (writable) partition for script usage..."
MUTABLE_PARTITION_START_SPEC="$BACKINGFILES_PARTITION_END_SPEC"
parted  -a optimal -m /dev/mmcblk0 unit B mkpart primary ext4 "$MUTABLE_PARTITION_START_SPEC" 100%

NEW_DISK_IDENTIFIER=$( fdisk -l /dev/mmcblk0 | grep -e "^Disk identifier" | sed "s/Disk identifier: 0x//" )

setup_progress "Writing updated partitions to fstab and /boot/cmdline.txt"
sed -i "s/${ORIGINAL_DISK_IDENTIFIER}/${NEW_DISK_IDENTIFIER}/g" /etc/fstab
sed -i "s/${ORIGINAL_DISK_IDENTIFIER}/${NEW_DISK_IDENTIFIER}/" /boot/cmdline.txt

setup_progress "Formatting new partitions..."
mkfs.btrfs -f -L backingfiles /dev/mmcblk0p3
mkfs.ext4 -F /dev/mmcblk0p4
echo "/dev/mmcblk0p3 $BACKINGFILES_MOUNTPOINT btrfs defaults,ssd_spread,noatime 0 0" >> /etc/fstab
# echo "/dev/mmcblk0p3 $BACKINGFILES_MOUNTPOINT ext4 auto,rw,noatime 0 2" >> /etc/fstab
echo "/dev/mmcblk0p4 $MUTABLE_MOUNTPOINT ext4 auto,rw 0 2" >> /etc/fstab

# function setup_progress () {
#   local setup_logfile=/boot/teslausb-headless-setup.log
#   local headless_setup=${HEADLESS_SETUP:-false}
#   if [ $headless_setup = "true" ]
#   then
#     echo "$( date ) : $1" >> "$setup_logfile"
#   fi
#     echo $1
# }

# BACKINGFILES_MOUNTPOINT="$1"
# MUTABLE_MOUNTPOINT="$2"
# # BACKINGFILES_MOUNTPOINT="/backingfiles"
# # MUTABLE_MOUNTPOINT="/mutable"

# setup_progress "Checking existing partitions..."
# export DISK_SIZE_BYTES="$(blockdev --getsize64 /dev/mmcblk0)"
# export BOOT_SIZE_BYTES="$(blockdev --getsize64 /dev/mmcblk0p1)"
# export ROOT_PARTITION_SIZE_BYTES="$(blockdev --getsize64 /dev/mmcblk0p2)"
# export USED_PERCENTAGE="$(( ($BOOT_SIZE_BYTES+$ROOT_PARTITION_SIZE_BYTES) * 100 / $DISK_SIZE_BYTES ))"
# export NEW_START_PERCENTAGE="$(( $USED_PERCENTAGE + 1 ))"

# # Per the googles, percentages will align optimal, within an acceptable margin
# setup_progress "Modifying partition table for backing files partition..."
# parted  -s -m /dev/mmcblk0 mkpart primary btrfs $NEW_START_PERCENTAGE% 85%
# setup_progress "Modifying partition table for mutable partition..."
# parted  -s -m /dev/mmcblk0 mkpart primary btrfs 86% 100% 

# ORIGINAL_DISK_IDENTIFIER=$( fdisk -l /dev/mmcblk0 | grep -e "^Disk identifier" | sed "s/Disk identifier: 0x//" )

# NEW_DISK_IDENTIFIER=$( fdisk -l /dev/mmcblk0 | grep -e "^Disk identifier" | sed "s/Disk identifier: 0x//" )

# setup_progress "Writing updated partitions to fstab and /boot/cmdline.txt"
# sed -i "s/${ORIGINAL_DISK_IDENTIFIER}/${NEW_DISK_IDENTIFIER}/g" /etc/fstab
# sed -i "s/${ORIGINAL_DISK_IDENTIFIER}/${NEW_DISK_IDENTIFIER}/" /boot/cmdline.txt

# setup_progress "Formatting new partitions..."
# mkfs.btrfs -f -L backingfiles /dev/mmcblk0p3
# mkfs.btrfs -f -L mutable /dev/mmcblk0p4

# cp /etc/fstab /etc/fstab.orig
# #echo "LABEL=backingfiles /backingfiles btrfs defaults,ssd_spread,noatime,noauto 0 0" >> /etc/fstab
# #echo "LABEL=mutable /mutable btrfs defaults,ssd_spread,noatime,noauto 0 0" >> /etc/fstab
# # echo "/dev/mmcblk0p3 $BACKINGFILES_MOUNTPOINT btrfs auto,rw,noatime 0 2" >> /etc/fstab
# # echo "/dev/mmcblk0p4 $MUTABLE_MOUNTPOINT btrfs auto,rw 0 2" >> /etc/fstab