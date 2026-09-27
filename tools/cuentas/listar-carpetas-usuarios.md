# Listado de carpetas de usuarios Zimbra

## Qué hace

Obtiene el listado de carpetas (`gaf`) de cada cuenta del servidor y guarda un archivo independiente por usuario.

La herramienta está basada en la guía original que generaba un listado global de cuentas y luego consultaba cada mailbox con `zmmailbox`.

## Uso

```bash
./listar-carpetas-usuarios.sh
```

Por defecto escribe en:

```text
/tmp/LISTADO-CARPETAS/
```

Puedes cambiar el destino:

```bash
OUTPUT_DIR=/var/tmp/zimbra-carpetas ./listar-carpetas-usuarios.sh
```

## Requisitos

- Ejecutar como usuario `zimbra`.
- `zmprov` y `zmmailbox` disponibles.

## Resultado

Se crea un archivo por cuenta usando `usuario_dominio.tld.txt` como nombre seguro.