#!/bin/bash

# OrangeBox - Crear alias de correo Zimbra

set -euo pipefail

ZMPROV="/opt/zimbra/bin/zmprov"

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

if [[ $# -ne 2 ]]; then
    echo "Uso: $0 CUENTA@DOMINIO.TLD ALIAS@DOMINIO.TLD" >&2
    exit 1
fi

ACCOUNT="$1"
ALIAS="$2"

"$ZMPROV" aaa "$ACCOUNT" "$ALIAS"

echo "Alias creado: $ALIAS -> $ACCOUNT"