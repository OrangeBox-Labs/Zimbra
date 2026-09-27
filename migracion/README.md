# Migración Zimbra

Herramientas OrangeBox para rescatar la configuración de un Zimbra existente, reconstruir la plataforma en un servidor nuevo y migrar el contenido de los buzones mediante IMAP.

## Flujo

1. Ejecutar `zimbra-migration-export.sh` en el Zimbra antiguo.
2. Revisar el bundle `/root/zimbra-migration-YYYYMMDD_HHMMSS/`.
3. Copiar el bundle al servidor nuevo.
4. Ejecutar el `restore.sh` generado.
5. Verificar dominios, cuentas, passwords, aliases, forwarding y Distribution Lists.
6. Migrar los buzones con `imapsync-migration.sh`.

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

La migración de buzones usa `imapsync-migration.sh`.

Por defecto, la migración mantiene todos los mensajes pero aplica una política MIME para **omitir únicamente attachments mayores a 5 MiB**. El mensaje no se descarta completo por superar ese tamaño.

El filtro `imapsync-strip-large-attachments.py` se ejecuta mediante `--pipemess` y registra cada eliminación en `logs/large-attachments.csv`.

Ejemplo:

```bash
./imapsync-migration.sh \
  -s zimbra-viejo.example.cl \
  -t zimbra-nuevo.example.cl \
  -u usuario@example.cl
```

Las contraseñas se pueden proporcionar mediante `SOURCE_PASSWORD` y `TARGET_PASSWORD` o ingresarlas de forma interactiva.

La documentación completa está en [`imapsync-migration.md`](./imapsync-migration.md).

## Seguridad

Un bundle puede contener información extremadamente sensible. No publiques `passwords.ldif`, exports, logs de migración ni bundles completos en GitHub.
