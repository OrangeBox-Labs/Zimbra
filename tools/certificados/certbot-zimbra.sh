#!/bin/bash

# OrangeBox - Let's Encrypt -> Zimbra
# Certificado multidominio con Certbot standalone

set -u
set -o pipefail

DOMAINS=(
    "mail.example.com"
    "mail.example.net"
    "mail.example.org"
)

# Cuenta utilizada para registrar/renovar el certificado ACME.
CERTBOT_EMAIL="admin@example.com"

DOMAIN="${DOMAINS[0]}"
DIRECTORY="/etc/letsencrypt/live/${DOMAIN}"
ZIMBRA_DIR="/opt/zimbra/ssl/zimbra/commercial"
ZIMBRA_KEY="${ZIMBRA_DIR}/commercial.key"
BACKUP_DIR="${ZIMBRA_DIR}/backup"

CERT="${DIRECTORY}/cert.pem"
CHAIN="${DIRECTORY}/chain.pem"
PRIVKEY="${DIRECTORY}/privkey.pem"
ZIMBRA_CHAIN="/tmp/zimbra-chain-${DOMAIN}.pem"

cleanup() {
    rm -f "$ZIMBRA_CHAIN"
}
trap cleanup EXIT

echo
echo "============================================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Renovación Let's Encrypt"
echo "============================================================"

if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: este script debe ejecutarse como root."
    exit 1
fi

if [[ ! -x /usr/bin/certbot ]]; then
    echo "ERROR: no existe /usr/bin/certbot."
    exit 1
fi

if [[ -z "$CERTBOT_EMAIL" || "$CERTBOT_EMAIL" == *"example.com" ]]; then
    echo "ERROR: debes configurar CERTBOT_EMAIL con una dirección real."
    echo "Edita CERTBOT_EMAIL junto a DOMAINS antes de ejecutar el script."
    exit 1
fi

echo
echo ">>> Correo ACME: $CERTBOT_EMAIL"
echo ">>> Dominios:"
CERTBOT_DOMAINS=()
for DOMAIN_NAME in "${DOMAINS[@]}"; do
    echo "    - $DOMAIN_NAME"
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
    echo
    echo "ERROR: Certbot falló."
    echo ">>> Levantando Zimbra nuevamente..."
    su - zimbra -c "zmcontrol start" || true
    exit 1
fi

echo
echo ">>> Levantando Zimbra..."
if ! su - zimbra -c "zmcontrol start"; then
    echo "ERROR: no se pudo iniciar Zimbra."
    exit 1
fi

if [[ ! -f "$CERT" || ! -f "$CHAIN" || ! -f "$PRIVKEY" ]]; then
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
echo ">>> Cadena entregada por Certbot:"
openssl crl2pkcs7 -nocrl -certfile "$CHAIN" |
    openssl pkcs7 -print_certs -noout

echo
echo ">>> Preparando cadena compatible con Zimbra..."
awk '
/BEGIN CERTIFICATE/ { n++ }
n <= 2 { print }
/END CERTIFICATE/ && n == 2 { exit }
' "$CHAIN" > "$ZIMBRA_CHAIN"

if [[ ! -s "$ZIMBRA_CHAIN" ]]; then
    echo "ERROR: no se pudo construir la cadena para Zimbra."
    exit 1
fi

echo
echo ">>> Cadena que usará Zimbra:"
openssl crl2pkcs7 -nocrl -certfile "$ZIMBRA_CHAIN" |
    openssl pkcs7 -print_certs -noout

echo
echo ">>> Creando backup de commercial.key..."
mkdir -p "$BACKUP_DIR"
cp -a "$ZIMBRA_KEY" \
    "$BACKUP_DIR/commercial.key.$(date '+%Y%m%d-%H%M%S')"

echo
echo ">>> Instalando clave privada Let's Encrypt..."
cp -f "$PRIVKEY" "$ZIMBRA_KEY"
chown zimbra:zimbra "$ZIMBRA_KEY"
chmod 640 "$ZIMBRA_KEY"

echo
echo ">>> Verificando certificado y clave..."
if ! su - zimbra -c "
    /opt/zimbra/bin/zmcertmgr verifycrt comm \
    '$ZIMBRA_KEY' \
    '$CERT' \
    '$ZIMBRA_CHAIN'
"; then
    echo
    echo "ERROR: verifycrt falló."
    echo "NO se realizará el deploy."
    exit 1
fi

echo
echo ">>> Desplegando certificado..."
if ! su - zimbra -c "
    cd /tmp &&
    /opt/zimbra/bin/zmcertmgr deploycrt comm \
    '$CERT' \
    '$ZIMBRA_CHAIN'
"; then
    echo
    echo "ERROR: deploycrt falló."
    exit 1
fi

echo
echo ">>> Certificados desplegados:"
su - zimbra -c "/opt/zimbra/bin/zmcertmgr viewdeployedcrt all"

echo
echo ">>> Reiniciando Zimbra..."
if ! su - zimbra -c "zmcontrol restart"; then
    echo "ERROR: fallo al reiniciar Zimbra."
    exit 1
fi

echo
echo ">>> Esperando 10 segundos..."
sleep 10

echo
echo ">>> Estado de Zimbra:"
su - zimbra -c "zmcontrol status"

echo
echo "============================================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Proceso terminado"
echo "============================================================"
echo