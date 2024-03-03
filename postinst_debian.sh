#!/bin/bash
trap "exit 1" INT TERM EXIT
. $HOME/Linux-Stuff/scripts/preparelutris.sh
. $HOME/Linux-Stuff/postinst_shared.sh
. /etc/os-release

packages=(
aria2
audacious
audacity
ca-certificates
cabextract
clinfo
cpu-x
curl
default-jre
docker.io
f3
filezilla
fish
flac
flatpak
gnome-calculator
gnome-disk-utility
gnupg
gstreamer1.0-plugins-bad
gstreamer1.0-plugins-base
gstreamer1.0-plugins-good
gstreamer1.0-plugins-ugly
hplip
intel-media-va-driver-non-free
intel-opencl-icd
k3b
kamoso
kdenlive
kio-audiocd
kio-fuse
krdc
libadwaita-1-0
libgtk-4-1
libspa-0.2-bluetooth
linssid
mesa-vulkan-drivers
mpv
neofetch
network-manager-openvpn
obs-studio
okteta
okular-extra-backends
pavucontrol
piper
pipewire
power-profiles-daemon
python-is-python3
python3-pip
python3-wxgtk4.0
qdirstat
samba
shellcheck
simple-scan
system-config-printer
tealdeer
transmission-qt
uget
unrar
wayland-utils
xdelta3
)

postinst() {
    sudo dpkg --add-architecture i386
    sudo add-apt-repository -y contrib
    sudo add-apt-repository -y non-free
    #if [[ $(cat /etc/apt/sources.list | grep -c 'backports main') == 0 ]]; then
    #    echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free" | sudo tee -a /etc/apt/sources.list
    #fi
    sudo apt update
    sudo apt upgrade -y
    #sudo apt -t bookworm-backports install linux-image-amd64
    sudo apt install -y "${packages[@]}"
    sudo apt install -y $HOME/Programs/Packages/deb/*.deb

    sudo chown -R $USER: /usr/local
    ln -sf $HOME/Linux-Stuff/postinst_debian.sh /usr/local/bin/postinst
    printf '#!/bin/sh\nyt-dlp --compat-options youtube-dl "$@"' > /usr/local/bin/youtube-dl
    printf '#!/bin/sh\nsystemctl poweroff' > /usr/local/bin/poweroff
    printf '#!/bin/sh\nsystemctl reboot' > /usr/local/bin/reboot
    chmod +x /usr/local/bin/youtube-dl /usr/local/bin/poweroff /usr/local/bin/reboot
    if [[ ! $(ls /mnt/Data) ]]; then
        sudo mkdir /mnt/Data
        sudo chown $USER: /mnt/Data
    fi
    sudo usermod -aG vboxusers $USER
    sudo cp /usr/share/samba/smb.conf /etc/samba/smb.conf
    sudo sed -i '/them./{n;s/.*/read only = no\nfollow symlinks = yes\nwide links = yes\nacl allow execute always = yes/}' /etc/samba/smb.conf
    sudo sed -i '/\[global\]/{n;s/.*/allow insecure wide links = yes/}' /etc/samba/smb.conf
    fc-cache -f -v
    #echo '#!/bin/sh' | sudo tee /etc/rc.local
    #echo 'echo "1" | tee /sys/devices/system/cpu/intel_pstate/no_turbo' | sudo tee -a /etc/rc.local
    #sudo chmod 700 /etc/rc.local
    echo 'w /sys/power/pm_async - - - - 0' | sudo tee /etc/tmpfiles.d/no-pm-async.conf
    systemctl --user enable --now pipewire

    sudo mkdir -pm755 /etc/apt/keyrings
    # winehq repo
    sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/$VERSION_CODENAME/winehq-$VERSION_CODENAME.sources
    # node repo
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    NODE_MAJOR=20 echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    # mozilla repo
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); print "\n"$0"\n"}'
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
    echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
    # lutris repo
    echo "deb [signed-by=/etc/apt/keyrings/lutris.gpg] https://download.opensuse.org/repositories/home:/strycore/Debian_12/ ./" | sudo tee /etc/apt/sources.list.d/lutris.list > /dev/null
    wget -q -O- https://download.opensuse.org/repositories/home:/strycore/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/keyrings/lutris.gpg > /dev/null

    sudo apt update
    sudo apt install -y firefox fonts-{takao,mona,monapo} gstreamer1.0-{plugins-{good,ugly},libav}:i386 nodejs
    sudo apt install -y --install-recommends winehq-stable lutris winbind mesa-vulkan-drivers:i386
    sudo apt remove -y firefox-esr gwenview konqueror pulseaudio
    sudo apt autoremove -y

    pipinst

    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak override --filesystem=xdg-config/gtk-3.0
    sudo flatpak override --filesystem=xdg-config/gtk-4.0
    flatpak install -y flathub "${flatpkgs[@]}"
}

emulatorsinst() {
    #sudo apt install -y nestopia
    flatpakemusinst
}

kvm() {
    sudo apt install qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf
    sudo usermod -aG kvm,libvirt $USER
    echo 'SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"' | sudo tee /etc/udev/rules.d/10-qemu.rules
    echo "add 'iommu=pt intel-iommu=on' (or amd-iommu) to /etc/default/grub then press enter"
    read -s
    sudo update-grub
}

main() {
    clear
    select opt in "postinst" "install stuff" "backup and restore"; do
    case $opt in
        "postinst" ) postinst; break;;
        "install stuff" ) installstuff; break;;
        "backup and restore" ) $HOME/Linux-Stuff/postinst.sh BackupRestore; break;;
    esac
    done
}

installstuff() {
    select opt in "wine prefixes" "osu!" "Emulators" "FL Studio" "VBox Extension Pack" "KVM w/ virt-manager"; do
    case $opt in
        "wine prefixes" ) wineprefixes; break;;
        "osu!" ) $HOME/Linux-Stuff/scripts/osu.sh install; break;;
        "Emulators" ) emulatorsinst; break;;
        "FL Studio" ) $HOME/Linux-Stuff/scripts/flstudio.sh install; break;;
        "VBox Extension Pack" ) vboxextension; break;;
        "KVM w/ virt-manager" ) kvm; break;;
        * ) exit;;
    esac
    done
}

if [[ $(groups | grep -c 'sudo') == 0 ]]; then
    echo "$USER is not in sudo group. add $USER to sudo first:"
    echo "    su -"
    echo "    <enter root pass>"
    echo "    usermod -aG sudo $USER"
    echo "    systemctl reboot"
    exit 1
fi

if [[ $1 == "update" ]]; then
    sudo apt update
    sudo apt upgrade -y
    pipinst
    flatpak update -y
    exit
fi

main
