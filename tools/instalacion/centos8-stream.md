# CentOS 8 Stream y compatibilidad con instaladores antiguos

**Legacy / workaround histórico.**

La guía original registraba un instalador que identificaba el sistema como `UNKNOWN64`. El workaround documentado consistía en reemplazar `Stream` por `Linux` en archivos `/etc/redhat-release` para conseguir que el instalador continuara.

## Importante

Este cambio altera la identificación declarada del sistema operativo y puede afectar otras herramientas.

Se conserva únicamente como referencia de troubleshooting para instaladores antiguos. No debe aplicarse sin probar el impacto en el entorno.