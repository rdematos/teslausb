#!/bin/bash -eu

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

function bad_msg () {
    msg=$1
    echo "${red}${1}${reset}"
}

function good_msg () {
    msg=$1
    echo "${green}${1}${reset}"
}

bad_msg "This will attempt to reset the changes setup-teslausb made to your Pi."
echo "This can be destructive and should be used with care!"
echo "Press Ctrl-C to exit now if you don't want to continue."
read -p "Press any other key to start..."

if [ -e /root/bin/remountfs_rw ]
then
    /root/bin/remountfs_rw 
fi

umount /backingfiles
umount /mutable
rm -rf /mnt/cam
parted -s -m /dev/mmcblk0 rm 3 
parted -s -m /dev/mmcblk0 rm 4 
rm /tmp/*.sh
