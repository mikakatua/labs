#!/bin/bash

COUNTRY="US"
STATE="New York"
LOCATION="New York"
USAGE="Personal"
EMAIL="example@example.com"
SERVERDOMAIN="localhost"
POSTGRES_USER="myuser"

ROOT_CSR_SUBJ="/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$USAGE/OU=$USAGE/emailAddress=$EMAIL/CN=$SERVERDOMAIN"
CLIENT_CSR_SUBJ="/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$USAGE/OU=$USAGE/emailAddress=$EMAIL/CN=$POSTGRES_USER"

echo create ca root and server certificates
openssl req -days 3650 -new -text -nodes -subj "$ROOT_CSR_SUBJ" -keyout server.key -out server.csr
openssl req -days 3650 -x509 -text -in server.csr -key server.key -out server.crt
cp server.crt root.crt
openssl x509 -in server.crt -outform PEM -out server.pem
rm server.csr

echo create client certs
openssl req -days 3650 -new -nodes -subj "$CLIENT_CSR_SUBJ" -keyout client.key -out client.csr
openssl x509 -days 3650 -req  -CAcreateserial -in client.csr -CA root.crt -CAkey server.key -out client.crt
rm client.csr

echo convert client cert to PKCS8 DER
openssl pkcs8 -topk8 -inform PEM -outform DER -in client.key -out client-key.pk8 -nocrypt

echo ssl setting into pg_hba.conf configuration file
echo 'local all all trust' > pg_hba.conf
echo 'hostssl all all all cert clientcert=verify-full' >> pg_hba.conf

echo fix permissions
sudo chown 999 server.key
