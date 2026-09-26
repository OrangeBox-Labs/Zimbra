# OrangeBox · Zimbra

> Herramientas Zimbra para migración, administración, backup, restore, IMAPSync, monitoreo y seguridad sobre Linux.

[![OrangeBox IT Services](https://img.shields.io/badge/OrangeBox-IT%20Services-ff6a00?style=for-the-badge)](https://www.orangebox.cl/)
[![Bash](https://img.shields.io/badge/Bash-tooling-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Zimbra](https://img.shields.io/badge/Zimbra-Collaboration-0073c6?style=for-the-badge)](https://www.zimbra.com/)

## Zimbra: migración, administración y herramientas de infraestructura

Repositorio técnico de **OrangeBox IT Services** para herramientas reutilizables de **Zimbra Collaboration Server**, especialmente en entornos Linux y migraciones de correo entre versiones.

Aquí construimos scripts para problemas reales de administración de correo: **migración de Zimbra 8.8.15 a Zimbra 10.x, exportación y restore de configuración, cuentas, passwords, aliases, forwarding, Distribution Lists, IMAPSync, backup, monitoreo y seguridad**.

Las herramientas están pensadas para administradores de sistemas, ingenieros Linux y equipos de infraestructura que necesitan procedimientos reproducibles y fáciles de auditar.

## Estructura del proyecto

```text
.
├── migracion/       # Migración Zimbra, exportación, restore e imapsync
├── backup/          # Backup y exportación futura
├── operacion/       # Administración y mantenimiento
├── monitoreo/       # Observabilidad, métricas y alertas
├── seguridad/       # Seguridad, auditoría y hardening
├── integracion/     # Integraciones con otros sistemas
└── docs/            # Documentación transversal
```

## Migración Zimbra

### zimbra-migration-export.sh

Se ejecuta en el **Zimbra origen** para rescatar configuración y generar un bundle de migración con un `restore.sh` autocontenido.

El proceso está orientado a una reconstrucción limpia en un **servidor Zimbra nuevo**, evitando depender de identificadores internos del servidor anterior.

### restore.sh

El `restore.sh` es generado automáticamente por el exportador y prioriza la información funcional de correo:

- dominios
- cuentas
- passwords
- atributos básicos portables
- cuotas
- aliases
- forwarding
- Distribution Lists y miembros

El forwarding multivaluado mediante `zimbraMailForwardingAddress` se conserva correctamente, incluyendo múltiples destinos.

Configuraciones adicionales como COS, firmas, identidades, DataSources, grants y otros atributos quedan disponibles en el bundle para revisión y futuras herramientas de restore específico.

### imapsync-migration.sh

Herramienta para migrar el contenido de los buzones mediante **IMAPSync / imapsync**, separando la migración de datos de la reconstrucción de la configuración Zimbra.

## Casos de uso

- Migración Zimbra 8.8.15 → Zimbra 10.x
- Cambio de servidor Zimbra
- Reconstrucción de una plataforma de correo
- Rescate de configuración antes de una migración
- Migración de buzones con imapsync
- Recuperación de aliases y forwarding
- Recuperación de Distribution Lists
- Automatización de tareas de administración Zimbra
- Futuras herramientas de backup, monitoreo y seguridad

## Compatibilidad

La familia de migración fue desarrollada a partir de escenarios **Zimbra 8.8.15 → Zimbra 10.x**. La compatibilidad exacta debe verificarse para cada combinación de versiones, distribución Linux y arquitectura antes de una migración productiva.

## Seguridad

Los bundles generados por las herramientas pueden contener información sensible, incluidos hashes LDAP, configuración interna, nombres de servidores y datos de clientes.

**Nunca publiques bundles reales, `passwords.ldif`, exports, logs de migración o datos de clientes en este repositorio.**

## Filosofía OrangeBox

**Infraestructura antes que magia.**

Herramientas pequeñas, reproducibles y auditables para Linux, correo empresarial y plataformas Zimbra.

## OrangeBox IT Services

Enterprise Linux · Zimbra · VMware · Monitoring · Security · Infrastructure

https://www.orangebox.cl/

### Keywords

Zimbra, Zimbra Collaboration, Zimbra Server, Zimbra 8, Zimbra 8.8.15, Zimbra 10, Zimbra migration, Zimbra backup, Zimbra restore, Zimbra administration, imapsync, IMAP migration, email server, mail server, Linux mail server, LDAP, aliases, email forwarding, distribution lists, mail infrastructure, enterprise email, correo empresarial, migración de correo, OrangeBox.