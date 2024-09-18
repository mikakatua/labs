# Using a custom trust store in Spring Boot

## Run the demo (requires docker)
Follow these steps:
```
sh generate-truststore.sh # The truststore will have the default Java CA certificates plus an untrusted cert (for https://untrusted-root.badssl.com)
sh build.sh               # Creates the container image `https-client`
sh run.sh                 # Execute several test cases to show the different configuration options
```

## Demo without a SSL Bundle
It is not mandatory to use a SSL Bundle. The SSL context can be set using the `javax.net.ssl` properties
```
cp src/main/java/com/example/httpsclient/HttpsClientApplication.java-no-ssl-bundle \
src/main/java/com/example/httpsclient/HttpsClientApplication.java
sh build.sh
sh run.sh                 # Tests 1 and 2 will fail
```
