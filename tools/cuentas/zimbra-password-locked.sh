#!/bin/bash

# OrangeBox - Configuración zimbraPasswordLocked

set -euo pipefail

ZMPROV="/opt/zimbra/bin/zmprov"
COS="${1:-default}"
VALUE="${2:-FALSE}"

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

case "$VALUE" in
    TRUE|FALSE) ;;
    *)
        echo "ERROR: el valor debe ser TRUE o FALSE." >&2
        exit 1
        ;;
esac

"$ZMPROV" mc "$COS" zimbraPasswordLocked "$VALUE"
echo "zimbraPasswordLocked configurado en COS '$COS': $VALUE"