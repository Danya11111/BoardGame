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
read_prop() { grep -E "^[[:space:]]*$1[[:space:]]*=" "$PROPS" | tail -n1 | cut -d= -f2-; }

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
exec java \
  "-Ddb.server=$DB_SERVER" \
  "-Ddb.name=$DB_NAME" \
  "-Ddb.user=$DB_USER" \
  "-Ddb.password=$DB_PASS" \
  -cp "$CP" \
  lsfusion.server.logics.BusinessLogicsBootstrap
