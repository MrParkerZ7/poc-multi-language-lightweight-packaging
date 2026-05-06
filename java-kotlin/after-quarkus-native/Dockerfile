# Quarkus native (native-first JVM framework, fastest cold-start)
FROM ghcr.io/graalvm/native-image-community:21 AS build
WORKDIR /app
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz \
    | tar xz -C /opt && ln -s /opt/apache-maven-3.9.6/bin/mvn /usr/local/bin/mvn
COPY pom.xml .
COPY src ./src
RUN mvn -Pnative -B -q clean package -DskipTests

FROM debian:12-slim
COPY --from=build /app/target/app-1.0.0-runner /app
ENTRYPOINT ["/app"]
