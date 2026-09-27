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

```bash
export SOURCE_PASSWORD='password-origen'
export TARGET_PASSWORD='password-destino'

./imapsync-migration.sh \
  -s zimbra-viejo.example.cl \
  -t zimbra-nuevo.example.cl \
  -u usuario@example.cl
```

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

Las credenciales se proporcionan por variables de entorno o por prompt interactivo; no deben guardarse en el repositorio.
