# DKIM en Zimbra

DKIM permite firmar digitalmente el correo saliente para que el dominio pueda ser validado por los receptores.

## Crear DKIM

En el servidor MTA:

```bash
/opt/zimbra/libexec/zmdkimkeyutil -a -d example.com
```

La herramienta entrega un selector y la información necesaria para crear el registro TXT en DNS.

## Publicar en DNS

El registro sigue el formato:

```text
SELECTOR._domainkey.example.com
```

Verificar el TXT:

```bash
dig -t txt SELECTOR._domainkey.example.com NAMESERVER
```

## Consultar configuración

```bash
/opt/zimbra/libexec/zmdkimkeyutil -q -d example.com
```

## Actualizar una clave

```bash
/opt/zimbra/libexec/zmdkimkeyutil -u -d example.com
```

Después de actualizar la clave, también debes actualizar el TXT público correspondiente.

## Eliminar DKIM

```bash
/opt/zimbra/libexec/zmdkimkeyutil -r -d example.com
```

## Validar la clave publicada

```bash
/opt/zimbra/opendkim/sbin/opendkim-testkey -d example.com -s SELECTOR -x /opt/zimbra/conf/opendkim.conf
```

La guía original indica que el registro DKIM debe estar disponible tanto en las vistas DNS internas como externas cuando el diseño del entorno lo requiere.