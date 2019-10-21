#!/bin/bash

clear

echo "LukeZGD Arch Install Script"
echo "This script will assume that you have a working Internet connection"
echo "Press [enter] to continue, or ^C to cancel"
read

echo ""
echo "[Log] Moving mirrorlist"
cp installscript/mirrorlist /etc/pacman.d/mirrorlist

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

clear
lsblk
echo ""
echo "[Input] Please enter root partition (/dev/sdaX)"
read rootpart
echo "[Input] Please enter home partition /dev/sdaX)"
read homepart
echo "[Input] Please enter swap partition (/dev/sdaX)"
read swappart
echo "[Input] Please enter EFI partition (/dev/sdaX) (leave blank if no EFI)"
read efipart

echo "[Log] Formatting $rootpart as ext4"
mkfs.ext4 $rootpart
echo "[Log] Mounting $rootpart to /mnt"
mount $rootpart /mnt

echo "[Input] Format home partition? (y/n)"
read formathome
if [ $formathome == y ]
then
    echo "[Log] Formatting $homepart as ext4"
    mkfs.ext4 $homepart
fi
echo "[Log] Creating directory /mnt/home"
mkdir /mnt/home
echo "[Log] Mounting $homepart to /mnt/home"
mount $homepart /mnt/home

echo "[Log] Formatting $swappart as swap"
mkswap $swappart
echo "[Log] Running swapon $swappart"
swapon $swappart

if [ $efipart != "" ]
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
echo "[Log] Installing base"
pacstrap -i /mnt base
echo "[Log] Generating fstab"
genfstab -U -p /mnt >> /mnt/etc/fstab
echo "[Log] Copying chroot.sh to /mnt"
cp installscript/chroot.sh /mnt
echo "[Log] Copying pacman lists to /mnt"
cp installscript/pacman /mnt
cp installscript/pacman2 /mnt
echo "[Log] Running arch-chroot /mnt ./chroot.sh"
arch-chroot /mnt ./chroot.sh
