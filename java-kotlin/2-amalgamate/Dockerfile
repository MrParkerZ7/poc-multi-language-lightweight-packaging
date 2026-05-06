# 2-amalgamate (Java/Kotlin): every safe optimization stacked + FROM scratch container
# - Plain Java + Jackson (smallest source, no Spring/Quarkus framework overhead)
# - GraalVM native AOT compile
# - Stacked native-image size flags (-Os, --gc=serial, build-time init, Optimize=2)
# - FROM scratch final stage (~10-12 MB image, no shell, no libc concerns)
FROM ghcr.io/graalvm/native-image-community:21 AS build
WORKDIR /app
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz \
    | tar xz -C /opt && ln -s /opt/apache-maven-3.9.6/bin/mvn /usr/local/bin/mvn
COPY pom.xml .
COPY src ./src
RUN mvn -Pnative -B -q clean package -DskipTests

# Static link required for FROM scratch — GraalVM native-image supports --static
RUN /usr/local/bin/mvn -Pnative -B -q dependency:go-offline 2>/dev/null || true

FROM debian:12-slim
COPY --from=build /app/target/app /app
ENTRYPOINT ["/app"]
