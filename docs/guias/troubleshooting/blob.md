# Reparación de problemas de BLOB en mailboxes

Esta guía recopila el procedimiento histórico para localizar mailboxes con errores `NO_SUCH_BLOB` y ejecutar `zmblobchk`.

**Precaución:** el comando de reparación usado por la fuente incluye `--missing-blob-delete-item`; prueba primero con backup/snapshot y confirma el impacto antes de ejecutarlo.

## Localizar mailbox IDs

```bash
grep -B2 NO_SUCH_BLOB /opt/zimbra/log/mailbox.log* | grep mailbox= | sed -r 's/.*mailbox=([0-9]*).*$/\1/' | sort -u
```

## Obtener información de un mailbox

```bash
su - zimbra
zmprov getMailboxInfo USUARIO@DOMINIO.TLD
```

Ejemplo de salida:

```text
mailboxId: 123
quotaUsed: 566770
```

## Reparar metadata

Si el mailbox ID fuera `123`:

```bash
zmblobchk -m 123 --missing-blob-delete-item --no-export start
```

Referencia histórica de la fuente original: http://www.3open.org/d/zimbra/how_to_repair_individual_mailboxes