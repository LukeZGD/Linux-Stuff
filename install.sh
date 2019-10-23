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
until [ ! -z "$rootpart" ]
do
    echo "[Input] Please enter root partition (/dev/sdaX) (REQUIRED)"
    read rootpart
done
echo "[Input] Please enter home partition (/dev/sdaX) (leave blank if none)"
read homepart
echo "[Input] Please enter swap partition (/dev/sdaX) (leave blank if none)"
read swappart
echo "[Input] Please enter EFI partition (/dev/sdaX) (leave blank if none)"
read efipart

echo "[Log] Formatting $rootpart as ext4"
mkfs.ext4 $rootpart
echo "[Log] Mounting $rootpart to /mnt"
mount $rootpart /mnt

if [ ! -z "$homepart" ]
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

if [ ! -z "$swappart" ]
then
    echo "[Log] Formatting $swappart as swap"
    mkswap $swappart
    echo "[Log] Running swapon $swappart"
    swapon $swappart
fi

if [ ! -z "$efipart" ]
then
    echo "[Log] Formatting $efipart as fat32"
    mkfs.fat -F32 $efipart
    echo "[Log] Creating directory /mnt/boot"
    mkdir /mnt/boot
    echo "[Log] Mounting $efipart to /mnt/boot"
    mount $efipart /mnt/boot
fi

echo "[Log] Copying chroot.sh to /mnt"
cp installscript/chroot.sh /mnt
echo "[Log] Copying pacman lists to /mnt"
cp installscript/pacman /mnt
cp installscript/pacman2 /mnt

echo "[Input] Copy local cache to /mnt? (y/n)"
read dotcache
if [ $dotcache == y ]
then
    mkdir -p /mnt/var/cache/pacman
    cp -R pkg /mnt/var/cache/pacman
fi
echo "[Log] Installing base"
pacstrap -i /mnt base
echo "[Log] Generating fstab"
genfstab -U -p /mnt >> /mnt/etc/fstab
echo "[Log] Running arch-chroot /mnt ./chroot.sh"
arch-chroot /mnt ./chroot.sh
echo "[Log] Script done"
