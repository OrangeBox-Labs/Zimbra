# Whitelist y blacklist por IP en Postfix/Zimbra

**Legacy:** procedimiento proveniente de documentación antigua de Zimbra.

## Qué hace

Permite mantener listas de clientes permitidos o rechazados por dirección IP usando archivos de mapa de Postfix y una restricción `check_client_access` en Zimbra.

## Whitelist

Editar:

```text
/opt/zimbra/conf/whitelist
```

Formato:

```text
192.0.2.10 OK
```

Aplicar:

```bash
postmap /opt/zimbra/conf/whitelist
zmprov mcf +zimbraMtaRestriction 'check_client_access lmdb:/opt/zimbra/conf/whitelist'
```

## Blacklist

Editar:

```text
/opt/zimbra/conf/postfix_blacklist
```

Formato:

```text
192.0.2.10 REJECT
```

Aplicar:

```bash
postmap /opt/zimbra/conf/postfix_blacklist
zmprov mcf +zimbraMtaRestriction 'check_client_access lmdb:/opt/zimbra/conf/postfix_blacklist'
```

## Importante

Después de agregar o eliminar una entrada debes volver a ejecutar `postmap`. Valida el backend de mapa configurado por tu versión de Postfix/Zimbra antes de aplicar el procedimiento.