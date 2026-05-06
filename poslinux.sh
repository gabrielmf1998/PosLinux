#!/usr/bin/env bash

set -o pipefail

APP_NAME="PosLinux"
LOG_FILE="$HOME/pos-instalacao-linux.log"

DISTRO_ID=""
DISTRO_ID_LIKE=""
DISTRO_NAME=""
PKG_MANAGER=""

# Paleta do whiptail/newt: visual escuro, discreto e com acento azul.
configure_tui_theme() {
    export NEWT_COLORS='
root=gray,black
border=brightblue,black
window=white,black
shadow=gray,black
title=brightblue,black
button=white,blue
actbutton=white,blue
compactbutton=white,black
checkbox=brightblue,black
actcheckbox=white,blue
entry=white,black
label=white,black
listbox=white,black
actlistbox=white,blue
sellistbox=white,blue
actsellistbox=white,blue
textbox=white,black
acttextbox=white,blue
helpline=gray,black
roottext=gray,black
emptyscale=gray,black
fullscale=white,blue
disentry=gray,black
'
}

# ==========================================================
# Core
# ==========================================================

require_root_tools() {
    if ! command -v whiptail >/dev/null 2>&1; then
        echo "Erro: whiptail não encontrado."
        echo "Instale com:"
        echo "Debian/Ubuntu: sudo apt install whiptail"
        echo "Fedora: sudo dnf install newt"
        echo "RHEL/CentOS: sudo dnf install newt ou sudo yum install newt"
        echo "Arch: sudo pacman -S libnewt"
        echo "openSUSE: sudo zypper install whiptail"
        exit 1
    fi
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
        DISTRO_NAME="${PRETTY_NAME:-unknown}"
    else
        DISTRO_ID="unknown"
        DISTRO_ID_LIKE=""
        DISTRO_NAME="unknown"
    fi

    case " $DISTRO_ID $DISTRO_ID_LIKE " in
        *" ubuntu "*|*" debian "*|*" linuxmint "*|*" pop "*)
            PKG_MANAGER="apt"
            ;;
        *" fedora "*|*" rhel "*|*" rocky "*|*" almalinux "*|*" centos "*|*" nobara "*)
            if command_exists dnf; then
                PKG_MANAGER="dnf"
            elif command_exists yum; then
                PKG_MANAGER="yum"
            else
                PKG_MANAGER="dnf"
            fi
            ;;
        *" arch "*|*" cachyos "*|*" manjaro "*|*" endeavouros "*|*" garuda "*|*" artix "*)
            PKG_MANAGER="pacman"
            ;;
        *" opensuse"*|*" suse "*|*" sles "*)
            PKG_MANAGER="zypper"
            ;;
        *)
            if command_exists apt; then
                PKG_MANAGER="apt"
            elif command_exists dnf; then
                PKG_MANAGER="dnf"
            elif command_exists yum; then
                PKG_MANAGER="yum"
            elif command_exists pacman; then
                PKG_MANAGER="pacman"
            elif command_exists zypper; then
                PKG_MANAGER="zypper"
            else
                PKG_MANAGER="unknown"
            fi
            ;;
    esac
}

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

show_msg() {
    whiptail --title "$APP_NAME" --msgbox "$1" 20 78
}

confirm_action() {
    whiptail --title "$APP_NAME" --yesno "$1" 15 78
}

run_cmd() {
    local cmd="$1"

    log_msg "Executando: $cmd"

    if ! whiptail --title "$APP_NAME" \
        --yesno "Executar o comando abaixo?\n\n$cmd" \
        18 78; then
        log_msg "Cancelado: $cmd"
        return 1
    fi

    bash -c "$cmd" 2>&1 | tee -a "$LOG_FILE"

    local exit_code="${PIPESTATUS[0]}"

    if [[ "$exit_code" -eq 0 ]]; then
        whiptail --title "$APP_NAME" --msgbox "Comando executado com sucesso." 10 60
    else
        whiptail --title "$APP_NAME" --msgbox "Erro ao executar comando. Verifique o log:\n\n$LOG_FILE" 12 70
    fi

    return "$exit_code"
}

run_cmd_show_output() {
    local cmd="$1"
    local title="${2:-Resultado do comando}"
    local output_file
    local exit_code

    output_file=$(mktemp) || {
        show_msg "Erro ao criar arquivo temporário para exibir a saída."
        return 1
    }

    log_msg "Executando: $cmd"

    if ! whiptail --title "$APP_NAME" \
        --yesno "Executar o comando abaixo?\n\n$cmd" \
        18 78; then
        log_msg "Cancelado: $cmd"
        rm -f "$output_file"
        return 1
    fi

    bash -c "$cmd" > "$output_file" 2>&1
    exit_code="$?"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Saída de: $cmd"
        cat "$output_file"
        echo
    } >> "$LOG_FILE"

    if [[ ! -s "$output_file" ]]; then
        printf 'Comando executado, mas não retornou saída.\n' > "$output_file"
    fi

    printf '\nCódigo de saída: %s\n' "$exit_code" >> "$output_file"
    whiptail --title "$title" --textbox "$output_file" 25 100

    rm -f "$output_file"
    return "$exit_code"
}

run_pkg_install() {
    local packages="$1"

    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt update && sudo apt install -y $packages"
            ;;
        dnf)
            run_cmd "sudo dnf install -y $packages"
            ;;
        yum)
            run_cmd "sudo yum install -y $packages"
            ;;
        pacman)
            run_cmd "sudo pacman -S --needed $packages"
            ;;
        zypper)
            run_cmd "sudo zypper install -y $packages"
            ;;
        *)
            show_msg "Gerenciador de pacotes não suportado para esta distro."
            ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

package_installed() {
    local package="$1"

    if command_exists pacman; then
        pacman -Q "$package" >/dev/null 2>&1
    elif command_exists dpkg-query; then
        dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"
    elif command_exists rpm; then
        rpm -q "$package" >/dev/null 2>&1
    else
        return 1
    fi
}

join_by() {
    local delimiter="$1"
    shift

    local output=""
    local item

    for item in "$@"; do
        if [[ -n "$output" ]]; then
            output+="$delimiter"
        fi

        output+="$item"
    done

    printf '%s' "$output"
}

truncate_text() {
    local text="$1"
    local max_length="$2"
    local cutoff

    if ((${#text} <= max_length)); then
        printf '%s' "$text"
        return
    fi

    cutoff=$((max_length - 3))
    printf '%s...' "${text:0:cutoff}"
}

get_warning_colors() {
    local colors="$NEWT_COLORS"

    colors="${colors/label=white,black/label=red,black}"
    colors="${colors/textbox=white,black/textbox=red,black}"
    colors="${colors/roottext=gray,black/roottext=red,black}"
    colors="${colors/title=brightblue,black/title=red,black}"
    colors="${colors/border=brightblue,black/border=red,black}"

    printf '%s' "$colors"
}

show_danger_install_warning() {
    local old_colors
    local warning_colors

    old_colors="$NEWT_COLORS"
    warning_colors="$(get_warning_colors)"
    export NEWT_COLORS="$warning_colors"

    whiptail --title "Nota" \
        --msgbox "Nota: Cuidado, não instale várias opções, e saiba exatamente o que está fazendo antes de realizar instalação, qualquer alteração nessa tela pode danificar o sistema.\n\nRecomendado sempre ter Secure-Boot desabilitado!" \
        14 90

    export NEWT_COLORS="$old_colors"
}

get_package_manager_summary() {
    local managers=()
    local aur_helpers=()
    local manager
    local summary

    for manager in apt dnf yum pacman zypper; do
        if command_exists "$manager"; then
            if [[ "$manager" == "$PKG_MANAGER" ]]; then
                managers+=("$manager (principal)")
            else
                managers+=("$manager")
            fi
        fi
    done

    if [[ "${#managers[@]}" -eq 0 && "$PKG_MANAGER" != "unknown" ]]; then
        managers+=("$PKG_MANAGER (detectado)")
    fi

    for manager in yay paru pikaur trizen aura; do
        if command_exists "$manager"; then
            aur_helpers+=("$manager")
        fi
    done

    summary=$(join_by ", " "${managers[@]}")
    [[ -n "$summary" ]] || summary="não detectado"

    if [[ "${#aur_helpers[@]}" -gt 0 ]]; then
        summary+=" | AUR: $(join_by ", " "${aur_helpers[@]}")"
    elif [[ "$PKG_MANAGER" == "pacman" ]]; then
        summary+=" | AUR: nenhum helper"
    fi

    printf '%s' "$summary"
}

get_extra_package_summary() {
    local extras=()
    local count

    if command_exists flatpak; then
        count=$(flatpak list --app 2>/dev/null | wc -l)
        count="${count//[[:space:]]/}"
        extras+=("Flatpak: ${count:-0} apps")
    fi

    if command_exists snap; then
        count=$(snap list 2>/dev/null | awk 'NR > 1 {total++} END {print total + 0}')
        extras+=("Snap: ${count:-0} snaps")
    fi

    if command_exists brew; then
        extras+=("Homebrew")
    fi

    if command_exists nix || command_exists nix-env; then
        extras+=("Nix")
    fi

    if command_exists appimagelauncherd; then
        extras+=("AppImageLauncher")
    fi

    if [[ "${#extras[@]}" -eq 0 ]]; then
        printf 'nenhum detectado'
        return
    fi

    join_by ", " "${extras[@]}"
}

get_cpu_info() {
    local model=""
    local cores=""

    if [[ -r /proc/cpuinfo ]]; then
        model=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)
    fi

    if command_exists nproc; then
        cores=$(nproc 2>/dev/null)
    fi

    if [[ -z "$cores" ]]; then
        cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null)
    fi

    [[ -n "$model" ]] || model="desconhecida"
    [[ -n "$cores" ]] || cores="?"

    printf '%s (%s threads)' "$model" "$cores"
}

get_ram_info() {
    if [[ ! -r /proc/meminfo ]]; then
        printf 'desconhecida'
        return
    fi

    awk '
        /^MemTotal:/ {total = $2}
        /^MemAvailable:/ {available = $2}
        END {
            if (total > 0 && available > 0) {
                printf "%.1f GiB total / %.1f GiB disp.", total / 1048576, available / 1048576
            } else if (total > 0) {
                printf "%.1f GiB total", total / 1048576
            } else {
                printf "desconhecida"
            }
        }
    ' /proc/meminfo
}

format_date_value() {
    local raw_date="$1"
    local formatted=""

    formatted=$(date -d "$raw_date" '+%Y-%m-%d %H:%M' 2>/dev/null)

    if [[ -n "$formatted" ]]; then
        printf '%s' "$formatted"
    else
        printf '%s' "$raw_date"
    fi
}

get_install_date() {
    local created=""
    local first_pacman_date=""
    local path

    created=$(stat -c %w / 2>/dev/null)
    if [[ -n "$created" && "$created" != "-" ]]; then
        format_date_value "$created"
        return
    fi

    if [[ -r /var/log/pacman.log ]]; then
        first_pacman_date=$(awk -F'[][]' 'NR == 1 {print $2; exit}' /var/log/pacman.log)
        if [[ -n "$first_pacman_date" ]]; then
            printf '%s' "$first_pacman_date"
            return
        fi
    fi

    for path in /var/log/installer/syslog /var/log/anaconda/anaconda.log /root/install.log; do
        if [[ -r "$path" ]]; then
            created=$(stat -c %y "$path" 2>/dev/null)
            if [[ -n "$created" ]]; then
                format_date_value "$created"
                return
            fi
        fi
    done

    printf 'desconhecida'
}

get_uptime_short() {
    local uptime_raw=""
    local uptime_seconds
    local days
    local hours
    local minutes

    if [[ ! -r /proc/uptime ]]; then
        printf 'desconhecido'
        return
    fi

    read -r uptime_raw _ < /proc/uptime
    uptime_seconds="${uptime_raw%.*}"
    days=$((uptime_seconds / 86400))
    hours=$(((uptime_seconds % 86400) / 3600))
    minutes=$(((uptime_seconds % 3600) / 60))

    if ((days > 0)); then
        printf '%sd %sh' "$days" "$hours"
    elif ((hours > 0)); then
        printf '%sh %sm' "$hours" "$minutes"
    else
        printf '%sm' "$minutes"
    fi
}

get_boot_info() {
    local startup_line=""
    local startup_time=""
    local uptime

    if command_exists systemd-analyze; then
        startup_line=$(systemd-analyze --no-pager 2>/dev/null | awk 'NR == 1 {print; exit}')

        if [[ "$startup_line" == *"= "* ]]; then
            startup_time="${startup_line##*= }"
            startup_time="${startup_time%% graphical.target*}"
            startup_time="${startup_time%% multi-user.target*}"
        elif [[ "$startup_line" == *" in "* ]]; then
            startup_time="${startup_line#* in }"
            startup_time="${startup_time%.}"
        fi
    fi

    uptime=$(get_uptime_short)

    if [[ -n "$startup_time" ]]; then
        printf '%s | ligado há %s' "$startup_time" "$uptime"
    else
        printf 'ligado há %s' "$uptime"
    fi
}

get_gpu_dkms_status() {
    local driver="$1"
    local modules="$2"
    local dkms_status=""

    if command_exists dkms; then
        dkms_status=$(dkms status 2>/dev/null)

        if [[ -n "$driver" && "$dkms_status" == *"$driver"* ]]; then
            printf 'sim'
            return
        fi

        if [[ "$driver" == nvidia* || "$modules" == *nvidia* ]]; then
            if [[ "$dkms_status" == *nvidia* ]]; then
                printf 'sim'
                return
            fi
        fi

        if [[ "$driver" == amdgpu* || "$modules" == *amdgpu* ]]; then
            if [[ "$dkms_status" == *amdgpu* ]]; then
                printf 'sim'
                return
            fi
        fi
    fi

    if [[ "$driver" == nvidia* || "$modules" == *nvidia* ]]; then
        if package_installed "nvidia-dkms"; then
            printf 'sim'
            return
        fi
    fi

    if [[ "$driver" == amdgpu* || "$modules" == *amdgpu* ]]; then
        if package_installed "amdgpu-dkms" || package_installed "amdgpu-pro-dkms"; then
            printf 'sim'
            return
        fi
    fi

    printf 'não'
}

detect_gpu_entries() {
    lspci -nnk 2>/dev/null | awk '
        /^[[:xdigit:]:.]+[[:space:]]/ && $0 !~ /(VGA compatible controller|3D controller|Display controller)/ {
            if (gpu != "") {
                print gpu "|" driver "|" modules
                gpu = ""
                driver = ""
                modules = ""
            }
            next
        }

        /(VGA compatible controller|3D controller|Display controller)/ {
            if (gpu != "") {
                print gpu "|" driver "|" modules
            }

            gpu = $0
            sub(/^[[:xdigit:]:.]+[[:space:]]+/, "", gpu)
            sub(/^(VGA compatible controller|3D controller|Display controller)( \[[^]]+\])?:[[:space:]]*/, "", gpu)
            gsub(/[[:space:]]+\[[[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]]:[[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]]\]/, "", gpu)
            sub(/[[:space:]]+\(rev [^)]+\)$/, "", gpu)
            driver = ""
            modules = ""
            next
        }

        /Kernel driver in use:/ && gpu != "" {
            driver = $0
            sub(/.*Kernel driver in use:[[:space:]]*/, "", driver)
            next
        }

        /Kernel modules:/ && gpu != "" {
            modules = $0
            sub(/.*Kernel modules:[[:space:]]*/, "", modules)
            next
        }

        END {
            if (gpu != "") {
                print gpu "|" driver "|" modules
            }
        }
    '
}

build_gpu_overview() {
    local gpu=""
    local driver=""
    local modules=""
    local gpu_name=""
    local driver_name=""
    local gpu_count=0
    local dkms_status=""
    local driver_status=""

    if command_exists lspci; then
        while IFS='|' read -r gpu driver modules; do
            [[ -n "$gpu" ]] || continue

            gpu_count=$((gpu_count + 1))
            gpu_name=$(truncate_text "$gpu" 36)

            if [[ -n "$driver" ]]; then
                driver_name=$(truncate_text "$driver" 14)
                driver_status="driver: $driver_name"
            else
                driver_status="driver: não instalado"
            fi

            dkms_status=$(get_gpu_dkms_status "$driver" "$modules")
            printf 'GPU %s: %s | %s | DKMS: %s\n' "$gpu_count" "$gpu_name" "$driver_status" "$dkms_status"
        done < <(detect_gpu_entries)

        if ((gpu_count == 0)); then
            printf 'GPU: não detectada\n'
        fi

        return
    fi

    if compgen -G "/sys/class/drm/card*/device/uevent" >/dev/null; then
        printf 'GPU 1: detectada | driver: instale pciutils para verificar | DKMS: não\n'
    else
        printf 'GPU: não detectada\n'
    fi
}

get_gpu_info() {
    build_gpu_overview | head -n 1
}

get_ssh_status() {
    local service
    local enabled=""
    local active=""
    local unit_found="false"

    if command_exists systemctl; then
        for service in ssh sshd; do
            if systemctl list-unit-files "${service}.service" --no-legend 2>/dev/null | grep -q "${service}.service"; then
                unit_found="true"
                enabled=$(systemctl is-enabled "$service" 2>/dev/null)
                active=$(systemctl is-active "$service" 2>/dev/null)

                if [[ "$enabled" == "enabled" ]]; then
                    if [[ "$active" == "active" ]]; then
                        printf 'sim (ativo)'
                    else
                        printf 'sim (inativo)'
                    fi
                    return
                fi

                if [[ "$active" == "active" ]]; then
                    printf 'ativo, não habilitado'
                    return
                fi
            fi
        done

        if [[ "$unit_found" == "true" ]]; then
            printf 'não'
            return
        fi
    fi

    if command_exists sshd; then
        printf 'instalado, serviço não detectado'
    else
        printf 'não instalado'
    fi
}

get_uefi_status() {
    if [[ -d /sys/firmware/efi ]]; then
        printf 'sim'
    else
        printf 'não'
    fi
}

get_secure_boot_status() {
    local secure_boot_var=""
    local status=""
    local value_hex=""

    if [[ ! -d /sys/firmware/efi ]]; then
        printf 'não (Legacy/BIOS)'
        return
    fi

    if command_exists mokutil; then
        status=$(mokutil --sb-state 2>/dev/null)

        case "$status" in
            *enabled*|*Enabled*)
                printf 'sim (recomendado: não)'
                return
                ;;
            *disabled*|*Disabled*)
                printf 'não'
                return
                ;;
        esac
    fi

    secure_boot_var=$(find /sys/firmware/efi/efivars -maxdepth 1 -name 'SecureBoot-*' -print -quit 2>/dev/null)

    if [[ -r "$secure_boot_var" ]]; then
        value_hex=$(od -An -tx1 -j4 -N1 "$secure_boot_var" 2>/dev/null | tr -d '[:space:]')

        if [[ "$value_hex" == "01" ]]; then
            printf 'sim (recomendado: não)'
        elif [[ "$value_hex" == "00" ]]; then
            printf 'não'
        else
            printf 'desconhecido'
        fi
    else
        printf 'desconhecido'
    fi
}

get_ipv4_address() {
    local ip_address=""

    if command_exists ip; then
        ip_address=$(ip -o -4 addr show scope global 2>/dev/null | awk '{split($4, address, "/"); print address[1]; exit}')
    fi

    if [[ -z "$ip_address" ]] && command_exists hostname; then
        ip_address=$(hostname -I 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+\./) {print $i; exit}}')
    fi

    [[ -n "$ip_address" ]] || ip_address="não encontrado"
    printf '%s' "$ip_address"
}

get_ipv6_address() {
    local ip_address=""

    if command_exists ip; then
        ip_address=$(ip -o -6 addr show scope link 2>/dev/null | awk '{split($4, address, "/"); if (address[1] ~ /^fe80:/) {print address[1]; exit}}')
    fi

    if [[ -z "$ip_address" ]] && command_exists hostname; then
        ip_address=$(hostname -I 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^fe80:/) {print $i; exit}}')
    fi

    [[ -n "$ip_address" ]] || ip_address="não encontrado"
    printf '%s' "$ip_address"
}

build_system_overview() {
    local package_managers
    local extras
    local gpu_overview
    local cpu
    local boot

    package_managers=$(truncate_text "$(get_package_manager_summary)" 82)
    extras=$(truncate_text "$(get_extra_package_summary)" 82)
    gpu_overview=$(build_gpu_overview)
    cpu=$(truncate_text "$(get_cpu_info)" 82)
    boot=$(truncate_text "$(get_boot_info)" 82)

    printf 'Distro detectada: %s\n' "$DISTRO_NAME"
    printf 'Gerenciadores: %s\n' "$package_managers"
    printf 'Extras: %s\n' "$extras"
    printf 'Kernel: %s\n' "$(uname -r)"
    printf '%s\n' "$gpu_overview"
    printf 'CPU: %s\n' "$cpu"
    printf 'RAM: %s\n' "$(get_ram_info)"
    printf 'Instalação do sistema: %s\n' "$(get_install_date)"
    printf 'Boot: %s\n' "$boot"
    printf 'SSH habilitado: %s\n' "$(get_ssh_status)"
    printf 'UEFI habilitada: %s\n' "$(get_uefi_status)"
    printf 'Secure Boot: %s\n' "$(get_secure_boot_status)"
    printf 'IPv4: %s\n' "$(get_ipv4_address)"
    printf 'IPv6: %s\n' "$(get_ipv6_address)"
}

build_main_menu_header() {
    printf '%s\n\nSelecione uma categoria:' "$(build_system_overview)"
}

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

# ==========================================================
# Firewall
# ==========================================================

install_firewall() {
    case "$PKG_MANAGER" in
        apt|pacman)
            run_pkg_install "ufw"
            ;;
        dnf|yum|zypper)
            run_pkg_install "firewalld"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

enable_firewall() {
    case "$PKG_MANAGER" in
        apt|pacman)
            run_cmd "sudo ufw enable"
            ;;
        dnf|yum|zypper)
            run_cmd "sudo systemctl enable --now firewalld"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

firewall_allow_ssh() {
    case "$PKG_MANAGER" in
        apt|pacman)
            run_cmd "sudo ufw allow ssh"
            ;;
        dnf|yum|zypper)
            run_cmd "sudo firewall-cmd --permanent --add-service=ssh && sudo firewall-cmd --reload"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

firewall_status() {
    case "$PKG_MANAGER" in
        apt|pacman)
            run_cmd_show_output "sudo ufw status verbose" "Status do Firewall"
            ;;
        dnf|yum|zypper)
            run_cmd_show_output "sudo firewall-cmd --state; echo; sudo firewall-cmd --list-all" "Status do Firewall"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

# ==========================================================
# Ferramentas Dev
# ==========================================================

install_dev_tools() {
    local choice

    choice=$(whiptail --title "Ferramentas Dev" \
        --checklist "Selecione as ferramentas:" \
        22 78 10 \
        "git" "Git" ON \
        "docker" "Docker" OFF \
        "nodejs" "Node.js" OFF \
        "python" "Python/pip/venv" ON \
        "vscode" "Visual Studio Code Flatpak" OFF \
        3>&1 1>&2 2>&3)

    [[ -z "$choice" ]] && return

    if echo "$choice" | grep -q "git"; then
        run_pkg_install "git"
    fi

    if echo "$choice" | grep -q "docker"; then
        install_docker_basic
    fi

    if echo "$choice" | grep -q "nodejs"; then
        install_nodejs
    fi

    if echo "$choice" | grep -q "python"; then
        install_python_tools
    fi

    if echo "$choice" | grep -q "vscode"; then
        install_flatpak_app "com.visualstudio.code"
    fi
}

install_python_tools() {
    case "$PKG_MANAGER" in
        apt)
            run_pkg_install "python3 python3-pip python3-venv"
            ;;
        dnf|yum)
            run_pkg_install "python3 python3-pip"
            ;;
        pacman)
            run_pkg_install "python python-pip"
            ;;
        zypper)
            run_pkg_install "python3 python3-pip"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

install_nodejs() {
    case "$PKG_MANAGER" in
        apt)
            run_pkg_install "nodejs npm"
            ;;
        dnf|yum)
            run_pkg_install "nodejs npm"
            ;;
        pacman)
            run_pkg_install "nodejs npm"
            ;;
        zypper)
            run_pkg_install "nodejs npm"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

install_docker_basic() {
    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt update && if apt-cache show docker-compose-v2 >/dev/null 2>&1; then sudo apt install -y docker.io docker-compose-v2; elif apt-cache show docker-compose >/dev/null 2>&1; then sudo apt install -y docker.io docker-compose; else sudo apt install -y docker.io; fi" || return
            ;;
        dnf)
            run_pkg_install "moby-engine docker-compose" || return
            ;;
        yum)
            show_msg "Em RHEL/CentOS antigos, Docker/Compose pode exigir repositórios extras como EPEL/CRB conforme a versão."
            run_pkg_install "moby-engine docker-compose" || return
            ;;
        pacman)
            run_pkg_install "docker docker-compose" || return
            ;;
        zypper)
            run_cmd "sudo zypper install -y docker docker-compose || { echo 'docker-compose não disponível nos repositórios desta versão. Tentando instalar somente docker.'; sudo zypper install -y docker; }" || return
            ;;
        *)
            show_msg "Distro não suportada."
            return
            ;;
    esac

    run_cmd "sudo systemctl enable --now docker" || return
    run_cmd "sudo usermod -aG docker $USER"
    show_msg "Docker instalado. Faça logout/login para aplicar o grupo docker ao usuário."
}

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

install_flatpak_app() {
    local app_id="$1"

    if ! command_exists flatpak; then
        show_msg "Flatpak não está instalado.\n\nInstale em:\nProgramas > Flatpak > Instalar Flatpak"
        return 1
    fi

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
        dnf|yum)
            show_msg "Em Fedora/RHEL/CentOS, o driver NVIDIA normalmente exige repositórios externos compatíveis, como RPM Fusion ou ELRepo.\n\nDepois de habilitar o repositório correto para sua distro, instale akmod-nvidia/kmod-nvidia conforme a documentação."
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
        dnf|yum)
            show_msg "Em Fedora/RHEL/CentOS, use akmod-nvidia ou kmod-nvidia via repositório compatível, como RPM Fusion ou ELRepo.\n\nNão há comando DKMS NVIDIA universal seguro nos repositórios padrão."
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
            run_pkg_install "mesa-dri-drivers mesa-vulkan-drivers mesa-libGL"
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
    run_pkg_install "telegram-desktop"
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
    run_pkg_install "vlc"
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
    run_pkg_install "partitionmanager"
}

install_protonup_qt_flatpak() {
    install_flatpak_app "net.davidotek.pupgui2"
}

# ==========================================================
# Codecs
# ==========================================================

install_codecs() {
    local rpm_manager="$PKG_MANAGER"

    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt update && if apt-cache show ubuntu-restricted-extras >/dev/null 2>&1; then sudo apt install -y ubuntu-restricted-extras ffmpeg; else sudo apt install -y ffmpeg gstreamer1.0-libav gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly; fi"
            ;;
        dnf|yum)
            if run_cmd "sudo $rpm_manager install -y ffmpeg-free gstreamer1-plugins-good gstreamer1-plugins-good-extras gstreamer1-plugins-bad-free gstreamer1-plugins-bad-free-extras || { echo 'Alguns pacotes extras de codec não estão disponíveis nesta versão. Tentando conjunto básico.'; sudo $rpm_manager install -y ffmpeg-free gstreamer1-plugins-good gstreamer1-plugins-bad-free; }"; then
                show_msg "Codecs livres instalados quando disponíveis.\n\nCodecs completos em Fedora/RHEL/CentOS podem exigir RPM Fusion ou repositório equivalente."
            fi
            ;;
        pacman)
            run_pkg_install "ffmpeg gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly"
            ;;
        zypper)
            if run_cmd "sudo zypper install -y ffmpeg gstreamer-plugins-good gstreamer-plugins-bad gstreamer-plugins-ugly || { echo 'Alguns pacotes extras de codec não estão disponíveis nesta versão. Tentando conjunto básico.'; sudo zypper install -y ffmpeg gstreamer-plugins-good; }"; then
                show_msg "Codecs livres instalados quando disponíveis.\n\nCodecs completos no openSUSE podem exigir o repositório Packman, conforme sua versão."
            fi
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

# ==========================================================
# Limpeza
# ==========================================================

clean_system() {
    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt autoremove -y && sudo apt autoclean"
            ;;
        dnf)
            run_cmd "sudo dnf autoremove -y && sudo dnf clean all"
            ;;
        yum)
            run_cmd "sudo yum clean all"
            ;;
        pacman)
            run_cmd "sudo pacman -Sc"
            ;;
        zypper)
            run_cmd "sudo zypper clean --all"
            ;;
        *)
            show_msg "Gerenciador de pacotes não suportado."
            ;;
    esac
}

# ==========================================================
# Logs
# ==========================================================

view_log() {
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "Log ainda não existe." > "$LOG_FILE"
    fi

    whiptail --title "Log de Execução" --textbox "$LOG_FILE" 25 90
}

clear_log() {
    if confirm_action "Deseja limpar o log?\n\n$LOG_FILE"; then
        : > "$LOG_FILE"
        show_msg "Log limpo."
    fi
}

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
            "0" "Voltar" \
            3>&1 1>&2 2>&3)

        case "$option" in
            1) show_system_info ;;
            2) update_system ;;
            3) enable_ssh_service ;;
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

# ==========================================================
# Bootstrap
# ==========================================================

main() {
    require_root_tools
    configure_tui_theme
    detect_distro

    log_msg "Aplicação iniciada"
    log_msg "Distro: $DISTRO_NAME"
    log_msg "Gerenciador: $PKG_MANAGER"

    main_menu

    log_msg "Aplicação encerrada"
    clear
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi
