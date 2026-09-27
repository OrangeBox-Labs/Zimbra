# Whitelist y blacklist de remitentes

**Legacy:** la guía original modifica `amavisd.conf.in`. Revisa primero si tu versión conserva este mecanismo y si el archivo es regenerado automáticamente.

Agregar al archivo `/opt/zimbra/conf/amavisd.conf.in`:

```perl
read_hash(\%whitelist_sender, '/opt/zimbra/conf/whitelist');
read_hash(\%blacklist_sender, '/opt/zimbra/conf/blacklist');
```

Ejemplo de whitelist:

```text
example.com
```

Ejemplo de blacklist:

```text
blocked.example
```

Reiniciar Amavis:

```bash
su - zimbra -c 'zmamavisdctl restart'
```