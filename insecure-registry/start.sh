#!/bin/bash

REGISTRY_SERVER=myregistry.domain.com

generate_certs() {
  local DOMAIN=$1

  # Create a Root CA Certificate
  openssl genrsa -out rootCA.key 4096
  openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt \
  -subj "/C=US/ST=MyState/L=MyCity/O=MyOrg/OU=MyUnit/CN=My Root CA"

  # Create a Certificate Signing Request (CSR)
  openssl genrsa -out domain.key 2048
  openssl req -new -key domain.key -out domain.csr \
  -subj "/C=US/ST=MyState/L=MyCity/O=MyOrg/OU=MyUnit/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:$DOMAIN"

  # Create a configuration file for SANs
  cat > v3.ext << EOF
  authorityKeyIdentifier=keyid,issuer
  basicConstraints=CA:FALSE
  keyUsage = digitalSignature, keyEncipherment
  extendedKeyUsage = serverAuth
  subjectAltName = @alt_names

  [alt_names]
  DNS.1 = $DOMAIN
EOF

  # Sign the CSR with the Root CA to issue the certificate
  openssl x509 -req -in domain.csr -CA rootCA.crt -CAkey rootCA.key \
  -CAcreateserial -out domain.crt -days 825 -sha256 -extfile v3.ext

  #Verify the certificate
  openssl verify -CAfile rootCA.crt domain.crt
}

if [ -d auth ]; then
  echo auth dir exists. Skipping creation
else
  mkdir auth
  docker run --rm --entrypoint htpasswd \
    httpd:2 -Bbn testuser testpassword > auth/htpasswd
fi

if [ -d certs ]; then
  echo certs dir exists. Skipping creation
else
  mkdir certs
  (cd certs && generate_certs $REGISTRY_SERVER)
fi

docker run -d --restart=always --name registry \
  -v $PWD/auth:/auth \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -v $PWD/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -p 443:443 \
  registry:2
