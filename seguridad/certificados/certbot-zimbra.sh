#!/bin/bash
#
# OrangeBox - Certbot -> Zimbra
# Renovación de certificado Let's Encrypt multidominio
#

set -u

DOMAINS=(
    "mail.example.com"
    "mail.example.net"
    "mail.example.org"
)

CERTBOT_EMAIL="${CERTBOT_EMAIL:-admin@example.com}"
DOMAIN="${DOMAINS[0]}"
DIRECTORY="/etc/letsencrypt/live/${DOMAIN}"
ZIMBRA_DIR="/opt/zimbra/ssl/zimbra/commercial"
ZIMBRA_KEY="${ZIMBRA_DIR}/commercial.key"
BACKUP_DIR="${ZIMBRA_DIR}/backup"
CERT="${DIRECTORY}/cert.pem"
CHAIN="${DIRECTORY}/chain.pem"
PRIVKEY="${DIRECTORY}/privkey.pem"
LOG="/var/log/letsencrypt-zimbra.log"

exec >> "$LOG" 2>&1

echo
echo "============================================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Renovación Let's Encrypt"
echo "============================================================"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: este script debe ejecutarse como root."
    exit 1
fi

echo
echo ">>> Dominios del certificado:"
for DOMAIN_NAME in "${DOMAINS[@]}"; do
    echo "    - ${DOMAIN_NAME}"
done

if [ ! -x /usr/bin/certbot ]; then
    echo "ERROR: no existe /usr/bin/certbot"
    exit 1
fi

CERTBOT_DOMAINS=()
for DOMAIN_NAME in "${DOMAINS[@]}"; do
    CERTBOT_DOMAINS+=("-d" "$DOMAIN_NAME")
done

echo
echo ">>> Deteniendo Zimbra..."
if ! su - zimbra -c "zmcontrol stop"; then
    echo "ERROR: no se pudo detener Zimbra."
    exit 1
fi

echo
echo ">>> Ejecutando Certbot..."
if ! /usr/bin/certbot certonly \
    --expand \
    --standalone \
    -n \
    --agree-tos \
    --email "$CERTBOT_EMAIL" \
    --preferred-chain "ISRG Root X1" \
    --keep-until-expiring \
    "${CERTBOT_DOMAINS[@]}"
then
    echo "ERROR: Certbot falló."
    su - zimbra -c "zmcontrol start"
    exit 1
fi

echo
echo ">>> Levantando Zimbra..."
su - zimbra -c "zmcontrol start" || exit 1

if [ ! -f "$CERT" ] || [ ! -f "$CHAIN" ] || [ ! -f "$PRIVKEY" ]; then
    echo "ERROR: faltan archivos de Let's Encrypt."
    exit 1
fi

echo
echo ">>> Certificado Let's Encrypt:"
openssl x509 -in "$CERT" -noout -subject -issuer -dates

echo
echo ">>> SAN del certificado:"
openssl x509 -in "$CERT" -noout -ext subjectAltName

echo
echo ">>> Backup de commercial.key..."
mkdir -p "$BACKUP_DIR"
cp -a "$ZIMBRA_KEY" "$BACKUP_DIR/commercial.key.$(date '+%Y%m%d-%H%M%S')"

echo
echo ">>> Instalando clave privada..."
cp -f "$PRIVKEY" "$ZIMBRA_KEY"
chown zimbra:zimbra "$ZIMBRA_KEY"
chmod 640 "$ZIMBRA_KEY"

echo
echo ">>> Verificando certificado y clave..."
su - zimbra -c "/opt/zimbra/bin/zmcertmgr verifycrt comm '$ZIMBRA_KEY' '$CERT' '$CHAIN'" || {
    echo "ERROR: verifycrt falló. No se realizará el deploy."
    exit 1
}

echo
echo ">>> Desplegando certificado en Zimbra..."
su - zimbra -c "cd /tmp && /opt/zimbra/bin/zmcertmgr deploycrt comm '$CERT' '$CHAIN'" || {
    echo "ERROR: deploycrt falló."
    exit 1
}

echo
echo ">>> Certificados desplegados:"
su - zimbra -c "/opt/zimbra/bin/zmcertmgr viewdeployedcrt all"

echo
echo ">>> Reiniciando Zimbra..."
su - zimbra -c "zmcontrol restart" || exit 1

sleep 10
echo
echo ">>> Estado de Zimbra:"
su - zimbra -c "zmcontrol status"

echo
echo "============================================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Proceso terminado"
echo "============================================================"