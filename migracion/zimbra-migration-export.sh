#!/bin/bash
#
# OrangeBox - Zimbra Migration Export
#
# SOURCE:
#   Zimbra 8.8.15
#
# TARGET:
#   Zimbra 10.x
#
# Exporta:
#   - Dominios
#   - Cuentas
#   - Aliases
#   - Distribution Lists
#   - Miembros de DL
#   - Calendar Resources
#   - COS
#   - Password hashes LDAP
#   - Firmas
#   - Identidades
#   - DataSources
#   - Grants
#   - Account attributes
#   - Domain attributes
#   - COS attributes
#
# NO exporta correo.
# El correo será migrado posteriormente mediante imapsync.
#
# IMPORTANTE:
#   - No elimina nada.
#   - No modifica cuentas.
#   - No toca MariaDB.
#   - No toca /opt/zimbra/store.
#

set -uo pipefail

ZMPROV="/opt/zimbra/bin/zmprov"
ZMAILBOX="/opt/zimbra/bin/zmmailbox"
ZMLLOCAL="/opt/zimbra/bin/zmlocalconfig"
LDAPSEARCH="/opt/zimbra/common/bin/ldapsearch"

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
BASE_DIR="/root/zimbra-migration-${TIMESTAMP}"

DOMAINS_DIR="${BASE_DIR}/domains"
ACCOUNTS_DIR="${BASE_DIR}/accounts"
ALIASES_DIR="${BASE_DIR}/aliases"
DL_DIR="${BASE_DIR}/distribution-lists"
RESOURCES_DIR="${BASE_DIR}/resources"
COS_DIR="${BASE_DIR}/cos"
SIGNATURES_DIR="${BASE_DIR}/signatures"
IDENTITIES_DIR="${BASE_DIR}/identities"
DATASOURCES_DIR="${BASE_DIR}/datasources"
GRANTS_DIR="${BASE_DIR}/grants"
RAW_DIR="${BASE_DIR}/raw"

mkdir -p \
    "$DOMAINS_DIR" \
    "$ACCOUNTS_DIR" \
    "$ALIASES_DIR" \
    "$DL_DIR" \
    "$RESOURCES_DIR" \
    "$COS_DIR" \
    "$SIGNATURES_DIR" \
    "$IDENTITIES_DIR" \
    "$DATASOURCES_DIR" \
    "$GRANTS_DIR" \
    "$RAW_DIR"

LOG="${BASE_DIR}/export.log"

exec > >(tee -a "$LOG") 2>&1

echo
echo "============================================================"
echo " OrangeBox - Zimbra Migration Export"
echo "============================================================"
echo
echo "Destino: $BASE_DIR"
echo

if [[ "$(id -un)" != "zimbra" && "$(id -u)" != "0" ]]; then
    echo "ERROR: ejecutar como root o zimbra."
    exit 1
fi

if [[ ! -x "$ZMPROV" ]]; then
    echo "ERROR: no existe $ZMPROV"
    exit 1
fi

echo "[1/12] Detectando configuración LDAP..."

LDAP_MASTER="$("$ZMLLOCAL" -m nokey -s ldap_master_url 2>/dev/null || true)"
LDAP_ROOT="$("$ZMLLOCAL" -m nokey -s ldap_root_password 2>/dev/null || true)"

echo "$LDAP_MASTER" > "$BASE_DIR/ldap-master-url.txt"

echo
echo "LDAP master: $LDAP_MASTER"
echo

#
# ------------------------------------------------------------
# 1. DOMAINS
# ------------------------------------------------------------
#

echo "[2/12] Exportando dominios..."

"$ZMPROV" -l gad > "$BASE_DIR/domains.txt"

while IFS= read -r DOMAIN; do
    [[ -z "$DOMAIN" ]] && continue

    echo "  -> $DOMAIN"

    SAFE_DOMAIN="${DOMAIN//\//_}"

    "$ZMPROV" -l gd "$DOMAIN" \
        > "$DOMAINS_DIR/${SAFE_DOMAIN}.txt" 2>&1

done < "$BASE_DIR/domains.txt"


#
# ------------------------------------------------------------
# 2. COS
# ------------------------------------------------------------
#

echo "[3/12] Exportando COS..."

"$ZMPROV" -l gac > "$BASE_DIR/cos.txt"

while IFS= read -r COS; do
    [[ -z "$COS" ]] && continue

    echo "  -> $COS"

    SAFE_COS="$(echo "$COS" | tr '/ ' '__')"

    "$ZMPROV" -l gc "$COS" \
        > "$COS_DIR/${SAFE_COS}.txt" 2>&1

done < "$BASE_DIR/cos.txt"


#
# ------------------------------------------------------------
# 3. ACCOUNTS
# ------------------------------------------------------------
#

echo "[4/12] Exportando cuentas..."

"$ZMPROV" -l gaa > "$BASE_DIR/accounts.txt"

ACCOUNT_COUNT=0

while IFS= read -r ACCOUNT; do

    [[ -z "$ACCOUNT" ]] && continue

    #
    # Ignorar cuentas internas de Zimbra
    #
    case "$ACCOUNT" in
        galsync.*)
            continue
            ;;
        virus-quarantine.*)
            continue
            ;;
        spam.*)
            continue
            ;;
        ham.*)
            continue
            ;;
    esac

    ACCOUNT_COUNT=$((ACCOUNT_COUNT + 1))

    echo "  -> $ACCOUNT"

    SAFE_ACCOUNT="${ACCOUNT//@/_}"

    #
    # Todos los atributos del account.
    #
    "$ZMPROV" -l ga "$ACCOUNT" \
        > "$ACCOUNTS_DIR/${SAFE_ACCOUNT}.txt" 2>&1

    #
    # Alias explícitos.
    #
    "$ZMPROV" -l ga "$ACCOUNT" zimbraMailAlias \
        > "$ALIASES_DIR/${SAFE_ACCOUNT}.txt" 2>&1

    #
    # Signatures.
    #
    "$ZMPROV" -l gsig "$ACCOUNT" \
        > "$SIGNATURES_DIR/${SAFE_ACCOUNT}.txt" 2>&1

    #
    # Identities.
    #
    "$ZMPROV" -l gid "$ACCOUNT" \
        > "$IDENTITIES_DIR/${SAFE_ACCOUNT}.txt" 2>&1

    #
    # DataSources.
    #
    "$ZMPROV" -l gds "$ACCOUNT" \
        > "$DATASOURCES_DIR/${SAFE_ACCOUNT}.txt" 2>&1

    #
    # Grants.
    #
    "$ZMPROV" -l ggr "$ACCOUNT" \
        > "$GRANTS_DIR/${SAFE_ACCOUNT}.txt" 2>&1

done < "$BASE_DIR/accounts.txt"

echo
echo "Cuentas exportadas: $ACCOUNT_COUNT"


#
# ------------------------------------------------------------
# 4. PASSWORDS
# ------------------------------------------------------------
#

echo "[5/12] Exportando hashes LDAP de passwords..."

PASSWORD_LDIF="$BASE_DIR/passwords.ldif"

: > "$PASSWORD_LDIF"

while IFS= read -r ACCOUNT; do

    [[ -z "$ACCOUNT" ]] && continue

    case "$ACCOUNT" in
        galsync.*|virus-quarantine.*|spam.*|ham.*)
            continue
            ;;
    esac

    USER="${ACCOUNT%@*}"
    DOMAIN="${ACCOUNT#*@}"

    DOMAIN_DN=""

    IFS='.' read -ra PARTS <<< "$DOMAIN"

    for PART in "${PARTS[@]}"; do
        DOMAIN_DN="${DOMAIN_DN},dc=${PART}"
    done

    DOMAIN_DN="${DOMAIN_DN#,}"

    DN="uid=${USER},ou=people,${DOMAIN_DN}"

    #
    # Obtener únicamente userPassword en formato LDIF.
    #
    PASS_LINE="$(
        "$ZMPROV" -l ga "$ACCOUNT" userPassword 2>/dev/null \
        | awk -F': ' '/^userPassword:: / {sub(/^userPassword:: /, ""); print; exit}'
    )"

    #
    # Si Zimbra entrega userPassword: en lugar de ::,
    # convertirlo a base64 para mantener SIEMPRE el formato
    # solicitado.
    #
    if [[ -z "$PASS_LINE" ]]; then

        PLAINTEXT_HASH="$(
            "$ZMPROV" -l ga "$ACCOUNT" userPassword 2>/dev/null \
            | awk -F': ' '/^userPassword: / {print $2; exit}'
        )"

        if [[ -n "$PLAINTEXT_HASH" ]]; then
            PASS_LINE="$(
                printf '%s' "$PLAINTEXT_HASH" | base64 -w0
            )"
        fi
    fi

    #
    # Si no hay password, dejar el atributo vacío.
    #
    if [[ -n "$PASS_LINE" ]]; then

        cat >> "$PASSWORD_LDIF" <<EOF
dn: ${DN}
changetype: modify
replace: userPassword
userPassword:: ${PASS_LINE}

EOF

    else

        cat >> "$PASSWORD_LDIF" <<EOF
dn: ${DN}
changetype: modify
replace: userPassword
userPassword:

EOF

    fi

done < "$BASE_DIR/accounts.txt"


#
# ------------------------------------------------------------
# 5. DISTRIBUTION LISTS
# ------------------------------------------------------------

echo "[6/12] Exportando Distribution Lists..."

"$ZMPROV" -l gadl > "$BASE_DIR/distribution-lists.txt"

while IFS= read -r DL; do

    [[ -z "$DL" ]] && continue

    echo "  -> $DL"

    SAFE_DL="${DL//@/_}"

    "$ZMPROV" -l gdl "$DL" \
        > "$DL_DIR/${SAFE_DL}.details" 2>&1

    "$ZMPROV" -l gdlm "$DL" \
        > "$DL_DIR/${SAFE_DL}.members" 2>&1

done < "$BASE_DIR/distribution-lists.txt"


#
# ------------------------------------------------------------
# 6. CALENDAR RESOURCES
# ------------------------------------------------------------
#

echo "[7/12] Exportando Calendar Resources..."

"$ZMPROV" -l gacr > "$BASE_DIR/resources.txt"

while IFS= read -r RESOURCE; do

    [[ -z "$RESOURCE" ]] && continue

    echo "  -> $RESOURCE"

    SAFE_RESOURCE="${RESOURCE//@/_}"

    "$ZMPROV" -l gcr "$RESOURCE" \
        > "$RESOURCES_DIR/${SAFE_RESOURCE}.txt" 2>&1

done < "$BASE_DIR/resources.txt"


#
# ------------------------------------------------------------
# 7. SERVER / GLOBAL CONFIG REFERENCE
# ------------------------------------------------------------

echo "[8/12] Guardando referencia de configuración..."

"$ZMPROV" -l gas \
    > "$RAW_DIR/servers.txt" 2>&1

"$ZMPROV" -l gacf \
    > "$RAW_DIR/global-config.txt" 2>&1


#
# ------------------------------------------------------------
# 8. VERSION / SYSTEM INFO
# ------------------------------------------------------------

echo "[9/12] Guardando información del sistema..."

{
    echo "DATE:"
    date

    echo
    echo "HOSTNAME:"
    hostname -f

    echo
    echo "ZIMBRA VERSION:"
    "$ZMPROV" -l gsas 2>/dev/null || true

    echo
    echo "ZMCONTROL:"
    /opt/zimbra/bin/zmcontrol -v 2>/dev/null || true

    echo
    echo "SERVERS:"
    "$ZMPROV" -l gas 2>/dev/null || true

} > "$RAW_DIR/system-info.txt"


#
# ------------------------------------------------------------
# 9. GENERATE RESTORE SCRIPT
# ------------------------------------------------------------

echo "[10/12] Generando restore.sh..."

cat > "$BASE_DIR/restore.sh" <<'RESTORE'
#!/bin/bash

set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

ZMPROV="/opt/zimbra/bin/zmprov"
LDAPMODIFY="/opt/zimbra/common/bin/ldapmodify"

LOG="${BASE_DIR}/restore.log"

exec > >(tee -a "$LOG") 2>&1

echo
echo "============================================================"
echo " OrangeBox - Zimbra Migration Restore"
echo "============================================================"
echo

if [[ "$(id -un)" != "zimbra" && "$(id -u)" != "0" ]]; then
    echo "ERROR: ejecutar como root o zimbra."
    exit 1
fi

if [[ ! -x "$ZMPROV" ]]; then
    echo "ERROR: no existe $ZMPROV"
    exit 1
fi

echo "Bundle: $BASE_DIR"
echo

#
# ------------------------------------------------------------
# FUNCION: aplicar password mediante zmprov
# ------------------------------------------------------------
#
set_password_from_ldif()
{
    local ACCOUNT="$1"
    local USER="${ACCOUNT%@*}"
    local DOMAIN="${ACCOUNT#*@}"

    local DOMAIN_DN=""
    local PART

    IFS='.' read -ra PARTS <<< "$DOMAIN"

    for PART in "${PARTS[@]}"; do
        DOMAIN_DN="${DOMAIN_DN},dc=${PART}"
    done

    DOMAIN_DN="${DOMAIN_DN#,}"

    local DN="uid=${USER},ou=people,${DOMAIN_DN}"

    local HASH_B64
    HASH_B64="$(
        awk -v dn="$DN" '
            $0 == "dn: " dn {
                found=1
                next
            }
            found && /^userPassword:: / {
                print substr($0,17)
                exit
            }
            found && /^$/ {
                exit
            }
        ' "$BASE_DIR/passwords.ldif"
    )"

    if [[ -z "$HASH_B64" ]]; then
        echo "  [WARN] $ACCOUNT: no se encontró hash"
        return 0
    fi

    local HASH
    HASH="$(printf '%s' "$HASH_B64" | base64 -d 2>/dev/null || true)"

    if [[ -z "$HASH" ]]; then
        echo "  [WARN] $ACCOUNT: hash inválido"
        return 0
    fi

    #
    # Zimbra acepta el hash almacenado como userPassword.
    #
    "$ZMPROV" ma "$ACCOUNT" userPassword "$HASH"

    if [[ $? -eq 0 ]]; then
        echo "  [OK] password: $ACCOUNT"
    else
        echo "  [ERROR] password: $ACCOUNT"
    fi
}


#
# ------------------------------------------------------------
# 1. DOMAINS
# ------------------------------------------------------------

echo
echo "[1/7] Creando dominios..."

while IFS= read -r DOMAIN; do

    [[ -z "$DOMAIN" ]] && continue

    #
    # Evitar dominios internos o entradas inválidas.
    #
    case "$DOMAIN" in
        localhost|localhost.localdomain)
            continue
            ;;
    esac

    if "$ZMPROV" gd "$DOMAIN" >/dev/null 2>&1; then
        echo "  [EXISTS] $DOMAIN"
        continue
    fi

    "$ZMPROV" cd "$DOMAIN"

    if [[ $? -eq 0 ]]; then
        echo "  [OK] $DOMAIN"
    else
        echo "  [ERROR] $DOMAIN"
    fi

done < "$BASE_DIR/domains.txt"


#
# ------------------------------------------------------------
# 2. COS
# ------------------------------------------------------------

echo
echo "[2/7] COS..."

#
# No recreamos el COS default.
# Los COS personalizados se registran para revisión.
#
mkdir -p "$BASE_DIR/restore-review"

while IFS= read -r COS; do

    [[ -z "$COS" ]] && continue

    if [[ "$COS" == "default" ]]; then
        continue
    fi

    echo
    echo "  COS: $COS"
    echo "  Revisar: $BASE_DIR/cos"

done < "$BASE_DIR/cos.txt"


#
# ------------------------------------------------------------
# 3. ACCOUNTS
# ------------------------------------------------------------

echo
echo "[3/7] Creando cuentas..."

while IFS= read -r ACCOUNT; do

    [[ -z "$ACCOUNT" ]] && continue

    case "$ACCOUNT" in
        galsync.*|virus-quarantine.*|spam.*|ham.*)
            continue
            ;;
    esac

    if "$ZMPROV" ga "$ACCOUNT" >/dev/null 2>&1; then
        echo "  [EXISTS] $ACCOUNT"
        continue
    fi

    #
    # Crear inicialmente sin password.
    # El hash original se aplica después.
    #
    "$ZMPROV" ca "$ACCOUNT" ""

    if [[ $? -eq 0 ]]; then
        echo "  [OK] $ACCOUNT"
    else
        echo "  [ERROR] $ACCOUNT"
    fi

done < "$BASE_DIR/accounts.txt"


#
# ------------------------------------------------------------
# 4. ACCOUNT ATTRIBUTES
# ------------------------------------------------------------

echo
echo "[4/7] Restaurando atributos portables de cuentas..."

while IFS= read -r ACCOUNT; do

    [[ -z "$ACCOUNT" ]] && continue

    case "$ACCOUNT" in
        galsync.*|virus-quarantine.*|spam.*|ham.*)
            continue
            ;;
    esac

    FILE="$BASE_DIR/accounts/${ACCOUNT//@/_}.txt"

    [[ ! -f "$FILE" ]] && continue

    #
    # Restauramos únicamente atributos explícitamente portables.
    #
    # NO restauramos:
    #   zimbraId
    #   zimbraMailHost
    #   zimbraMailboxId
    #   zimbraCOSId
    #   zimbraServer
    #   zimbraAccountStatus
    #
    # porque son dependientes del nuevo servidor.
    #

    #
    # Restauramos únicamente atributos básicos y forwarding.
    # Las preferencias zimbraPref* quedan fuera de la restauración base
    # porque no son críticas y pueden variar entre versiones de Zimbra.
    #
    while IFS=$'\t' read -r ATTR VALUE; do

        [[ -z "$ATTR" ]] && continue

        case "$ATTR" in
            displayName|givenName|sn|cn|initials|preferredLanguage|zimbraMailQuota)
                "$ZMPROV" ma "$ACCOUNT" "$ATTR" "$VALUE" 2>&1 || \
                    echo "  [WARN] atributo $ATTR: $ACCOUNT"
                ;;

            zimbraPrefMailForwardingAddress)
                # Preferencia de forwarding: un valor normal.
                if [[ -n "$VALUE" ]]; then
                    "$ZMPROV" ma "$ACCOUNT" "$ATTR" "$VALUE" 2>&1 || \
                        echo "  [WARN] atributo $ATTR: $ACCOUNT"
                fi
                ;;
        esac

    done < <(
        awk -F': ' '
            /^[A-Za-z][A-Za-z0-9]*: / {
                attr=$1
                value=substr($0,index($0,": ")+2)
                print attr "\t" value
            }
        ' "$FILE"
    )

    #
    # zimbraMailForwardingAddress es multivaluado.
    # El primer valor reemplaza el contenido del atributo y los
    # siguientes se agregan con +.
    #
    mapfile -t FORWARDS < <(
        awk -F': ' '
            $1=="zimbraMailForwardingAddress" {
                print substr($0,index($0,": ")+2)
            }
        ' "$FILE"
    )

    if [[ ${#FORWARDS[@]} -gt 0 ]]; then

        if [[ -n "${FORWARDS[0]}" ]]; then
            "$ZMPROV" ma "$ACCOUNT" zimbraMailForwardingAddress "${FORWARDS[0]}" 2>&1 || \
                echo "  [WARN] forwarding principal: $ACCOUNT"
        fi

        for ((i=1; i<${#FORWARDS[@]}; i++)); do
            [[ -z "${FORWARDS[i]}" ]] && continue

            "$ZMPROV" ma "$ACCOUNT" +zimbraMailForwardingAddress "${FORWARDS[i]}" 2>&1 || \
                echo "  [WARN] forwarding adicional: $ACCOUNT"
        done
    fi

done < "$BASE_DIR/accounts.txt"


#
# ------------------------------------------------------------
# 5. PASSWORDS
# ------------------------------------------------------------

echo
echo "[5/7] Restaurando passwords..."

while IFS= read -r ACCOUNT; do

    [[ -z "$ACCOUNT" ]] && continue

    case "$ACCOUNT" in
        galsync.*|virus-quarantine.*|spam.*|ham.*)
            continue
            ;;
    esac

    set_password_from_ldif "$ACCOUNT"

done < "$BASE_DIR/accounts.txt"


#
# ------------------------------------------------------------
# 6. ALIASES
# ------------------------------------------------------------

echo
echo "[6/7] Restaurando aliases..."

while IFS= read -r ACCOUNT; do

    [[ -z "$ACCOUNT" ]] && continue

    case "$ACCOUNT" in
        galsync.*|virus-quarantine.*|spam.*|ham.*)
            continue
            ;;
    esac

    FILE="$BASE_DIR/aliases/${ACCOUNT//@/_}.txt"

    [[ ! -f "$FILE" ]] && continue

    while IFS= read -r LINE; do

        ALIAS="${LINE#*: }"

        [[ -z "$ALIAS" ]] && continue

        "$ZMPROV" aaa "$ACCOUNT" "$ALIAS" 2>/dev/null || \
            echo "  [WARN] alias $ALIAS -> $ACCOUNT"

    done < <(
        awk -F': ' '/^zimbraMailAlias: / {print $2}' "$FILE"
    )

done < "$BASE_DIR/accounts.txt"


#
# ------------------------------------------------------------
# 7. DL
# ------------------------------------------------------------

echo
echo "[7/7] Restaurando Distribution Lists..."

if [[ -f "$BASE_DIR/distribution-lists.txt" ]]; then

    while IFS= read -r DL; do

        [[ -z "$DL" ]] && continue

        if "$ZMPROV" gdl "$DL" >/dev/null 2>&1; then
            echo "  [EXISTS] $DL"
        else
            "$ZMPROV" cdl "$DL"

            if [[ $? -eq 0 ]]; then
                echo "  [OK] $DL"
            else
                echo "  [ERROR] $DL"
            fi
        fi

        SAFE_DL="${DL//@/_}"

        MEMBERS="$BASE_DIR/distribution-lists/${SAFE_DL}.members"

        [[ ! -f "$MEMBERS" ]] && continue

        while IFS= read -r LINE; do

            MEMBER="${LINE#*: }"

            [[ -z "$MEMBER" ]] && continue

            "$ZMPROV" adlm "$DL" "$MEMBER" 2>/dev/null || \
                echo "  [WARN] miembro $MEMBER -> $DL"

        done < <(
            awk -F': ' '/^zimbraMailForwardingAddress: / {print $2}' "$MEMBERS"
        )

    done < "$BASE_DIR/distribution-lists.txt"

fi


echo
echo "============================================================"
echo " RESTORE BASE TERMINADO"
echo "============================================================"
echo
echo "IMPORTANTE:"
echo
echo "1. Revisar:"
echo "   $BASE_DIR/restore.log"
echo
echo "2. Revisar COS:"
echo "   $BASE_DIR/cos/"
echo
echo "3. Revisar firmas:"
echo "   $BASE_DIR/signatures/"
echo
echo "4. Revisar identidades:"
echo "   $BASE_DIR/identities/"
echo
echo "5. Revisar DataSources:"
echo "   $BASE_DIR/datasources/"
echo
echo "6. Revisar grants:"
echo "   $BASE_DIR/grants/"
echo
echo "7. Luego ejecutar la migración de correo con imapsync."
echo
RESTORE