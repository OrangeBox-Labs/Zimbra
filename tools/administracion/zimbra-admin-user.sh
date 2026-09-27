#!/bin/bash

# OrangeBox - Administración de cuentas Zimbra

set -euo pipefail

ZMPROV="/opt/zimbra/bin/zmprov"

usage() {
    echo "Uso:"
    echo "  $0                  Listar cuentas administradoras"
    echo "  $0 USUARIO@DOMINIO  Convertir una cuenta en administradora"
}

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

if [[ ! -x "$ZMPROV" ]]; then
    echo "ERROR: no existe $ZMPROV" >&2
    exit 1
fi

if [[ $# -eq 0 ]]; then
    exec "$ZMPROV" gaaa
fi

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 1
fi

ACCOUNT="$1"

"$ZMPROV" ma "$ACCOUNT" zimbraIsAdminAccount TRUE
echo "Cuenta administrativa configurada: $ACCOUNT"