# OrangeBox · Zimbra

> Herramientas de administración, migración, operación y seguridad para entornos Zimbra.

[![OrangeBox IT Services](https://img.shields.io/badge/OrangeBox-IT%20Services-ff6a00?style=for-the-badge)](https://www.orangebox.cl/)
[![Bash](https://img.shields.io/badge/Bash-tooling-121011?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

## Qué es

Repositorio técnico de OrangeBox IT Services para herramientas reutilizables alrededor de Zimbra: migración, operación, backup, monitoreo, seguridad e integración.

El foco es infraestructura real: scripts simples de auditar, con comportamiento explícito y documentación útil para administradores.

## Estructura

```text
.
├── migracion/       # Migración y recuperación
├── backup/          # Backup y exportación
├── operacion/       # Operación y mantenimiento
├── monitoreo/       # Monitoreo y observabilidad
├── seguridad/       # Seguridad y hardening
├── integracion/     # Integraciones
└── docs/            # Documentación transversal
```

## Migración

### zimbra-migration-export.sh

Se ejecuta en el Zimbra antiguo. Rescata configuración y genera un bundle autocontenido con un `restore.sh` para reconstruir la base funcional en el servidor nuevo.

Prioridades del restore:

- dominios
- cuentas
- passwords
- aliases
- forwarding
- Distribution Lists y miembros

El exportador también conserva información adicional —COS, firmas, identidades, DataSources, grants y configuración— como material de referencia, sin forzar atributos dependientes del nuevo servidor.

### imapsync-migration.sh

Migra el contenido de un buzón IMAP después de reconstruir la cuenta en el destino.

## Compatibilidad

La familia de migración fue desarrollada a partir de escenarios **Zimbra 8.8.15 → Zimbra 10.x**. Verifica las versiones exactas y realiza pruebas antes de una migración productiva.

## Seguridad

Los bundles de migración pueden contener hashes LDAP, configuración interna y datos de clientes.

**Nunca publiques bundles, `passwords.ldif`, logs de migración ni exports reales en este repositorio.**

## Filosofía OrangeBox

Infraestructura antes que magia: herramientas pequeñas, reproducibles y fáciles de revisar.

## OrangeBox IT Services

Enterprise Linux · Zimbra · VMware · Monitoring · Security · Infrastructure

https://www.orangebox.cl/