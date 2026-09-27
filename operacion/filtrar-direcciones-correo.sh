#!/bin/bash

# OrangeBox - Extraer direcciones de correo desde un archivo

set -euo pipefail

INPUT="${1:-lista.txt}"
OUTPUT="${2:-/tmp/blacklist.txt}"

if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: no existe el archivo: $INPUT" >&2
    exit 1
fi

grep -Eio '\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b' "$INPUT" |
    sort -fu |
    sed 's/^/blacklist_from /' > "$OUTPUT"

echo "Lista generada: $OUTPUT"