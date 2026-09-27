# Estados de cuenta en Zimbra

| Estado | Descripción |
|---|---|
| `active` | Estado normal de la cuenta. |
| `maintenance` | Login deshabilitado y el correo queda en cola en el MTA. |
| `locked` | Login deshabilitado, pero el correo continúa entregándose. |
| `closed` | Cuenta cerrada; la guía original la describe como eliminación lógica. |
| `lockout` | Bloqueo temporal asociado a intentos fallidos de autenticación. |

## Revisar estados

```bash
zmaccts
```

## Cambiar estado

```bash
zmprov ma USUARIO@DOMINIO.TLD zimbraAccountStatus lockout
zmprov ma USUARIO@DOMINIO.TLD zimbraAccountStatus active
zmprov ma USUARIO@DOMINIO.TLD zimbraAccountStatus closed
```