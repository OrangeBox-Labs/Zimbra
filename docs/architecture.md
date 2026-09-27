# Arquitectura del repositorio

El repositorio se organiza por familias funcionales.

```text
.
├── migracion/       # Migraciones completas y herramientas de migración
├── tools/           # Herramientas y guías operativas
│   ├── administracion/
│   ├── cuentas/
│   ├── correo/
│   ├── seguridad/
│   ├── certificados/
│   ├── troubleshooting/
│   └── instalacion/
└── docs/            # Documentación transversal
```

## Regla de herramientas

Cuando existe un script, su documentación vive junto a él y usa el mismo nombre base:

```text
tools/cuentas/reporte-uso-cuentas.sh
tools/cuentas/reporte-uso-cuentas.md
```

Las guías puramente procedimentales se mantienen como Markdown dentro de la familia correspondiente.

Los nombres de archivo no contienen clientes, dominios reales, credenciales ni datos de producción.