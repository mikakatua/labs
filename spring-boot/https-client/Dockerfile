# Use the Maven build image to build the application
FROM maven:3.9.9-eclipse-temurin-22 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Use a lightweight Java runtime image to run the application
FROM eclipse-temurin:22-jdk AS runtime
WORKDIR /app
COPY --from=build /app/target/https-client-1.0.0.jar /app/http-client.jar
COPY src/main/resources/customTrustStore.jks /app/customTrustStore.jks

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/http-client.jar \"$@\"", "--"]
