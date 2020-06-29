#!/bin/bash

trap 'rm failed.txt 2>/dev/null; exit' INT TERM EXIT

packages=(
checkra1n-cli
gconf
libirecovery-git
exfat-utils-nofuse
futurerestore-s0uthwest-git
idevicerestore-git
informant
ncurses5-compat-libs
python2-twodict-git
gallery-dl
github-desktop-bin
masterpdfeditor-free
qdirstat
qsynth
ventoy-bin
wps-office
youtube-dl-gui-git
)

paccache=$HOME/.cache/yay

function MainMenu {
  select opt in "Install stuff" "Run postinstall commands" "Backup and restore" "Add user" "NVIDIA Optimus+TLP" "NVIDIA 390xx"; do
    case $opt in
      "Install stuff" ) installstuff; break;;
      "Run postinstall commands" ) postinstallcomm; break;;
      "Backup and restore" ) BackupRestore; break;;
      "Add user" ) adduser; break;;
      "NVIDIA Optimus+TLP" ) laptop; break;;
      "NVIDIA 390xx" ) 390xx; break;;
      * ) exit;;
    esac
  done
}

function installstuff {
  select opt in "Install AUR pkgs yay" "VirtualBox" "osu!" "Emulators" "devkitPro" "KVM with GVT-g"; do
    case $opt in
      "Install AUR pkgs yay" ) postinstall; break;;
      "VirtualBox" ) vbox; break;;
      "osu!" ) osu; break;;
      "Emulators" ) emulatorsinstall; break;;
      "devkitPro" ) devkitPro; break;;
      "KVM with GVT-g" ) kvm; break;;
      * ) exit;;
    esac
  done
}

function installpac {
  git clone https://aur.archlinux.org/$1.git
  cd $1
  makepkg -sic
  cd ..
  rm -rf $1
}

function postinstall {
  for package in "${packages[@]}"; do
    sudo pacman -U --noconfirm --needed $paccache/$package/$package*.zst 2>/dev/null
    if [ $? == 1 ]; then
      echo $package | tee -a failed.txt
    fi
  done
  IFS=$'\r\n' GLOBIGNORE='*' command eval 'failed=($(cat failed.txt))'
  for package in "${failed[@]}"; do
    pac install $package
  done
  echo 'export PATH="/usr/lib/ccache/bin/:$PATH"
  export DEVKITPRO=/opt/devkitpro
  export DEVKITARM=/opt/devkitpro/devkitARM
  export DEVKITPPC=/opt/devkitpro/devkitPPC' | tee $HOME/.profile
}

function postinstallcomm {
  [ -e $HOME/Documents/Packages/ ] && sudo pacman -U --noconfirm --needed $HOME/Documents/Packages/*.xz $HOME/Documents/Packages/*.gz $HOME/Documents/Packages/*.zst #for veikk drivers and fonts
  sudo timedatectl set-ntp true
  sudo systemctl --global disable pipewire pipewire.socket
  sudo modprobe ohci_hcd
  setxkbmap -layout us
  xmodmap -e 'keycode 84 = Down KP_5 Down KP_5'
  sudo pac.sh /usr/bin/pac
  sudo chmod +x /usr/bin/pac
  # home symlinks
  cd $HOME/.config
  ln -sf /mnt/Data/$USER/config/PCSX2/
  ln -sf /mnt/Data/$USER/config/ppsspp/
  ln -sf /mnt/Data/$USER/config/rpcs3/
  cd $HOME/.local/share
  ln -sf /mnt/Data/$USER/share/citra-emu/
  ln -sf /mnt/Data/$USER/share/dolphin-emu/
  ln -sf /mnt/Data/$USER/share/osu/
  ln -sf /mnt/Data/$USER/share/yuzu/
  cd $HOME/.cemu
  ln -sf /mnt/Data/$USER/cemu/controllerProfiles/
  ln -sf /mnt/Data/$USER/cemu/graphicPacks/
  ln -sf /mnt/Data/$USER/cemu/mlc01/
  ln -sf /mnt/Data/$USER/cemu/shaderCache/
  cd $HOME/.cache
  ln -sf /mnt/Data/$USER/cache/wine
  ln -sf /mnt/Data/$USER/cache/winetricks
  ln -sf /mnt/Data/$USER/cache/yay
}

function adduser {
  echo "[Input] Enter username"
  read username2
  echo "[Log] Creating user $username2"
  sudo useradd -m -g users -G audio -s /usr/bin/fish $username2
  echo "[Log] Running passwd $username2"
  sudo passwd $username2
}

function autocreate {
  a=$1
  [ ! -z $2 ] && a=$2
  echo "[Desktop Entry]
  Encoding=UTF-8
  Version=0.9.4
  Type=Application
  Name=$1
  Exec=$a
  RunHook=0
  StartupNotify=false
  Terminal=false
  Hidden=false" | tee $HOME/.config/autostart/$1.desktop
}

function vbox {
  pac install virtualbox virtualbox-host-dkms virtualbox-guest-iso virtualbox-ext-oracle
  sudo usermod -aG vboxusers $USER
  sudo modprobe vboxdrv
}

function laptop {
  pac install bbswitch-dkms nvidia-lts lib32-nvidia-utils nvidia-settings tlp tlp-rdw tlpui-git optimus-manager optimus-manager-qt vulkan-icd-loader lib32-vulkan-icd-loader vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver
  sudo systemctl enable tlp
  sudo sed -i '/DisplayCommand/s/^/#/g' /etc/sddm.conf
  sudo sed -i '/DisplayStopCommand/s/^/#/g' /etc/sddm.conf
}

function 390xx {
  pac install nvidia-390xx-lts lib32-nvidia-390xx-utils nvidia-390xx-settings
}

function emulatorsinstall {
  pacman -S --noconfirm --needed dolphin-emu fceux melonds-git-jit mgba-qt ppsspp
  yay -S --noconfirm $(yay -Qi cemu citra-canary-git pcsx2-git rpcs3-bin yuzu-mainline-git 2>&1 >/dev/null | grep "error: package" | grep "was not found" | cut -d"'" -f2 | tr "\n" " ")
}

function osu {
  $(dirname $(type -p $0))/osu.sh install
}

function devkitPro {
  sudo pacman-key --recv F7FD5492264BB9D0
  sudo pacman-key --lsign F7FD5492264BB9D0
  sudo pacman -U https://downloads.devkitpro.org/devkitpro-keyring-r1.787e015-2-any.pkg.tar.xz
  echo '[dkp-libs]
  Server = https://downloads.devkitpro.org/packages
  [dkp-linux]
  Server = https://downloads.devkitpro.org/packages/linux' | sudo tee -a /etc/pacman.conf
  sudo pacman -Sy --noconfirm 3ds-dev switch-dev
}

function kvm {
  if [ -e /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types ] && [ ! -e /etc/systemd/system/gvtvgpu.service ]; then
    kvmstep2
  else
    kvmstep1
  fi
}

function kvmstep1 {
  sudo pacman -S --noconfirm --needed virt-manager qemu vde2 ebtables dnsmasq bridge-utils openbsd-netcat

  echo "[global]
  allow insecure wide links = yes
  workgroup = WORKGROUP
  netbios name = $USER

  [LinuxHost]
  comment = Host Share
  path = $HOME
  valid users = $USER
  public = no
  writable = yes
  printable = no
  follow symlinks = yes
  wide links = yes" | sudo tee /etc/samba/smb.conf

  sudo systemctl enable --now libvirtd smb nmb
  sudo sed -i "s|MODULES=(ext4)|MODULES=(ext4 kvmgt vfio vfio-iommu-type1 vfio-mdev)|g" /etc/mkinitcpio.conf
  sudo mkinitcpio -p linux-lts
  echo 'SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"' | sudo tee /etc/udev/rules.d/10-qemu.rules
  sudo usermod -aG kvm,libvirt $USER 
  sudo smbpasswd -a $USER
  sudo sed -i '/^options/ s/$/ i915.enable_gvt=1 kvm.ignore_msrs=1 iommu=pt intel_iommu=on/' /boot/loader/entries/arch.conf
  echo
  echo "Reboot and run this again to continue install"
}

function kvmstep2 {
  UUID=029a88f0-6c3e-4673-8b3c-097fe77d7c97
  sudo /bin/sh -c "echo $UUID > /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create"
  echo "[Unit]
  Description=Create Intel GVT-g vGPU

  [Service]
  Type=oneshot
  ExecStart=/bin/sh -c \"echo '$UUID' > /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create\"
  ExecStop=/bin/sh -c \"echo '1' > /sys/devices/pci0000:00/0000:00:02.0/$UUID/remove\"
  RemainAfterExit=yes

  [Install]
  WantedBy=graphical.target" | sudo tee /etc/systemd/system/gvtvgpu.service
  echo $UUID | tee gpu_uuid
  sudo systemctl enable gvtvgpu
  echo
  echo "Done! Reboot before continuing"
}

function RSYNC {
  [[ $ArgR == sparse ]] && ArgR=--sparse
  [[ $ArgR != full ]] && Update=--update
  if [[ $3 == user ]]; then
    sudo rsync -va $ArgR $Update --delete-after --info=progress2 --exclude '.ccache' --exclude '.local/share/lutris' --exclude 'KVM' --exclude 'osu' --exclude '.cache' --exclude '.local/share/baloo' --exclude '.local/share/Trash' --exclude '.config/chromium/Default/Service Worker/CacheStorage' --exclude '.config/chromium/Default/File System' --exclude '.local/share/gvfs-metadata' --exclude '.wine' --exclude '.wine_lutris' --exclude '.wine_osu' --exclude '.cemu/wine' $1 $2
  else
    sudo rsync -va $ArgR $Update --delete-after --info=progress2 --exclude 'VirtualBox VMs' $1 $2
  fi
}

function BackupRestore {
  select opt in "Backup" "Restore"; do
    case $opt in
      "Backup" ) Action=Backup; break;;
      "Restore" ) Action=Restore; break;;
      * ) exit;;
    esac
  done
  select opt in "$Action home" "$Action pacman" "$Action VMs"; do
    case $opt in
      "$Action home" ) Mode=user; break;;
      "$Action pacman" ) Mode=pac; break;;
      "$Action VMs" ) ArgR=sparse; Mode=vm; break;;
      * ) exit;;
    esac
  done
  if [ $Mode == user ]; then
    Paths=(/home/$USER/ /run/media/$USER/LukeHDD2/Backups/$USER/
           /mnt/Data/$USER/ /run/media/$USER/LukeHDD2/Backups/Data/$USER/
           /home/$USER/osu/ /run/media/$USER/LukeHDD2/Backups/Data/osu/)
  elif [ $Mode == pac ]; then
    Paths=(/var/cache/pacman/pkg/ /run/media/$USER/LukeHDD2/Backups/pkg/
           $HOME/.cache/yay/ /run/media/$USER/LukeHDD2/Backups/yay/)
  elif [ $Mode == vm ]; then
    Paths=($HOME/KVM/ /run/media/$USER/LukeHDD2/Backups/Data/KVM/)
  fi
  if [ $Action == Backup ]; then
    if [ $Mode == user ]; then
      RSYNC ${Paths[0]} ${Paths[1]} user
      RSYNC ${Paths[2]} ${Paths[3]}
      RSYNC ${Paths[4]} ${Paths[5]}
    elif [ $Mode == pac ]; then
      RSYNC ${Paths[0]} ${Paths[1]}
      RSYNC ${Paths[2]} ${Paths[3]}
    elif [ $Mode == vm ]; then
      RSYNC ${Paths[0]} ${Paths[1]}
    fi
  elif [ $Action == Restore ]; then
    if [ $Mode == user ]; then
      select opt in "Update restore" "Full restore"; do
        case $opt in
          "Update restore" ) Restoreuser; break;;
          "Full restore" ) ArgR=full; Restoreuser; break;;
          * ) exit;;
        esac
      done
    elif [ $Mode == pac ]; then
      RSYNC ${Paths[1]} ${Paths[0]}
      RSYNC ${Paths[3]} ${Paths[2]}
    elif [ $Mode == vm ]; then
      RSYNC ${Paths[1]} ${Paths[0]}
    fi
  fi
}

function Restoreuser {
  RSYNC ${Paths[1]} ${Paths[0]} user
  RSYNC ${Paths[3]} ${Paths[2]}
  RSYNC ${Paths[5]} ${Paths[4]}
  rm -rf $HOME/.cache/wine $HOME/.cache/winetricks $HOME/.cache/yay
  cd $HOME/.cache
  ln -sf /mnt/Data/$USER/cache/wine
  ln -sf /mnt/Data/$USER/cache/winetricks
  ln -sf /mnt/Data/$USER/cache/yay
}

# ----------------------------------

clear
echo "LukeZGD Arch Post-Install Script"
echo "This script will assume that you have a working Internet connection"
echo

if [ ! $(which yay) ]; then
  echo "No yay detected, installing yay"
  installpac yay-bin
fi

MainMenu
