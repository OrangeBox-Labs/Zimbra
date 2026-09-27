# Certificado autofirmado en Zimbra

## Qué hace

Automatiza la secuencia histórica de creación de una CA local, generación de un certificado y despliegue mediante `zmcertmgr`.

## Uso

```bash
./zimbra-autofirmado.sh
```

Para otra vigencia:

```bash
DAYS=365 ./zimbra-autofirmado.sh
```

## Secuencia

1. `createca -new` crea una nueva CA.
2. `deployca` despliega la CA.
3. `createcrt -new -days` genera el certificado.
4. `deploycrt self` lo instala.
5. `viewdeployedcrt` verifica el despliegue.
6. `zmcontrol restart` aplica el cambio.

## Precaución

Es un certificado autofirmado. Los clientes deben confiar explícitamente en la CA si se quiere evitar advertencias TLS.