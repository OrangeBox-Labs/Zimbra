#!/bin/bash

# OrangeBox - Activar/desactivar antivirus y antispam de Zimbra

set -euo pipefail

ZMPROV="/opt/zimbra/bin/zmprov"

usage() {
    echo "Uso: $0 enable|disable"
}

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

[[ $# -eq 1 ]] || { usage >&2; exit 1; }

case "$1" in
    disable)
        "$ZMPROV" ms "$(hostname -f)" -zimbraServiceEnabled antispam
        "$ZMPROV" ms "$(hostname -f)" -zimbraServiceEnabled antivirus
        echo "Antispam y antivirus desactivados."
        ;;
    enable)
        "$ZMPROV" ms "$(hostname -f)" +zimbraServiceEnabled antispam
        "$ZMPROV" ms "$(hostname -f)" +zimbraServiceEnabled antivirus
        echo "Antispam y antivirus activados."
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac