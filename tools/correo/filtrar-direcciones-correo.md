# Extraer direcciones de correo desde una lista

## Qué hace

Extrae direcciones de correo desde un archivo de texto y genera una lista con el prefijo `blacklist_from`.

La guía original realizaba la extracción mediante `grep` y luego agregaba el prefijo con `sed`. La versión del repositorio además elimina duplicados y normaliza mayúsculas/minúsculas antes de generar el resultado.

## Uso

```bash
./filtrar-direcciones-correo.sh ENTRADA.txt SALIDA.txt
```

Ejemplo:

```bash
./filtrar-direcciones-correo.sh correos.txt /tmp/blacklist.txt
```

## Verificar

Revisa el archivo generado antes de incorporarlo a una política de correo.

## Importante

El script genera líneas con el formato `blacklist_from DIRECCION`. El uso posterior depende del sistema de filtrado que procese ese formato.