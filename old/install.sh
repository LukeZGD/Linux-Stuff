#!/bin/bash

mirrorlist='Server = https://mirror.telepoint.bg/archlinux/$repo/os/$arch
Server = https://archlinux.mailtunnel.eu/$repo/os/$arch
Server = https://at.arch.mirror.kescher.at/$repo/os/$arch
Server = https://de.arch.mirror.kescher.at/$repo/os/$arch
Server = https://mirror.chaoticum.net/arch/$repo/os/$arch
Server = https://mirror.cyberbits.eu/archlinux/$repo/os/$arch
Server = https://mirrors.wsyu.edu.cn/archlinux/$repo/os/$arch
Server = https://archlinux.thaller.ws/$repo/os/$arch
Server = https://mirror.cyberbits.asia/archlinux/$repo/os/$arch
Server = https://mirror.theash.xyz/arch/$repo/os/$arch'

# iwctl
# device list
# adapter phy0 set-property Powered on
# device wlan0 set-property Powered on
# station list
# station wlan0 scan
# station wlan0 get-networks
# station wlan0 connect network_name

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

echo
while [[ ! -b $disk ]]; do
    lsblk
    echo
    read -p "[Input] Please enter device to be used (/dev/sdX) " disk
done

while [[ $repeat != 'y' && $repeat != 'Y' ]]; do
    echo "[Log] Will now enter gdisk with device $disk"
    echo "Commands:
    # Erase: o, y
    # Create boot: n, defaults, last sector +500M, type EF00
    # Create partition: n, defaults, type 8E00
    # Check and write: p, w"
    gdisk $disk
    read -p "[Input] Is the configuration correct? (y/N): " repeat
done
repeat=

while [[ $repeat != 'y' && $repeat != 'Y' ]]; do
    clear
    lsblk
    echo
    read -p "[Input] Please enter encrypted/root partition (/dev/sdaX) " rootpart
    read -p "[Input] Please enter boot partition (/dev/sdaX) " bootpart
    read -p "[Input] Format boot partition? (Y/n) " formatboot
    read -p "[Input] Is the configuration correct? (y/N): " repeat
done
repeat=

echo "[Log] Formatting/mounting stuff... (please enter NEW password when prompted)"
pvname="lvm"
vgname="vg0"
lvname="root"
cryptsetup luksFormat $rootpart
cryptsetup luksOpen $rootpart $pvname
pvcreate /dev/mapper/$pvname
vgcreate $vgname /dev/mapper/$pvname
lvcreate -l 100%FREE $vgname -n $lvname

if [[ $formatboot != 'n' && $formatboot != 'N' ]]; then
    echo "[Log] Formatting boot partition"
    mkfs.vfat -F32 $bootpart
fi

rootpart="/dev/mapper/$vgname-$lvname"
echo "[Log] Formatting and mounting volumes"
#mkfs.f2fs -f $rootpart
echo 'y' | mkfs.ext4 -j $rootpart
mount $rootpart /mnt
mkdir /mnt/boot
mount $bootpart /mnt/boot
echo "[Log] Copying stuff to /mnt"
cp chroot.sh /mnt

read -p  "[Input] Include mount data HDD? (Y/n): " mounthdd
if [[ $mounthdd != 'n' && $mounthdd != 'N' ]]; then
    echo
    read -p "[Input] Format and set up data device? (y/N) " formatdata
    if [[ $formatdata == 'y' || $formatdata == 'Y' ]]; then
        while [[ ! -b $datadevice ]]; do
            lsblk
            echo
            read -p "[Input] Please enter device to be used (/dev/sdX) " datadevice
        done
        while [[ $repeat != 'y' && $repeat != 'Y' ]]; do
            echo "[Log] Will now enter gdisk with device $disk"
            echo -e "Commands:\n# Erase: o, y\n# Create partition: n, defaults\n# Check and write: p, w"
            gdisk $datadevice
            read -p "[Input] Is the configuration correct? (y/N): " repeat
        done
        repeat=
        lsblk
        while [[ ! -b $datapart ]]; do
            read -p "[Input] Please enter data partition (/dev/sdaX) " datapart
        done
        echo "[Log] Formatting data partition"
        echo 'y' | mkfs.ext4 -j $datapart
    else
        lsblk
        while [[ ! -b $datapart ]]; do
            read -p "[Input] Please enter data partition (/dev/sdaX) " datapart
        done
    fi
    
    mkdir -p /mnt/mnt/Data
    mount $datapart /mnt/mnt/Data
fi

echo "[Log] archlinux-keyring"
pacman -Sy --noconfirm archlinux-keyring
echo "[Log] Installing base"
pacstrap /mnt base
echo "[Log] Generating fstab"
genfstab -pU /mnt > /mnt/etc/fstab
echo "tmpfs	/tmp	tmpfs	defaults,noatime,mode=1777	0	0" | tee -a /mnt/etc/fstab
sed -i "s/relatime/noatime/" /mnt/etc/fstab
echo "[Log] Running chroot.sh in arch-chroot"
arch-chroot /mnt ./chroot.sh
echo "[Log] Removing chroot.sh"
rm /mnt/chroot.sh
echo "[Log] Install script done!"
