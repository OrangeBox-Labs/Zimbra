# Extraer direcciones de correo desde una lista

Permite extraer direcciones de correo desde un archivo de texto para luego convertirlas en una lista utilizada por controles de correo.

## Extraer direcciones

```bash
grep -E -o '\b[a-zA-Z0-9.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+\b' ARCHIVO.txt > /tmp/blacklist.txt
```

## Agregar prefijo

```bash
sed -i 's/^/blacklist_from /' /tmp/blacklist.txt
```

El archivo de entrada debe ser revisado antes de usar el resultado en una política de filtrado.