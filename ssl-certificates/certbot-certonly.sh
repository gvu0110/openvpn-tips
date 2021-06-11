#!/usr/bin/env bash

# This script is used to generate a brand-new SSL certificates with Let's Encrypt
# Should not use this script to renew an existing SSL certificate

EMAIL="admin@example.com"
DOMAIN_NAME="example.com"
OPENVPN_AS_DIR="/usr/local/openvpn_as"

apt-get update && apt-get install -y certbot awscli python3-certbot-dns-route53
aws route53 list-hosted-zones --output text && \
certbot certonly --non-interactive \
                 --agree-tos \
                 --dns-route53 \
                 --domain ${DOMAIN_NAME} \
                 --email "${EMAIL}"

cp "${OPENVPN_AS_DIR}/etc/web-ssl/server.crt" "${OPENVPN_AS_DIR}/etc/web-ssl/server.crt.bak"
cp "${OPENVPN_AS_DIR}/etc/web-ssl/server.key" "${OPENVPN_AS_DIR}/etc/web-ssl/server.key.bak"

"${OPENVPN_AS_DIR}"/scripts/sacli --key "cs.cert" --value_file "/etc/letsencrypt/live/${DOMAIN_NAME}/cert.pem" ConfigPut
"${OPENVPN_AS_DIR}"/scripts/sacli --key "cs.ca_bundle" --value_file "/etc/letsencrypt/live/${DOMAIN_NAME}/chain.pem" ConfigPut
"${OPENVPN_AS_DIR}"/scripts/sacli --key "cs.priv_key" --value_file "/etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem" ConfigPut

"${OPENVPN_AS_DIR}"/scripts/sacli start
