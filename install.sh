#!/bin/bash

mirrorlist='Server = https://mirror.osbeck.com/archlinux/$repo/os/$arch
Server = https://america.mirror.pkgbuild.com/$repo/os/$arch
Server = https://arch.mirror.constant.com/$repo/os/$arch
Server = https://mirror.bethselamin.de/$repo/os/$arch
Server = http://archlinux.polymorf.fr/$repo/os/$arch
Server = http://mirror.dkm.cz/archlinux/$repo/os/$arch
Server = https://mirror.tarellia.net/distr/archlinux/$repo/os/$arch
Server = https://mirrors.neusoft.edu.cn/archlinux/$repo/os/$arch'

clear

echo "LukeZGD Arch Install Script"
echo "This script will assume that you have a working Internet connection"
echo "Press [enter] to continue, or ^C to cancel"
read -s

echo
echo "[Log] Creating mirrorlist"
echo "$mirrorlist" > /etc/pacman.d/mirrorlist
sed -i "s/#Color/Color/" /etc/pacman.conf
sed -i "s/#TotalDownload/TotalDownload/" /etc/pacman.conf
#echo "[Log] Installing reflector"
#pacman -Sy --noconfirm --needed python reflector
#echo "[Log] Creating mirrorlist with reflector"
#reflector --verbose --country 'Singapore' -l 5 --sort rate --save /etc/pacman.d/mirrorlist
echo "[Log] Enabling ntp"
timedatectl set-ntp true

read -p "[Input] (y) fdisk BIOS/MBR, (N) gdisk UEFI/GPT: " diskprog
if [[ $diskprog == y ]] || [[ $diskprog == Y ]]; then
    diskprog=fdisk
else
    diskprog=gdisk
fi

echo
lsblk
echo
read -p "[Input] Please enter device to be used (/dev/sdX) " disk
echo "[Log] Will now enter $diskprog with device $disk"
echo "Commands: (f) fdisk (g) gdisk
# Erase: o, (g) y
# Create boot: n, defaults, last sector +200M, (g) type EF00
# Create partition: n, defaults, (g) type 8E00
# Check and write: p, w"
$diskprog $disk

clear
lsblk
echo
read -p "[Input] Please enter encrypted/root partition (/dev/sdaX) " rootpart
read -p "[Input] Please enter boot partition (/dev/sdaX) " bootpart
read -p "[Input] Please enter swap partition (ia32 ONLY) (/dev/sdaX) " swappart
[[ -z $swappart ]] && read -p "[Input] Format boot partition? (Y/n) " formatboot

echo "[Log] Formatting/mounting stuff... (please enter NEW password when prompted)"
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
    mount /dev/mapper/vg0-root /mnt
    mkdir /mnt/boot
    mount $bootpart /mnt/boot
    echo "[Log] Creating swap"
    dd if=/dev/zero of=/mnt/swapfile bs=1M count=4096 status=progress
    chmod 600 /mnt/swapfile
    mkswap /mnt/swapfile
    swapon /mnt/swapfile
fi
echo "[Log] Copying stuff to /mnt"
cp chroot.sh /mnt
mkdir -p /mnt/var/cache/pacman /mnt/usr/bin
cp pac.sh /mnt/usr/bin/pac
cp -R Backups/pkg /mnt/var/cache/pacman
echo "[Log] Installing base"
pacstrap /mnt base
[[ ! -z $swappart ]] && touch /mnt/ia32
[[ $diskprog == y ]] || [[ $diskprog == Y ]] && touch /mnt/fdisk
echo "[Log] Generating fstab"
genfstab -pU /mnt > /mnt/etc/fstab
echo 'tmpfs	/tmp	tmpfs	defaults,noatime,mode=1777	0	0' | tee -a /mnt/etc/fstab
sed -i "s/relatime/noatime/" /mnt/etc/fstab
echo "[Log] Running chroot.sh in arch-chroot"
arch-chroot /mnt ./chroot.sh
echo "[Log] Removing chroot.sh"
rm /mnt/chroot.sh
echo "[Log] Install script done!"
