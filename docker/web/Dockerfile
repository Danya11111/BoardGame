# Tomcat 9 + lsFusion web client WAR
FROM tomcat:9.0-jdk17-temurin-jammy

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

# One Context descriptor: avoids duplicate /lsfusion if WAR were also under webapps/
RUN mkdir -p /opt/lsfusion /usr/local/tomcat/conf/Catalina/localhost \
  && curl -fsSL "https://download.lsfusion.org/java/lsfusion-client-6.1.war" -o /opt/lsfusion/lsfusion-client.war \
  && rm -rf /usr/local/tomcat/webapps/*

COPY lsfusion-context.xml /usr/local/tomcat/conf/Catalina/localhost/lsfusion.xml

ENV CATALINA_OPTS="--add-opens=java.base/java.util=ALL-UNNAMED"

EXPOSE 8080
