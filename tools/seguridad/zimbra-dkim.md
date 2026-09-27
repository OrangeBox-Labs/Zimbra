# DKIM en Zimbra

## Qué hace

Administra la configuración DKIM a nivel de dominio usando `zmdkimkeyutil`. La fuente original documenta cuatro operaciones: crear, actualizar, consultar y eliminar la configuración DKIM.

## Crear

```bash
./zimbra-dkim.sh add example.com
```

También puedes ejecutar directamente:

```bash
/opt/zimbra/libexec/zmdkimkeyutil -a -d example.com
```

La herramienta entrega el selector y el valor público que debe publicarse en DNS.

## Consultar

```bash
./zimbra-dkim.sh query example.com
```

## Actualizar

```bash
./zimbra-dkim.sh update example.com
```

Después de actualizar la clave debes actualizar el TXT de DNS correspondiente.

## Eliminar

```bash
./zimbra-dkim.sh remove example.com
```

## Verificar DNS

El registro público sigue la forma:

```text
SELECTOR._domainkey.example.com
```

Comprobar:

```bash
dig -t txt SELECTOR._domainkey.example.com
```

## Verificar la clave

```bash
/opt/zimbra/opendkim/sbin/opendkim-testkey -d example.com -s SELECTOR -x /opt/zimbra/conf/opendkim.conf
```

La fuente original indica que una verificación correcta puede no producir salida en consola.

## Precaución

Eliminar o rotar una clave DKIM afecta la autenticación del correo saliente. Actualiza DNS de manera coordinada y conserva la clave anterior durante el período operativo necesario.