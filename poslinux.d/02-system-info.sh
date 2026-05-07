# shellcheck shell=bash
# Coleta e formatação dos dados exibidos no topo do TUI.

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
