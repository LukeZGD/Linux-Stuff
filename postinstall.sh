#!/bin/bash

trap 'rm failed.txt 2>/dev/null; exit' INT TERM EXIT

packages=(
checkra1n-cli
gconf
libirecovery-git
libsndio-61-compat
ncurses5-compat-libs
python2-twodict-git
etcher-bin
gallery-dl
github-desktop-bin
masterpdfeditor-free
qdirstat
qsynth
woeusb
wps-office
youtube-dl-gui-git
)

osu='
#!/bin/sh
export WINEPREFIX="$HOME/.wine_osu"
cd $HOME/osu # Or wherever you installed osu! in
wine osu!.exe "$@"
'

osukill='
#!/bin/sh
export WINEPREFIX="$HOME/.wine_osu"
wineserver -k
'

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
  makepkg -si
  cd ..
  rm -rf $1
}

function postinstall {
  for package in "${packages[@]}"; do
    sudo pacman -U --noconfirm --needed $paccache/$package/$package*.xz 2>/dev/null
    if [ $? == 1 ]; then
      echo $package | tee -a failed.txt
    fi
  done
  IFS=$'\r\n' GLOBIGNORE='*' command eval 'failed=($(cat failed.txt))'
  for package in "${failed[@]}"; do
    yay -S --noconfirm --answerclean All --removemake $package
  done
  installpac libimobiledevice-git
  yay -S --noconfirm --answerclean All --removemake idevicerestore-git
}

function postinstallcomm {
  [ -e $HOME/Documents/packages/ ] && sudo pacman -U --noconfirm --needed $HOME/Documents/packages/*.xz $HOME/Documents/packages/*.gz #for veikk drivers and fonts
  #gsettings set org.nemo.desktop font 'Cantarell Regular 10'
  gsettings set org.nemo.preferences size-prefixes 'base-2'
  #xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-power-key -n -t bool -s true
  #xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-lid-switch -n -t bool -s true
  #autocreate "light-locker"
  #autocreate "xfce4-clipman"
  #echo 'export QT_STYLE_OVERRIDE=adwaita-dark' | tee -a $HOME/.xprofile
  sudo timedatectl set-ntp true
  #sudo timedatectl set-local-rtc 1 --adjust-system-clock
  sudo systemctl --global disable pipewire pipewire.socket
  setxkbmap -layout us
  xmodmap -e 'keycode 84 = Down KP_5 Down KP_5'
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
  if [ -z "$2" ]; then
    a=$1
  else
    a=$2
  fi
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
  yay -S --noconfirm --answerclean All --removemake virtualbox virtualbox-host-dkms virtualbox-guest-iso virtualbox-ext-oracle
  sudo usermod -aG vboxusers $USER
  sudo modprobe vboxdrv
}

function laptop {
  yay -S --noconfirm --answerclean All --removemake bbswitch-dkms nvidia-lts lib32-nvidia-utils nvidia-settings tlp optimus-manager optimus-manager-qt vulkan-icd-loader lib32-vulkan-icd-loader vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver
  sudo systemctl enable tlp
  sudo sed -i '/DisplayCommand/s/^/#/g' /etc/sddm.conf
  sudo sed -i '/DisplayStopCommand/s/^/#/g' /etc/sddm.conf
}

function 390xx {
  sudo pacman -S --noconfirm nvidia-390xx-lts lib32-nvidia-390xx-utils nvidia-390xx-settings
}

function emulatorsinstall {
  pacman -S --noconfirm --needed desmume dolphin-emu fceux mgba-qt ppsspp
  yay -S --noconfirm $(yay -Qi citra-canary-git cemu pcsx2-git rpcs3-bin yuzu-mainline-git 2>&1 >/dev/null | grep "error: package" | grep "was not found" | cut -d"'" -f2 | tr "\n" " ")
}

function osu {
  sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
  sudo pacman -Sy
  
  sudo cp /etc/security/limits.conf /etc/security/limits.conf.bak
  echo "@audio - nice -20
  @audio - rtprio 99" | sudo tee /etc/security/limits.conf

  sudo mkdir /etc/pulse/daemon.conf.d
  echo "high-priority = yes
  nice-level = -15

  realtime-scheduling = yes
  realtime-priority = 50

  resample-method = speex-float-0

  default-fragments = 2 # Minimum is 2
  default-fragment-size-msec = 4" | sudo tee /etc/pulse/daemon.conf.d/10-better-latency.conf

  echo "$osu" | sudo tee /usr/bin/osu
  echo "$osukill" | sudo tee /usr/bin/osukill
  sudo chmod +x /usr/bin/osu /usr/bin/osukill

  sink="$(pacmd info |grep 'Default sink name' |cut -c 20-)"

  mkdir $HOME/.config/pulse 2>/dev/null
  cp -R /etc/pulse/default.pa $HOME/.config/pulse/default.pa
  sed -i "s/load-module module-udev-detect.*/load-module module-udev-detect tsched=0 fixed_latency_range=yes/" $HOME/.config/pulse/default.pa
  
  sudo pacman -S --noconfirm lib32-alsa-plugins lib32-gnutls lib32-libxcomposite winetricks

  #sudo rsync -va --update --delete-after /run/media/$USER/LukeHDD2/Backups/winetricks/ $HOME/.cache/winetricks/
  rm -rf $HOME/.wine_osu
  
  export WINEPREFIX="$HOME/.wine_osu"
  export WINEARCH=win32

  winetricks dotnet40
  winetricks gdiplus
  
  #echo "Preparations complete. Download and install osu! now? (y/N)"
  #read installoss
  if [ $installoss == y ] || [ $installoss == Y ]; then
    curl -L -# 'https://m1.ppy.sh/r/osu!install.exe'
    wine 'osu!install.exe'
  fi
  echo "Script done"
}

function devkitPro {
  echo 'export DEVKITPRO=/opt/devkitpro
  export DEVKITARM=/opt/devkitpro/devkitARM
  export DEVKITPPC=/opt/devkitpro/devkitPPC' | tee $HOME/.profile
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
  sudo gpasswd -a $USER kvm
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

function RSYNCuser {
  sudo rsync -va --update --delete-after --info=progress2 --exclude 'macOS-Simple-KVM' --exclude 'win10.qcow2' --exclude 'osu' --exclude '.cache' --exclude '.local/share/baloo' --exclude '.local/share/Trash' --exclude '.config/chromium/Default/Service Worker/CacheStorage' --exclude '.config/chromium/Default/File System' --exclude '.local/share/gvfs-metadata' --exclude '.wine' --exclude '.wineoffice' --exclude '.wine_osu' --exclude '.cemu/wine' $1 $2
}

function RSYNC {
  # -va can be replaced with -vrltD
  [ ! $Full ] && Update=--update
  sudo rsync -va $Update --delete-after --info=progress2 --exclude 'VirtualBox VMs' $1 $2
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
      "$Action VMs" ) Mode=vm; break;;
      * ) exit;;
    esac
  if [ $Mode == user ]; then
    Paths=(/home/$USER/ /run/media/$USER/LukeHDD2/Backups/$USER/
           /mnt/Data/$USER/ /run/media/$USER/LukeHDD2/Backups/Data/$USER/
           /home/$USER/osu/ /run/media/$USER/LukeHDD2/Backups/Data/osu/)
  elif [ $Mode == pac ]; then
    Paths=(/var/cache/pacman/pkg/ /run/media/$USER/LukeHDD2/Backups/pkg/
           $HOME/.cache/yay/ /run/media/$USER/LukeHDD2/Backups/yay/)
  elif [ $Mode == vm ]; then
    Paths=($HOME/win10.qcow2 /run/media/$USER/LukeHDD2/Backups/Data
           $HOME/macOS-Simple-KVM/ /run/media/$USER/LukeHDD2/Backups/Data/macOS-Simple-KVM/)
  fi
  if [ $Action == Backup ]; then
    if [ $Mode == user ]; then
      RSYNCuser ${Paths[0]} ${Paths[1]}
      RSYNC ${Paths[2]} ${Paths[3]}
      RSYNC ${Paths[4]} ${Paths[5]}
    elif [ $Mode == pac ] || [ $Mode == vm ]; then
      RSYNC ${Paths[0]} ${Paths[1]}
      RSYNC ${Paths[2]} ${Paths[3]}
    fi
  elif [ $Action == Restore ]; then
    if [ $Mode == user ]; then
      select opt in "Update restore" "Full restore"; do
        case $opt in
          "Update restore" ) Restoreuser; break;;
          "Full restore" ) Full=0; Restoreuser; break;;
          * ) exit;;
        esac
      done
    elif [ $Mode == pac ] || [ $Mode == vm ]; then
      RSYNC ${Paths[1]} ${Paths[0]}
      RSYNC ${Paths[3]} ${Paths[2]}
    fi
  fi
}

function Restoreuser {
  RSYNCuser ${Paths[1]} ${Paths[0]}
  RSYNC ${Paths[3]} ${Paths[2]}
  RSYNC ${Paths[5]} ${Paths[4]}
  rm -rf $HOME/.cache/wine $HOME/.cache/winetricks $HOME/.cache/yay
  cd $HOME/.cache
  ln -sf /mnt/Data/$USER/cache/wine
  ln -sf /mnt/Data/$USER/cache/winetricks
  ln -sf /mnt/Data/$USER/cache/yay
}

function Restoreuserfull {
  #just a copy of RSYNCuser with --update removed
  sudo rsync -va --delete-after --info=progress2 --exclude 'macOS-Simple-KVM' --exclude 'win10.qcow2' --exclude 'osu' --exclude '.cache' --exclude '.local/share/baloo' --exclude '.local/share/Trash' --exclude '.config/chromium/Default/Service Worker/CacheStorage' --exclude '.config/chromium/Default/File System' --exclude '.local/share/gvfs-metadata' --exclude '.wine' --exclude '.wineoffice' --exclude '.wine_osu' --exclude '.cemu/wine' ${Paths[1]} ${Paths[0]}
  sudo rsync -va --info=progress2 ${Paths[3]} ${Paths[2]}
  sudo rsync -va --info=progress2 ${Paths[5]} ${Paths[4]}
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
