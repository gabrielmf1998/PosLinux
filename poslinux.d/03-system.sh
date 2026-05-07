# shellcheck shell=bash
# Ações do menu Sistema: informações, atualização completa e SSH.

# ==========================================================
# Sistema
# ==========================================================

show_system_info() {
    local info

    info="$(build_system_overview)

ID: $DISTRO_ID
Arquitetura: $(uname -m)
Sessão: ${XDG_SESSION_TYPE:-desconhecida}
Desktop: ${XDG_CURRENT_DESKTOP:-desconhecido}
Shell: $SHELL
Usuário: $USER
Log: $LOG_FILE
"

    whiptail --title "Informações do Sistema" --msgbox "$info" 28 100
}

update_system() {
    local aur_helper=""

    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt update && sudo apt full-upgrade -y" || return
            ;;
        dnf)
            run_cmd "sudo dnf upgrade --refresh -y" || return
            ;;
        yum)
            run_cmd "sudo yum update -y" || return
            ;;
        pacman)
            run_cmd "sudo pacman -Syu" || return
            ;;
        zypper)
            if [[ "$DISTRO_ID" == "opensuse-tumbleweed" || "$DISTRO_NAME" == *"Tumbleweed"* ]]; then
                run_cmd "sudo zypper refresh && sudo zypper dup -y" || return
            else
                run_cmd "sudo zypper refresh && sudo zypper update -y" || return
            fi
            ;;
        *)
            show_msg "Gerenciador de pacotes não suportado."
            return
            ;;
    esac

    if [[ "$PKG_MANAGER" == "pacman" ]] && aur_helper=$(get_available_aur_helper); then
        run_cmd "$aur_helper -Syu"
    fi

    if command_exists flatpak; then
        run_cmd "flatpak update -y"
    fi

    if command_exists snap; then
        run_cmd "sudo snap refresh"
    fi

    if command_exists dkms; then
        run_cmd "sudo dkms autoinstall"
    fi

    if command_exists fwupdmgr; then
        run_cmd "sudo fwupdmgr --force refresh && sudo fwupdmgr --assume-yes update"
    fi

    show_msg "Atualização concluída.\n\nPacotes, kernels e drivers instalados via repositórios foram atualizados pelo gerenciador da distro.\n\nFlatpak, Snap, AUR, DKMS e firmware também foram atualizados quando detectados.\n\nDrivers instalados manualmente fora dos repositórios precisam ser atualizados manualmente."
}

is_fedora_like() {
    case " $DISTRO_ID $DISTRO_ID_LIKE " in
        *" fedora "*|*" nobara "*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

enable_fedora_rpmfusion() {
    if ! is_fedora_like; then
        show_msg "RPM Fusion é uma opção específica para Fedora/Nobara.\n\nEsta distro detectada foi:\n$DISTRO_NAME"
        return 1
    fi

    if package_installed "rpmfusion-free-release" && package_installed "rpmfusion-nonfree-release"; then
        show_msg "RPM Fusion Free e Nonfree já parecem estar instalados."
        return 0
    fi

    if ! confirm_action "Deseja habilitar RPM Fusion Free e Nonfree?\n\nIsso adiciona repositórios de terceiros usados no Fedora para codecs, drivers NVIDIA e alguns pacotes que o Fedora não distribui oficialmente."; then
        return 1
    fi

    run_cmd "sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm && sudo dnf group upgrade -y core"
}

enable_ssh_service() {
    local service=""

    case "$PKG_MANAGER" in
        apt)
            run_pkg_install "openssh-server" || return
            service="ssh"
            ;;
        dnf|yum)
            run_pkg_install "openssh-server" || return
            service="sshd"
            ;;
        pacman)
            run_pkg_install "openssh" || return
            service="sshd"
            ;;
        zypper)
            run_pkg_install "openssh" || return
            service="sshd"
            ;;
        *)
            show_msg "Distro não suportada."
            return
            ;;
    esac

    if ! command_exists systemctl; then
        show_msg "systemctl não encontrado.\n\nInstale e habilite o serviço SSH manualmente para esta distro."
        return 1
    fi

    run_cmd "sudo systemctl enable --now $service"
}
