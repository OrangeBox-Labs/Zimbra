#!/bin/bash

# OrangeBox - Let's Encrypt -> Zimbra
# Certificado multidominio con Certbot standalone

set -u
set -o pipefail

# ============================================================
# CONFIGURACION
# ============================================================

DOMAINS=(
    "mail.example.com"
    "mail.example.net"
    "mail.example.org"
)

CERTBOT_EMAIL="admin@example.com"

# Renovar solamente cuando falten menos de estos dias.
RENEWAL_DAYS=30

DOMAIN="${DOMAINS[0]}"
DIRECTORY="/etc/letsencrypt/live/${DOMAIN}"
ZIMBRA_DIR="/opt/zimbra/ssl/zimbra/commercial"
ZIMBRA_KEY="${ZIMBRA_DIR}/commercial.key"
BACKUP_DIR="${ZIMBRA_DIR}/backup"

CERT="${DIRECTORY}/cert.pem"
FULLCHAIN="${DIRECTORY}/fullchain.pem"
CHAIN="${DIRECTORY}/chain.pem"
PRIVKEY="${DIRECTORY}/privkey.pem"

# Zimbra debe poder leer estos archivos como usuario zimbra.
ZIMBRA_CERT="/tmp/zimbra-cert-${DOMAIN}.pem"
ZIMBRA_CHAIN="/tmp/zimbra-chain-${DOMAIN}.pem"
ISRG_ROOT_X1="/tmp/ISRG-Root-X1.pem"

ZIMBRA_STOPPED=0

cleanup() {
    rm -f "$ZIMBRA_CERT" "$ZIMBRA_CHAIN"
}
trap cleanup EXIT

# ============================================================
# FUNCIONES
# ============================================================

start_zimbra() {
    if [[ "$ZIMBRA_STOPPED" -eq 1 ]]; then
        echo
        echo ">>> Levantando Zimbra..."
        if ! su - zimbra -c "zmcontrol start"; then
            echo "ERROR: no se pudo iniciar Zimbra."
            exit 1
        fi
        ZIMBRA_STOPPED=0
    fi
}

stop_zimbra() {
    echo
    echo ">>> Deteniendo Zimbra..."
    if ! su - zimbra -c "zmcontrol stop"; then
        echo "ERROR: no se pudo detener Zimbra."
        exit 1
    fi
    ZIMBRA_STOPPED=1
}

# ============================================================
# INICIO
# ============================================================

echo
echo "============================================================"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Let's Encrypt -> Zimbra"
echo "============================================================"

if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: este script debe ejecutarse como root."
    exit 1
fi

if [[ ! -x /usr/bin/certbot ]]; then
    echo "ERROR: no existe /usr/bin/certbot."
    exit 1
fi

if [[ -z "$CERTBOT_EMAIL" ]]; then
    echo "ERROR: CERTBOT_EMAIL está vacío."
    exit 1
fi

echo
echo ">>> Cuenta ACME: $CERTBOT_EMAIL"
echo ">>> Dominios del certificado:"

CERTBOT_DOMAINS=()
for DOMAIN_NAME in "${DOMAINS[@]}"; do
    echo "    - $DOMAIN_NAME"
    CERTBOT_DOMAINS+=("-d" "$DOMAIN_NAME")
done

# ============================================================
# COMPROBAR SI HAY QUE RENOVAR
# ============================================================

NEEDS_CERTBOT=1

if [[ -f "$CERT" ]]; then
    echo
echo ">>> Certificado existente encontrado."

    if openssl x509 -in "$CERT" -noout -checkend "$((RENEWAL_DAYS * 86400))" >/dev/null 2>&1; then
        echo ">>> El certificado todavía es válido por más de ${RENEWAL_DAYS} días."
        echo ">>> NO se ejecutará Certbot y NO se detendrá Zimbra."
        NEEDS_CERTBOT=0
    else
        echo ">>> El certificado vence dentro de ${RENEWAL_DAYS} días."
        echo ">>> Se solicitará renovación."
    fi
else
    echo
echo ">>> No existe certificado local. Se solicitará uno nuevo."
fi

# ============================================================
# CERTBOT SOLO CUANDO ES NECESARIO
# ============================================================

if [[ "$NEEDS_CERTBOT" -eq 1 ]]; then
    stop_zimbra

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
        start_zimbra
        exit 1
    fi

    start_zimbra
else
    echo
echo ">>> Zimbra permanece funcionando."
fi

# ============================================================
# COMPROBAR ARCHIVOS
# ============================================================

if [[ ! -f "$CERT" || ! -f "$CHAIN" || ! -f "$FULLCHAIN" || ! -f "$PRIVKEY" ]]; then
    echo "ERROR: faltan archivos de Let's Encrypt."
    exit 1
fi

# ============================================================
# INFORMACION DEL CERTIFICADO
# ============================================================

echo
echo ">>> Certificado Let's Encrypt:"
openssl x509 -in "$CERT" -noout -subject -issuer -dates

echo
echo ">>> SAN del certificado:"
openssl x509 -in "$CERT" -noout -ext subjectAltName

echo
echo ">>> Cadena entregada por Certbot:"
openssl crl2pkcs7 -nocrl -certfile "$CHAIN" | \
    openssl pkcs7 -print_certs -noout

# ============================================================
# PREPARAR CERTIFICADO PARA ZIMBRA
# ============================================================

# No usamos los symlinks de /etc/letsencrypt directamente con zmcertmgr:
# el proceso corre como zimbra y normalmente no puede atravesar /etc/letsencrypt.

echo
echo ">>> Copiando certificado a /tmp para Zimbra..."
cp -f "$CERT" "$ZIMBRA_CERT"
chmod 644 "$ZIMBRA_CERT"

# Zimbra valida la cadena con OpenSSL. Las cadenas nuevas de Let's Encrypt
# pueden terminar en Root YE -> ISRG Root X2 -> ISRG Root X1.
# El Root X1 se agrega explícitamente para que zmcertmgr pueda cerrar la cadena.

echo
echo ">>> Obteniendo ISRG Root X1..."
if ! curl -fsSL \
    "https://letsencrypt.org/certs/isrgrootx1.pem" \
    -o "$ISRG_ROOT_X1"; then
    echo "ERROR: no se pudo obtener ISRG Root X1."
    exit 1
fi

chmod 644 "$ISRG_ROOT_X1"

# Importante: chain.pem NO contiene el certificado del servidor.
# Para zmcertmgr necesitamos solamente la CA chain.
echo
echo ">>> Preparando cadena compatible con Zimbra..."
cat "$CHAIN" "$ISRG_ROOT_X1" > "$ZIMBRA_CHAIN"
chmod 644 "$ZIMBRA_CHAIN"

echo
echo ">>> Cadena que usará Zimbra:"
openssl crl2pkcs7 -nocrl -certfile "$ZIMBRA_CHAIN" | \
    openssl pkcs7 -print_certs -noout

# Comprobación independiente antes de entregársela a zmcertmgr.
echo
echo ">>> Verificando cadena con OpenSSL..."
if ! openssl verify \
    -CAfile "$ISRG_ROOT_X1" \
    -untrusted "$CHAIN" \
    "$ZIMBRA_CERT"; then
    echo "ERROR: la cadena Let's Encrypt no valida contra ISRG Root X1."
    exit 1
fi

# ============================================================
# BACKUP E INSTALACION DE LA CLAVE
# ============================================================

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

# ============================================================
# VERIFYCRT
# ============================================================

echo
echo ">>> Verificando certificado y clave..."

if ! su - zimbra -c "
    /opt/zimbra/bin/zmcertmgr verifycrt comm \
    '$ZIMBRA_KEY' \
    '$ZIMBRA_CERT' \
    '$ZIMBRA_CHAIN'
"; then
    echo
echo "ERROR: verifycrt falló."
    echo "NO se realizará el deploy."
    exit 1
fi

# ============================================================
# DEPLOY
# ============================================================

echo
echo ">>> Desplegando certificado..."

if ! su - zimbra -c "
    cd /tmp &&
    /opt/zimbra/bin/zmcertmgr deploycrt comm \
    '$ZIMBRA_CERT' \
    '$ZIMBRA_CHAIN'
"; then
    echo
echo "ERROR: deploycrt falló."
    exit 1
fi

# ============================================================
# RESULTADO
# ============================================================

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