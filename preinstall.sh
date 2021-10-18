#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------
(

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib --needed
pacman -S --noconfirm reflector --needed
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector --age 12 --country "$iso" --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt


echo -e "\nInstalling prereqs...\n"
pacman -S --noconfirm gptfdisk --needed
pacman -S --noconfirm btrfs-progs --needed

echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
echo "Please enter disk to work on: (example /dev/sda)"
read -r DISK
echo "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
read -r -p "are you sure you want to continue (Y/N):" formatdisk
case $formatdisk in

    y|Y|yes|Yes|YES)
    echo "--------------------------------------"
    echo -e "\nFormatting disk...\n"
    echo "--------------------------------------"

    # disk prep
    sgdisk -Z "${DISK}" # zap all on disk
    sgdisk -a 2048 -o "${DISK}" # new gpt disk 2048 alignment

    # create partitions
    sgdisk -n 1:0:+1000M "${DISK}" # partition 1 (UEFI SYS), default start block, 512MB
    sgdisk -n 2:0:0 "${DISK}"  # partition 2 (Root), default start, remaining

    # set partition types
    sgdisk -t 1:ef00 "${DISK}"
    sgdisk -t 2:8300 "${DISK}"

    # label partitions
    sgdisk -c 1:"UEFISYS" "${DISK}"
    sgdisk -c 2:"ROOT" "${DISK}"

    # make filesystems
    echo -e "\nCreating Filesystems...\n"

    mkfs.vfat -F32 -n "UEFISYS" "${DISK}1"
    mkfs.btrfs -L "ROOT" "${DISK}2"
    mount -t btrfs "${DISK}2" /mnt
    btrfs subvolume create /mnt/@
    umount /mnt
    ;;

    n|N|No|no|NO)
    exit
    ;;

    *)
    echo "Wrong key, exiting"
    exit
    ;;
esac

# mount target
mount -t btrfs -o subvol=@ "${DISK}2" /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat "${DISK}1" /mnt/boot/

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf

echo "--------------------------------------"
echo "-- Bootloader Systemd Installation  --"
echo "--------------------------------------"
bootctl install --esp-path=/mnt/boot
[ ! -d "/mnt/boot/loader/entries" ] && mkdir -p /mnt/boot/loader/entries
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title Arch Linux  
linux /vmlinuz-linux  
initrd  /initramfs-linux.img  
options root=${DISK}2 rw rootflags=subvol=@
EOF

cp -R "/root/Archmatic" "/mnt/root/"

echo "--------------------------------------"
echo "--   SYSTEM READY FOR 0-setup       --"
echo "--------------------------------------"
arch-chroot /mnt

) 2>&1 | tee installlog.txt
