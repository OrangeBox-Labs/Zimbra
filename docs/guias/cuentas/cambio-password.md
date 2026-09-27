# Configuración de cambio de contraseña

La guía original contiene esta modificación sobre el COS `default`:

```bash
zmprov mc default zimbraPasswordLocked FALSE
```

Esta instrucción establece explícitamente el atributo en `FALSE`. Antes de aplicarla, revisa el valor actual y confirma que ese es el comportamiento requerido para tu entorno.