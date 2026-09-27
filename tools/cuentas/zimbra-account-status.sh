#!/bin/bash

# OrangeBox - Estado de cuenta Zimbra

set -euo pipefail

ZMPROV="/opt/zimbra/bin/zmprov"

usage() {
    echo "Uso: $0 USUARIO@DOMINIO.TLD active|maintenance|locked|closed|lockout"
}

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

if [[ $# -ne 2 ]]; then
    usage >&2
    exit 1
fi

ACCOUNT="$1"
STATUS="$2"

case "$STATUS" in
    active|maintenance|locked|closed|lockout) ;;
    *)
        echo "ERROR: estado no soportado: $STATUS" >&2
        usage >&2
        exit 1
        ;;
esac

"$ZMPROV" ma "$ACCOUNT" zimbraAccountStatus "$STATUS"
echo "Estado configurado: $ACCOUNT -> $STATUS"