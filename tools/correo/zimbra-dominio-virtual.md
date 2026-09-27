# Dominio virtual y servidor secundario Zimbra

## Qué resuelve

Este procedimiento histórico permite mantener un dominio principal y un dominio alias para soportar un segundo servidor que recibe correo de respaldo y lo reenvía al dominio principal.

Los nombres e IP de la fuente original fueron reemplazados por valores de documentación.

## 1. DNS

Ejemplo:

```text
IN MX 0 mail.example.com.
IN MX 20 mail2.example.com.
```

Usar `192.0.2.10` y `192.0.2.20` como IP de documentación.

## 2. Dominio alias

En el servidor principal:

```bash
zmprov createAliasDomain alias.example.com example.com zimbraMailCatchAllForwardingAddress @example.com
zmprov md alias.example.com zimbraMailCatchAllAddress @alias.example.com zimbraMailCatchAllCanonicalAddress @example.com
```

## 3. Exportar cuentas

```bash
zmprov -l gaa > /tmp/usuarios.txt
```

## 4. Crear las cuentas en el secundario

```bash
while IFS= read -r cuenta; do
    zmprov ca "$cuenta" PASSWORD_INICIAL
done < /tmp/usuarios.txt
```

## 5. DNS interno

Crear la zona `alias.example.com` en el DNS interno utilizado por el secundario.

## 6. Forwarding

```bash
while IFS= read -r usuario; do
    cuenta="${usuario%@*}"
    zmprov ma "$cuenta@example.com" zimbraMailForwardingAddress "$cuenta@alias.example.com"
done < /tmp/usuarios.txt
```

## Precauciones

Este diseño modifica el flujo de correo y depende de la arquitectura DNS/MTA. Valida MX, rutas de retorno, bucles de forwarding y comportamiento ante caída del servidor principal antes de utilizarlo en producción.