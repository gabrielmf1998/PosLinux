# shellcheck shell=bash
# Menus do TUI. Este módulo apenas conecta opções de interface às funções dos outros módulos.

# ==========================================================
# Menus
# ==========================================================

menu_system() {
    while true; do
        local option

        option=$(whiptail --title "Sistema" \
            --menu "Selecione uma opção:" \
            22 78 10 \
            "1" "Informações do sistema" \
            "2" "Atualizar sistema" \
            "3" "Habilitar SSH" \
            "4" "Habilitar RPM Fusion (Fedora)" \
            "0" "Voltar" \
            3>&1 1>&2 2>&3)

        case "$option" in
            1) show_system_info ;;
            2) update_system ;;
            3) enable_ssh_service ;;
            4) enable_fedora_rpmfusion ;;
            0|"") break ;;
        esac
    done
}

menu_flatpak() {
    while true; do
        local option

        option=$(whiptail --title "Flatpak" \
            --menu "Selecione uma opção:" \
            22 78 10 \
            "1" "Instalar Flatpak" \
            "2" "Adicionar Flathub" \
            "3" "Instalar apps Flatpak" \
            "0" "Voltar" \
            3>&1 1>&2 2>&3)

        case "$option" in
            1) install_flatpak ;;
            2) add_flathub ;;
            3) install_flatpak_apps ;;
            0|"") break ;;
        esac
    done
}

menu_aur_helpers() {
    while true; do
        local old_colors
        local option

        old_colors="$NEWT_COLORS"
        export NEWT_COLORS="${NEWT_COLORS/title=brightblue,black/title=red,black}"

        option=$(whiptail --title "ATENÇÃO: INSTALE SOMENTE 1" \
            --menu "Instale apenas um AUR helper para evitar conflitos de fluxo.\n\nSelecione o AUR helper:" \
            20 78 8 \
            "1" "Yay" \
            "2" "Paru" \
            "3" "Trizen" \
            "0" "Voltar" \
            3>&1 1>&2 2>&3)

        export NEWT_COLORS="$old_colors"

        case "$option" in
            1) install_aur_helper "yay" ;;
            2) install_aur_helper "paru" ;;
            3) install_aur_helper "trizen" ;;
            0|"") break ;;
        esac
    done
}

menu_gaming() {
    local choice
    local selected

    choice=$(whiptail --title "Recomendação Desenvolvedor" \
        --checklist "Selecione os programas e pacotes:" \
        25 100 16 \
        "base" "Base gaming: Lutris/Wine/MangoHud" OFF \
        "steam" "Steam" OFF \
        "protonup" "ProtonUp-Qt Flatpak" OFF \
        "octopi" "Octopi (AUR)" OFF \
        "chrome" "Google Chrome (AUR)" OFF \
        "anydesk" "AnyDesk (AUR)" OFF \
        "curseforge" "CurseForge (AUR)" OFF \
        "stremio" "Stremio Flatpak" OFF \
        "discord" "Discord" OFF \
        "telegram" "Telegram" OFF \
        "obs" "OBS Studio" OFF \
        "prism" "PrismLauncher" OFF \
        "prism-flatpak" "PrismLauncher Flatpak" OFF \
        "sober" "Roblox/Sober Flatpak" OFF \
        "vlc" "VLC" OFF \
        "filelight" "Filelight KDE" OFF \
        "hytale" "Hytale Flatpak local" OFF \
        "parsec" "Parsec (AUR - cliente)" OFF \
        "r2modman" "r2modman pacote local" OFF \
        "gwenview" "Gwenview" OFF \
        "partitionmanager" "KDE Partition Manager" OFF \
        3>&1 1>&2 2>&3)

    [[ -z "$choice" ]] && return

    choice=$(echo "$choice" | tr -d '"')

    for selected in $choice; do
        case "$selected" in
            base) install_gaming_base ;;
            steam) install_steam ;;
            protonup) install_protonup_qt_flatpak ;;
            octopi) install_octopi ;;
            chrome) install_google_chrome ;;
            anydesk) install_anydesk ;;
            curseforge) install_curseforge ;;
            stremio) install_stremio ;;
            discord) install_discord ;;
            telegram) install_telegram ;;
            obs) install_obs ;;
            prism) install_prismlauncher_repo ;;
            prism-flatpak) install_prismlauncher_flatpak ;;
            sober) install_roblox_sober ;;
            vlc) install_vlc ;;
            filelight) install_filelight ;;
            hytale) install_hytale_flatpak_file ;;
            parsec) install_parsec ;;
            r2modman) install_r2modman_local_pkg ;;
            gwenview) install_gwenview ;;
            partitionmanager) install_kde_partition_manager ;;
        esac
    done
}

menu_kernels() {
    show_danger_install_warning

    while true; do
        local option

        option=$(whiptail --title "Kernels" \
            --menu "Selecione uma opção:" \
            22 78 10 \
            "1" "Instalar kernel padrão + headers" \
            "2" "Instalar kernel LTS (Arch)" \
            "3" "Instalar kernel Zen (Arch)" \
            "4" "Instalar kernel Hardened (Arch)" \
            "5" "Listar kernels instalados" \
            "0" "Voltar" \
            3>&1 1>&2 2>&3)

        case "$option" in
            1) install_default_kernel_headers ;;
            2) install_arch_kernel "linux-lts" ;;
            3) install_arch_kernel "linux-zen" ;;
            4) install_arch_kernel "linux-hardened" ;;
            5) list_installed_kernels ;;
            0|"") break ;;
        esac
    done
}

menu_gpu_drivers() {
    show_danger_install_warning

    while true; do
        local option

        option=$(whiptail --title "Drivers GPU" \
            --menu "Selecione uma opção:" \
            22 78 10 \
            "1" "Ver GPUs e status dos drivers" \
            "2" "Instalar driver NVIDIA" \
            "3" "Instalar driver NVIDIA DKMS" \
            "4" "Instalar drivers Mesa AMD/Intel" \
            "5" "Instalar drivers legacy AMD/Intel" \
            "6" "Instalar kernel/headers padrão" \
            "0" "Voltar" \
            3>&1 1>&2 2>&3)

        case "$option" in
            1) show_gpu_driver_overview ;;
            2) install_nvidia_driver ;;
            3) install_nvidia_dkms_driver ;;
            4) install_mesa_gpu_drivers ;;
            5) install_legacy_amd_intel_drivers ;;
            6) install_default_kernel_headers ;;
            0|"") break ;;
        esac
    done
}

menu_programs() {
    while true; do
        local option

        option=$(whiptail --title "Programas" \
            --menu "Selecione uma seção:" \
            22 78 10 \
            "1" "Flatpak" \
            "2" "AUR Helpers" \
            "3" "Recomendação Desenvolvedor" \
            "0" "Voltar" \
            3>&1 1>&2 2>&3)

        case "$option" in
            1) menu_flatpak ;;
            2) menu_aur_helpers ;;
            3) menu_gaming ;;
            0|"") break ;;
        esac
    done
}

menu_firewall() {
    while true; do
        local option

        option=$(whiptail --title "Firewall" \
            --menu "Selecione uma opção:" \
            22 78 10 \
            "1" "Instalar firewall padrão" \
            "2" "Permitir SSH" \
            "3" "Ativar firewall" \
            "4" "Ver status" \
            "0" "Voltar" \
            3>&1 1>&2 2>&3)

        case "$option" in
            1) install_firewall ;;
            2) firewall_allow_ssh ;;
            3) enable_firewall ;;
            4) firewall_status ;;
            0|"") break ;;
        esac
    done
}

menu_dev() {
    install_dev_tools
}

menu_codecs() {
    install_codecs
}

menu_cleanup() {
    clean_system
}

menu_logs() {
    while true; do
        local option

        option=$(whiptail --title "Logs" \
            --menu "Selecione uma opção:" \
            22 78 10 \
            "1" "Ver log" \
            "2" "Limpar log" \
            "0" "Voltar" \
            3>&1 1>&2 2>&3)

        case "$option" in
            1) view_log ;;
            2) clear_log ;;
            0|"") break ;;
        esac
    done
}

main_menu() {
    while true; do
        local menu_header
        local option

        menu_header=$(build_main_menu_header)

        option=$(whiptail --title "$APP_NAME" \
            --menu "$menu_header" \
            34 100 12 \
            "1" "Sistema" \
            "2" "Programas" \
            "3" "Kernels" \
            "4" "Drivers GPU" \
            "5" "Firewall" \
            "6" "Ferramentas Dev" \
            "7" "Codecs" \
            "8" "Limpeza" \
            "9" "Logs" \
            "0" "Sair" \
            3>&1 1>&2 2>&3)

        case "$option" in
            1) menu_system ;;
            2) menu_programs ;;
            3) menu_kernels ;;
            4) menu_gpu_drivers ;;
            5) menu_firewall ;;
            6) menu_dev ;;
            7) menu_codecs ;;
            8) menu_cleanup ;;
            9) menu_logs ;;
            0|"") break ;;
        esac
    done
}
