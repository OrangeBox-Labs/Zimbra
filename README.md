# OrangeBox · Zimbra

> Herramientas Zimbra para migración, administración, backup, restore, IMAPSync, monitoreo y seguridad sobre Linux.

[![OrangeBox IT Services](https://img.shields.io/badge/OrangeBox-IT%20Services-ff6a00?style=for-the-badge)](https://www.orangebox.cl/)
[![Bash](https://img.shields.io/badge/Bash-tooling-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Zimbra](https://img.shields.io/badge/Zimbra-Collaboration-0073c6?style=for-the-badge)](https://www.zimbra.com/)

## Zimbra: migración, administración y herramientas de infraestructura

Repositorio técnico de **OrangeBox IT Services** para herramientas reutilizables de **Zimbra Collaboration Server**, especialmente en entornos Linux y migraciones de correo.

El proyecto reúne scripts y procedimientos para **Zimbra 8.8.15, Zimbra 10.x, migración de correo, restore, aliases, forwarding, Distribution Lists, IMAPSync, certificados TLS, DKIM, troubleshooting y administración Linux**.

## Estructura

```text
.
├── migracion/       # Migración completa de plataformas y buzones
├── tools/           # Herramientas y guías, agrupadas por tarea
│   ├── administracion/
│   ├── cuentas/
│   ├── correo/
│   ├── seguridad/
│   ├── certificados/
│   ├── troubleshooting/
│   └── instalacion/
└── docs/            # Arquitectura y contribución
```

## Regla simple

Cada herramienta ejecutable mantiene su script y su documentación juntos:

```text
tools/cuentas/reporte-uso-cuentas.sh
tools/cuentas/reporte-uso-cuentas.md
```

Así no tienes que buscar una guía en otro directorio para entender un script.

## Migración Zimbra

La familia `migracion/` contiene el exportador de configuración, generación automática de `restore.sh` e integración con `imapsync`.

El restore base prioriza dominios, cuentas, passwords, aliases, forwarding y Distribution Lists. El forwarding multivaluado mediante `zimbraMailForwardingAddress` se conserva incluyendo múltiples destinos.

## Seguridad

Los bundles de migración pueden contener hashes LDAP, configuración interna y datos de clientes.

**Nunca publiques bundles, `passwords.ldif`, exports, logs reales ni datos de producción.**

## Filosofía OrangeBox

**Infraestructura antes que magia.**

Herramientas pequeñas, reproducibles y auditables para Linux, correo empresarial y plataformas Zimbra.

## OrangeBox IT Services

Enterprise Linux · Zimbra · VMware · Monitoring · Security · Infrastructure

https://www.orangebox.cl/