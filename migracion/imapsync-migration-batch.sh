#!/bin/bash
set -euo pipefail

# ============================================================
# OrangeBox - IMAPSync paralelo para migraciones Zimbra
# ============================================================
# Este script ejecuta varias instancias independientes de IMAPSync
# en paralelo para acelerar una migración masiva de buzones.
#
# Características principales:
#   - Autenticación administrativa de Zimbra (--authuser1/2).
#   - Ejecución no interactiva: las passwords nunca se solicitan.
#   - Lista de cuentas mediante USERS_FILE, una cuenta por línea.
#   - Paralelismo configurable con -p.
#   - Filtro MIME mediante --pipemess para retirar attachments > umbral.
#   - Un log independiente por cuenta.
#
# IMPORTANTE:
#   Las passwords deben llegar desde el entorno o una configuración externa.
#   Nunca escribir passwords reales dentro de este archivo ni subirlas a Git.
# ============================================================

# Directorio donde está ubicado este script y donde vive el filtro MIME.
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Ruta al ejecutable de IMAPSync.
# Si IMAPSYNC no está definida, se intenta localizarlo mediante PATH.
IMAPSYNC="${IMAPSYNC:-$(command -v imapsync || true)}"
# Directorio de logs de la migración paralela.
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
  --threshold-mib N         Umbral de attachment en MiB (default: 5)
  --inline-threshold-mib N  Umbral de imagen inline/CID en MiB (default: 1)
  --no-attachment-filter    Desactiva filtro MIME
  --delay SEC               Espera entre inicios (default: 1)
  -h, --help    Ayuda

La autenticación usa las cuentas admin de Zimbra:
  --user1 cuenta --authuser1 admin
  --user2 cuenta --authuser2 admin

Las passwords se configuran directamente en las variables
SOURCE_ADMIN_PASSWORD y TARGET_ADMIN_PASSWORD.
El script no solicita passwords por consola.
USAGE
}

# Hostname o IP del servidor Zimbra de origen.
SOURCE_HOST=""

# Hostname o IP del servidor Zimbra de destino.
TARGET_HOST=""

# Cuenta administrativa de Zimbra en el servidor de origen.
# Se utiliza junto con --authuser1 para migrar cada buzón sin conocer su password.
SOURCE_ADMIN=""

# Cuenta administrativa de Zimbra en el servidor de destino.
# Se utiliza junto con --authuser2 para entregar los mensajes al buzón correspondiente.
TARGET_ADMIN=""

# Archivo de texto que contiene una cuenta de correo por línea.
USERS_FILE=""

# Cantidad máxima de cuentas que IMAPSync procesa simultáneamente.
# 8 es el valor por defecto y se puede cambiar con -p.
PARALLEL=8

# Umbral general para attachments MIME.
THRESHOLD_MIB=5

# Umbral independiente para imágenes inline/CID, principalmente firmas HTML.
INLINE_THRESHOLD_MIB=1

# Indica si el filtro MIME de attachments está activo: 1=activo, 0=desactivado.
FILTER=1

# Cantidad de segundos entre el inicio de cada proceso paralelo.
DELAY=1

# Puerto IMAPS del servidor de origen.
SOURCE_PORT=993

# Puerto IMAPS del servidor de destino.
TARGET_PORT=993

# Password de la cuenta administrativa de Zimbra en el servidor de origen.
# Esta variable debe contener la password utilizada por IMAPSync para --authuser1.
# IMPORTANTE: no subir una password real a GitHub.
SOURCE_ADMIN_PASSWORD=""

# Password de la cuenta administrativa de Zimbra en el servidor de destino.
# Esta variable debe contener la password utilizada por IMAPSync para --authuser2.
# IMPORTANTE: no subir una password real a GitHub.
TARGET_ADMIN_PASSWORD=""

# Procesamiento de parámetros de línea de comandos.
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s) SOURCE_HOST="$2"; shift 2 ;;
        -t) TARGET_HOST="$2"; shift 2 ;;
        -a) SOURCE_ADMIN="$2"; shift 2 ;;
        -b) TARGET_ADMIN="$2"; shift 2 ;;
        -f) USERS_FILE="$2"; shift 2 ;;
        -p) PARALLEL="$2"; shift 2 ;;
        --threshold-mib) THRESHOLD_MIB="$2"; shift 2 ;;
        --inline-threshold-mib) INLINE_THRESHOLD_MIB="$2"; shift 2 ;;
        --no-attachment-filter) FILTER=0; shift ;;
        --delay) DELAY="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: opción desconocida: $1" >&2; usage; exit 1 ;;
    esac
done

# Validar parámetros obligatorios antes de iniciar la migración.
[[ -n "$SOURCE_HOST" && -n "$TARGET_HOST" && -n "$SOURCE_ADMIN" &&
   -n "$TARGET_ADMIN" && -n "$USERS_FILE" ]] || {
    echo "ERROR: faltan parámetros obligatorios." >&2
    usage
    exit 1
}

# GNU Parallel es el encargado de limitar la cantidad de migraciones concurrentes.
command -v parallel >/dev/null 2>&1 || {
    echo "ERROR: GNU Parallel no está instalado." >&2
    exit 1
}

# Validar que el binario de IMAPSync exista y sea ejecutable.
[[ -x "$IMAPSYNC" ]] || {
    echo "ERROR: imapsync no está instalado o no está en PATH." >&2
    exit 1
}

# Validar que el archivo de cuentas exista y sea legible.
[[ -r "$USERS_FILE" ]] || {
    echo "ERROR: no se puede leer $USERS_FILE." >&2
    exit 1
}

# Validar que el nivel de paralelismo sea un entero positivo.
[[ "$PARALLEL" =~ ^[1-9][0-9]*$ ]] || {
    echo "ERROR: -p debe ser entero positivo." >&2
    exit 1
}

# Interpretador Python usado por el filtro MIME.
PYTHON3="${PYTHON3:-python3}"
# Filtro MIME que elimina únicamente attachments que superan el umbral.
FILTER_SCRIPT="$BASE_DIR/imapsync-strip-large-attachments.py"

# Validaciones específicas del filtro MIME, solamente cuando está habilitado.
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

# Crear el directorio de logs antes de iniciar las migraciones.
mkdir -p "$LOG_DIR"

# El batch debe ser completamente no interactivo para poder ejecutarse desde cron.
# Por eso las passwords administrativas se validan antes de lanzar cualquier proceso.
[[ -n "$SOURCE_ADMIN_PASSWORD" && -n "$TARGET_ADMIN_PASSWORD" ]] || {
    echo "ERROR: faltan SOURCE_ADMIN_PASSWORD y/o TARGET_ADMIN_PASSWORD." >&2
    echo "       Configure las passwords en el entorno antes de ejecutar el batch." >&2
    exit 1
}

# Variables que IMAPSync utilizará para autenticarse como administrador de Zimbra.
export IMAPSYNC_PASSWORD1="$SOURCE_ADMIN_PASSWORD"
export IMAPSYNC_PASSWORD2="$TARGET_ADMIN_PASSWORD"

# Convertir la cuenta en un nombre seguro para utilizarlo como nombre de archivo de log.
sanitize_account() {
    printf '%s' "$1" | tr '@/:[:space:]' '____'
}

# Ejecutar una migración individual.
# Cada cuenta corre en un proceso independiente de IMAPSync.
run_one() {
    # Cuenta que será migrada en esta ejecución de IMAPSync.
    local account="$1"

    # Nombre seguro derivado de la cuenta, usado para el archivo de log.
    local safe

    # Archivo de log exclusivo de esta cuenta.
    local account_log

    # Comando externo que recibirá cada mensaje mediante --pipemess.
    local filter_command

    # Código de retorno de IMAPSync.
    local rc

    # Arreglo con todos los argumentos que se pasan a IMAPSync.
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
        # IMAPSync enviará cada mensaje RFC822 por STDIN al filtro MIME.
        # El filtro devuelve por STDOUT el mismo mensaje, salvo los attachments
        # que superen THRESHOLD_MIB, que son eliminados.
        filter_command="$(printf '%q ' \
            "$PYTHON3" \
            "$FILTER_SCRIPT" \
            --threshold-mib "$THRESHOLD_MIB" \
            --inline-threshold-mib "$INLINE_THRESHOLD_MIB" \
            --log "$LOG_DIR/large-attachments.csv"\
        )"
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

# Cargar las cuentas desde USERS_FILE:
#   - elimina comentarios;
#   - elimina líneas vacías;
#   - recorta espacios;
#   - elimina duplicados.
# Array final de cuentas que serán migradas.
mapfile -t ACCOUNTS < <(
    sed 's/#.*$//' "$USERS_FILE" |
    awk 'NF { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print }' |
    awk '!seen[$0]++'
)

(( ${#ACCOUNTS[@]} > 0 )) || {
    echo "ERROR: no hay cuentas válidas en $USERS_FILE." >&2
    exit 1
}

# Crear un archivo temporal con la lista limpia que consumirá GNU Parallel.
CLEAN_USERS="$(mktemp "$LOG_DIR/users.XXXXXX")"
trap 'rm -f "$CLEAN_USERS"' EXIT
printf '%s\n' "${ACCOUNTS[@]}" >"$CLEAN_USERS"

# Mostrar en pantalla la configuración efectiva de esta ejecución.
echo "============================================================"
echo " OrangeBox - IMAPSync paralelo"
echo "============================================================"
echo "Cuentas    : ${#ACCOUNTS[@]}"
echo "Paralelo   : $PARALLEL"
echo "Origen     : $SOURCE_HOST:$SOURCE_PORT"
echo "Destino    : $TARGET_HOST:$TARGET_PORT"
if (( FILTER == 1 )); then
    echo "Filtro     : attachments > $THRESHOLD_MIB MiB"
    echo "Inline/CID  : imágenes > $INLINE_THRESHOLD_MIB MiB"
else
    echo "Filtro     : DESACTIVADO"
fi
echo "Logs       : $LOG_DIR"
echo "============================================================"
echo

# Exportar variables y funciones para que GNU Parallel pueda ejecutar run_one
# dentro de los procesos hijos.
export SOURCE_HOST TARGET_HOST SOURCE_ADMIN TARGET_ADMIN
export SOURCE_PORT TARGET_PORT IMAPSYNC PYTHON3 FILTER_SCRIPT LOG_DIR
export THRESHOLD_MIB INLINE_THRESHOLD_MIB FILTER
export -f sanitize_account run_one
export IMAPSYNC_PASSWORD1 IMAPSYNC_PASSWORD2

# Lanzar las migraciones concurrentes.
# run_one es una función Bash exportada para que GNU Parallel pueda ejecutarla
# directamente en cada proceso hijo.
#
# --max-procs limita la cantidad de buzones procesados simultáneamente.
# --delay evita iniciar todos los procesos exactamente al mismo tiempo.
# --line-buffer mantiene la salida de cada proceso legible.
#
# La lista limpia se entrega mediante ::::, por lo que cada línea de
# CLEAN_USERS llega directamente como $1 de run_one.
parallel --will-cite \
    --max-procs "$PARALLEL" \
    --delay "$DELAY" \
    --line-buffer \
    --tagstring '[{#}]' \
    run_one \
    :::: "$CLEAN_USERS"

echo
echo "============================================================"
echo " IMAPSync paralelo terminado"
echo "============================================================"
