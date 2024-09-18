# Generate a truststore and import the CA certificate
docker run --rm -v $PWD:/app eclipse-temurin:22-jdk sh -c '
rm -f /app/src/main/resources/customTrustStore.jks \
&& keytool -importkeystore -srckeystore $JAVA_HOME/lib/security/cacerts -srcstorepass changeit -destkeystore /app/src/main/resources/customTrustStore.jks -deststorepass changeit -deststoretype JKS -noprompt \
&& keytool -import -file /app/badssl-ca.pem -alias badssl -keystore /app/src/main/resources/customTrustStore.jks -storetype JKS -storepass changeit -noprompt
'

