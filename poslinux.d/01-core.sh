# shellcheck shell=bash
# shellcheck disable=SC2034
# Núcleo compartilhado: detecção de distro, execução de comandos, mensagens e helpers genéricos.

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

ensure_log_dir() {
    if mkdir -p "$LOG_DIR" 2>/dev/null; then
        return 0
    fi

    LOG_DIR="${TMPDIR:-/tmp}/poslinux-${RUN_USER:-user}/logs"
    LOG_FILE="$LOG_DIR/poslinux.log"
    mkdir -p "$LOG_DIR" 2>/dev/null
}

log_msg() {
    ensure_log_dir || return 1
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
