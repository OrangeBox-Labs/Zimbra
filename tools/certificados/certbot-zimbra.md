# Let's Encrypt y Certbot para Zimbra

## Qué hace

Obtiene o renueva un certificado Let's Encrypt multidominio mediante Certbot en modo `standalone` y lo despliega en Zimbra usando `zmcertmgr`.

El script muestra todo el proceso por la salida estándar para facilitar la depuración. No redirige la ejecución a un archivo de log.

Antes de desplegar, verifica que el certificado y la clave privada coincidan y prepara una cadena compatible con `zmcertmgr` a partir de la cadena entregada por Certbot.

## Requisitos

- Ejecutar como `root`.
- Certbot instalado en `/usr/bin/certbot`.
- El servidor debe poder responder al desafío HTTP-01 mientras Certbot está usando `standalone`.
- Tener un backup operativo antes de modificar certificados.
- Zimbra debe poder detenerse y levantarse correctamente.

## Configurar dominios

Editar el arreglo `DOMAINS` del script:

```bash
DOMAINS=(
    "mail.example.com"
    "mail.example.net"
    "mail.example.org"
)
```

El primer dominio se usa como nombre del certificado y como directorio de Let's Encrypt.

Configurar el correo de Certbot:

```bash
CERTBOT_EMAIL=admin@example.com ./certbot-zimbra.sh
```

## Ejecutar

```bash
chmod +x certbot-zimbra.sh
./certbot-zimbra.sh
```

El script:

1. Detiene Zimbra para liberar los puertos usados por Certbot.
2. Obtiene o renueva el certificado con Certbot `standalone`.
3. Levanta Zimbra nuevamente.
4. Muestra Subject, issuer, fechas y SAN.
5. Muestra la cadena entregada por Certbot.
6. Construye una cadena temporal para Zimbra usando los dos primeros certificados de `chain.pem`.
7. Hace backup de `commercial.key`.
8. Instala la clave privada.
9. Ejecuta `zmcertmgr verifycrt comm`.
10. Solo si la verificación es correcta, ejecuta `zmcertmgr deploycrt comm`.
11. Reinicia Zimbra y muestra su estado.

## Cadena de certificados

Certbot puede entregar una cadena más larga que la que espera `zmcertmgr`. El script no modifica `chain.pem`; genera una copia temporal en:

```text
/tmp/zimbra-chain-<dominio>.pem
```

La cadena temporal se elimina al terminar el script.

## Verificación

La ejecución se puede depurar directamente desde la consola:

```bash
bash -x ./certbot-zimbra.sh
```

También puedes comprobar manualmente:

```bash
su - zimbra -c 'zmcontrol status'
```

El script muestra Subject, issuer, fechas, SAN y los certificados presentes en la cadena.

## Precauciones

El proceso implica una detención de Zimbra. Programa la renovación en una ventana apropiada y verifica que todos los nombres DNS del certificado sean resolubles y accesibles.

El certificado no se despliega si `zmcertmgr verifycrt comm` falla.
