# Desactivar antivirus y antispam en Zimbra

Este procedimiento deshabilita los servicios `antivirus` y `antispam` para el servidor Zimbra.

## Desactivar

Ejecutar como usuario `zimbra`:

```bash
zmprov ms `zmhostname` -zimbraServiceEnabled antispam
zmprov ms `zmhostname` -zimbraServiceEnabled antivirus
```

## Volver a activar

```bash
zmprov ms `zmhostname` +zimbraServiceEnabled antispam
zmprov ms `zmhostname` +zimbraServiceEnabled antivirus
```

Desactivar estas capas reduce la protección del servicio; úsalo solamente durante una tarea que lo justifique y vuelve a habilitarlas al terminar.