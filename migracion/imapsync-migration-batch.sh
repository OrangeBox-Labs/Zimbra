#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAPSYNC="${IMAPSYNC:-$(command -v imapsync || true)}"
LOG_DIR="$BASE_DIR/logs/imapsync-batch"

usage() {
    cat <<'USAGE'
Uso:
  $0 -s SOURCE_HOST -t TARGET_HOST -a SOURCE_ADMIN -b TARGET_ADMIN -f USERS_FILE [opciones]

Opciones:
  -s HOST       Host IMAP origen
  -t HOST       Host IMAP destino
  -a ACCOUNT    Admin IMAP origen
  -b ACCOUNT    Admin IMAP destino
  -f FILE       Una cuenta por línea
  -p N          Cuentas simultáneas (default: 8)
  --threshold-mib N  Umbral de attachment en MiB (default: 5)
  --no-attachment-filter  Desactiva filtro MIME
  --delay SEC   Espera entre inicios (default: 1)
  -h, --help    Ayuda

La autenticación usa las cuentas admin de Zimbra:
  --user1 cuenta --authuser1 admin
  --user2 cuenta --authuser2 admin

Las passwords se solicitan una vez y se entregan mediante:
  IMAPSYNC_PASSWORD1
  IMAPSYNC_PASSWORD2
USAGE
}

SOURCE_HOST=""
TARGET_HOST=""
SOURCE_ADMIN=""
TARGET_ADMIN=""
USERS_FILE=""
PARALLEL=8
THRESHOLD_MIB=5
FILTER=1
DELAY=1
SOURCE_PORT=993
TARGET_PORT=993

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s) SOURCE_HOST="$2"; shift 2 ;;
        -t) TARGET_HOST="$2"; shift 2 ;;
        -a) SOURCE_ADMIN="$2"; shift 2 ;;
        -b) TARGET_ADMIN="$2"; shift 2 ;;
        -f) USERS_FILE="$2"; shift 2 ;;
        -p) PARALLEL="$2"; shift 2 ;;
        --threshold-mib) THRESHOLD_MIB="$2"; shift 2 ;;
        --no-attachment-filter) FILTER=0; shift ;;
        --delay) DELAY="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: opción desconocida: $1" >&2; usage; exit 1 ;;
    esac
done

[[ -n "$SOURCE_HOST" && -n "$TARGET_HOST" && -n "$SOURCE_ADMIN" &&
   -n "$TARGET_ADMIN" && -n "$USERS_FILE" ]] || {
    echo "ERROR: faltan parámetros obligatorios." >&2
    usage
    exit 1
}

command -v parallel >/dev/null 2>&1 || {
    echo "ERROR: GNU Parallel no está instalado." >&2
    exit 1
}

[[ -x "$IMAPSYNC" ]] || {
    echo "ERROR: imapsync no está instalado o no está en PATH." >&2
    exit 1
}

[[ -r "$USERS_FILE" ]] || {
    echo "ERROR: no se puede leer $USERS_FILE." >&2
    exit 1
}

[[ "$PARALLEL" =~ ^[1-9][0-9]*$ ]] || {
    echo "ERROR: -p debe ser entero positivo." >&2
    exit 1
}

PYTHON3="${PYTHON3:-python3}"
FILTER_SCRIPT="$BASE_DIR/imapsync-strip-large-attachments.py"

if (( FILTER == 1 )); then
    command -v "$PYTHON3" >/dev/null 2>&1 || {
        echo "ERROR: $PYTHON3 no está instalado." >&2
        exit 1
    }
    [[ -r "$FILTER_SCRIPT" ]] || {
        echo "ERROR: no existe $FILTER_SCRIPT." >&2
        exit 1
    }
    "$PYTHON3" -m py_compile "$FILTER_SCRIPT"
fi

mkdir -p "$LOG_DIR"

if [[ -z "${IMAPSYNC_PASSWORD1:-}" ]]; then
    read -r -s -p "Password admin origen [$SOURCE_ADMIN]: " IMAPSYNC_PASSWORD1
    echo
    export IMAPSYNC_PASSWORD1
fi

if [[ -z "${IMAPSYNC_PASSWORD2:-}" ]]; then
    read -r -s -p "Password admin destino [$TARGET_ADMIN]: " IMAPSYNC_PASSWORD2
    echo
    export IMAPSYNC_PASSWORD2
fi

sanitize_account() {
    printf '%s' "$1" | tr '@/:[:space:]' '____'
}

run_one() {
    local account="$1"
    local safe
    local account_log
    local filter_command
    local rc
    local -a args

    safe="$(sanitize_account "$account")"
    account_log="$LOG_DIR/$safe.log"

    args=(
        --host1 "$SOURCE_HOST"
        --port1 "$SOURCE_PORT"
        --ssl1
        --user1 "$account"
        --authuser1 "$SOURCE_ADMIN"
        --host2 "$TARGET_HOST"
        --port2 "$TARGET_PORT"
        --ssl2
        --user2 "$account"
        --authuser2 "$TARGET_ADMIN"
        --automap
        --usecache
        --syncinternaldates
        --subscribe
        --nofoldersizes
        --skipsize
        --errorsmax 1000
        --logdir "$LOG_DIR"
    )

    if (( FILTER == 1 )); then
        filter_command="$(printf '%q ' "$PYTHON3" "$FILTER_SCRIPT")"
        filter_command="${filter_command% }"
        args+=( --pipemess "$filter_command" )
    fi

    printf '[START] %s\n' "$account"

    {
        echo "============================================================"
        echo " OrangeBox - IMAPSync"
        echo " Cuenta : $account"
        echo " Origen : $SOURCE_HOST:$SOURCE_PORT"
        echo " Destino: $TARGET_HOST:$TARGET_PORT"
        echo " Inicio : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "============================================================"
        echo
    } >"$account_log"

    if "$IMAPSYNC" "${args[@]}" >>"$account_log" 2>&1; then
        rc=0
    else
        rc=$?
    fi

    {
        echo
        echo "============================================================"
        echo " Return : $rc"
        echo " Fin    : $(date '+%Y-%m-%d %H:%M:%S')"
        echo " Log    : $account_log"
        echo "============================================================"
    } >>"$account_log"

    if (( rc == 0 )); then
        printf '[OK]    %s\n' "$account"
    else
        printf '[ERROR] %s (rc=%s) -> %s\n' "$account" "$rc" "$account_log"
    fi

    return "$rc"
}

mapfile -t ACCOUNTS < <(
    sed 's/#.*$//' "$USERS_FILE" |
    awk 'NF { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print }' |
    awk '!seen[$0]++'
)

(( ${#ACCOUNTS[@]} > 0 )) || {
    echo "ERROR: no hay cuentas válidas en $USERS_FILE." >&2
    exit 1
}

CLEAN_USERS="$(mktemp "$LOG_DIR/users.XXXXXX")"
trap 'rm -f "$CLEAN_USERS"' EXIT
printf '%s\n' "${ACCOUNTS[@]}" >"$CLEAN_USERS"

echo "============================================================"
echo " OrangeBox - IMAPSync paralelo"
echo "============================================================"
echo "Cuentas    : ${#ACCOUNTS[@]}"
echo "Paralelo   : $PARALLEL"
echo "Origen     : $SOURCE_HOST:$SOURCE_PORT"
echo "Destino    : $TARGET_HOST:$TARGET_PORT"
if (( FILTER == 1 )); then
    echo "Filtro     : attachments > $THRESHOLD_MIB MiB"
else
    echo "Filtro     : DESACTIVADO"
fi
echo "Logs       : $LOG_DIR"
echo "============================================================"
echo

export SOURCE_HOST TARGET_HOST SOURCE_ADMIN TARGET_ADMIN
export SOURCE_PORT TARGET_PORT IMAPSYNC PYTHON3 FILTER_SCRIPT LOG_DIR THRESHOLD_MIB FILTER
export -f sanitize_account run_one
export IMAPSYNC_PASSWORD1 IMAPSYNC_PASSWORD2

parallel --will-cite     --max-procs "$PARALLEL"     --delay "$DELAY"     --line-buffer     --tagstring '[{#}]'     bash -c 'run_one "$1"' _ {}     :::: "$CLEAN_USERS"

echo
echo "============================================================"
echo " IMAPSync paralelo terminado"
echo "============================================================"
