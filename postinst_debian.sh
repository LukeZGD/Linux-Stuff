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
cpu-x
curl
default-jre
docker.io
f3
filezilla
fish
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
k3b
kamoso
kdenlive
krdc
libadwaita-1-0
libgtk-4-1
linssid
mesa-vulkan-drivers
mpv
neofetch
network-manager-openvpn
obs-studio
okteta
piper
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
    sudo apt install -y $HOME/Programs/Packages/*.deb

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

    sudo mkdir -pm755 /etc/apt/keyrings
    sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/$VERSION_CODENAME/winehq-$VERSION_CODENAME.sources

    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    NODE_MAJOR=20 echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

    sudo apt update
    sudo apt install -y nodejs
    sudo apt install -y --install-recommends winehq-staging lutris winbind mesa-vulkan-drivers:i386 gstreamer1.0-plugins-bad:i386 gstreamer1.0-plugins-base:i386 gstreamer1.0-plugins-good:i386 gstreamer1.0-plugins-ugly:i386

    pipinst

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak override --filesystem=xdg-config/gtk-3.0
    sudo flatpak override --filesystem=xdg-config/gtk-4.0
    flatpak install -y flathub "${flatpkgs[@]}"
}

emulatorsinst() {
    sudo apt install -y nestopia
    flatpakemusinst
}

kvm() {
    :
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
