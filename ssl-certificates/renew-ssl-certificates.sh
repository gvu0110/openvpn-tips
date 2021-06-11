#!/usr/bin/env bash

# By default, /lib/systemd/system/certbot.service will run twice a day to renew the SSL certificates.
# This script is used to detect if the SSL certificates are renewed automatically or not.
# If the SSL certificates are renewd by the certbot.service, the OpenVPN Access Server will be updated. 
# This script should be run every day at 12:00AM.

DOMAIN_NAME="$1"
OPENVPN_AS_DIR="/usr/local/openvpn_as"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SAVED_MD5_SUM_FILE="${SCRIPT_DIR}/saved_md5_sum.log"
CURRENT_MD5_SUM=$(md5sum "/etc/letsencrypt/live/${DOMAIN_NAME}/cert.pem" | cut -d' ' -f1)

function createSavedMD5SumFile {
    echo "Creating saved MD5 checksum file ..."
    echo $CURRENT_MD5_SUM > $SAVED_MD5_SUM_FILE
    echo "Created saved MD5 checksum file!"
}

if [ ! -f $SAVED_MD5_SUM_FILE ]; then
    createSavedMD5SumFile
fi

SAVED_MD5_SUM=$(<$SAVED_MD5_SUM_FILE)

if [ "$SAVED_MD5_SUM" != "$CURRENT_MD5_SUM" ]; then
    echo "Certificates are renewed"
    echo "Adding new certificates to OpenVPN Access Server ..."
    cp "${OPENVPN_AS_DIR}/etc/web-ssl/server.crt" "${OPENVPN_AS_DIR}/etc/web-ssl/server.crt.bak"
    cp "${OPENVPN_AS_DIR}/etc/web-ssl/server.key" "${OPENVPN_AS_DIR}/etc/web-ssl/server.key.bak"

    "${OPENVPN_AS_DIR}"/scripts/sacli --key "cs.cert" --value_file "/etc/letsencrypt/live/${DOMAIN_NAME}/cert.pem" ConfigPut
    "${OPENVPN_AS_DIR}"/scripts/sacli --key "cs.ca_bundle" --value_file "/etc/letsencrypt/live/${DOMAIN_NAME}/chain.pem" ConfigPut
    "${OPENVPN_AS_DIR}"/scripts/sacli --key "cs.priv_key" --value_file "/etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem" ConfigPut

    "${OPENVPN_AS_DIR}"/scripts/sacli start
    echo "Added new certificates to OpenVPN Access Server!"
    createSavedMD5SumFile
fi
