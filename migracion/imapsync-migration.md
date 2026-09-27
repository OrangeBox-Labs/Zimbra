# Migración de buzones con IMAPSync

`imapsync-migration.sh` migra una cuenta IMAP desde el Zimbra antiguo al nuevo usando `imapsync`.

## Política de attachments

Por defecto, la migración **no descarta mensajes completos**.

Cada mensaje se entrega por `--pipemess` al filtro:

```
imapsync-strip-large-attachments.py
```

El filtro elimina solamente los attachments con tamaño **mayor a 5 MiB**. Los attachments de 5 MiB o menos se conservan.

La detección sigue la lógica utilizada por `zimbra_attachment_scan.py`:

- `Content-Disposition: attachment`.
- O existencia de `filename` / `name`.

El tamaño se calcula sobre el contenido decodificado del MIME.

### Ejemplo

Un mensaje con:

```
informe.pdf   2.1 MiB
foto.jpg      800 KiB
respaldo.zip  18.7 MiB
```

llega al Zimbra nuevo con `informe.pdf` y `foto.jpg`; `respaldo.zip` se elimina del MIME del mensaje.

El mensaje completo, sus headers y el cuerpo no se descartan por superar el límite.

## Auditoría

Cada attachment eliminado se registra en:

```
logs/large-attachments.csv
```

Se registran, entre otros:

- `Message-ID`
- asunto
- número MIME de la parte
- MIME type
- nombre de archivo
- tamaño
- umbral
- acción

El filtro también informa por STDERR para que el evento quede visible en la ejecución de `imapsync`.

## Fail closed

Si el filtro no puede parsear el mensaje o determinar el tamaño de una parte candidata, termina con código distinto de cero.

La intención es evitar copiar silenciosamente un mensaje transformado de forma incompleta.

## Ejecución

### Batch paralelo

Configura en `imapsync-migration-batch.sh` las variables de conexión y las passwords administrativas:

```bash
SOURCE_HOST="zimbra-viejo.example.cl"
TARGET_HOST="zimbra-nuevo.example.cl"
SOURCE_ADMIN="admin@example.cl"
SOURCE_ADMIN_PASSWORD="password-origen"
TARGET_ADMIN="admin@example.cl"
TARGET_ADMIN_PASSWORD="password-destino"
USERS_FILE="/root/imapsync-users.txt"
PARALLEL=8
THRESHOLD_MIB=5
```

El batch no solicita passwords por consola. Internamente las entrega a IMAPSync mediante `IMAPSYNC_PASSWORD1` y `IMAPSYNC_PASSWORD2` para utilizar la autenticación administrativa de Zimbra.

Luego ejecuta:

```bash
./imapsync-migration-batch.sh \
  -p 1
```

Para una ejecución controlada desde la línea de comandos también pueden sobrescribirse los parámetros soportados por el script, por ejemplo `-s`, `-t`, `-a`, `-b` y `-f`.

### Migración individual

El script `imapsync-migration.sh` mantiene su flujo independiente y actualmente utiliza autenticación directa de la cuenta mediante `SOURCE_PASSWORD` y `TARGET_PASSWORD`.

El umbral predeterminado es 5 MiB:

```bash
./imapsync-migration.sh \
  -s zimbra-viejo.example.cl \
  -t zimbra-nuevo.example.cl \
  -u usuario@example.cl \
  --threshold-mib 5
```

Para desactivar temporalmente el filtro:

```bash
./imapsync-migration.sh \
  -s zimbra-viejo.example.cl \
  -t zimbra-nuevo.example.cl \
  -u usuario@example.cl \
  --no-attachment-filter
```

## Prueba previa

Antes de una migración masiva se recomienda probar el filtro de forma aislada con un mensaje RFC822 conocido:

```bash
cat mensaje.eml | \
  ./imapsync-strip-large-attachments.py \
  --threshold-mib 5 \
  --log ./logs/large-attachments-test.csv \
  > mensaje-filtrado.eml
```

Luego validar el MIME resultante y comprobar que:

- el cuerpo permanece presente;
- los attachments pequeños permanecen;
- los attachments grandes desaparecen;
- los headers principales permanecen;
- el CSV registra la eliminación.

## Consideraciones

La eliminación se hace **antes de entregar el mensaje al Zimbra nuevo**, no después de almacenarlo en el buzón destino.

El tráfico entre ambos servidores no se utiliza como criterio de descarte. La red entre Zimbra viejo y nuevo puede transportar temporalmente el mensaje completo; la política determina qué contenido termina persistiendo en el destino.

El batch paralelo utiliza las variables `SOURCE_ADMIN_PASSWORD` y `TARGET_ADMIN_PASSWORD` definidas en el propio script y no solicita credenciales por consola. Para mantener las credenciales fuera de Git, configura esos valores solamente en la copia local del servidor donde ejecutarás la migración y no hagas commit de las passwords reales.
