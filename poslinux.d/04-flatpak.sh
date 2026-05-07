# shellcheck shell=bash
# Instalação e gerenciamento de Flatpak e apps Flatpak.

# ==========================================================
# Flatpak
# ==========================================================

install_flatpak() {
    case "$PKG_MANAGER" in
        apt|dnf|yum|pacman|zypper)
            run_pkg_install "flatpak"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

add_flathub() {
    run_cmd "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
}

install_flatpak_apps() {
    local choice

    choice=$(whiptail --title "Flatpak Apps" \
        --checklist "Selecione os aplicativos:" \
        22 78 10 \
        "org.mozilla.firefox" "Firefox" OFF \
        "com.visualstudio.code" "Visual Studio Code" OFF \
        "org.videolan.VLC" "VLC" OFF \
        "com.spotify.Client" "Spotify" OFF \
        "org.gimp.GIMP" "GIMP" OFF \
        "com.discordapp.Discord" "Discord" OFF \
        3>&1 1>&2 2>&3)

    if [[ -z "$choice" ]]; then
        return
    fi

    local apps
    apps=$(echo "$choice" | tr -d '"')

    run_cmd "flatpak install -y flathub $apps"
}
