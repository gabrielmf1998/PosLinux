# shellcheck shell=bash
# Programas recomendados pelo desenvolvedor e instaladores auxiliares.

# ==========================================================
# Recomendação Desenvolvedor
# ==========================================================

install_gaming_base() {
    case "$PKG_MANAGER" in
        apt)
            run_pkg_install "wine winetricks lutris mangohud gamemode vulkan-tools"
            ;;
        dnf)
            run_pkg_install "wine winetricks lutris mangohud gamemode vulkan-tools"
            ;;
        yum)
            show_msg "Em RHEL/CentOS, pacotes de jogos como Lutris/MangoHud/GameMode podem exigir EPEL, RPM Fusion ou repositórios equivalentes."
            run_pkg_install "wine winetricks lutris mangohud gamemode vulkan-tools"
            ;;
        pacman)
            run_pkg_install "wine winetricks umu-launcher protontricks gamescope goverlay lutris mangohud lib32-mangohud vulkan-tools alsa-plugins giflib glfw gst-plugins-base-libs lib32-alsa-plugins lib32-giflib lib32-gtk3 lib32-libjpeg-turbo lib32-libva lib32-mpg123 lib32-ocl-icd lib32-openal libjpeg-turbo libva libxslt mpg123 ocl-icd openal ttf-liberation wqy-zenhei" || return
            install_aur_package "heroic-games-launcher-bin" || return
            install_aur_package "faugus-launcher"
            ;;
        zypper)
            run_pkg_install "wine winetricks lutris mangohud gamemode vulkan-tools"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

install_steam() {
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        run_pkg_install "steam"
    else
        install_flatpak_app "com.valvesoftware.Steam"
    fi
}

install_octopi() {
    install_aur_package "octopi"
}

install_google_chrome() {
    install_aur_package "google-chrome"
}

install_anydesk() {
    install_aur_package "anydesk-bin"
}

install_curseforge() {
    install_aur_package "curseforge"
}

configure_curseforge_auth_handler() {
    local appimage_path
    local appimage_path_quoted

    appimage_path=$(whiptail --title "CurseForge Login" \
        --inputbox "Caminho do AppImage do CurseForge:" \
        12 90 "$HOME/Games/CurseForge/curseforge-latest-linux.appimage" \
        3>&1 1>&2 2>&3)

    [[ -z "$appimage_path" ]] && return

    appimage_path_quoted=$(printf '%q' "$appimage_path")

    run_cmd "mkdir -p \"\$HOME/.local/share/applications\" && printf '%s\n' '[Desktop Entry]' 'Name=CF Auth Handler' 'Exec=${appimage_path_quoted} %u' 'Type=Application' 'Terminal=false' 'MimeType=x-scheme-handler/cfauth;' > \"\$HOME/.local/share/applications/cfauth-handler.desktop\" && xdg-mime default cfauth-handler.desktop x-scheme-handler/cfauth && (update-desktop-database \"\$HOME/.local/share/applications\" 2>/dev/null || true)"
}

install_stremio() {
    install_flatpak_app "com.stremio.Stremio"
}

install_discord() {
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        run_pkg_install "discord"
    else
        install_flatpak_app "com.discordapp.Discord"
    fi
}

install_telegram() {
    case "$PKG_MANAGER" in
        dnf|yum)
            install_flatpak_app "org.telegram.desktop"
            ;;
        *)
            run_pkg_install "telegram-desktop"
            ;;
    esac
}

install_obs() {
    run_pkg_install "obs-studio"
}

install_prismlauncher_repo() {
    case "$PKG_MANAGER" in
        pacman)
            run_pkg_install "prismlauncher"
            ;;
        *)
            show_msg "PrismLauncher por repositório não é garantido em todas as distros.\n\nPara manter a instalação universal, use a opção PrismLauncher Flatpak."
            ;;
    esac
}

install_prismlauncher_flatpak() {
    install_flatpak_app "org.prismlauncher.PrismLauncher"
}

install_roblox_sober() {
    install_flatpak_app "org.vinegarhq.Sober"
}

install_vlc() {
    case "$PKG_MANAGER" in
        dnf|yum)
            install_flatpak_app "org.videolan.VLC"
            ;;
        *)
            run_pkg_install "vlc"
            ;;
    esac
}

install_filelight() {
    run_pkg_install "filelight"
}

install_hytale_flatpak_file() {
    install_local_flatpak_file "Hytale Flatpak" "$HOME/Downloads/nome-do-arquivo.flatpak"
}

install_parsec() {
    show_msg "Parsec no Linux funciona apenas como cliente.\n\nEle não funciona como Host no Linux."
    install_aur_package "parsec-bin"
}

install_r2modman_local_pkg() {
    local package_path
    local package_path_quoted

    if [[ "$PKG_MANAGER" != "pacman" ]]; then
        show_msg "Esta instalação foi cadastrada para distros baseadas em Arch."
        return 1
    fi

    package_path=$(whiptail --title "r2modman" \
        --inputbox "Informe o caminho do pacote .pacman baixado do GitHub:" \
        12 90 "$HOME/Downloads/r2modman-3.2.15.pacman" \
        3>&1 1>&2 2>&3)

    [[ -z "$package_path" ]] && return

    package_path_quoted=$(printf '%q' "$package_path")
    install_aur_package "http-parser" || return
    run_cmd "sudo pacman -U $package_path_quoted"
}

install_gwenview() {
    run_pkg_install "gwenview"
}

install_kde_partition_manager() {
    case "$PKG_MANAGER" in
        dnf|yum)
            run_pkg_install "kde-partitionmanager"
            ;;
        *)
            run_pkg_install "partitionmanager"
            ;;
    esac
}

install_protonup_qt_flatpak() {
    install_flatpak_app "net.davidotek.pupgui2"
}
