# Let's Encrypt y Certbot en Zimbra

Guía de certificado gratuito basada en la colección histórica de OrangeBox.

## Nota de compatibilidad

**Legacy:** la fuente original usa EPEL 7 y un repositorio externo específico para Zimbra. Conservamos el procedimiento como referencia histórica; valida primero la compatibilidad con tu distribución y versión de Zimbra.

## Procedimiento original

Instalar Certbot:

```bash
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install certbot
```

El procedimiento original utilizaba `letsencrypt-zimbra` para automatizar la obtención y despliegue del certificado.

Ejemplo de configuración sanitizada:

```text
email="ADMIN@DOMINIO.TLD"
common_names=( "mail.DOMINIO.TLD" "correo.DOMINIO.TLD" )
```

Antes de renovar, hacer un backup de `/opt/zimbra/ssl/zimbra`.

## Implementación actual de la colección

El script `seguridad/certificados/certbot-zimbra.sh` contiene el procedimiento automatizado más nuevo de esta colección: detiene Zimbra, ejecuta Certbot en modo standalone, valida el certificado con `zmcertmgr`, despliega el certificado comercial y reinicia Zimbra.