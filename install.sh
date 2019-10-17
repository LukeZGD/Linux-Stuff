#!/bin/bash

clear

echo "LukeZGD Arch Install Script"
echo "This script will assume that you have a working Internet connection"
echo "Press [enter] to continue, or ^C to cancel"
read

echo ""
echo "[Log] Moving installscript to root"
cp -R installscript /
cd /installscript
echo "[Log] Moving mirrorlist"
cp mirrorlist /etc/pacman.d/mirrorlist

function setupdisk {
    echo "[Input] cfdisk or cgdisk?"
    read diskprog
    echo ""
    lsblk
    echo ""
    echo "[Input] Please enter device to be used (/dev/sdX)"
    read disk
    echo "Will now enter $diskprog with device $disk. Press [enter]"
    read
    $diskprog $disk
}

setupdisk
echo "Do you want to set up disk again? (y/n)"
read setupdiska
if [ $setupdiska == y ]
then
    setupdisk
fi

clear
lsblk
echo ""
echo "[Input] Please enter root partition (/dev/sdaX)"
read rootpart
echo "[Log] Formatting $rootpart as ext4"
mkfs.ext4 $rootpart
echo "[Log] Mounting $rootpart to /mnt"
mount $rootpart /mnt

echo "[Input] Please enter home partition /dev/sdaX)"
read homepart
echo "[Log] Formatting $homepart as ext4"
mkfs.ext4 $homepart
echo "[Log] Creating directory /mnt/home"
mkdir /mnt/home
echo "[Log] Mounting $homepart to /mnt/home"
mount $homepart /mnt/home

echo "[Input] Please enter swap partition (/dev/sdaX)"
read swappart
echo "[Log] Formatting $swappart as swap"
mkswap $swappart
echo "[Log] Running swapon $swappart"
swapon $swappart

echo "[Input] Please enter EFI partition (/dev/sdaX) (Enter na if no EFI)"
read efipart
if [ $efipart != na ]
then
    echo "[Log] Formatting $efipart as fat32"
    mkfs.fat -F32 $efipart
    echo "[Log] Creating directory /mnt/boot"
    mkdir /mnt/boot
    echo "[Log] Mounting $efipart to /mnt/boot"
    mount $efipart /mnt/boot
fi
echo "[Log] Running pacman -Sy"
pacman -Sy
echo "[Log] Installing packages listed in 'pacman'"
pacstrap -i /mnt - < pacman
echo "[Log] Installing packages listed in 'pacman2'"
pacstrap -i /mnt - < pacman2
echo "[Log] Copying chroot.sh to /mnt"
cp chroot.sh /mnt
echo "[Log] Running arch-chroot /mnt ./chroot.sh"
arch-chroot /mnt ./chroot.sh
