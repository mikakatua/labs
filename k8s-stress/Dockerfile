FROM eclipse-temurin:21-jdk as builder
WORKDIR /src
COPY CrunchifyGenerateOOM.java .
RUN javac CrunchifyGenerateOOM.java

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /src .

ENV JVM_OPTS "-XX:MaxHeapSize=64m"
ENTRYPOINT ["sh", "-c", "java $JVM_OPTS -cp . CrunchifyGenerateOOM"]
