# Administración de cuentas Zimbra

## Qué hace

Esta herramienta permite listar las cuentas que actualmente tienen privilegios administrativos y convertir una cuenta existente en administradora.

Está basada en la guía original que utiliza `zmprov gaaa` y el atributo `zimbraIsAdminAccount`.

## Requisitos

- Ejecutar como usuario `zimbra`.
- La cuenta que se convertirá en administradora debe existir.

## Listar administradores

```bash
./zimbra-admin-user.sh
```

Internamente ejecuta:

```bash
zmprov gaaa
```

## Crear una cuenta administradora

```bash
./zimbra-admin-user.sh USUARIO@DOMINIO.TLD
```

El cambio corresponde a:

```bash
zmprov ma USUARIO@DOMINIO.TLD zimbraIsAdminAccount TRUE
```

## Verificación

Ejecuta nuevamente el script sin argumentos y confirma que la cuenta aparezca en la lista.

## Precaución

Una cuenta administradora tiene privilegios elevados sobre Zimbra. Verifica la identidad de la cuenta antes de aplicar el cambio.