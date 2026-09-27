# Migración Zimbra

Herramientas OrangeBox para rescatar la configuración de un Zimbra existente, reconstruir la plataforma en un servidor nuevo y migrar el contenido de los buzones mediante IMAP.

## Flujo

1. Ejecutar `zimbra-migration-export.sh` en el Zimbra antiguo.
2. Revisar el bundle `/root/zimbra-migration-YYYYMMDD_HHMMSS/`.
3. Copiar el bundle al servidor nuevo.
4. Ejecutar el `restore.sh` generado.
5. Verificar dominios, cuentas, passwords, aliases, forwarding y Distribution Lists.
6. Migrar los buzones con IMAPSync.

## Exportación

El exportador rescata dominios, cuentas, aliases, Distribution Lists, recursos, COS y otras configuraciones como referencia. También genera automáticamente el `restore.sh`.

## Restore base

La restauración automática prioriza la base funcional de correo:

- Dominios.
- Cuentas.
- Passwords.
- Atributos básicos portables.
- Cuotas.
- `zimbraMailForwardingAddress`, incluyendo múltiples valores.
- `zimbraPrefMailForwardingAddress`.
- Aliases.
- Distribution Lists y sus miembros.

Las preferencias `zimbraPref*` genéricas y atributos dependientes del servidor no se fuerzan en el restore base.

## IMAPSync

Para una cuenta individual:

```bash
./imapsync-migration.sh \
  -s zimbra-viejo.example.cl \
  -t zimbra-nuevo.example.cl \
  -u usuario@example.cl
```

Para una migración masiva se usa `imapsync-migration-batch.sh`. Ejecuta múltiples instancias independientes de IMAPSync en paralelo; el valor por defecto es **8 cuentas simultáneas** y se puede modificar con `-p`.

El modo batch utiliza autenticación administrativa de Zimbra mediante `--authuser1` y `--authuser2`, por lo que no es necesario guardar las passwords individuales de cada cuenta en el archivo de usuarios. La documentación oficial de IMAPSync confirma este mecanismo para Zimbra y recomienda autenticación administrativa cuando está disponible.

Archivo de cuentas:

```text
usuario1@example.com
usuario2@example.com
usuario3@example.com
```

Existe una plantilla en [`imapsync-users.example.txt`](./imapsync-users.example.txt).

Ejemplo con 8 cuentas simultáneas:

```bash
./imapsync-migration-batch.sh \
  -s zimbra-viejo.example.cl \
  -t zimbra-nuevo.example.cl \
  -a admin@example.cl \
  -b admin@example.cl \
  -f imapsync-users.txt \
  -p 8 \
  --threshold-mib 5
```

Para trabajar con 4 cuentas simultáneas:

```bash
./imapsync-migration-batch.sh \
  -s zimbra-viejo.example.cl \
  -t zimbra-nuevo.example.cl \
  -a admin@example.cl \
  -b admin@example.cl \
  -f imapsync-users.txt \
  -p 4
```

IMAPSync no incorpora actualmente la migración masiva dentro del propio binario; su documentación oficial proporciona scripts Unix para ejecutar varias cuentas, incluyendo un ejemplo de paralelización con GNU Parallel.

## Política de attachments

Por defecto, la migración mantiene todos los mensajes pero elimina únicamente los attachments **mayores a 5 MiB** antes de entregarlos al Zimbra nuevo.

El filtro es:

```
imapsync
  └── --pipemess
        └── imapsync-strip-large-attachments.py
```

Los attachments de 5 MiB o menos se conservan. El mensaje completo no se descarta por superar el límite.

La auditoría de eliminaciones se registra en:

```text
logs/imapsync-batch/large-attachments.csv
```

El filtro puede desactivarse con:

```text
--no-attachment-filter
```

La documentación completa está en [`imapsync-migration.md`](./imapsync-migration.md).

## Logs y operación

Cada cuenta del modo batch genera su propio log bajo:

```text
logs/imapsync-batch/
```

Esto permite revisar una cuenta que falle sin perder el contexto de las demás.

El tráfico entre ambos Zimbra no se utiliza como criterio de descarte de attachments. La política se aplica antes de almacenar el mensaje en el destino.

## Seguridad

Las passwords se solicitan una vez y se entregan a IMAPSync mediante `IMAPSYNC_PASSWORD1` y `IMAPSYNC_PASSWORD2`, funcionalidad disponible desde IMAPSync 2.229.

No publiques passwords, exports, logs de migración ni bundles completos en GitHub.
