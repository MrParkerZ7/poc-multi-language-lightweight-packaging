# Spring Boot 3 + GraalVM native (keeps Spring DI, AOT-compiled)
FROM ghcr.io/graalvm/native-image-community:21 AS build
WORKDIR /app
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz \
    | tar xz -C /opt && ln -s /opt/apache-maven-3.9.6/bin/mvn /usr/local/bin/mvn
COPY pom.xml .
COPY src ./src
RUN mvn -Pnative -B -q native:compile -DskipTests

FROM debian:12-slim
COPY --from=build /app/target/app /app
ENTRYPOINT ["/app"]
