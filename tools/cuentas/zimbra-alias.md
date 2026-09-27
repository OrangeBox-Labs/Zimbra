# Alias de correo Zimbra

## Qué hace

Crea una dirección alternativa que entrega el correo en una cuenta existente.

## Uso

```bash
./zimbra-alias.sh USUARIO@DOMINIO.TLD alias@DOMINIO.TLD
```

El script ejecuta:

```bash
zmprov aaa USUARIO@DOMINIO.TLD alias@DOMINIO.TLD
```

## Verificación

```bash
zmprov ga USUARIO@DOMINIO.TLD zimbraMailAlias
```

## Precaución

Confirma que el alias no se encuentre asignado a otra cuenta antes de crearla.