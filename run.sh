#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
JAR="$ROOT/lib/lsfusion-server-6.1.jar"
PROPS="$ROOT/lsfusion.properties"
EXAMPLE="$ROOT/lsfusion.properties.example"

if [[ ! -f "$JAR" ]]; then
  echo "Missing $JAR — run download-server.ps1 or download the JAR manually." >&2
  exit 1
fi

if [[ ! -f "$PROPS" ]]; then
  if [[ -f "$EXAMPLE" ]]; then
    cp "$EXAMPLE" "$PROPS"
  fi
  echo "Created lsfusion.properties from example. Set db.password and run again." >&2
  exit 1
fi

# Bootstrap uses /lsfusion.properties (filesystem root), not this folder — same -D workaround as run.ps1.
read_prop() {
  local v
  v=$(grep -E "^[[:space:]]*$1[[:space:]]*=" "$PROPS" 2>/dev/null | tail -n1 | cut -d= -f2- | tr -d '\r') || true
  printf '%s' "$v"
}

DB_SERVER="$(read_prop db.server)"
DB_NAME="$(read_prop db.name)"
DB_USER="$(read_prop db.user)"
DB_PASS="$(read_prop db.password)"

if [[ -z "$DB_SERVER" || -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
  echo "lsfusion.properties must define db.server, db.name, db.user, db.password" >&2
  exit 1
fi
case "$DB_PASS" in CHANGE_ME|yourpassword) echo "Set a real db.password in lsfusion.properties." >&2; exit 1;; esac

mvn -q clean compile

CP="$JAR:$ROOT/target/classes"
JAVA_OPTS=(
  "-Ddb.server=$DB_SERVER"
  "-Ddb.name=$DB_NAME"
  "-Ddb.user=$DB_USER"
  "-Ddb.password=$DB_PASS"
)
RMI_PORT="$(read_prop rmi.port)"
HTTP_PORT="$(read_prop http.port)"
INIT_ADMIN_EMAIL="$(read_prop boardgame.initialAdminEmail)"
REG_URL="$(read_prop boardgame.registrationUrl)"
[[ -n "$RMI_PORT" ]] && JAVA_OPTS+=("-Drmi.port=$RMI_PORT")
[[ -n "$HTTP_PORT" ]] && JAVA_OPTS+=("-Dhttp.port=$HTTP_PORT")
[[ -n "$INIT_ADMIN_EMAIL" ]] && JAVA_OPTS+=("-Dboardgame.initialAdminEmail=$INIT_ADMIN_EMAIL")
[[ -n "$REG_URL" ]] && JAVA_OPTS+=("-Dboardgame.registrationUrl=$REG_URL")

exec java "${JAVA_OPTS[@]}" -cp "$CP" lsfusion.server.logics.BusinessLogicsBootstrap
