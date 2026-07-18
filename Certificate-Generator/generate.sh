#!/bin/sh

set -eu
umask 077

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUTPUT_DIR="$SCRIPT_DIR"
TLS_DIR="$OUTPUT_DIR/tls"

rm -rf "$TLS_DIR"
mkdir -p "$TLS_DIR"

TLS_KEY="$TLS_DIR/tls.key"
TLS_CERT="$TLS_DIR/tls.crt"
ROOT_CA_KEY="$TLS_DIR/root-ca.key"
ROOT_CA_CERT="$TLS_DIR/root-ca.pem"
INTERMEDIATE_CA_KEY="$TLS_DIR/intermediate-ca.key"
INTERMEDIATE_CA_CERT="$TLS_DIR/intermediate-ca.pem"
TLS_CSR="$TLS_DIR/tls.csr"
TLS_LEAF_CERT="$TLS_DIR/tls-leaf.crt"
INTERMEDIATE_CSR="$TLS_DIR/intermediate.csr"

ROOT_CONFIG=$(mktemp)
INTERMEDIATE_REQ_CONFIG=$(mktemp)
INTERMEDIATE_EXT=$(mktemp)
TLS_CONFIG=$(mktemp)

cleanup()
{
    rm -f \
    "$ROOT_CONFIG" \
    "$INTERMEDIATE_REQ_CONFIG" \
    "$INTERMEDIATE_EXT" \
    "$TLS_CONFIG"
}

trap cleanup EXIT

cat > "$ROOT_CONFIG" <<EOF
[req]
prompt=no
distinguished_name=dn
x509_extensions=ca_ext

[dn]
C=EU
ST=NL
L=Amsterdam
O=GTA ODT
OU=Online
CN=GTA ODT Root CA

[ca_ext]
basicConstraints=critical,CA:TRUE
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always
EOF

cat > "$INTERMEDIATE_REQ_CONFIG" <<EOF
[req]
prompt=no
distinguished_name=dn

[dn]
C=EU
ST=NL
L=Amsterdam
O=GTA ODT
CN=GTA ODT TLS Intermediate CA
EOF

cat > "$INTERMEDIATE_EXT" <<EOF
basicConstraints=critical,CA:TRUE,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

cat > "$TLS_CONFIG" <<EOF
[req]
prompt=no
distinguished_name=dn
req_extensions=req_ext

[dn]
CN=ros.rockstargames.com
O=GTA ODT

[req_ext]
subjectAltName=@alt_names

[alt_names]
DNS.1=ros.rockstargames.com
DNS.2=ros.rockstargames.com
DNS.3=ros.rockstargames.com
EOF

echo "Generating Root CA..."

openssl genrsa \
-out "$ROOT_CA_KEY" \
2048

openssl req \
-new \
-x509 \
-days 7300 \
-sha256 \
-key "$ROOT_CA_KEY" \
-out "$ROOT_CA_CERT" \
-config "$ROOT_CONFIG"

echo "Generating Intermediate CA..."

openssl genrsa \
-out "$INTERMEDIATE_CA_KEY" \
2048

openssl req \
-new \
-key "$INTERMEDIATE_CA_KEY" \
-out "$INTERMEDIATE_CSR" \
-config "$INTERMEDIATE_REQ_CONFIG"

openssl x509 \
-req \
-in "$INTERMEDIATE_CSR" \
-CA "$ROOT_CA_CERT" \
-CAkey "$ROOT_CA_KEY" \
-CAcreateserial \
-days 3650 \
-sha256 \
-extfile "$INTERMEDIATE_EXT" \
-out "$INTERMEDIATE_CA_CERT"

echo "Generating TLS certificate..."

openssl genrsa \
-out "$TLS_KEY" \
2048

openssl req \
-new \
-key "$TLS_KEY" \
-out "$TLS_CSR" \
-config "$TLS_CONFIG"

openssl x509 \
-req \
-in "$TLS_CSR" \
-CA "$INTERMEDIATE_CA_CERT" \
-CAkey "$INTERMEDIATE_CA_KEY" \
-CAcreateserial \
-days 3650 \
-sha256 \
-extfile "$TLS_CONFIG" \
-extensions req_ext \
-out "$TLS_LEAF_CERT"

echo "Creating Go TLS chain..."

cat \
"$TLS_LEAF_CERT" \
"$INTERMEDIATE_CA_CERT" \
"$ROOT_CA_CERT" \
> "$TLS_CERT"

echo "Creating certificate in DER format..."

openssl x509 \
-in "$TLS_LEAF_CERT" \
-outform DER \
-out "$TLS_DIR/tls.cer"

openssl x509 \
-in "$TLS_LEAF_CERT" \
-noout \
-subject \
-issuer \
-ext subjectAltName

echo
echo "DONE"
echo
echo "Go server:"
echo "$TLS_CERT"
echo
echo "Key:"
echo "$TLS_KEY"
echo
echo "DER:"
echo "$TLS_DIR/tls.cer"
