# Verificación de dominios para Google

## Contexto

Algunos servicios de Google requieren comprobar que un dominio está bajo control del administrador mediante DNS.

## Procedimiento

1. Inicia el proceso de verificación en el servicio de Google correspondiente.
2. Publica en DNS el registro que Google indique.
3. Espera la propagación del registro.
4. Comprueba desde un resolver externo que el registro sea visible.
5. Completa la verificación en Google.

## Referencia

https://support.google.com/mail/answer/6227174?hl=es

Esta guía deriva de la nota original de la colección y no depende de un proveedor DNS concreto.