#!/usr/bin/env bash

flatpkgs=(
com.github.tchx84.Flatseal
com.github.unrud.VideoDownloader
com.github.wwmm.easyeffects
com.interversehq.qView
com.moonlight_stream.Moonlight
com.obsproject.Studio
com.usebottles.bottles
com.valvesoftware.Steam
com.vysp3r.ProtonPlus
io.ente.auth
io.github.shiftey.Desktop
io.missioncenter.MissionCenter
org.filezillaproject.Filezilla
org.gnome.Papers
org.kde.kate
org.kde.kdenlive
org.libreoffice.LibreOffice
org.localsend.localsend_app
org.mozilla.firefox
us.zoom.Zoom
)
#org.freedesktop.Platform.VulkanLayer.gamescope
#org.freedesktop.Platform.VulkanLayer.MangoHud

pipinst() {
    pipx install gallery-dl yt-dlp
}

flatpakemusinst() {
    flatpak install -y net.retrodeck.retrodeck
}

hsr() {
    flatpak install -y moe.launcher.the-honkers-railway-launcher
}

vboxextension() {
    vboxversion=$(curl https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)
    vboxextpack="Oracle_VirtualBox_Extension_Pack-$vboxversion.vbox-extpack"
    wget https://download.virtualbox.org/virtualbox/$vboxversion/$vboxextpack
    sudo VBoxManage extpack install --replace $vboxextpack
    rm $vboxextpack
}

bashrc_custom() {
    BASHRC="${HOME}/.bashrc"

read -r -d '' PATH_SNIPPET <<'EOF'
# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH
EOF

read -r -d '' FISH_SNIPPET <<'EOF'
if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ${BASH_EXECUTION_STRING} && ${SHLVL} == 1 ]]
then
    shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
    exec fish $LOGIN_OPTION
fi
EOF

    # Add PATH block if missing
    if ! grep -Fq 'PATH="$HOME/.local/bin:$HOME/bin:$PATH"' "$BASHRC"; then
        {
            echo
            printf '%s\n' "$PATH_SNIPPET"
        } >> "$BASHRC"

        echo "Added PATH block."
    else
        echo "PATH block already exists."
    fi

    # Add fish auto-start block if missing
    if ! grep -Fq 'exec fish $LOGIN_OPTION' "$BASHRC"; then
        {
            echo
            echo "# Auto-start fish shell"
            printf '%s\n' "$FISH_SNIPPET"
        } >> "$BASHRC"

        echo "Added fish auto-start block."
    else
        echo "Fish auto-start block already exists."
    fi
}

disable_bluetooth_le() {
    CONF="/etc/bluetooth/main.conf"

    # Ensure the file exists
    if [[ ! -f "$CONF" ]]; then
        echo "Error: $CONF not found."
        return 1
    fi

    # Replace any existing (commented or uncommented) ControllerMode line
    if grep -Eq '^[[:space:]]*#?[[:space:]]*ControllerMode[[:space:]]*=' "$CONF"; then
        sudo sed -Ei \
            's|^[[:space:]]*#?[[:space:]]*ControllerMode[[:space:]]*=.*$|ControllerMode = bredr|' \
            "$CONF"
    else
        # Add it under the [General] section if it doesn't exist
        sudo sed -i '/^\[General\]/a ControllerMode = bredr' "$CONF"
    fi
}
