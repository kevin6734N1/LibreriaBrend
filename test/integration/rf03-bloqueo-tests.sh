#!/usr/bin/env bash
# RF03 - Bloqueo temporal por intentos fallidos.
# Pruebas HTTP de integracion contra LoginServlet con Tomcat aislado + base
# de PRUEBAS aislada (libreria_brenda_test). NO cubre la expiracion de 120 s
# en tiempo real: esa frontera se valida de forma determinista con reloj
# inyectado en test/libreria/util/ControlIntentosLoginExpiracionTest.java.
#
# SEGURIDAD DE DATOS (correccion posterior a la revision del PR #4):
#   - Toda precondicion de aislamiento es FATAL: si alguna falla, el script
#     termina con exit 1 ANTES de registrar el trap y ANTES de cualquier
#     INSERT/DELETE. El trap de limpieza unicamente se instala despues de
#     que todas las precondiciones pasan.
#   - Exige literalmente DB_NAME=libreria_brenda_test (no una comparacion
#     contra la propia variable) y que SELECT DATABASE() devuelva ese
#     mismo esquema.
#   - El cleanup elimina SOLO los correos creados por ESTA ejecucion
#     (nunca un LIKE generico sobre rf03.*@test.local).
#
# Requisitos:
#   - Tomcat de pruebas con el contexto /LibreriaBrend desplegado en :8091.
#   - Base libreria_brenda_test creada con database/schema_test.sql + fixtures.
#   - Cliente mysql accesible.
#
# Uso:
#   BASE=http://localhost:8091/LibreriaBrend \
#   DB_PORT=3307 DB_USER=root DB_PASSWORD= \
#   bash test/integration/rf03-bloqueo-tests.sh
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

# FATAL para precondiciones: aborta sin escrituras ni limpieza.
abortar() {
  echo "FALLO DE PRECONDICION: $1"
  echo "ABORTADO: no se ejecuto ningun INSERT ni DELETE."
  rm -rf "$TMP"
  exit 1
}

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

# Solo los correos de ESTA ejecucion (para cleanup y verificaciones).
MIS_CLIENTES="'$EMAIL_CUATRO','$EMAIL_BLOQ','$EMAIL_INDEP','$EMAIL_RESET','$EMAIL_ROL'"
MIS_ADMINS="'$EMAIL_ROL'"

HASH_CLI="$(sed -n "/INSERT INTO clientes/,/;/p" "$ROOT/database/fixtures_test.sql" | grep -oE '\$2a\$10\$[./A-Za-z0-9]+' | head -1)"
HASH_ADMIN="$(sed -n "/INSERT INTO administradores/,/;/p" "$ROOT/database/fixtures_test.sql" | grep -oE '\$2a\$10\$[./A-Za-z0-9]+' | head -1)"

cleanup() {
  q "DELETE FROM administradores WHERE email IN ($MIS_ADMINS)" >/dev/null
  q "DELETE FROM clientes WHERE email IN ($MIS_CLIENTES)" >/dev/null
  rm -rf "$TMP"
}

echo "== Preparacion: aislamiento obligatorio (todas las condiciones son fatales) =="

# 1) El esquema exigido es literal, no la propia variable.
if [ "$DB_NAME" != "libreria_brenda_test" ]; then
  abortar "DB_NAME='$DB_NAME' (se exige literalmente libreria_brenda_test)"
fi
ok "DB_NAME literalmente libreria_brenda_test"

# 2) El Tomcat debe ser el de pruebas aislado (:8091).
case "$BASE" in
  *:8091*) ok "BASE apunta al Tomcat de pruebas aislado (:8091)" ;;
  *) abortar "BASE='$BASE' no apunta al Tomcat de pruebas :8091" ;;
esac

# 3) La conexion activa debe devolver ese mismo esquema.
DB_ACTUAL="$(q 'SELECT DATABASE()')"
if [ "$DB_ACTUAL" != "libreria_brenda_test" ]; then
  abortar "SELECT DATABASE()='$DB_ACTUAL' (se exige libreria_brenda_test)"
fi
ok "SELECT DATABASE() = libreria_brenda_test"

# 4) Fixtures de la base de pruebas presentes.
[ "$(q 'SELECT COUNT(*) FROM clientes')" = "3" ] \
  || abortar "fixtures de clientes ausentes o alterados en libreria_brenda_test"
ok "Fixture de clientes cargado (3)"
[ "$(q 'SELECT COUNT(*) FROM administradores')" = "1" ] \
  || abortar "fixtures de administradores ausentes o alterados en libreria_brenda_test"
ok "Fixture de administradores cargado (1)"

# 5) En este motor NO existen las bases prohibidas.
[ -z "$(q "SHOW DATABASES LIKE 'libreria_brenda'")" ] \
  || abortar "el motor expone la base comercial libreria_brenda"
ok "En este motor NO existe la base comercial libreria_brenda"
[ -z "$(q "SHOW DATABASES LIKE 'libreria_brenda_demo'")" ] \
  || abortar "el motor expone la base demo libreria_brenda_demo"
ok "En este motor NO existe la base demo"

# Precondiciones superadas: a partir de aqui si se instala el trap de limpieza.
trap cleanup EXIT

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
eq "Cuentas sinteticas de ESTA ejecucion creadas (5 clientes)" "5" \
   "$(q "SELECT COUNT(*) FROM clientes WHERE email IN ($MIS_CLIENTES)")"
eq "Administrador sintetico creado (mismo correo que un cliente)" "1" \
   "$(q "SELECT COUNT(*) FROM administradores WHERE email IN ($MIS_ADMINS)")"

echo
echo "== RF03-BL-01: cuatro fallos no bloquean y permiten autenticar =="
J_CUATRO="$TMP/cuatro.jar"
for _ in 1 2 3; do login "$J_CUATRO" "$EMAIL_CUATRO" 'mala' cliente >/dev/null; done
BODY=$(login "$J_CUATRO" "$EMAIL_CUATRO" 'mala' cliente)
notcontains "RF03-BL-01 tras 3 fallos el 4.º aun no encuentra bloqueo" 'Demasiados' "$BODY"
BODY=$(login "$J_CUATRO" "$EMAIL_CUATRO" 'Cliente#2026' cliente)
contains "RF03-BL-01 cuatro fallos: autenticacion correcta posible" '"ok":true' "$BODY"

echo
echo "== RF03-BL-02: el 5.º fallo PROPIO activa el bloqueo =="
J_BLOQ="$TMP/bloq.jar"
for _ in 1 2 3 4; do login "$J_BLOQ" "$EMAIL_BLOQ" 'mala' cliente >/dev/null; done
# Quinto fallo consecutivo de este ciclo (sin ningun exito intermedio):
BODY=$(login "$J_BLOQ" "$EMAIL_BLOQ" 'mala' cliente)
notcontains "RF03-BL-02 el 5.º fallo procesa credenciales (no esta bloqueado aun)" 'Demasiados' "$BODY"
contains "RF03-BL-02 el 5.º fallo informa credenciales incorrectas" 'incorrectos' "$BODY"

echo
echo "== RF03-BL-03/04/05: bloqueo activo, minutos restantes y password correcta =="
BODY=$(login "$J_BLOQ" "$EMAIL_BLOQ" 'mala' cliente)
contains "RF03-BL-03 el 6.º intento recibe el mensaje de bloqueo" 'Demasiados intentos' "$BODY"
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
echo "== Limpieza (solo correos de esta ejecucion) =="
cleanup
trap - EXIT
eq "Cuentas de ESTA ejecucion eliminadas" "0" \
   "$(q "SELECT (SELECT COUNT(*) FROM clientes WHERE email IN ($MIS_CLIENTES)) + (SELECT COUNT(*) FROM administradores WHERE email IN ($MIS_ADMINS))")"

echo
echo "=============================================="
echo "RESULTADO RF03: PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf 'FALLIDOS:\n'
  printf ' - %s\n' "${FAILS[@]}"
  exit 1
fi
exit 0
