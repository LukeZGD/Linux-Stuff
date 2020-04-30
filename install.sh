#!/bin/bash

clear

echo "LukeZGD Arch Install Script"
echo "This script will assume that you have a working Internet connection"
echo "Press [enter] to continue, or ^C to cancel"
read

echo ""
echo "[Log] Creating mirrorlist"
pacman -Sy reflector
reflector --verbose --country 'Singapore' -l 5 --sort rate --save /etc/pacman.d/mirrorlist
echo "[Log] Enabling ntp"
timedatectl set-ntp true

echo "[Input] (y) fdisk BIOS/MBR, (N) gdisk UEFI/GPT"
read diskprog
if [[ $diskprog == y ]] || [[ $diskprog == Y ]]; then
  diskprog=fdisk
else
  diskprog=gdisk
fi

echo ""
lsblk
echo ""
echo "[Input] Please enter device to be used (/dev/sdX)"
read disk
echo "[Log] Will now enter $diskprog with device $disk"
echo "Commands: (f) fdisk (g) gdisk
# Erase: o, y
# Create boot: n, defaults, last sector +200M, (g) type EF00
# Create partition: n, defaults, (g) type 8E00
# Check and write: p, w"
$diskprog $disk

clear
lsblk
echo ""
echo "[Input] Please enter encrypted/root partition (/dev/sdaX)"
read rootpart
echo "[Input] Please enter boot partition (/dev/sdaX)"
read bootpart
echo "[Input] Please enter swap partition (ia32 ONLY) (/dev/sdaX)"
read swappart
if [[ -z $swappart ]]; then
  echo "[Input] Format boot partition? (Y/n)"
  read formatboot
fi

echo "[Log] Formatting/mounting stuff..."
if [[ ! -z $swappart ]]; then
  mkfs.ext4 $rootpart
  mount $rootpart /mnt
  mkswap $swappart
  swapon $swappart
  mkfs.fat -F32 $bootpart
  mkdir -p /mnt/boot/EFI
  mount $bootpart /mnt/boot/EFI
else
  cryptsetup luksFormat $rootpart
  cryptsetup luksOpen $rootpart lvm
  pvcreate /dev/mapper/lvm
  vgcreate vg0 /dev/mapper/lvm
  lvcreate -L 6G vg0 -n swap
  lvcreate -l 100%FREE vg0 -n root
fi
if [[ $formatboot != n ]] && [[ $formatboot != N ]]; then
  echo "[Log] Formatting boot partition"
  if [[ $diskprog == y ]] || [[ $diskprog == Y ]]; then
    mkfs.ext2 $bootpart
  else
    mkfs.vfat -F32 $bootpart
  fi
fi
if [[ -z $swappart ]]; then
  echo "[Log] Formatting and mounting volumes"
  mkfs.ext4 /dev/mapper/vg0-root
  mkswap /dev/mapper/vg0-swap
  mount /dev/mapper/vg0-root /mnt
  mkdir /mnt/boot
  mount $bootpart /mnt/boot
  swapon /dev/mapper/vg0-swap
fi

echo "[Log] Copying stuff to /mnt"
cp chroot.sh /mnt
mkdir -p /mnt/var/cache/pacman
cp -R Backups/pkg /mnt/var/cache/pacman
echo "[Log] Installing base"
pacstrap /mnt base
if [[ ! -z $swappart ]]; then
  touch /mnt/ia32
fi
echo "[Log] Generating fstab"
genfstab -pU /mnt > /mnt/etc/fstab
echo 'tmpfs	/tmp	tmpfs	defaults,noatime,mode=1777	0	0' | tee -a /mnt/etc/fstab
sed -i "s/relatime/noatime/" /mnt/etc/fstab
echo "[Log] Running chroot.sh in arch-chroot"
arch-chroot /mnt ./chroot.sh
echo "[Log] Removing chroot.sh"
rm /mnt/chroot.sh
echo "[Log] Install script done!"
