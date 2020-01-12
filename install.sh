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

select opt in "cfdisk" "cgdisk" "fdisk" "gdisk"; do
    case $opt in
        "cfdisk" ) diskprog="cfdisk"; break;;
        "cgdisk" ) diskprog="cgdisk"; break;;
        "fdisk" ) diskprog="fdisk"; break;;
        "gdisk" ) diskprog="gdisk"; break;;
    esac
done
echo ""
lsblk
echo ""
echo "[Input] Please enter device to be used (/dev/sdX)"
read disk
echo "Will now enter $diskprog with device $disk. Press [enter]"
read
echo "Commands for gdisk:
# Erasure
o
Y

# Create EFI
n
<enter>
<enter>
+512M
EF00

# Create partition
n
<enter>
<enter>
<enter>
8E00

# Check and write
p
w"
$diskprog $disk

clear
lsblk
echo ""
echo "[Input] Please enter encrypted partition (/dev/sdaX) (REQUIRED)"
read rootpart
echo "[Input] Please enter EFI partition (/dev/sdaX)"
read efipart

mkfs.vfat -F32 $efipart
cryptsetup luksFormat $rootpart
cryptsetup luksOpen $rootpart lvm
pvcreate /dev/mapper/lvm
vgcreate vg0 /dev/mapper/lvm
lvcreate -L 6G vg0 -n swap
lvcreate -L 25G vg0 -n root
lvcreate -l 100%FREE vg0 -n home
mkfs.ext4 /dev/mapper/vg0-root
mkfs.ext4 /dev/mapper/vg0-home
mkswap /dev/mapper/vg0-swap
mount /dev/mapper/vg0-root /mnt
mkdir /mnt/boot /mnt/home
mount /dev/mapper/vg0-home /mnt/home
mount $efipart /mnt/boot
swapon /dev/mapper/vg0-swap

echo "[Log] Copying stuff to /mnt"
cp chroot.sh /mnt
mkdir -p /mnt/usr/bin
cp unmountonlogout /mnt/usr/bin/
chmod +x /mnt/usr/bin/unmountonlogout

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
