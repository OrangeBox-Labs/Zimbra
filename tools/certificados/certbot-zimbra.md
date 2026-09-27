# Let's Encrypt y Certbot para Zimbra

## Qué hace

Obtiene o renueva un certificado Let's Encrypt multidominio mediante Certbot en modo `standalone` y lo despliega en Zimbra usando `zmcertmgr`.

El procedimiento está basado en la herramienta original de la colección. Los dominios y el correo real se reemplazan por variables y ejemplos.

## Requisitos

- Ejecutar como `root`.
- Certbot instalado en `/usr/bin/certbot`.
- El servidor debe poder responder al desafío HTTP-01 mientras Certbot está usando `standalone`.
- Tener un backup operativo antes de modificar certificados.

## Configurar dominios

Editar el arreglo `DOMAINS` del script:

```bash
DOMAINS=(
    "mail.example.com"
    "mail.example.net"
    "mail.example.org"
)
```

Configurar el correo de Certbot opcionalmente mediante:

```bash
CERTBOT_EMAIL=admin@example.com ./certbot-zimbra.sh
```

## Ejecutar

```bash
chmod +x certbot-zimbra.sh
./certbot-zimbra.sh
```

El script detiene Zimbra para liberar los puertos que Certbot necesita, obtiene el certificado, vuelve a levantar Zimbra, verifica certificado y clave, realiza un backup de `commercial.key`, ejecuta `zmcertmgr deploycrt comm` y reinicia Zimbra.

## Verificación

Revisa:

```bash
tail -f /var/log/letsencrypt-zimbra.log
su - zimbra -c 'zmcontrol status'
```

También se muestran Subject, issuer, fechas y SAN del certificado.

## Precauciones

El proceso implica una detención de Zimbra. Programa la renovación en una ventana apropiada y verifica que todos los nombres DNS del certificado sean resolubles y accesibles.