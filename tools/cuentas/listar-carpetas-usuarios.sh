#!/bin/bash

# OrangeBox - Listado de carpetas de usuarios Zimbra

set -euo pipefail

ZMPROV="/opt/zimbra/bin/zmprov"
ZMMAILBOX="/opt/zimbra/bin/zmmailbox"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/LISTADO-CARPETAS}"
USERS="${USERS:-/tmp/zimbra-usuarios.txt}"

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
"$ZMPROV" -l gaa > "$USERS"

while IFS= read -r account; do
    [[ -z "$account" ]] && continue
    filename="${account//@/_}.txt"
    echo "Consultando $account"
    "$ZMMAILBOX" -z -m "$account" gaf > "$OUTPUT_DIR/$filename"
done < "$USERS"

echo
echo "Listado generado en: $OUTPUT_DIR"