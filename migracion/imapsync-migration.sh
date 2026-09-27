#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$BASE_DIR/logs"

usage() {
    cat <<'USAGE'
Uso:
  $0 -s SOURCE_HOST -t TARGET_HOST -u ACCOUNT [opciones]

Opciones:
  -s HOST       Host IMAP origen
  -t HOST       Host IMAP destino
  -u ACCOUNT    Cuenta a migrar
  -S PORT       Puerto IMAPS origen (default: 993)
  -T PORT       Puerto IMAPS destino (default: 993)
  --threshold-mib N
                Tamaño máximo de attachment a migrar en MiB (default: 5)
  --no-attachment-filter
                Desactiva el filtro de attachments grandes
  --dry         Mostrar comando sin ejecutarlo
  -h, --help    Mostrar ayuda

Credenciales:
  SOURCE_PASSWORD   Password origen
  TARGET_PASSWORD   Password destino

Política por defecto:
  Se migran todos los mensajes, pero se eliminan del mensaje los
  attachments cuyo tamaño sea MAYOR al umbral antes de entregarlo
  al servidor destino.
USAGE
}

SOURCE_HOST=""
TARGET_HOST=""
ACCOUNT=""
SOURCE_PORT="993"
TARGET_PORT="993"
THRESHOLD_MIB="5"
FILTER_LARGE_ATTACHMENTS=1
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s)
            [[ $# -ge 2 ]] || { echo "ERROR: falta valor para -s." >&2; exit 1; }
            SOURCE_HOST="$2"
            shift 2
            ;;
        -t)
            [[ $# -ge 2 ]] || { echo "ERROR: falta valor para -t." >&2; exit 1; }
            TARGET_HOST="$2"
            shift 2
            ;;
        -u)
            [[ $# -ge 2 ]] || { echo "ERROR: falta valor para -u." >&2; exit 1; }
            ACCOUNT="$2"
            shift 2
            ;;
        -S)
            [[ $# -ge 2 ]] || { echo "ERROR: falta valor para -S." >&2; exit 1; }
            SOURCE_PORT="$2"
            shift 2
            ;;
        -T)
            [[ $# -ge 2 ]] || { echo "ERROR: falta valor para -T." >&2; exit 1; }
            TARGET_PORT="$2"
            shift 2
            ;;
        --threshold-mib)
            [[ $# -ge 2 ]] || { echo "ERROR: falta valor para --threshold-mib." >&2; exit 1; }
            THRESHOLD_MIB="$2"
            shift 2
            ;;
        --no-attachment-filter)
            FILTER_LARGE_ATTACHMENTS=0
            shift
            ;;
        --dry)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: opción desconocida: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$SOURCE_HOST" || -z "$TARGET_HOST" || -z "$ACCOUNT" ]]; then
    echo "ERROR: faltan -s, -t o -u." >&2
    usage
    exit 1
fi

if ! command -v imapsync >/dev/null 2>&1; then
    echo "ERROR: imapsync no está instalado o no está en PATH." >&2
    exit 1
fi

if [[ "$FILTER_LARGE_ATTACHMENTS" -eq 1 ]]; then
    PYTHON3="${PYTHON3:-python3}"

    if ! command -v "$PYTHON3" >/dev/null 2>&1; then
        echo "ERROR: $PYTHON3 no está instalado o no está en PATH." >&2
        exit 1
    fi

    FILTER_SCRIPT="$BASE_DIR/imapsync-strip-large-attachments.py"

    if [[ ! -r "$FILTER_SCRIPT" ]]; then
        echo "ERROR: no existe el filtro MIME: $FILTER_SCRIPT" >&2
        exit 1
    fi

    if ! "$PYTHON3" -m py_compile "$FILTER_SCRIPT"; then
        echo "ERROR: el filtro MIME no pasa la validación de sintaxis." >&2
        exit 1
    fi
fi

SOURCE_PASSWORD="${SOURCE_PASSWORD:-}"
TARGET_PASSWORD="${TARGET_PASSWORD:-}"

if [[ -z "$SOURCE_PASSWORD" ]]; then
    read -r -s -p "Password origen [$ACCOUNT]: " SOURCE_PASSWORD
    echo
fi

if [[ -z "$TARGET_PASSWORD" ]]; then
    read -r -s -p "Password destino [$ACCOUNT]: " TARGET_PASSWORD
    echo
fi

mkdir -p "$LOG_DIR"

ARGS=(
    --host1 "$SOURCE_HOST"
    --port1 "$SOURCE_PORT"
    --ssl1
    --user1 "$ACCOUNT"
    --password1 "$SOURCE_PASSWORD"
    --host2 "$TARGET_HOST"
    --port2 "$TARGET_PORT"
    --ssl2
    --user2 "$ACCOUNT"
    --password2 "$TARGET_PASSWORD"
    --automap
    --usecache
    --syncinternaldates
    --subscribe
    --nofoldersizes
    --skipsize
    --errorsmax 1000
    --logdir "$LOG_DIR"
)

if [[ "$FILTER_LARGE_ATTACHMENTS" -eq 1 ]]; then
    FILTER_LOG="$LOG_DIR/large-attachments.csv"
    export ORANGEBOX_ATTACHMENT_THRESHOLD_MIB="$THRESHOLD_MIB"
    export ORANGEBOX_IMAPSYNC_FILTER_LOG="$FILTER_LOG"

    FILTER_COMMAND="$(printf '%q ' "$PYTHON3" "$FILTER_SCRIPT")"
    FILTER_COMMAND="${FILTER_COMMAND% }"

    ARGS+=(
        --pipemess "$FILTER_COMMAND"
    )
fi

echo "============================================================"
echo " OrangeBox - Zimbra IMAP Migration"
echo "============================================================"
echo "Cuenta : $ACCOUNT"
echo "Origen : $SOURCE_HOST:$SOURCE_PORT"
echo "Destino: $TARGET_HOST:$TARGET_PORT"

if [[ "$FILTER_LARGE_ATTACHMENTS" -eq 1 ]]; then
    echo "Filtro : attachments > $THRESHOLD_MIB MiB serán omitidos"
    echo "Auditoría: $LOG_DIR/large-attachments.csv"
else
    echo "Filtro : DESACTIVADO"
fi

echo

if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'imapsync'
    printf ' %q' "${ARGS[@]}"
    printf '\n'
    exit 0
fi

exec imapsync "${ARGS[@]}"
