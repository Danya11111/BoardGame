#!/bin/sh
# Генерация lsfusion.xml перед стартом Tomcat: host/port сервера логики задаются переменными окружения.
# В compose по умолчанию — имя сервиса logics; на машине разработчика при отдельном Tomcat — localhost.
set -e
HOST="${LSFUSION_LOGICS_HOST:-logics}"
PORT="${LSFUSION_LOGICS_PORT:-7652}"
TEMPLATE="/usr/local/tomcat/conf/Catalina/localhost/lsfusion-context.template.xml"
OUT="/usr/local/tomcat/conf/Catalina/localhost/lsfusion.xml"
sed -e "s|@LOGICS_HOST@|${HOST}|g" -e "s|@LOGICS_PORT@|${PORT}|g" "$TEMPLATE" > "$OUT"
exec catalina.sh run
