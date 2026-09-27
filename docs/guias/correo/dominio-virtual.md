# Dominio virtual y servidor secundario Zimbra

Este procedimiento describe un escenario donde un dominio alias permite mantener las mismas cuentas en un servidor secundario y reenviar el correo hacia el dominio principal.

Los dominios e IP originales fueron reemplazados por valores de documentación.

## 1. DNS

Ejemplo con MX principal y secundario:

```text
IN MX 0 mail.example.com.
IN MX 20 mail2.example.com.
```

Direcciones reservadas para documentación: `192.0.2.10` y `192.0.2.20`.

## 2. Crear el dominio alias

En el servidor principal:

```bash
zmprov createAliasDomain alias.example.com example.com zimbraMailCatchAllForwardingAddress @example.com
```

Enmascarar el dominio alias como el original:

```bash
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

Crear una zona para `alias.example.com` en el DNS interno utilizado por el secundario.

Ejemplo:

```text
zone "alias.example.com" IN {
    type master;
    file "alias.example.com.zone";
    allow-update { none; };
};
```

## 6. Zona del dominio alias

```text
IN MX 0 mail.alias.example.com.
mail IN A 192.0.2.10
```

## 7. Forwarding

```bash
while IFS= read -r usuario; do
    cuenta="${usuario%@*}"
    zmprov ma "$cuenta@example.com" zimbraMailForwardingAddress "$cuenta@alias.example.com"
done < /tmp/usuarios.txt
```

Revisa cuidadosamente el flujo de correo y los MX antes de usar este esquema en producción.