#!/bin/sh
set -e

JAVA_FLAGS=""

# Dev mode is very handy for local demo: enables anonymous UI/API access as admin.
# Set in docker-compose via LSFUSION_DEVMODE=true
if [ "${LSFUSION_DEVMODE:-}" = "true" ] || [ "${LSFUSION_DEVMODE:-}" = "1" ]; then
  JAVA_FLAGS="$JAVA_FLAGS -Dlsfusion.server.devmode=true"
fi

# Sets initial admin password on first start (when DB is empty).
# Set in docker-compose via LSFUSION_INITIAL_ADMIN_PASSWORD=...
if [ -n "${LSFUSION_INITIAL_ADMIN_PASSWORD:-}" ]; then
  JAVA_FLAGS="$JAVA_FLAGS -Dlogics.initialAdminPassword=${LSFUSION_INITIAL_ADMIN_PASSWORD}"
fi

# Email для автоназначения роли admin при регистрации (совпадение с email учётной записи).
if [ -n "${BOARDGAME_INITIAL_ADMIN_EMAIL:-}" ]; then
  JAVA_FLAGS="$JAVA_FLAGS -Dboardgame.initialAdminEmail=${BOARDGAME_INITIAL_ADMIN_EMAIL}"
fi

if [ -n "${BOARDGAME_REGISTRATION_URL:-}" ]; then
  JAVA_FLAGS="$JAVA_FLAGS -Dboardgame.registrationUrl=${BOARDGAME_REGISTRATION_URL}"
fi

# Приветствие до логина: анонимный доступ к UI (навигатор с welcomeLanding), без открытого API для гостей.
# Явно задаём и при devmode, и без него — чтобы при LSFUSION_DEVMODE=false логин не был первым экраном.
JAVA_FLAGS="$JAVA_FLAGS -Dsettings.enableUI=2 -Dsettings.enableAPI=1"

exec java $JAVA_FLAGS \
  -Ddb.server=postgres:5432 \
  -Ddb.name=boardgame \
  -Ddb.user=postgres \
  -Ddb.password="${DB_PASSWORD}" \
  -Djava.rmi.server.hostname=logics \
  -Drmi.port=7652 \
  -Dhttp.port=7651 \
  -cp "/app/lsfusion-server-6.1.jar:/app/classes" \
  lsfusion.server.logics.BusinessLogicsBootstrap
