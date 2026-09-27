# Herramientas Zimbra

Este directorio contiene las herramientas ejecutables y sus documentos asociados.

**Regla del proyecto:** cuando una herramienta tiene script, el `*.sh` y su `*.md` viven juntos y comparten el mismo nombre.

## Familias

- `administracion/` — administración de cuentas y configuración.
- `cuentas/` — cuentas, aliases, estados y buzones.
- `correo/` — listas de correo, forwarding, DNS y controles de Postfix.
- `seguridad/` — DKIM, antispam y controles de seguridad.
- `certificados/` — Let's Encrypt, certificados comerciales y autofirmados.
- `troubleshooting/` — diagnóstico y reparación.
- `instalacion/` — procedimientos de instalación y compatibilidad histórica.

## Convención

```text
tools/cuentas/
├── zimbra-alias.sh
├── zimbra-alias.md
├── zimbra-account-status.sh
└── zimbra-account-status.md
```

Los nombres de archivo describen la tarea. La documentación explica qué hace la herramienta, requisitos, procedimiento, verificación y precauciones.