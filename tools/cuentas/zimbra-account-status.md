# Estados de cuenta Zimbra

## Qué hace

Permite consultar conceptualmente y cambiar el estado operativo de una cuenta Zimbra.

Los estados documentados en la fuente son:

| Estado | Descripción |
|---|---|
| `active` | Estado normal de la cuenta. |
| `maintenance` | El login se deshabilita y el correo queda en cola en el MTA. |
| `locked` | El login se deshabilita, pero el correo continúa entregándose. |
| `closed` | La cuenta queda cerrada. |
| `lockout` | Bloqueo temporal asociado a intentos fallidos de autenticación. |

## Revisar estados

```bash
zmaccts
```

## Cambiar estado

```bash
./zimbra-account-status.sh USUARIO@DOMINIO.TLD locked
```

El script ejecuta `zmprov ma` sobre `zimbraAccountStatus`.

## Precaución

El cambio de estado afecta directamente el acceso y, dependiendo del estado, el flujo de correo. Verifica la cuenta y documenta el motivo del cambio.