# 3-best (Java/Kotlin): GraalVM native + epsilon GC + every 2-amalgamate flag + UPX-LZMA + scratch
FROM ghcr.io/graalvm/native-image-community:21 AS build
WORKDIR /app
RUN microdnf install -y findutils wget tar gzip xz \
 && wget -q https://github.com/upx/upx/releases/download/v4.2.4/upx-4.2.4-amd64_linux.tar.xz -O /tmp/upx.txz \
 && tar -xJf /tmp/upx.txz -C /tmp \
 && cp /tmp/upx-4.2.4-amd64_linux/upx /usr/local/bin/ \
 && wget -q https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -O /tmp/mvn.tgz \
 && tar -xzf /tmp/mvn.tgz -C /opt \
 && ln -s /opt/apache-maven-3.9.6/bin/mvn /usr/local/bin/mvn

COPY pom.xml .
COPY src ./src
RUN mvn -Pnative -B -q clean package -DskipTests
RUN upx --best --lzma /app/target/app

FROM scratch
COPY --from=build /app/target/app /app
ENTRYPOINT ["/app"]
