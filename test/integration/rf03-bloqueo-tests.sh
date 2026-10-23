#!/usr/bin/env bash
# RF03 - Bloqueo temporal por intentos fallidos.
# Pruebas HTTP de integracion contra LoginServlet con Tomcat aislado + base
# de PRUEBAS aislada (libreria_brenda_test). NO cubre la expiracion de 120 s
# en tiempo real: esa frontera se valida de forma determinista con reloj
# inyectado en test/libreria/util/ControlIntentosLoginExpiracionTest.java.
#
# Requisitos:
#   - Tomcat de pruebas con el contexto /LibreriaBrend desplegado (8091).
#   - Base libreria_brenda_test creada con database/schema_test.sql + fixtures.
#   - Cliente mysql accesible.
#
# Uso:
#   BASE=http://localhost:8091/LibreriaBrend \
#   DB_PORT=3307 DB_USER=root DB_PASSWORD= \
#   bash test/integration/rf03-bloqueo-tests.sh
#
# Crea clientes/administrador sinteticos unicos rf03.*@test.local por
# ejecucion, por lo que no contamina RF02 ni las demas suites.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE="${BASE:-http://localhost:8091/LibreriaBrend}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-libreria_brenda_test}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"

MYSQL=(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER")
[ -n "$DB_PASSWORD" ] && MYSQL+=("-p$DB_PASSWORD")
MYSQL+=(-N -B "$DB_NAME")
q() { "${MYSQL[@]}" -e "$1" 2>/dev/null; }

PASS=0
FAIL=0
FAILS=()
TMP="$(mktemp -d)"

ok()  { PASS=$((PASS+1)); echo "PASS  $1"; }
ko()  { FAIL=$((FAIL+1)); FAILS+=("$1"); echo "FAIL  $1 | esperado=[$2] actual=[$3]"; }
eq()  { if [ "$2" = "$3" ]; then ok "$1"; else ko "$1" "$2" "$3"; fi; }
contains()    { case "$3" in *"$2"*) ok "$1";; *) ko "$1" "contiene '$2'" "$3";; esac; }
notcontains() { case "$3" in *"$2"*) ko "$1" "NO contiene '$2'" "$3";; *) ok "$1";; esac; }

login() { # jar email password rol [codigo]
  local jar=$1 email=$2 pass=$3 rol=$4 codigo=${5-}
  local args=(--data-urlencode "email=$email" --data-urlencode "password=$pass" --data-urlencode "rol=$rol")
  [ -n "$codigo" ] && args+=(--data-urlencode "codigo=$codigo")
  curl -s -c "$jar" -b "$jar" -X POST "$BASE/LoginServlet" "${args[@]}"
}

login_code() { # jar email password rol codigo -> solo codigo HTTP
  local jar=$1 email=$2 pass=$3 rol=$4 codigo=${5-}
  local args=(--data-urlencode "email=$email" --data-urlencode "password=$pass" --data-urlencode "rol=$rol")
  [ -n "$codigo" ] && args+=(--data-urlencode "codigo=$codigo")
  curl -s -o /dev/null -w '%{http_code}' -c "$jar" -b "$jar" -X POST "$BASE/LoginServlet" "${args[@]}"
}

RUN="$(date +%s)-$$"
RUN_SHORT="$(date +%H%M%S)$$"
EMAIL_CUATRO="rf03.cuatro.${RUN}@test.local"
EMAIL_BLOQ="rf03.bloqueo.${RUN}@test.local"
EMAIL_INDEP="rf03.indep.${RUN}@test.local"
EMAIL_RESET="rf03.reset.${RUN}@test.local"
EMAIL_ROL="rf03.rol.${RUN}@test.local"
CODIGO_ROL="EMP-${RUN_SHORT}"
DNI_CUATRO="$(printf '3%07d' $(( (RANDOM * 32768 + RANDOM) % 10000000 )))"
DNI_BLOQ="$(printf '2%07d' $(( (RANDOM * 32768 + RANDOM) % 10000000 )))"
DNI_INDEP="$(printf '1%07d' $(( (RANDOM * 32768 + RANDOM) % 10000000 )))"
DNI_RESET="$(printf '0%07d' $(( (RANDOM * 32768 + RANDOM) % 10000000 )))"
DNI_ROL="$(printf '6%07d' $(( (RANDOM * 32768 + RANDOM) % 10000000 )))"

HASH_CLI="$(sed -n "/INSERT INTO clientes/,/;/p" "$ROOT/database/fixtures_test.sql" | grep -oE '\$2a\$10\$[./A-Za-z0-9]+' | head -1)"
HASH_ADMIN="$(sed -n "/INSERT INTO administradores/,/;/p" "$ROOT/database/fixtures_test.sql" | grep -oE '\$2a\$10\$[./A-Za-z0-9]+' | head -1)"

cleanup() {
  q "DELETE FROM clientes WHERE email LIKE 'rf03.%@test.local'" >/dev/null
  q "DELETE FROM administradores WHERE email LIKE 'rf03.%@test.local'" >/dev/null
  rm -rf "$TMP"
}
trap cleanup EXIT

echo "== Preparacion: aislamiento obligatorio (base de pruebas) =="
eq "La conexion apunta a libreria_brenda_test" "$DB_NAME" "$(q 'SELECT DATABASE()')"
eq "Fixture de clientes cargado" "3" "$(q 'SELECT COUNT(*) FROM clientes')"
eq "Fixture de administradores cargado" "1" "$(q 'SELECT COUNT(*) FROM administradores')"
eq "En este motor NO existe la base comercial libreria_brenda" "" \
   "$(q "SHOW DATABASES LIKE 'libreria_brenda'")"
eq "En este motor NO existe la base demo" "" \
   "$(q "SHOW DATABASES LIKE 'libreria_brenda_demo'")"

q "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash, activo)
   VALUES ('Cliente', 'RF03 Cuatro', '$DNI_CUATRO', '$EMAIL_CUATRO', '900000301', 'Av. Pruebas 301, Lima', '$HASH_CLI', 1)"
q "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash, activo)
   VALUES ('Cliente', 'RF03 Bloqueo', '$DNI_BLOQ', '$EMAIL_BLOQ', '900000302', 'Av. Pruebas 302, Lima', '$HASH_CLI', 1)"
q "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash, activo)
   VALUES ('Cliente', 'RF03 Independencia', '$DNI_INDEP', '$EMAIL_INDEP', '900000303', 'Av. Pruebas 303, Lima', '$HASH_CLI', 1)"
q "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash, activo)
   VALUES ('Cliente', 'RF03 Reset', '$DNI_RESET', '$EMAIL_RESET', '900000304', 'Av. Pruebas 304, Lima', '$HASH_CLI', 1)"
q "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash, activo)
   VALUES ('Cliente', 'RF03 Roles', '$DNI_ROL', '$EMAIL_ROL', '900000305', 'Av. Pruebas 305, Lima', '$HASH_CLI', 1)"
q "INSERT INTO administradores (nombre, email, password_hash, codigo_empleado)
   VALUES ('Admin RF03 Roles', '$EMAIL_ROL', '$HASH_ADMIN', '$CODIGO_ROL')"
eq "Cuentas sinteticas rf03 creadas (4 clientes +1 cliente/admin compartido)" "5" \
   "$(q "SELECT COUNT(*) FROM clientes WHERE email LIKE 'rf03.%@test.local'")"
eq "Administrador sintetico rf03 creado (mismo correo que un cliente)" "1" \
   "$(q "SELECT COUNT(*) FROM administradores WHERE email LIKE 'rf03.%@test.local'")"

echo
echo "== RF03-BL-01/02: cuatro fallos permiten seguir; el 5.º activa el bloqueo =="
J_CUATRO="$TMP/cuatro.jar"
for _ in 1 2 3; do login "$J_CUATRO" "$EMAIL_CUATRO" 'mala' cliente >/dev/null; done
BODY=$(login "$J_CUATRO" "$EMAIL_CUATRO" 'mala' cliente)
notcontains "RF03-BL-01 tras 3 fallos el 4.º aun no encuentra bloqueo" 'Demasiados' "$BODY"
BODY=$(login "$J_CUATRO" "$EMAIL_CUATRO" 'Cliente#2026' cliente)
contains "RF03-BL-01 cuatro fallos: autenticacion correcta posible" '"ok":true' "$BODY"

BODY=$(login "$J_CUATRO" "$EMAIL_CUATRO" 'mala' cliente)
notcontains "RF03-BL-02 el 5.º fallo procesa credenciales (no esta bloqueado aun)" 'Demasiados' "$BODY"
contains "RF03-BL-02 el 5.º fallo informa credenciales incorrectas" 'incorrectos' "$BODY"

echo
echo "== RF03-BL-03/04/05: bloqueo activo, minutos restantes y password correcta =="
J_BLOQ="$TMP/bloq.jar"
for _ in 1 2 3 4 5; do login "$J_BLOQ" "$EMAIL_BLOQ" 'mala' cliente >/dev/null; done
BODY=$(login "$J_BLOQ" "$EMAIL_BLOQ" 'mala' cliente)
contains "RF03-BL-03 el 6.º intento queda bloqueado" 'Demasiados intentos' "$BODY"
contains "RF03-BL-03 el bloqueo responde JSON ok:false" '"ok":false' "$BODY"
eq "RF03-BL-03 el bloqueo conserva el contrato HTTP 200" "200" "$(login_code "$TMP/code.jar" "$EMAIL_BLOQ" 'mala' cliente)"
BODY=$(login "$J_BLOQ" "$EMAIL_BLOQ" 'mala' cliente)
contains "RF03-BL-04 informa los minutos restantes (2 min recien bloqueado)" 'en 2 minuto(s)' "$BODY"
BODY=$(login "$J_BLOQ" "$EMAIL_BLOQ" 'Cliente#2026' cliente)
contains "RF03-BL-05 la contrasena correcta NO autentica durante el bloqueo" 'Demasiados intentos' "$BODY"
notcontains "RF03-BL-05 la contrasena correcta no devuelve ok:true" '"ok":true' "$BODY"

echo
echo "== RF03-BL-06: el acceso exitoso reinicia el contador =="
J_RESET="$TMP/reset.jar"
for _ in 1 2 3 4; do login "$J_RESET" "$EMAIL_RESET" 'mala' cliente >/dev/null; done
BODY=$(login "$J_RESET" "$EMAIL_RESET" 'Cliente#2026' cliente)
contains "RF03-BL-06 login exitoso tras 4 fallos" '"ok":true' "$BODY"
for _ in 1 2 3 4; do login "$J_RESET" "$EMAIL_RESET" 'mala' cliente >/dev/null; done
BODY=$(login "$J_RESET" "$EMAIL_RESET" 'Cliente#2026' cliente)
contains "RF03-BL-06 tras el exito el contador arranca de cero (4 fallos mas y aun autentica)" '"ok":true' "$BODY"
notcontains "RF03-BL-06 sin residuo de bloqueo previo" 'Demasiados' "$BODY"

echo
echo "== RF03-BL-07: independencia entre correos =="
BODY=$(login "$TMP/indep.jar" "$EMAIL_INDEP" 'Cliente#2026' cliente)
contains "RF03-BL-07 un correo distinto autentica mientras otro esta bloqueado" '"ok":true' "$BODY"
notcontains "RF03-BL-07 el bloqueo no se propaga a otros correos" 'Demasiados' "$BODY"

echo
echo "== RF03-BL-08: coherencia del bloqueo entre roles (mismo correo) =="
J_ROL="$TMP/rol.jar"
for _ in 1 2 3 4 5; do login "$J_ROL" "$EMAIL_ROL" 'mala' cliente >/dev/null; done
BODY=$(login "$J_ROL" "$EMAIL_ROL" 'Cliente#2026' cliente)
contains "RF03-BL-08 cliente con credenciales correctas sigue bloqueado" 'Demasiados intentos' "$BODY"
BODY=$(login "$TMP/roladmin.jar" "$EMAIL_ROL" 'Admin#2026' admin "$CODIGO_ROL")
contains "RF03-BL-08 el mismo correo como administrador tambien esta bloqueado" 'Demasiados intentos' "$BODY"
notcontains "RF03-BL-08 el rol admin no elude el bloqueo" '"ok":true' "$BODY"
BODY=$(login "$TMP/adminlibre.jar" "rf03.adminlibre.${RUN}@test.local" 'Admin#2026' admin "$CODIGO_ROL")
notcontains "RF03-BL-08 control: otro correo no esta bloqueado (fallo de credenciales normal)" 'Demasiados' "$BODY"

echo
echo "== Limpieza =="
cleanup
trap - EXIT
eq "Cuentas sinteticas RF03 eliminadas" "0" \
   "$(q "SELECT (SELECT COUNT(*) FROM clientes WHERE email LIKE 'rf03.%@test.local') + (SELECT COUNT(*) FROM administradores WHERE email LIKE 'rf03.%@test.local')")"

echo
echo "=============================================="
echo "RESULTADO RF03: PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf 'FALLIDOS:\n'
  printf ' - %s\n' "${FAILS[@]}"
  exit 1
fi
exit 0
