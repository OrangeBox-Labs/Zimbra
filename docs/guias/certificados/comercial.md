# Certificado comercial para Zimbra

Procedimiento para convertir un certificado PKCS#12 y desplegar un certificado comercial mediante `zmcertmgr`.

## Convertir un archivo PFX

```bash
openssl pkcs12 -in CERTIFICADO.pfx -nocerts -nodes -out certificado.key
openssl pkcs12 -in CERTIFICADO.pfx -clcerts -nokeys -out certificado.cer
openssl pkcs12 -in CERTIFICADO.pfx -cacerts -nokeys -chain -out cadena.cer
```

## Crear CSR

Ejemplo sanitizado:

```bash
/opt/zimbra/bin/zmcertmgr createcsr comm -new -keysize 2048 -subject "/C=CL/ST=REGION/L=CIUDAD/O=EMPRESA/OU=TI/CN=mail.DOMINIO.TLD"
```

## Archivos

Colocar el certificado del servidor y la cadena en `/opt/zimbra/ssl/zimbra/commercial/`.

## Verificar

```bash
cd /opt/zimbra/ssl/zimbra/commercial/
/opt/zimbra/bin/zmcertmgr verifycrt comm commercial.key certificado.crt cadena.crt
```

## Desplegar

```bash
/opt/zimbra/bin/zmcertmgr deploycrt comm certificado.crt cadena.crt
```

## Verificar despliegue

```bash
/opt/zimbra/bin/zmcertmgr viewdeployedcrt
```

La guía original incluía referencias externas a proveedores como DigiCert y AlphaSSL; se mantienen como referencias conceptuales, no como requisitos.