# shellcheck shell=bash
# AUR helpers, kernels e drivers GPU. Área sensível: comandos variam por família de distro.

# ==========================================================
# AUR, kernels e drivers
# ==========================================================

install_aur_helper() {
    local helper="$1"

    if [[ "$PKG_MANAGER" != "pacman" ]]; then
        show_msg "AUR helpers são suportados apenas em distros baseadas em Arch."
        return
    fi

    if command_exists "$helper"; then
        show_msg "$helper já está instalado."
        return
    fi

    run_cmd "sudo pacman -S --needed base-devel git && build_dir=\$(mktemp -d) && git clone https://aur.archlinux.org/${helper}.git \"\$build_dir/${helper}\" && cd \"\$build_dir/${helper}\" && makepkg -si --noconfirm"
}

get_available_aur_helper() {
    local helper

    for helper in yay paru trizen; do
        if command_exists "$helper"; then
            printf '%s' "$helper"
            return 0
        fi
    done

    return 1
}

install_aur_package() {
    local package="$1"
    local helper=""

    if [[ "$PKG_MANAGER" != "pacman" ]]; then
        show_msg "Este pacote usa AUR e só é suportado em distros baseadas em Arch."
        return 1
    fi

    if ! helper=$(get_available_aur_helper); then
        show_msg "Nenhum AUR helper encontrado.\n\nInstale Yay, Paru ou Trizen em:\nProgramas > AUR Helpers"
        return 1
    fi

    run_cmd "$helper -S --needed $package"
}

ensure_flathub_remote() {
    if flatpak remotes --columns=name 2>/dev/null | grep -qx "flathub"; then
        return 0
    fi

    run_cmd "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
}

install_flatpak_app() {
    local app_id="$1"

    if ! command_exists flatpak; then
        if confirm_action "Flatpak não está instalado.\n\nDeseja instalar Flatpak agora?"; then
            install_flatpak || return 1
        else
            show_msg "Flatpak é necessário para instalar:\n$app_id"
            return 1
        fi
    fi

    ensure_flathub_remote || return 1
    run_cmd "flatpak install -y flathub $app_id"
}

install_local_flatpak_file() {
    local title="$1"
    local default_path="$2"
    local flatpak_file
    local flatpak_file_quoted

    if ! command_exists flatpak; then
        show_msg "Flatpak não está instalado.\n\nInstale em:\nProgramas > Flatpak > Instalar Flatpak"
        return 1
    fi

    flatpak_file=$(whiptail --title "$title" \
        --inputbox "Informe o caminho do arquivo .flatpak:" \
        12 90 "$default_path" \
        3>&1 1>&2 2>&3)

    [[ -z "$flatpak_file" ]] && return

    flatpak_file_quoted=$(printf '%q' "$flatpak_file")
    run_cmd "flatpak install -y $flatpak_file_quoted"
}

install_default_kernel_headers() {
    case "$PKG_MANAGER" in
        apt)
            if [[ "$DISTRO_ID" == "debian" ]]; then
                run_pkg_install "linux-image-amd64 linux-headers-amd64"
            else
                run_pkg_install "linux-generic linux-headers-generic"
            fi
            ;;
        dnf|yum)
            run_pkg_install "kernel kernel-devel kernel-headers"
            ;;
        pacman)
            run_pkg_install "linux linux-headers"
            ;;
        zypper)
            run_pkg_install "kernel-default kernel-default-devel"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

install_arch_kernel() {
    local kernel="$1"

    if [[ "$PKG_MANAGER" != "pacman" ]]; then
        show_msg "Esta opção é específica para distros baseadas em Arch."
        return
    fi

    run_pkg_install "$kernel ${kernel}-headers"
}

get_arch_current_kernel_headers() {
    local kernel_release

    kernel_release=$(uname -r)

    case "$kernel_release" in
        *zen*)
            printf 'linux-zen-headers'
            ;;
        *lts*)
            printf 'linux-lts-headers'
            ;;
        *hardened*)
            printf 'linux-hardened-headers'
            ;;
        *)
            printf 'linux-headers'
            ;;
    esac
}

list_installed_kernels() {
    local cmd

    case "$PKG_MANAGER" in
        apt)
            cmd="(dpkg-query -W -f='\${binary:Package} \${Version}\n' 'linux-image*' 'linux-headers*' 2>/dev/null || true); echo; echo '/boot:'; ls /boot | grep -E 'vmlinuz|initramfs' || true"
            ;;
        dnf|yum|zypper)
            cmd="(rpm -qa 'kernel*' | sort || true); echo; echo '/boot:'; ls /boot | grep -E 'vmlinuz|initramfs' || true"
            ;;
        pacman)
            cmd="(pacman -Q | awk '/^linux/ {print}' || true); echo; echo '/boot:'; ls /boot | grep -E 'vmlinuz|initramfs' || true"
            ;;
        *)
            cmd="uname -r; echo; echo '/boot:'; ls /boot | grep -E 'vmlinuz|initramfs' || true"
            ;;
    esac

    run_cmd_show_output "$cmd" "Kernels Instalados"
}

show_gpu_driver_overview() {
    whiptail --title "Drivers GPU" --msgbox "$(build_gpu_overview)" 18 100
}

install_nvidia_driver() {
    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt update && sudo apt install -y ubuntu-drivers-common && sudo ubuntu-drivers autoinstall"
            ;;
        dnf)
            if is_fedora_like; then
                enable_fedora_rpmfusion || return
                if run_cmd "sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda && sudo akmods --force"; then
                    show_msg "Driver NVIDIA Fedora instalado via RPM Fusion.\n\nAguarde a compilação do akmod terminar e reinicie o sistema.\n\nSecure Boot deve estar desabilitado ou o módulo precisa ser assinado manualmente."
                fi
            else
                show_msg "Em RHEL/Rocky/Alma/CentOS, o driver NVIDIA normalmente exige repositórios externos compatíveis, como ELRepo ou RPM Fusion para EL.\n\nNão há comando seguro universal para esta família."
            fi
            ;;
        yum)
            show_msg "Em RHEL/CentOS antigos, o driver NVIDIA normalmente exige repositórios externos compatíveis, como ELRepo.\n\nNão há comando seguro universal para esta família."
            ;;
        pacman)
            run_pkg_install "nvidia nvidia-utils nvidia-settings"
            ;;
        zypper)
            show_msg "No openSUSE, o driver NVIDIA normalmente exige o repositório oficial da NVIDIA para sua versão."
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

install_nvidia_dkms_driver() {
    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt update && sudo apt install -y dkms ubuntu-drivers-common && sudo ubuntu-drivers autoinstall"
            ;;
        dnf)
            if is_fedora_like; then
                show_msg "No Fedora, o caminho recomendado é AKMOD via RPM Fusion, não DKMS puro.\n\nO script vai instalar akmod-nvidia."
                install_nvidia_driver
            else
                show_msg "Em RHEL/Rocky/Alma/CentOS, use akmod-nvidia/kmod-nvidia via repositório compatível.\n\nNão há comando DKMS NVIDIA universal seguro nos repositórios padrão."
            fi
            ;;
        yum)
            show_msg "Em RHEL/CentOS antigos, use kmod-nvidia/akmod-nvidia via repositório compatível, como ELRepo.\n\nNão há comando DKMS NVIDIA universal seguro nos repositórios padrão."
            ;;
        pacman)
            run_pkg_install "dkms nvidia-dkms nvidia-utils nvidia-settings $(get_arch_current_kernel_headers)"
            ;;
        zypper)
            show_msg "No openSUSE, confirme o repositório NVIDIA compatível antes de instalar o driver DKMS."
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

install_mesa_gpu_drivers() {
    case "$PKG_MANAGER" in
        apt)
            run_pkg_install "mesa-vulkan-drivers mesa-va-drivers mesa-vdpau-drivers"
            ;;
        dnf|yum)
            run_pkg_install "mesa-dri-drivers mesa-vulkan-drivers mesa-libGL mesa-va-drivers mesa-vdpau-drivers vulkan-loader"
            ;;
        pacman)
            run_pkg_install "mesa vulkan-radeon vulkan-intel libva-mesa-driver mesa-vdpau"
            ;;
        zypper)
            run_pkg_install "Mesa Mesa-dri Mesa-libGL1 libvulkan1"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

install_legacy_amd_intel_drivers() {
    if ! confirm_action "Drivers legacy AMD/Intel são indicados apenas para GPUs antigas.\n\nEm algumas distros, eles podem substituir ou conflitar com drivers Mesa modernos.\n\nEm máquinas modernas, prefira os drivers Mesa normais.\n\nDeseja continuar?"; then
        return
    fi

    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt update && if apt-cache show libgl1-amber-dri >/dev/null 2>&1; then sudo apt install -y libgl1-amber-dri; else echo 'Pacote libgl1-amber-dri não disponível nesta versão da distro.'; exit 1; fi"
            ;;
        dnf|yum)
            show_msg "Fedora/RHEL geralmente usam mesa-dri-drivers para AMD/Intel.\n\nNão há instalação legacy universal segura nos repositórios padrão detectados por este script."
            ;;
        pacman)
            run_cmd "sudo pacman -S --needed mesa-amber"
            ;;
        zypper)
            show_msg "openSUSE geralmente usa Mesa-dri para AMD/Intel.\n\nNão há instalação legacy universal segura nos repositórios padrão detectados por este script."
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}
