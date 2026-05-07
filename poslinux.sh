#!/usr/bin/env bash

set -o pipefail

# PosLinux é o lançador local e também o bootstrap online.
# Quando executado via curl | bash, ele baixa o release .tar.gz,
# extrai em /tmp e executa a cópia completa com a pasta poslinux.d/.
POSLINUX_TARBALL_URL="${POSLINUX_TARBALL_URL:-https://github.com/SEU_USUARIO/SEU_REPO/releases/latest/download/poslinux.tar.gz}"

resolve_script_dir() {
    local source_path="${BASH_SOURCE[0]:-}"

    if [[ -n "$source_path" && -f "$source_path" ]]; then
        cd -- "$(dirname -- "$source_path")" && pwd
    fi
}

SCRIPT_DIR="$(resolve_script_dir)"
MODULE_DIR=""

if [[ -n "$SCRIPT_DIR" ]]; then
    MODULE_DIR="$SCRIPT_DIR/poslinux.d"
fi

bootstrap_log() {
    local message="$1"

    printf '%s\n' "$message" >&2

    if [[ -n "${BOOTSTRAP_LOG:-}" ]]; then
        printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >> "$BOOTSTRAP_LOG"
    fi
}

abort_bootstrap() {
    bootstrap_log "Erro: $1"
    exit 1
}

require_bootstrap_command() {
    local command_name="$1"

    command -v "$command_name" >/dev/null 2>&1 || abort_bootstrap "comando obrigatório não encontrado: $command_name"
}

validate_bootstrap_url() {
    case "$POSLINUX_TARBALL_URL" in
        ""|*"SEU_USUARIO"*|*"SEU_REPO"*)
            abort_bootstrap "edite POSLINUX_TARBALL_URL em poslinux.sh com a URL do seu release .tar.gz no GitHub."
            ;;
    esac
}

download_release_tarball() {
    local target_file="$1"

    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 2 --connect-timeout 20 "$POSLINUX_TARBALL_URL" -o "$target_file" >> "$BOOTSTRAP_LOG" 2>&1
        return "$?"
    fi

    if command -v wget >/dev/null 2>&1; then
        wget -O "$target_file" "$POSLINUX_TARBALL_URL" >> "$BOOTSTRAP_LOG" 2>&1
        return "$?"
    fi

    abort_bootstrap "curl ou wget não encontrado. Instale um deles para usar o modo online."
}

find_extracted_launcher() {
    local extract_dir="$1"
    local launcher
    local launcher_dir

    launcher="$(find "$extract_dir" -maxdepth 4 -type f -name 'poslinux.sh' -print -quit 2>> "$BOOTSTRAP_LOG")"

    [[ -n "$launcher" ]] || abort_bootstrap "poslinux.sh não foi encontrado dentro do tar.gz."

    launcher_dir="$(cd -- "$(dirname -- "$launcher")" && pwd)"
    [[ -d "$launcher_dir/poslinux.d" ]] || abort_bootstrap "a pasta poslinux.d não foi encontrada ao lado de $launcher."

    printf '%s\n' "$launcher"
}

bootstrap_from_release() {
    local tmp_dir
    local tarball_file
    local extract_dir
    local log_dir
    local launcher

    if [[ "${POSLINUX_BOOTSTRAPPED:-}" == "1" ]]; then
        abort_bootstrap "o script extraído não encontrou a pasta poslinux.d."
    fi

    tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/poslinux-online.XXXXXX")" || {
        echo "Erro: não foi possível criar pasta temporária." >&2
        exit 1
    }

    BOOTSTRAP_LOG="$tmp_dir/bootstrap.log"
    tarball_file="$tmp_dir/poslinux.tar.gz"
    extract_dir="$tmp_dir/extracted"
    log_dir="$tmp_dir/logs"

    mkdir -p "$extract_dir" "$log_dir" || abort_bootstrap "não foi possível preparar a pasta temporária: $tmp_dir"

    bootstrap_log "PosLinux online iniciado."
    bootstrap_log "Pasta temporária: $tmp_dir"

    validate_bootstrap_url
    require_bootstrap_command tar
    require_bootstrap_command find

    bootstrap_log "Baixando release: $POSLINUX_TARBALL_URL"
    download_release_tarball "$tarball_file" || abort_bootstrap "falha ao baixar o release. Log: $BOOTSTRAP_LOG"

    bootstrap_log "Extraindo release."
    tar -xzf "$tarball_file" -C "$extract_dir" >> "$BOOTSTRAP_LOG" 2>&1 || abort_bootstrap "falha ao extrair o tar.gz. Log: $BOOTSTRAP_LOG"

    launcher="$(find_extracted_launcher "$extract_dir")"
    chmod +x "$launcher" 2>> "$BOOTSTRAP_LOG" || true

    bootstrap_log "Executando: $launcher"
    bootstrap_log "Log da sessão: $log_dir/poslinux.log"

    if { exec 3< /dev/tty; } 2>/dev/null; then
        exec env POSLINUX_BOOTSTRAPPED=1 POSLINUX_LOG_DIR="$log_dir" POSLINUX_BOOTSTRAP_LOG="$BOOTSTRAP_LOG" bash "$launcher" "$@" <&3
    fi

    exec env POSLINUX_BOOTSTRAPPED=1 POSLINUX_LOG_DIR="$log_dir" POSLINUX_BOOTSTRAP_LOG="$BOOTSTRAP_LOG" bash "$launcher" "$@"
    abort_bootstrap "não foi possível executar o script extraído."
}

load_modules() {
    local module

    if [[ -z "$MODULE_DIR" || ! -d "$MODULE_DIR" ]]; then
        bootstrap_from_release "$@"
    fi

    for module in "$MODULE_DIR"/*.sh; do
        [[ -r "$module" ]] || continue
        # shellcheck source=/dev/null
        source "$module"
    done
}

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

load_modules "$@"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi
