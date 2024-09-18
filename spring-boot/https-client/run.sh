URL="${1:-https://untrusted-root.badssl.com}"

# Test 1: SSL Bundle with environment variables
docker run \
    -e SPRING_SSL_BUNDLE_JKS_MYBUNDLE_TRUSTSTORE_LOCATION=/app/customTrustStore.jks \
    -e SPRING_SSL_BUNDLE_JKS_MYBUNDLE_TRUSTSTORE_PASSWORD=changeit \
    https-client "$URL"

# Test 2: SSL Bundle with properties
docker run \
    -e JAVA_OPTS="-Dspring.ssl.bundle.jks.myBundle.truststore.location=/app/customTrustStore.jks -Dspring.ssl.bundle.jks.myBundle.truststore.password=changeit" \
    https-client "$URL"

# Test 3: Standard javax.net.ssl properties
docker run \
    -e JAVA_OPTS="-Djavax.net.ssl.trustStore=/app/customTrustStore.jks -Djavax.net.ssl.trustStorePassword=changeit" \
    https-client "$URL"

# Test 4: Default Java CA certificates
docker run https-client https://example.com
