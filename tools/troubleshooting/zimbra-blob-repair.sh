#!/bin/bash

# OrangeBox - Reparación controlada de BLOB de Zimbra

set -euo pipefail

if [[ "$(id -un)" != "zimbra" ]]; then
    echo "ERROR: ejecutar como usuario zimbra." >&2
    exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Uso: $0 MAILBOX_ID" >&2
    exit 1
fi

MAILBOX_ID="$1"

[[ "$MAILBOX_ID" =~ ^[0-9]+$ ]] || { echo "ERROR: MAILBOX_ID debe ser numérico." >&2; exit 1; }

echo "Mailbox ID: $MAILBOX_ID"
echo
echo "ADVERTENCIA: esta operación puede eliminar elementos cuyo BLOB no exista."
read -r -p "Escribe CONFIRMAR para continuar: " CONFIRM

[[ "$CONFIRM" == "CONFIRMAR" ]] || { echo "Operación cancelada."; exit 0; }

zmblobchk -m "$MAILBOX_ID" --missing-blob-delete-item --no-export start