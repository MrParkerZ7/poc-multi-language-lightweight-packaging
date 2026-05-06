# jlink runtime image — bundle only required JDK modules into a slim base (~80 MB image)
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn -B -q clean package -DskipTests
RUN MODULES=$(jdeps --print-module-deps --multi-release 21 --recursive \
        --class-path "target/lib/*" target/app.jar 2>/dev/null || echo "java.base") \
 && jlink --add-modules "${MODULES}" \
          --strip-debug --no-man-pages --no-header-files \
          --compress=2 \
          --output /jlink-runtime

FROM debian:12-slim
COPY --from=build /jlink-runtime /opt/jdk
COPY --from=build /app/target/app.jar /app.jar
COPY --from=build /app/target/lib /lib-app
ENV PATH="/opt/jdk/bin:${PATH}"
ENTRYPOINT ["java", "-cp", "/app.jar:/lib-app/*", "com.example.App"]
