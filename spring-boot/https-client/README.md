# Using a custom trust store in Spring Boot

## Run the demo (requires docker)
Follow these steps:
```
sh generate-truststore.sh # The truststore will have the default Java CA certificates plus an untrusted cert (for https://untrusted-root.badssl.com)
sh build.sh               # Creates the container image `https-client`
sh run.sh                 # Execute several test cases to show the different configuration options
```
