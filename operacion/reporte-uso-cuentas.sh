#!/bin/bash

# OrangeBox - Reporte de uso de buzones Zimbra

set -euo pipefail

ZMPROV="/opt/zimbra/bin/zmprov"
ZMMAILBOX="/opt/zimbra/bin/zmmailbox"
SERVER="$(hostname -f 2>/dev/null || hostname)"
REPORT_EMAIL="${REPORT_EMAIL:-admin@example.com}"
WORKDIR="${WORKDIR:-/tmp/zimbra-mailbox-report}"
USERS="${WORKDIR}/users.txt"
REPORT="${WORKDIR}/mailbox_size.txt"

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

if [[ ! -x "$ZMPROV" || ! -x "$ZMMAILBOX" ]]; then
    echo "ERROR: no se encontraron las herramientas de Zimbra." >&2
    exit 1
fi

mkdir -p "$WORKDIR"

"$ZMPROV" -l gaa > "$USERS"

{
    echo "Tamaño de mailboxes de $SERVER"
    echo
    while IFS= read -r account; do
        [[ -z "$account" ]] && continue
        mbox_size="$("$ZMMAILBOX" -z -m "$account" gms 2>/dev/null || echo 'ERROR')"
        echo "$account = $mbox_size"
    done < "$USERS"
} > "$REPORT"

mail -s "Espacio mailboxes $SERVER" "$REPORT_EMAIL" < "$REPORT"

echo "Informe enviado a: $REPORT_EMAIL"
echo "Archivo: $REPORT"