# Configuración de `zimbraPasswordLocked`

## Qué hace

Configura el atributo `zimbraPasswordLocked` en un Class of Service (COS).

La guía original contenía:

```bash
zmprov mc default zimbraPasswordLocked FALSE
```

El hecho importante es que el comando establece explícitamente el atributo en `FALSE`; este documento no interpreta `FALSE` como un bloqueo. Revisa el valor actual y el comportamiento esperado de tu versión antes de cambiarlo.

## Uso

Para el COS `default` y valor `FALSE`:

```bash
./zimbra-password-locked.sh
```

Para otro COS o valor:

```bash
./zimbra-password-locked.sh NOMBRE_COS TRUE
```

## Precaución

Estás modificando una política de COS y el cambio puede afectar a múltiples cuentas. Prueba primero en una cuenta o COS de laboratorio cuando corresponda.