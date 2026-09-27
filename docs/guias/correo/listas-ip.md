# Whitelist y blacklist por IP en Postfix

**Legacy:** procedimiento proveniente de documentación antigua de Zimbra. Valida la sintaxis y el backend de mapas de Postfix de tu versión antes de aplicarlo.

## Whitelist

Archivo:

```text
/opt/zimbra/conf/whitelist
```

Ejemplo:

```text
192.0.2.10 OK
```

Aplicar el mapa y registrar la restricción:

```bash
postmap /opt/zimbra/conf/whitelist
zmprov mcf +zimbraMtaRestriction 'check_client_access lmdb:/opt/zimbra/conf/whitelist'
```

## Blacklist

Archivo:

```text
/opt/zimbra/conf/postfix_blacklist
```

Ejemplo:

```text
192.0.2.10 REJECT
```

Aplicar:

```bash
postmap /opt/zimbra/conf/postfix_blacklist
zmprov mcf +zimbraMtaRestriction 'check_client_access lmdb:/opt/zimbra/conf/postfix_blacklist'
```

Cada modificación requiere volver a ejecutar `postmap`.