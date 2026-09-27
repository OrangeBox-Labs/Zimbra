# Activar o desactivar antivirus y antispam

## Qué hace

Modifica los servicios `antispam` y `antivirus` asociados al servidor Zimbra mediante `zimbraServiceEnabled`.

## Desactivar

```bash
./zimbra-desactivar-av-antispam.sh disable
```

## Activar nuevamente

```bash
./zimbra-desactivar-av-antispam.sh enable
```

## Precaución

Desactivar estos servicios reduce las capas de protección del correo. La fuente original documenta este procedimiento como una acción operativa puntual; vuelve a habilitarlos una vez terminada la tarea que motivó el cambio.