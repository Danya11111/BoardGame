# lsFusion logics server (BusinessLogicsBootstrap)
# Build from repository root: docker compose build logics

FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build

COPY pom.xml .
COPY src ./src
RUN mkdir -p lib \
  && curl -fsSL "https://download.lsfusion.org/java/lsfusion-server-6.1.jar" -o lib/lsfusion-server-6.1.jar
RUN mvn -q -B -DskipTests compile

FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/lib/lsfusion-server-6.1.jar /app/
COPY --from=build /build/target/classes /app/classes
COPY docker/logics/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh \
  && chmod +x /entrypoint.sh

EXPOSE 7651 7652
ENTRYPOINT ["sh", "/entrypoint.sh"]
