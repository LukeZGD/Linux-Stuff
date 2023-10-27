#!/bin/bash

flatpkgs=(
com.authy.Authy
com.discordapp.Discord
org.gtk.Gtk3theme.Breeze
us.zoom.Zoom
)

flatemus=(
com.snes9x.Snes9x
io.mgba.mGBA
net.kuribo64.melonDS
net.pcsx2.PCSX2
net.rpcs3.RPCS3
org.DolphinEmu.dolphin-emu
org.duckstation.DuckStation
org.ppsspp.PPSSPP
org.ryujinx.Ryujinx
)

pipinst() {
    mkdir ~/.config/pip 2>/dev/null
    printf "[global]\nbreak-system-packages = true" > ~/.config/pip/pip.conf
    python3 -m pip install -U gallery-dl yt-dlg yt-dlp
}

flatpakemusinst() {
    flatpak install -y flathub "${flatemus[@]}" "$@"
}

vboxextension() {
    vboxversion=$(curl https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)
    vboxextpack="Oracle_VM_VirtualBox_Extension_Pack-$vboxversion.vbox-extpack"
    wget https://download.virtualbox.org/virtualbox/$vboxversion/$vboxextpack
    sudo VBoxManage extpack install --replace $vboxextpack
    rm $vboxextpack
}

wineprefixes() {
    cd $HOME/.cache
    rm -rf wine winetricks
    ln -sf /mnt/Data/$USER/cache/wine
    ln -sf /mnt/Data/$USER/cache/winetricks

    curl -L https://github.com/Winetricks/winetricks/raw/20230212/src/winetricks -o /usr/local/bin/winetricks
    chmod +x /usr/local/bin/winetricks
    preparewineprefix "$HOME/.wine"
    winetricks -q corefonts quartz mfc42 vcrun2010 vcrun2013 vcrun2019 vkd3d win10 wmp9
    WINEPREFIX=$HOME/.wine $HOME/Documents/mf-install/mf-install.sh

    preparelutris "$lutrisver"
    preparewineprefix "$HOME/.wine_lutris"
    WINEPREFIX=$HOME/.wine_lutris winetricks -q corefonts quartz vkd3d win10 wmp9

    preparelutris "$protonver" "proton"
    preparewineprefix "$HOME/.wine_proton"
    mkdir -p $WINEPREFIX/drive_c/users/steamuser
    cd $WINEPREFIX/drive_c/users/steamuser
    rm -rf 'Saved Games'
    ln -sf $HOME/AppData 'Saved Games'
}
