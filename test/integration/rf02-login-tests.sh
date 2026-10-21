#!/usr/bin/env bash
# RF02 - Inicio de sesion de cliente y administrador.
# Pruebas HTTP de integracion contra Tomcat + base de PRUEBAS aislada.
#
# Requisitos:
#   - Tomcat con el contexto /LibreriaBrend desplegado.
#   - Base libreria_brenda_test creada con database/schema_test.sql.
#   - Cliente mysql accesible.
#
# Uso:
#   BASE=http://localhost:8091/LibreriaBrend \
#   DB_PORT=3307 DB_USER=root DB_PASSWORD= \
#   bash test/integration/rf02-login-tests.sh
#
# El script crea sus propios clientes/administrador ficticios por ejecucion,
# de modo que puede repetirse sin reiniciar Tomcat ni acumular bloqueos.
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

status() { # jar url
  curl -s -b "$1" -o /dev/null -w '%{http_code}' "$2"
}

session_id() { # jar
  awk '$6 == "JSESSIONID" { print $7 }' "$1" 2>/dev/null | tail -1
}

RUN="$(date +%s)-$$"
RUN_SHORT="$(date +%H%M%S)$$"
EMAIL_CLI="rf02.cli.${RUN}@test.local"
EMAIL_INACTIVO="rf02.inactivo.${RUN}@test.local"
EMAIL_ADMIN="rf02.admin.${RUN}@test.local"
EMAIL_HASH_ROTO="rf02.hashroto.${RUN}@test.local"
EMAIL_TEXTO="rf02.texto.${RUN}@test.local"
EMAIL_REGISTRO="rf02.registro.${RUN}@test.local"
CODIGO_ADMIN="EMP-${RUN_SHORT}"
DNI_CLI="$(printf '8%07d' $(( (RANDOM * 32768 + RANDOM) % 10000000 )))"
DNI_INACTIVO="$(printf '4%07d' $(( (RANDOM * 32768 + RANDOM) % 10000000 )))"
DNI_HASH_ROTO="$(printf '7%07d' $(( (RANDOM * 32768 + RANDOM) % 10000000 )))"
DNI_TEXTO="$(printf '6%07d' $(( (RANDOM * 32768 + RANDOM) % 10000000 )))"
DNI_REGISTRO="$(printf '5%07d' $(( (RANDOM * 32768 + RANDOM) % 10000000 )))"

HASH_CLI="$(sed -n "/INSERT INTO clientes/,/;/p" "$ROOT/database/fixtures_test.sql" | grep -oE '\$2a\$10\$[./A-Za-z0-9]+' | head -1)"
HASH_ADMIN="$(sed -n "/INSERT INTO administradores/,/;/p" "$ROOT/database/fixtures_test.sql" | grep -oE '\$2a\$10\$[./A-Za-z0-9]+' | head -1)"

cleanup() {
  q "DELETE FROM clientes WHERE email LIKE 'rf02.%@test.local'" >/dev/null
  q "DELETE FROM administradores WHERE email LIKE 'rf02.%@test.local'" >/dev/null
  rm -rf "$TMP"
}
trap cleanup EXIT

echo "== Preparacion: base de pruebas aislada =="
eq "La conexion apunta a libreria_brenda_test" "$DB_NAME" "$(q 'SELECT DATABASE()')"
eq "Fixture de clientes cargado" "3" "$(q 'SELECT COUNT(*) FROM clientes')"
eq "Fixture de administradores cargado" "1" "$(q 'SELECT COUNT(*) FROM administradores')"

q "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash, activo)
   VALUES ('Cliente', 'RF02 Activo', '$DNI_CLI', '$EMAIL_CLI', '900000111', 'Av. Pruebas 111, Lima', '$HASH_CLI', 1)"
q "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash, activo)
   VALUES ('Cliente', 'RF02 Inactivo', '$DNI_INACTIVO', '$EMAIL_INACTIVO', '900000222', 'Av. Pruebas 222, Lima', '$HASH_CLI', 0)"
q "INSERT INTO administradores (nombre, email, password_hash, codigo_empleado)
   VALUES ('Admin RF02', '$EMAIL_ADMIN', '$HASH_ADMIN', '$CODIGO_ADMIN')"
q "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash, activo)
   VALUES ('Cliente', 'RF02 Hash Roto', '$DNI_HASH_ROTO', '$EMAIL_HASH_ROTO', '900000333', 'Av. Pruebas 333, Lima', '\$2a\$10\$abc', 1)"
q "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash, activo)
   VALUES ('Cliente', 'RF02 Texto Plano', '$DNI_TEXTO', '$EMAIL_TEXTO', '900000444', 'Av. Pruebas 444, Lima', 'Cliente#2026', 1)"
eq "Cuenta activa ficticia creada" "1" "$(q "SELECT COUNT(*) FROM clientes WHERE email='$EMAIL_CLI' AND activo=1")"
eq "Cuenta inactiva ficticia creada" "1" "$(q "SELECT COUNT(*) FROM clientes WHERE email='$EMAIL_INACTIVO' AND activo=0")"
eq "Administrador ficticio creado" "1" "$(q "SELECT COUNT(*) FROM administradores WHERE email='$EMAIL_ADMIN'")"

echo
echo "== RF02-CL: inicio de sesion de cliente =="
J_CLI="$TMP/cli.jar"
BODY=$(login "$J_CLI" "$EMAIL_CLI" 'Cliente#2026' cliente)
contains "RF02-CL-01 credenciales validas -> ok" '"ok":true' "$BODY"
contains "RF02-CL-01 redirige al catalogo" '"redirect":"index.jsp"' "$BODY"
eq "RF02-CL-02 la sesion de cliente da acceso a sus pedidos" "200" "$(status "$J_CLI" "$BASE/PedidoServlet")"

J_WRONG="$TMP/wrong.jar"
BODY=$(login "$J_WRONG" "$EMAIL_CLI" 'cliente#2026' cliente)
contains "RF02-CL-03 contrasena incorrecta -> rechazo" '"ok":false' "$BODY"
contains "RF02-CL-03 mensaje sin revelar el campo fallido" 'Correo o contraseña incorrectos' "$BODY"
eq "RF02-CL-03 no se crea sesion autenticada" "401" "$(status "$J_WRONG" "$BASE/PedidoServlet")"

J_INACTIVO="$TMP/inactivo.jar"
BODY=$(login "$J_INACTIVO" "$EMAIL_INACTIVO" 'Cliente#2026' cliente)
contains "RF02-CL-04 cuenta inactiva con contrasena correcta -> rechazo" '"ok":false' "$BODY"
eq "RF02-CL-04 cuenta inactiva no obtiene sesion" "401" "$(status "$J_INACTIVO" "$BASE/PedidoServlet")"

J_NOEXISTE="$TMP/noexiste.jar"
BODY=$(login "$J_NOEXISTE" "rf02.nadie.${RUN}@test.local" 'Cliente#2026' cliente)
contains "RF02-CL-05 correo inexistente -> rechazo" '"ok":false' "$BODY"
contains "RF02-CL-05 mismo mensaje que contrasena incorrecta" 'Correo o contraseña incorrectos' "$BODY"

FORMATO_ERROR='Ingresa un correo con formato válido'
for caso in 'sin-arroba' 'sin-dominio@test' 'con espacio@test.local' '@test.local' 'doble@@test.local'; do
  BODY=$(login "$TMP/fmt.jar" "$caso" 'Cliente#2026' cliente)
  contains "RF02-CL-06 correo invalido '$caso' rechazado por formato" "$FORMATO_ERROR" "$BODY"
done

LONG_EMAIL="$(printf 'a%.0s' $(seq 1 110))@test.local"
BODY=$(login "$TMP/largo.jar" "$LONG_EMAIL" 'Cliente#2026' cliente)
contains "RF02-CL-07 correo de 121 caracteres rechazado (limite de columna 120)" "$FORMATO_ERROR" "$BODY"

BODY=$(login "$TMP/vacio.jar" "$EMAIL_CLI" '' cliente)
contains "RF02-CL-08 contrasena vacia -> campos incompletos" 'Completa todos los campos' "$BODY"
BODY=$(login "$TMP/vacio2.jar" '' 'Cliente#2026' cliente)
contains "RF02-CL-08 correo vacio -> campos incompletos" 'Completa todos los campos' "$BODY"

BODY=$(curl -s -c "$TMP/sinrol.jar" -b "$TMP/sinrol.jar" -X POST "$BASE/LoginServlet" \
  --data-urlencode "email=$EMAIL_CLI" --data-urlencode 'password=Cliente#2026')
contains "RF02-CL-09 rol ausente -> campos incompletos" 'Completa todos los campos' "$BODY"

BODY=$(login "$TMP/rol.jar" "$EMAIL_CLI" 'Cliente#2026' auditor)
contains "RF02-CL-10 rol desconocido rechazado" 'Rol no reconocido' "$BODY"

J_TRIM="$TMP/trim.jar"
BODY=$(login "$J_TRIM" "  $EMAIL_CLI  " 'Cliente#2026' cliente)
contains "RF02-CL-11 espacios externos en el correo se ignoran" '"ok":true' "$BODY"

J_MAYUS="$TMP/mayus.jar"
BODY=$(login "$J_MAYUS" "$(echo "$EMAIL_CLI" | tr '[:lower:]' '[:upper:]')" 'Cliente#2026' cliente)
contains "RF02-CL-12 el correo no distingue mayusculas (collation de la BD)" '"ok":true' "$BODY"

BODY=$(login "$TMP/hashroto.jar" "$EMAIL_HASH_ROTO" 'Cliente#2026' cliente)
contains "RF02-CL-13 hash BCrypt truncado no autentica" '"ok":false' "$BODY"
contains "RF02-CL-13 hash truncado responde error controlado, no 500" 'Correo o contraseña incorrectos' "$BODY"

BODY=$(login "$TMP/texto.jar" "$EMAIL_TEXTO" 'Cliente#2026' cliente)
contains "RF02-CL-14 hash en texto plano no autentica" '"ok":false' "$BODY"

echo
echo "== RF02-AD: inicio de sesion de administrador =="
J_ADMIN="$TMP/admin.jar"
BODY=$(login "$J_ADMIN" "$EMAIL_ADMIN" 'Admin#2026' admin "$CODIGO_ADMIN")
contains "RF02-AD-01 correo + contrasena + codigo validos -> ok" '"ok":true' "$BODY"
contains "RF02-AD-01 redirige al panel" '"redirect":"admin.jsp"' "$BODY"
eq "RF02-AD-02 la sesion de admin abre admin.jsp" "200" "$(status "$J_ADMIN" "$BASE/admin.jsp")"
eq "RF02-AD-02 la sesion de admin puede listar clientes" "200" "$(status "$J_ADMIN" "$BASE/ClienteServlet")"
eq "RF02-AD-02 un admin no obtiene sesion de cliente" "401" "$(status "$J_ADMIN" "$BASE/PedidoServlet")"

BODY=$(login "$TMP/mayusadmin.jar" "$(echo "$EMAIL_ADMIN" | tr '[:lower:]' '[:upper:]')" 'Admin#2026' admin "$CODIGO_ADMIN")
contains "RF02-AD-09 correo de admin no distingue mayusculas" '"ok":true' "$BODY"

J_CODIGO="$TMP/codigo.jar"
BODY=$(login "$J_CODIGO" "$EMAIL_ADMIN" 'Admin#2026' admin 'EMP-INCORRECTO')
contains "RF02-AD-03 codigo de empleado incorrecto -> rechazo" '"ok":false' "$BODY"
contains "RF02-AD-03 mensaje de credenciales de empleado" 'Credenciales de empleado incorrectas' "$BODY"
eq "RF02-AD-03 codigo incorrecto no crea sesion" "302" "$(curl -s -b "$J_CODIGO" -o /dev/null -w '%{http_code}' "$BASE/admin.jsp")"

J_PASS="$TMP/passadmin.jar"
BODY=$(login "$J_PASS" "$EMAIL_ADMIN" 'Admin#2027' admin "$CODIGO_ADMIN")
contains "RF02-AD-04 contrasena incorrecta con codigo correcto -> rechazo" '"ok":false' "$BODY"

BODY=$(curl -s -c "$TMP/nocodigo.jar" -b "$TMP/nocodigo.jar" -X POST "$BASE/LoginServlet" \
  --data-urlencode "email=$EMAIL_ADMIN" --data-urlencode 'password=Admin#2026' --data-urlencode 'rol=admin')
contains "RF02-AD-05 codigo de empleado ausente -> rechazo" '"ok":false' "$BODY"

BODY=$(login "$TMP/codigovacio.jar" "$EMAIL_ADMIN" 'Admin#2026' admin '')
contains "RF02-AD-06 codigo de empleado vacio -> rechazo" '"ok":false' "$BODY"

BODY=$(login "$TMP/cruzado.jar" "$EMAIL_CLI" 'Cliente#2026' admin 'EMP-0000')
contains "RF02-AD-07 una cuenta de cliente no entra como administrador" '"ok":false' "$BODY"

BODY=$(login "$TMP/cruzado2.jar" "$EMAIL_ADMIN" 'Admin#2026' cliente)
contains "RF02-AD-08 un administrador no entra con el rol cliente" '"ok":false' "$BODY"

echo
echo "== RF02-AZ: control de acceso ligado a la sesion =="
eq "RF02-AZ-01 admin.jsp anonimo redirige al login" "302" "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/admin.jsp")"
eq "RF02-AZ-02 admin.jsp con sesion de cliente redirige al login" "302" "$(status "$J_CLI" "$BASE/admin.jsp")"
eq "RF02-AZ-03 listado de clientes anonimo -> 401" "401" "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/ClienteServlet")"
eq "RF02-AZ-04 crear producto con sesion de cliente -> 401" "401" \
  "$(curl -s -b "$J_CLI" -o /dev/null -w '%{http_code}' -X POST "$BASE/ProductoServlet" \
      --data-urlencode 'accion=crear' --data-urlencode 'nombre=RF02' --data-urlencode 'precio=10' \
      --data-urlencode 'stock=1' --data-urlencode 'categoria=Libros')"
eq "RF02-AZ-05 crear producto sin sesion -> 401" "401" \
  "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/ProductoServlet" \
      --data-urlencode 'accion=crear' --data-urlencode 'nombre=RF02' --data-urlencode 'precio=10' \
      --data-urlencode 'stock=1' --data-urlencode 'categoria=Libros')"

J_LOGOUT="$TMP/logout.jar"
login "$J_LOGOUT" "$EMAIL_CLI" 'Cliente#2026' cliente >/dev/null
curl -s -b "$J_LOGOUT" -c "$J_LOGOUT" -o /dev/null "$BASE/LogoutServlet"
eq "RF02-AZ-06 logout invalida la sesion" "401" "$(status "$J_LOGOUT" "$BASE/PedidoServlet")"

echo
echo "== RF02-SES: higiene de sesion =="
J_FIX="$TMP/fixation.jar"
rm -f "$J_FIX"
curl -s -c "$J_FIX" -b "$J_FIX" -o /dev/null "$BASE/login.jsp"
ID_ANTES="$(session_id "$J_FIX")"
login "$J_FIX" "$EMAIL_CLI" 'Cliente#2026' cliente >/dev/null
ID_DESPUES="$(session_id "$J_FIX")"
[ -n "$ID_ANTES" ] && [ -n "$ID_DESPUES" ] \
  && ok "RF02-SES-01 sesion previa identificada antes del login" \
  || ko "RF02-SES-01 sesion previa identificada antes del login" "JSESSIONID antes y despues" "antes=[$ID_ANTES] despues=[$ID_DESPUES]"
eq "RF02-SES-02 el login rota el identificador de sesion (anti session fixation)" "distinto" \
  "$([ -n "$ID_ANTES" ] && [ -n "$ID_DESPUES" ] && [ "$ID_ANTES" != "$ID_DESPUES" ] && echo distinto || echo igual)"

J_REG="$TMP/registro.jar"
rm -f "$J_REG"
curl -s -c "$J_REG" -b "$J_REG" -o /dev/null "$BASE/registro.jsp"
ID_REG_ANTES="$(session_id "$J_REG")"
BODY=$(curl -s -c "$J_REG" -b "$J_REG" -X POST "$BASE/RegistroServlet" \
  --data-urlencode 'nombres=Cliente' --data-urlencode 'apellidos=RF02 Registro' \
  --data-urlencode "dni=$DNI_REGISTRO" --data-urlencode "email=$EMAIL_REGISTRO" \
  --data-urlencode 'telefono=900000555' --data-urlencode 'direccion=Av. Pruebas 555, Lima' \
  --data-urlencode 'password=Cliente#2026')
contains "RF02-SES-03 el registro crea la sesion del cliente" '"ok":true' "$BODY"
ID_REG_DESPUES="$(session_id "$J_REG")"
eq "RF02-SES-04 el registro rota el identificador de sesion" "distinto" \
  "$([ -n "$ID_REG_ANTES" ] && [ -n "$ID_REG_DESPUES" ] && [ "$ID_REG_ANTES" != "$ID_REG_DESPUES" ] && echo distinto || echo igual)"
eq "RF02-SES-04 la sesion del registro permite ver pedidos" "200" "$(status "$J_REG" "$BASE/PedidoServlet")"

echo
echo "== RF02-BR: bloqueo por intentos fallidos =="
EMAIL_BRUTO="rf02.bruto.${RUN}@test.local"
J_BRUTO="$TMP/bruto.jar"
for _ in 1 2 3 4; do login "$J_BRUTO" "$EMAIL_BRUTO" 'mala' cliente >/dev/null; done
BODY=$(login "$J_BRUTO" "$EMAIL_BRUTO" 'mala' cliente)
notcontains "RF02-BR-01 el 5.º intento aun procesa credenciales" 'Demasiados intentos' "$BODY"
BODY=$(login "$J_BRUTO" "$EMAIL_BRUTO" 'mala' cliente)
contains "RF02-BR-02 el 6.º intento queda bloqueado" 'Demasiados intentos' "$BODY"

BODY=$(login "$TMP/otro.jar" "rf02.otro.${RUN}@test.local" 'mala' cliente)
notcontains "RF02-BR-03 el bloqueo no afecta a otros correos" 'Demasiados intentos' "$BODY"

J_RESET="$TMP/reset.jar"
for _ in 1 2 3 4; do login "$J_RESET" "$EMAIL_CLI" 'mala' cliente >/dev/null; done
BODY=$(login "$J_RESET" "$EMAIL_CLI" 'Cliente#2026' cliente)
contains "RF02-BR-04 login exitoso tras 4 fallos" '"ok":true' "$BODY"
for _ in 1 2 3 4; do login "$J_RESET" "$EMAIL_CLI" 'mala' cliente >/dev/null; done
BODY=$(login "$J_RESET" "$EMAIL_CLI" 'Cliente#2026' cliente)
contains "RF02-BR-05 el exito reinicia el contador de fallos" '"ok":true' "$BODY"

echo
echo "== Limpieza =="
cleanup
trap - EXIT
eq "Cuentas ficticias RF02 eliminadas" "0" \
  "$(q "SELECT (SELECT COUNT(*) FROM clientes WHERE email LIKE 'rf02.%@test.local') + (SELECT COUNT(*) FROM administradores WHERE email LIKE 'rf02.%@test.local')")"

echo
echo "=============================================="
echo "RESULTADO RF02: PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf 'FALLIDOS:\n'
  printf ' - %s\n' "${FAILS[@]}"
  exit 1
fi
exit 0
