# Reparación de BLOB de un mailbox Zimbra

## Qué problema aborda

Esta herramienta está basada en la guía histórica para localizar mailboxes afectados por errores `NO_SUCH_BLOB` y ejecutar `zmblobchk` sobre un mailbox específico.

## 1. Buscar mailbox IDs afectados

```bash
grep -B2 NO_SUCH_BLOB /opt/zimbra/log/mailbox.log* | grep mailbox= | sed -r 's/.*mailbox=([0-9]*).*$/\1/' | sort -u
```

## 2. Obtener información del mailbox

```bash
su - zimbra
zmprov getMailboxInfo USUARIO@DOMINIO.TLD
```

Busca el campo `mailboxId`.

## 3. Ejecutar reparación

```bash
./zimbra-blob-repair.sh MAILBOX_ID
```

El script solicita escribir `CONFIRMAR` antes de ejecutar:

```bash
zmblobchk -m MAILBOX_ID --missing-blob-delete-item --no-export start
```

## Precaución crítica

El parámetro `--missing-blob-delete-item` implica una acción potencialmente destructiva sobre elementos cuyo BLOB falta. Realiza backup/snapshot y verifica el mailbox afectado antes de continuar.