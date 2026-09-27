#!/bin/bash

# OrangeBox - Despliegue de certificado comercial Zimbra

set -euo pipefail

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

if [[ $# -ne 3 ]]; then
    echo "Uso: $0 CERTIFICADO.crt CADENA.crt commercial.key" >&2
    exit 1
fi

CERT="$1"
CHAIN="$2"
KEY="$3"

/opt/zimbra/bin/zmcertmgr verifycrt comm "$KEY" "$CERT" "$CHAIN"
/opt/zimbra/bin/zmcertmgr deploycrt comm "$CERT" "$CHAIN"
/opt/zimbra/bin/zmcertmgr viewdeployedcrt

echo "Certificado comercial desplegado."