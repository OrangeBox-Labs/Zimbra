# Arquitectura del repositorio

El repositorio se organiza por familias funcionales y no por cliente.

```text
migracion/       Migración y recuperación
backup/          Backup y exportación
operacion/       Herramientas operativas
monitoreo/       Monitoreo y observabilidad
seguridad/       Seguridad y hardening
integracion/     Integraciones con otros sistemas
configuracion/   Configuración y utilidades administrativas

docs/            Documentación transversal
```

Cada familia debe contener herramientas reutilizables, documentación y ejemplos seguros.
Los datos reales de clientes, credenciales, hashes LDAP y exports nunca deben formar parte del repositorio.
