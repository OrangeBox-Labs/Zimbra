#!/bin/bash

# OrangeBox - Administración DKIM para Zimbra

set -euo pipefail

DKIM="/opt/zimbra/libexec/zmdkimkeyutil"

usage() {
    echo "Uso: $0 add|update|query|remove DOMINIO.TLD"
}

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

[[ -x "$DKIM" ]] || { echo "ERROR: no existe $DKIM" >&2; exit 1; }
[[ $# -eq 2 ]] || { usage >&2; exit 1; }

ACTION="$1"
DOMAIN="$2"

case "$ACTION" in
    add) "$DKIM" -a -d "$DOMAIN" ;;
    update) "$DKIM" -u -d "$DOMAIN" ;;
    query) "$DKIM" -q -d "$DOMAIN" ;;
    remove) "$DKIM" -r -d "$DOMAIN" ;;
    *) usage >&2; exit 1 ;;
esac