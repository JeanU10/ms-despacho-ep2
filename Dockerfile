# syntax=docker/dockerfile:1
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml ./
RUN mvn --batch-mode --no-transfer-progress dependency:go-offline

COPY src/main ./src/main
RUN mvn --batch-mode --no-transfer-progress package -Dmaven.test.skip=true

FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

RUN addgroup -S app && adduser -S -G app app

ARG VCS_REF=unknown
LABEL org.opencontainers.image.title="ms-despacho" \
      org.opencontainers.image.source="https://github.com/miguelcamposdasilva/ms-despacho" \
      org.opencontainers.image.revision="${VCS_REF}"

COPY --from=build --chown=app:app /app/target/despacho-svc-*.jar /app/app.jar

USER app
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/api/despachos || exit 1

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
