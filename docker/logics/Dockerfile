# lsFusion logics server (BusinessLogicsBootstrap)
# Сборка из корня репозитория: docker compose build logics
#
# JAR не качается внутри образа (медленно и часто рвётся сеть — curl 18 partial file).
# JAR в lib/ нужен до сборки; при отсутствии один раз запустите .\run.ps1 (скачивает JAR) или положите файл вручную.

FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build

COPY pom.xml .
COPY lib/lsfusion-server-6.1.jar lib/lsfusion-server-6.1.jar
COPY src ./src
RUN mvn -q -B -DskipTests compile

FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Нативный движок для tess4j (иначе после добавления JAR возможны ошибки загрузки нативной части).
RUN apt-get update \
  && apt-get install -y --no-install-recommends tesseract-ocr \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/lib/lsfusion-server-6.1.jar /app/
COPY --from=build /build/target/classes /app/classes
COPY --from=build /build/target/server-lib /app/server-lib
COPY docker/logics/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh \
  && chmod +x /entrypoint.sh

EXPOSE 7651 7652
ENTRYPOINT ["sh", "/entrypoint.sh"]
