#!/bin/bash
set -euo pipefail

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
  --dry         Mostrar comando sin ejecutarlo
  -h, --help    Mostrar ayuda

Credenciales:
  SOURCE_PASSWORD   Password origen
  TARGET_PASSWORD   Password destino
USAGE
}

SOURCE_HOST=""
TARGET_HOST=""
ACCOUNT=""
SOURCE_PORT="993"
TARGET_PORT="993"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s) SOURCE_HOST="$2"; shift 2 ;;
        -t) TARGET_HOST="$2"; shift 2 ;;
        -u) ACCOUNT="$2"; shift 2 ;;
        -S) SOURCE_PORT="$2"; shift 2 ;;
        -T) TARGET_PORT="$2"; shift 2 ;;
        --dry) DRY_RUN=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: opción desconocida: $1" >&2; usage; exit 1 ;;
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
    --logdir "./logs"
)

mkdir -p ./logs

echo "============================================================"
echo " OrangeBox - Zimbra IMAP Migration"
echo "============================================================"
echo "Cuenta : $ACCOUNT"
echo "Origen : $SOURCE_HOST:$SOURCE_PORT"
echo "Destino: $TARGET_HOST:$TARGET_PORT"
echo

if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'imapsync'
    printf ' %q' "${ARGS[@]}"
    printf '\n'
    exit 0
fi

exec imapsync "${ARGS[@]}"