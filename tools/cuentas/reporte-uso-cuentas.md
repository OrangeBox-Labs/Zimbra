# Reporte de uso de cuentas Zimbra

## Qué hace

Obtiene el listado de cuentas con `zmprov -l gaa`, consulta el tamaño de cada mailbox usando `zmmailbox gms` y genera un informe que puede enviarse por correo.

El script es una versión reutilizable de la guía original. La dirección de destino ya no está escrita dentro del código: se controla mediante `REPORT_EMAIL`.

## Requisitos

- Ejecutar como usuario `zimbra`.
- Tener disponibles `zmprov`, `zmmailbox` y el comando `mail`.

## Uso

```bash
REPORT_EMAIL=admin@DOMINIO.TLD ./reporte-uso-cuentas.sh
```

También puedes definir un directorio de trabajo:

```bash
WORKDIR=/var/tmp/zimbra-report REPORT_EMAIL=admin@DOMINIO.TLD ./reporte-uso-cuentas.sh
```

## Qué genera

- `/tmp/zimbra-mailbox-report/users.txt`: listado de cuentas.
- `/tmp/zimbra-mailbox-report/mailbox_size.txt`: informe final.

## Verificación

Revisa el informe y confirma que el destinatario haya recibido el correo.

## Nota

En servidores con muchas cuentas, la consulta se realiza una por una y puede tomar tiempo.