# Whitelist y blacklist de remitentes

**Legacy:** la guía original modifica directamente `/opt/zimbra/conf/amavisd.conf.in`. Revisa si tu versión mantiene este mecanismo y si el archivo es regenerado antes de aplicar cambios.

## Configuración

Agregar al archivo `/opt/zimbra/conf/amavisd.conf.in`:

```perl
read_hash(\%whitelist_sender, '/opt/zimbra/conf/whitelist');
read_hash(\%blacklist_sender, '/opt/zimbra/conf/blacklist');
```

## Whitelist

Archivo:

```text
/opt/zimbra/conf/whitelist
```

Ejemplo:

```text
example.com
```

## Blacklist

Archivo:

```text
/opt/zimbra/conf/blacklist
```

Ejemplo:

```text
blocked.example
```

## Aplicar

```bash
su - zimbra -c 'zmamavisdctl restart'
```

## Precaución

Un cambio en estas listas puede afectar entrega de correo. Documenta la modificación y valida con mensajes de prueba.