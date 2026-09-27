#!/bin/bash

# OrangeBox - Certificado autofirmado Zimbra

set -euo pipefail

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

/opt/zimbra/bin/zmcertmgr createca -new
/opt/zimbra/bin/zmcertmgr deployca
/opt/zimbra/bin/zmcertmgr createcrt -new -days "${DAYS:-365}"
/opt/zimbra/bin/zmcertmgr deploycrt self
/opt/zimbra/bin/zmcertmgr viewdeployedcrt

echo "Certificado autofirmado desplegado."
echo "Reiniciando Zimbra..."
zmcontrol restart