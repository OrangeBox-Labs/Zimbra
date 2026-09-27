# Contribuir

## Convención de herramientas

Cada herramienta ejecutable debe tener su documentación al lado:

```text
herramienta.sh
herramienta.md
```

El Markdown debe explicar como mínimo: objetivo, contexto, requisitos, uso, verificación y precauciones.

## Calidad

- Ejecutar `bash -n` sobre todo script Bash.
- Probar en laboratorio, VM o snapshot antes de producción.
- No incluir credenciales, hashes, dumps LDAP, logs reales ni datos de clientes.
- Reemplazar dominios, correos e IP reales por valores genéricos.
- Marcar como **Legacy** todo procedimiento que dependa de una versión antigua.
- Usar mensajes de commit en español y describir el cambio concreto.