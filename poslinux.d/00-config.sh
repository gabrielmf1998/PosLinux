# shellcheck shell=bash
# shellcheck disable=SC2034
# Configuração global do PosLinux: nome, caminhos e tema do TUI.


APP_NAME="PosLinux"
RUN_USER="${SUDO_USER:-${USER:-}}"
RUN_HOME="$HOME"

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]] && command -v getent >/dev/null 2>&1; then
    RUN_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
fi

[[ -n "$RUN_HOME" ]] || RUN_HOME="$HOME"

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    APP_DATA_DIR="$RUN_HOME/.local/share/poslinux"
else
    APP_DATA_DIR="${XDG_DATA_HOME:-$RUN_HOME/.local/share}/poslinux"
fi

if [[ -n "${POSLINUX_LOG_FILE:-}" ]]; then
    LOG_FILE="$POSLINUX_LOG_FILE"
    LOG_DIR="$(dirname -- "$LOG_FILE")"
elif [[ -n "${POSLINUX_LOG_DIR:-}" ]]; then
    LOG_DIR="$POSLINUX_LOG_DIR"
    LOG_FILE="$LOG_DIR/poslinux.log"
else
    LOG_DIR="$APP_DATA_DIR/logs"
    LOG_FILE="$LOG_DIR/poslinux.log"
fi

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
