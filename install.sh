#!/bin/bash

mirrorlist='Server = https://mirror.telepoint.bg/archlinux/$repo/os/$arch
Server = https://mirror.lty.me/archlinux/$repo/os/$arch
Server = https://de.arch.mirror.kescher.at/$repo/os/$arch
Server = https://archlinux.thaller.ws/$repo/os/$arch
Server = https://mirror.nw-sys.ru/archlinux/$repo/os/$arch
Server = https://mirror.telepoint.bg/archlinux/$repo/os/$arch
Server = https://archlinux.mailtunnel.eu/$repo/os/$arch'

clear

echo "LukeZGD Arch Install Script"
echo "This script will assume that you have a working Internet connection"
echo "Press [enter] to continue, or ^C to cancel"
read -s

echo
echo "[Log] Creating mirrorlist"
echo "$mirrorlist" > /etc/pacman.d/mirrorlist
sed -i "s/#Color/Color/" /etc/pacman.conf
sed -i "s|#ParallelDownloads = 5|ParallelDownloads = 5|g" /etc/pacman.conf
echo "[Log] Enabling ntp"
timedatectl set-ntp true

read -p "[Input] (y) fdisk BIOS/MBR, (N) gdisk UEFI/GPT: " diskprog
if [[ $diskprog == y || $diskprog == Y ]]; then
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
if [[ -n $swappart ]]; then
    mkfs.ext4 $rootpart
    mount $rootpart /mnt
    mkswap $swappart
    swapon $swappart
    mkfs.fat -F32 $bootpart
    mkdir -p /mnt/boot/EFI
    mount $bootpart /mnt/boot/EFI
else
    pvname="lvm"
    vgname="vg0"
    lvname="root"
    cryptsetup luksFormat $rootpart
    cryptsetup luksOpen $rootpart $pvname
    pvcreate /dev/mapper/$pvname
    vgcreate $vgname /dev/mapper/$pvname
    lvcreate -l 100%FREE $vgname -n $lvname
fi
if [[ $formatboot != n && $formatboot != N ]]; then
    echo "[Log] Formatting boot partition"
    if [[ $diskprog == y || $diskprog == Y ]]; then
        mkfs.ext2 $bootpart
    else
        mkfs.vfat -F32 $bootpart
    fi
fi
if [[ -z $swappart ]]; then
    rootpart="/dev/mapper/$vgname-$lvname"
    echo "[Log] Formatting and mounting volumes"
    #mkfs.btrfs -f $rootpart
    mkfs.f2fs -f $rootpart
    mount $rootpart /mnt
    mkdir /mnt/boot
    mount $bootpart /mnt/boot
    : '
    echo "[Log] Creating subvolumes"
    btrfs su cr /mnt/root
    btrfs su cr /mnt/home
    btrfs su cr /mnt/swap
    umount /mnt
    echo "[Log] Mounting subvolumes"
    mount -o compress=zstd:1,subvol=/root $rootpart /mnt
    mkdir /mnt/{boot,home,swap}
    mount $bootpart /mnt/boot
    mount -o compress=zstd:1,subvol=/home $rootpart /mnt/home
    mount -o subvol=/swap $rootpart /mnt/swap
    echo "[Log] Creating swap"
    touch /mnt/swap/swapfile
    chmod 600 /mnt/swap/swapfile
    chattr +C /mnt/swap/swapfile
    fallocate /mnt/swap/swapfile -l8g
    mkswap /mnt/swap/swapfile
    swapon /mnt/swap/swapfile
    '
fi
echo "[Log] Copying stuff to /mnt"
cp chroot.sh /mnt
#mkdir -p /mnt/var/cache/pacman /mnt/usr/bin
#cp -R Backups/pkg /mnt/var/cache/pacman
echo "[Log] Installing base"
pacstrap /mnt base
[[ -n $swappart ]] && touch /mnt/ia32
[[ $diskprog == fdisk ]] && touch /mnt/fdisk
echo "[Log] Generating fstab"
genfstab -pU /mnt > /mnt/etc/fstab
echo "tmpfs	/tmp	tmpfs	defaults,noatime,mode=1777	0	0" | tee -a /mnt/etc/fstab
sed -i "s/relatime/noatime/" /mnt/etc/fstab
echo "[Log] Running chroot.sh in arch-chroot"
arch-chroot /mnt ./chroot.sh
echo "[Log] Removing chroot.sh"
rm /mnt/chroot.sh
echo "[Log] Install script done!"
