# Certificado autofirmado en Zimbra

Procedimiento conservado de la guía original.

## 1. Crear una nueva CA

Este paso se indica como opcional cuando ya existe una CA funcional.

```bash
/opt/zimbra/bin/zmcertmgr createca -new
/opt/zimbra/bin/zmcertmgr deployca
```

## 2. Crear el certificado

```bash
/opt/zimbra/bin/zmcertmgr createcrt -new -days 365
```

## 3. Desplegar

```bash
/opt/zimbra/bin/zmcertmgr deploycrt self
```

## 4. Verificar

```bash
/opt/zimbra/bin/zmcertmgr viewdeployedcrt
```

## 5. Reiniciar Zimbra

```bash
su - zimbra -c 'zmcontrol restart'
```

Valida siempre el procedimiento con la versión de Zimbra instalada antes de ejecutarlo en producción.