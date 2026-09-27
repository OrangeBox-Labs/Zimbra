# Certificado comercial para Zimbra

## Qué hace

Verifica que el certificado, la clave privada y la cadena correspondan y luego despliega el certificado comercial mediante `zmcertmgr`.

## Antes de desplegar

Si recibiste un archivo PFX/PKCS#12, la guía original utilizaba OpenSSL para separar la clave, el certificado y la cadena:

```bash
openssl pkcs12 -in CERTIFICADO.pfx -nocerts -nodes -out certificado.key
openssl pkcs12 -in CERTIFICADO.pfx -clcerts -nokeys -out certificado.cer
openssl pkcs12 -in CERTIFICADO.pfx -cacerts -nokeys -chain -out cadena.cer
```

## Desplegar

```bash
./zimbra-certificado-comercial.sh certificado.crt cadena.crt commercial.key
```

El script ejecuta `verifycrt comm`, luego `deploycrt comm` y finalmente muestra el certificado desplegado.

## Crear un CSR

Ejemplo genérico basado en la guía original:

```bash
/opt/zimbra/bin/zmcertmgr createcsr comm -new -keysize 2048 -subject "/C=CL/ST=REGION/L=CIUDAD/O=EMPRESA/OU=TI/CN=mail.DOMINIO.TLD"
```

## Precauciones

No reemplaces `commercial.key` hasta haber verificado el certificado y su cadena. Mantén un backup antes del deploy.