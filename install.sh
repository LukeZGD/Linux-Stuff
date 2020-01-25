#!/bin/bash

mirrorlist='
Server = http://mirrors.evowise.com/archlinux/$repo/os/$arch
Server = http://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.aarnet.edu.au/pub/archlinux/$repo/os/$arch
Server = http://archlinux.mirror.digitalpacific.com.au/$repo/os/$arch
Server = http://ftp.iinet.net.au/pub/archlinux/$repo/os/$arch
Server = http://mirror.internode.on.net/pub/archlinux/$repo/os/$arch
Server = http://archlinux.melbourneitmirror.net/$repo/os/$arch
Server = http://syd.mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://syd.mirror.rackspace.com/archlinux/$repo/os/$arch
Server = http://ftp.swin.edu.au/archlinux/$repo/os/$arch
Server = http://mirror.0x.sg/archlinux/$repo/os/$arch
Server = https://mirror.0x.sg/archlinux/$repo/os/$arch
Server = http://mirror.aktkn.sg/archlinux/$repo/os/$arch
Server = https://mirror.aktkn.sg/archlinux/$repo/os/$arch
Server = https://download.nus.edu.sg/mirror/archlinux/$repo/os/$arch
Server = https://sgp.mirror.pkgbuild.com/$repo/os/$arch
Server = http://mirror.nus.edu.sg/archlinux/$repo/os/$arch
'

clear

echo "LukeZGD Arch Install Script"
echo "This script will assume that you have a working Internet connection"
echo "Press [enter] to continue, or ^C to cancel"
read

echo ""
echo "[Log] Creating mirrorlist"
echo "$mirrorlist" > /etc/pacman.d/mirrorlist
echo "[Log] Enabling ntp"
timedatectl set-ntp true

if [[ $diskprog != y ]] || [[ $diskprog != Y ]] || [[ $diskprog != n ]] || [[ $diskprog != N ]]; then
  echo "[Input] (y) fdisk BIOS/MBR, (n) gdisk UEFI/GPT"
  read diskprog
fi
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
echo "Will now enter $diskprog with device $disk. Press [enter]"
read
echo "Commands: (f) fdisk (g) gdisk
# Erase: o y
# Create boot (f): n <enter> <enter> <enter> +256M
# Create boot (g): n <enter> <enter> <enter> +256M EF00
# Create partition (f): n, <enter> <enter> <enter> <enter>
# Create partition (g): n, <enter> <enter> <enter> <enter> 8E00
# Check and write: p w"
$diskprog $disk

clear
lsblk
echo ""
echo "[Input] Please enter encrypted partition (/dev/sdaX)"
read rootpart
echo "[Input] Please enter boot partition (/dev/sdaX)"
read bootpart
echo "[Input] (y) Clean install | (N) Format root only"
read formatroot

if [[ $formatroot == y ]] || [[ $formatroot == Y ]]; then
  if [[ $diskprog != n ]] || [[ $diskprog != N ]]; then
    mkfs.vfat -F32 $bootpart
  elif [[ $diskprog != y ]] || [[ $diskprog != Y ]]; then
    mkfs.ext2 $bootpart
  fi
  cryptsetup luksFormat $rootpart
  cryptsetup luksOpen $rootpart lvm
  pvcreate /dev/mapper/lvm
  vgcreate vg0 /dev/mapper/lvm
  lvcreate -L 6G vg0 -n swap
  lvcreate -L 25G vg0 -n root
  lvcreate -l 100%FREE vg0 -n home
  mkfs.ext4 /dev/mapper/vg0-home
else
  cryptsetup luksOpen $rootpart lvm
fi
mkfs.ext4 /dev/mapper/vg0-root
mkswap /dev/mapper/vg0-swap
mount /dev/mapper/vg0-root /mnt
mkdir /mnt/boot /mnt/home 2>/dev/null
mount /dev/mapper/vg0-home /mnt/home
mount $bootpart /mnt/boot
swapon /dev/mapper/vg0-swap

echo "[Log] Copying chroot.sh to /mnt"
cp chroot.sh /mnt

echo "[Input] Copy local cache to /mnt? (y/n)"
read dotcache
if [ $dotcache == y ]
then
    mkdir -p /mnt/var/cache/pacman
    cp -R Backups/pkg /mnt/var/cache/pacman
    umount /mnt2
fi
echo "[Log] Installing base"
pacstrap /mnt base
if [ $i386efi == y ]
then
  echo "[Log] Installing efibootmgr"
  arch-chroot /mnt pacman -S --noconfirm efibootmgr
fi
echo "[Log] Generating fstab"
genfstab -pU /mnt > /mnt/etc/fstab
echo "[Log] Running chroot.sh in arch-chroot"
arch-chroot /mnt ./chroot.sh
echo "[Log] Install script done!"
