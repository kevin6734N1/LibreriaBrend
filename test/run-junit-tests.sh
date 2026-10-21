#!/usr/bin/env bash
# Compila el proyecto y ejecuta la suite JUnit 5.
#
# Sin DB_NAME, las pruebas de libreria.dao se omiten mediante Assumptions.
# Para ejecutarlas contra una base aislada:
#   DB_HOST=127.0.0.1 DB_PORT=3307 DB_NAME=libreria_brenda_test \
#   DB_USER=root DB_PASSWORD= bash test/run-junit-tests.sh
#
# Variables opcionales:
#   JUNIT_EXCLUDE  regex de clases a excluir (ej. 'libreria\.dao\..*')
#   OUT            directorio de clases compiladas (por defecto out/junit)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) SEP=';' ;;
  *) SEP=':' ;;
esac

L="WebContent/WEB-INF/lib"
JUNIT="$L/junit-platform-console-standalone-1.11.4.jar"
CP_COMPILE="$JUNIT${SEP}$L/jbcrypt-0.4.jar${SEP}$L/mysql-connector-j-9.7.0.jar${SEP}lib/tomcat-11/*"
CP_RUN="${OUT:-out/junit}${SEP}$L/jbcrypt-0.4.jar${SEP}$L/mysql-connector-j-9.7.0.jar"

OUT="${OUT:-out/junit}"
rm -rf "$OUT"
mkdir -p "$OUT"

javac -encoding UTF-8 -cp "$CP_COMPILE" -d "$OUT" \
  $(find src -name '*.java') $(find test -name '*.java')

ARGS=(--scan-class-path "$OUT" --disable-banner)
if [ -n "${JUNIT_EXCLUDE:-}" ]; then
  ARGS+=(--exclude-classname "$JUNIT_EXCLUDE")
fi

java -jar "$JUNIT" -cp "$CP_RUN" "${ARGS[@]}"
