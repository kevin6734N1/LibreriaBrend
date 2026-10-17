#!/usr/bin/env bash
# Pruebas de integración HTTP/BD de LibreriaBrend contra:
#   - Tomcat aislado en http://localhost:8091/LibreriaBrend
#   - base de datos libreria_brenda_test
# No toca la base real ni la instancia del usuario.
set -u

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

ok()  { PASS=$((PASS+1)); echo "PASS  $1"; }
ko()  { FAIL=$((FAIL+1)); FAILS+=("$1"); echo "FAIL  $1 | esperado=[$2] actual=[$3]"; }
eq()  { if [ "$2" = "$3" ]; then ok "$1"; else ko "$1" "$2" "$3"; fi; }
contains() { case "$3" in *"$2"*) ok "$1";; *) ko "$1" "contiene '$2'" "$3";; esac; }
notcontains() { case "$3" in *"$2"*) ko "$1" "NO contiene '$2'" "$3";; *) ok "$1";; esac; }

reset_fixtures() {
  "${MYSQL[@]}" < database/fixtures_test.sql 2>/dev/null
}

login() { # jar email pass rol [codigo]
  local jar=$1 email=$2 pass=$3 rol=$4 codigo=${5:-}
  local args=(--data-urlencode "email=$email" --data-urlencode "password=$pass" --data-urlencode "rol=$rol")
  [ -n "$codigo" ] && args+=(--data-urlencode "codigo=$codigo")
  curl -s -c "$jar" -b "$jar" -X POST "$BASE/LoginServlet" "${args[@]}"
}

pp() { # jar outfile args...
  local jar=$1 out=$2; shift 2
  curl -s -b "$jar" -o "$out" -w "%{http_code}" -X POST "$BASE/ProductoServlet" "$@"
}

po() { # jar outfile args...
  local jar=$1 out=$2; shift 2
  curl -s -b "$jar" -c "$jar" -o "$out" -w "%{http_code}" -X POST "$BASE/PedidoServlet" "$@"
}

echo "== Reiniciando fixtures de prueba =="
reset_fixtures
eq "BD de prueba inicia sin pedidos" "0" "$(q 'SELECT COUNT(*) FROM pedidos')"
eq "BD de prueba tiene 14 productos ficticios" "14" "$(q 'SELECT COUNT(*) FROM productos')"

echo
echo "== IT-01 / QA-02: acceso sin sesión =="
code=$(curl -s -o /tmp/it_anon_get.json -w "%{http_code}" "$BASE/PedidoServlet")
eq "GET PedidoServlet anónimo -> 401" "401" "$code"
contains "GET anónimo no expone pedidos" "Inicia sesión" "$(cat /tmp/it_anon_get.json)"

code=$(curl -s -o /tmp/it_anon_cancel.json -w "%{http_code}" -X POST "$BASE/PedidoServlet" \
  --data-urlencode "accion=cancelarPedido" --data-urlencode "idPedido=PED-1001")
eq "Cancelar pedido anónimo -> 401" "401" "$code"

code=$(curl -s -o /tmp/it_anon_create.json -w "%{http_code}" -X POST "$BASE/PedidoServlet" \
  --data-urlencode "accion=guardarDB" --data-urlencode "item_id=1" --data-urlencode "item_qty=1" \
  --data-urlencode "pago=Yape")
eq "Crear pedido anónimo -> 401" "401" "$code"
eq "Ningún pedido creado por anónimos" "0" "$(q 'SELECT COUNT(*) FROM pedidos')"

code=$(curl -s -o /tmp/it_anon_admin.json -w "%{http_code}" -X POST "$BASE/ProductoServlet" \
  --data-urlencode "accion=crear" --data-urlencode "nombre=X" --data-urlencode "precio=1" \
  --data-urlencode "stock=1" --data-urlencode "categoria=Libros")
eq "POST producto sin sesión admin -> 401" "401" "$code"

code=$(curl -s -o /tmp/it_admin_page.html -w "%{http_code}" "$BASE/admin.jsp")
eq "admin.jsp sin sesión -> 302" "302" "$code"

echo
echo "== IT-02: usuario inactivo =="
rm -f /tmp/c_inactivo.txt
body=$(login /tmp/c_inactivo.txt "inactivo@test.local" "Cliente#2026" "cliente")
contains "Login de cliente inactivo rechazado" '"ok":false' "$body"
code=$(curl -s -b /tmp/c_inactivo.txt -o /tmp/it_inactivo.json -w "%{http_code}" "$BASE/PedidoServlet")
eq "Sesión no creada para inactivo" "401" "$code"

echo
echo "== IT-03: bloqueo tras 5 fallos =="
rm -f /tmp/c_bloqueo.txt
# Email único por ejecución: el control de intentos es estático y vive en memoria.
BLOQUEO_EMAIL="bloqueo-$(date +%s)-$$@test.local"
for i in 1 2 3 4; do
  body=$(login /tmp/c_bloqueo.txt "$BLOQUEO_EMAIL" "mala-clave" "cliente")
done
notcontains "Tras 4 fallos aún no bloquea" "Demasiados intentos" "$body"
body=$(login /tmp/c_bloqueo.txt "$BLOQUEO_EMAIL" "mala-clave" "cliente")
notcontains "El 5.º fallo procesa credenciales y activa el bloqueo" "Demasiados intentos" "$body"
body=$(login /tmp/c_bloqueo.txt "$BLOQUEO_EMAIL" "mala-clave" "cliente")
contains "Tras 5 fallos el 6.º intento queda bloqueado" "Demasiados intentos" "$body"

echo
echo "== IT-04 / IT-05 / QA-06 / QA-10: validación de productos =="
rm -f /tmp/c_admin.txt
body=$(login /tmp/c_admin.txt "admin@test.local" "Admin#2026" "admin" "EMP-TEST")
contains "Login admin de prueba" '"ok":true' "$body"

P0=$(q 'SELECT COUNT(*) FROM productos')
code=$(pp /tmp/c_admin.txt /tmp/p0.json --data-urlencode "accion=crear" --data-urlencode "nombre=Producto precio cero" --data-urlencode "precio=0" --data-urlencode "stock=5" --data-urlencode "categoria=Libros")
eq "Precio 0 -> 400" "400" "$code"; eq "Precio 0 no inserta" "$P0" "$(q 'SELECT COUNT(*) FROM productos')"

code=$(pp /tmp/c_admin.txt /tmp/p1.json --data-urlencode "accion=crear" --data-urlencode "nombre=Producto precio negativo" --data-urlencode "precio=-1" --data-urlencode "stock=5" --data-urlencode "categoria=Libros")
eq "Precio -1 -> 400" "400" "$code"; eq "Precio -1 no inserta" "$P0" "$(q 'SELECT COUNT(*) FROM productos')"

code=$(pp /tmp/c_admin.txt /tmp/p2.json --data-urlencode "accion=crear" --data-urlencode "nombre=Producto stock negativo" --data-urlencode "precio=10" --data-urlencode "stock=-1" --data-urlencode "categoria=Libros")
eq "Stock -1 -> 400" "400" "$code"; eq "Stock -1 no inserta" "$P0" "$(q 'SELECT COUNT(*) FROM productos')"

code=$(pp /tmp/c_admin.txt /tmp/p3.json --data-urlencode "accion=crear" --data-urlencode "nombre=Producto stock abc" --data-urlencode "precio=10" --data-urlencode "stock=abc" --data-urlencode "categoria=Libros")
eq "Stock abc -> 400" "400" "$code"; eq "Stock abc no inserta ni vale 0" "$P0" "$(q 'SELECT COUNT(*) FROM productos')"

code=$(pp /tmp/c_admin.txt /tmp/p4.json --data-urlencode "accion=crear" --data-urlencode "nombre=Producto precio abc" --data-urlencode "precio=abc" --data-urlencode "stock=5" --data-urlencode "categoria=Libros")
eq "Precio abc -> 400" "400" "$code"; eq "Precio abc no inserta" "$P0" "$(q 'SELECT COUNT(*) FROM productos')"

code=$(pp /tmp/c_admin.txt /tmp/p5.json --data-urlencode "accion=crear" --data-urlencode "nombre=" --data-urlencode "precio=10" --data-urlencode "stock=5" --data-urlencode "categoria=Libros")
eq "Nombre vacío -> 400" "400" "$code"

code=$(pp /tmp/c_admin.txt /tmp/p6.json --data-urlencode "accion=crear" --data-urlencode "nombre=Producto categoria vacia" --data-urlencode "precio=10" --data-urlencode "stock=5" --data-urlencode "categoria=")
eq "Categoría vacía -> 400" "400" "$code"

code=$(pp /tmp/c_admin.txt /tmp/p7.json --data-urlencode "accion=crear" --data-urlencode "nombre=Producto Categoria Fantasma" --data-urlencode "precio=10" --data-urlencode "stock=5" --data-urlencode "categoria=NoExiste")
eq "Categoría inexistente -> 400" "400" "$code"
contains "Categoría inexistente da error explícito" "no existe" "$(cat /tmp/p7.json)"
eq "Categoría inexistente no usa fallback ni inserta" "0" "$(q "SELECT COUNT(*) FROM productos WHERE nombre='Producto Categoria Fantasma'")"
eq "Ninguna fila quedó en categoría 1 por fallback" "0" "$(q "SELECT COUNT(*) FROM productos WHERE nombre='Producto Categoria Fantasma' AND categoria_id=1")"

echo
echo "== Caso válido de producto y edición =="
code=$(pp /tmp/c_admin.txt /tmp/pv.json --data-urlencode "accion=crear" --data-urlencode "nombre=Producto HTTP Valido" --data-urlencode "precio=12.50" --data-urlencode "stock=3" --data-urlencode "categoria=Libros")
eq "Crear producto válido -> 200" "200" "$code"
PID=$(q "SELECT id FROM productos WHERE nombre='Producto HTTP Valido' LIMIT 1")
[ -n "$PID" ] && ok "Producto válido insertado (id=$PID)" || ko "Producto válido insertado" "id" "vacío"
eq "Categoría asignada correctamente" "Libros" "$(q "SELECT c.nombre FROM productos p JOIN categorias c ON c.id=p.categoria_id WHERE p.id=$PID")"

code=$(pp /tmp/c_admin.txt /tmp/pe.json --data-urlencode "accion=editar" --data-urlencode "id=$PID" --data-urlencode "nombre=Producto HTTP Valido" --data-urlencode "precio=7.50" --data-urlencode "stock=0" --data-urlencode "categoria=Libros")
eq "Editar con stock 0 (válido) -> 200" "200" "$code"
eq "Stock 0 aceptado" "0" "$(q "SELECT stock FROM productos WHERE id=$PID")"

code=$(pp /tmp/c_admin.txt /tmp/pe2.json --data-urlencode "accion=editar" --data-urlencode "id=$PID" --data-urlencode "nombre=Producto HTTP Valido" --data-urlencode "precio=7.50" --data-urlencode "stock=abc" --data-urlencode "categoria=Libros")
eq "Editar stock abc -> 400" "400" "$code"
eq "Edición inválida no modifica stock" "0" "$(q "SELECT stock FROM productos WHERE id=$PID")"

code=$(pp /tmp/c_admin.txt /tmp/pe3.json --data-urlencode "accion=editar" --data-urlencode "id=$PID" --data-urlencode "nombre=Producto HTTP Valido" --data-urlencode "precio=7.50" --data-urlencode "stock=0" --data-urlencode "categoria=NoExiste")
eq "Editar con categoría inexistente -> 400" "400" "$code"
eq "Edición inválida no cambia categoría" "Libros" "$(q "SELECT c.nombre FROM productos p JOIN categorias c ON c.id=p.categoria_id WHERE p.id=$PID")"

echo
echo "== IT-06 / IT-07 / IT-09 / IT-10: pedidos =="
rm -f /tmp/c_a.txt /tmp/c_b.txt
login /tmp/c_a.txt "cliente.a@test.local" "Cliente#2026" "cliente" >/dev/null
login /tmp/c_b.txt "cliente.b@test.local" "Cliente#2026" "cliente" >/dev/null

code=$(po /tmp/c_a.txt /tmp/order1.json --data-urlencode "accion=guardarDB" \
  --data-urlencode "item_id=1" --data-urlencode "item_qty=3" --data-urlencode "item_precio=0.01" \
  --data-urlencode "direccion=Av. Pruebas 100" --data-urlencode "pago=Yape")
eq "Crear pedido con sesión -> 200" "200" "$code"
OID=$(sed -n 's/.*"id":"\([^"]*\)".*/\1/p' /tmp/order1.json)
[ -n "$OID" ] && ok "Pedido creado ($OID)" || ko "Pedido creado" "id" "$(cat /tmp/order1.json)"
eq "Precio recalculado desde BD (15.00+10.00=25.00)" "15.00|10.00|25.00|PENDIENTE" "$(q "SELECT CONCAT(subtotal,'|',envio,'|',total,'|',estado) FROM pedidos WHERE id='$OID'")"
eq "Stock descontado (100-3)" "97" "$(q 'SELECT stock FROM productos WHERE id=1')"

GETA=$(curl -s -b /tmp/c_a.txt "$BASE/PedidoServlet")
GETB=$(curl -s -b /tmp/c_b.txt "$BASE/PedidoServlet")
contains "Cliente A ve su pedido" "$OID" "$GETA"
notcontains "Cliente B NO ve el pedido de A" "$OID" "$GETB"

code=$(po /tmp/c_b.txt /tmp/cancelb.json --data-urlencode "accion=cancelarPedido" --data-urlencode "idPedido=$OID")
eq "B no puede cancelar pedido de A -> 400" "400" "$code"
eq "Pedido de A sigue PENDIENTE" "PENDIENTE" "$(q "SELECT estado FROM pedidos WHERE id='$OID'")"
eq "Stock no cambia por cancelación ajena" "97" "$(q 'SELECT stock FROM productos WHERE id=1')"

code=$(po /tmp/c_a.txt /tmp/cancela.json --data-urlencode "accion=cancelarPedido" --data-urlencode "idPedido=$OID")
eq "A cancela su pedido PENDIENTE -> 200" "200" "$code"
eq "Pedido queda CANCELADO" "CANCELADO" "$(q "SELECT estado FROM pedidos WHERE id='$OID'")"
eq "Stock repuesto al cancelar (97+3)" "100" "$(q 'SELECT stock FROM productos WHERE id=1')"

code=$(po /tmp/c_a.txt /tmp/cancela2.json --data-urlencode "accion=cancelarPedido" --data-urlencode "idPedido=$OID")
eq "Segunda cancelación -> 400" "400" "$code"
eq "Segunda cancelación no infla stock" "100" "$(q 'SELECT stock FROM productos WHERE id=1')"

echo
echo "== Cupón y cancelación =="
code=$(po /tmp/c_a.txt /tmp/order2.json --data-urlencode "accion=guardarDB" \
  --data-urlencode "item_id=1" --data-urlencode "item_qty=3" \
  --data-urlencode "codigoPromo=BIENVENIDA10" --data-urlencode "pago=Yape")
eq "Pedido con cupón -> 200" "200" "$code"
OID2=$(sed -n 's/.*"id":"\([^"]*\)".*/\1/p' /tmp/order2.json)
eq "Total con 10% de descuento (15-1.50+10=23.50)" "15.00|1.50|10.00|23.50" "$(q "SELECT CONCAT(subtotal,'|',descuento,'|',envio,'|',total) FROM pedidos WHERE id='$OID2'")"
eq "Uso de cupón registrado" "1" "$(q "SELECT COUNT(*) FROM codigos_promo_usos WHERE pedido_id='$OID2'")"
code=$(po /tmp/c_a.txt /tmp/cancela3.json --data-urlencode "accion=cancelarPedido" --data-urlencode "idPedido=$OID2")
eq "Cancelar pedido con cupón -> 200" "200" "$code"
eq "Cupón liberado al cancelar" "0" "$(q "SELECT COUNT(*) FROM codigos_promo_usos WHERE pedido_id='$OID2'")"
eq "Stock repuesto tras cupón" "100" "$(q 'SELECT stock FROM productos WHERE id=1')"

echo
echo "== IT-08: límite de productos distintos =="
PEDIDOS0=$(q 'SELECT COUNT(*) FROM pedidos')
ARGS11=()
for i in $(seq 1 11); do ARGS11+=(--data-urlencode "item_id=$i" --data-urlencode "item_qty=1"); done
code=$(po /tmp/c_a.txt /tmp/o11.json --data-urlencode "accion=guardarDB" "${ARGS11[@]}" --data-urlencode "pago=Yape")
eq "11 productos distintos -> 400" "400" "$code"
contains "Rechazo por máximo de 10" "maximo de 10" "$(cat /tmp/o11.json)"
eq "No se creó pedido con 11" "$PEDIDOS0" "$(q 'SELECT COUNT(*) FROM pedidos')"

ARGS10=()
for i in $(seq 1 10); do ARGS10+=(--data-urlencode "item_id=$i" --data-urlencode "item_qty=1"); done
code=$(po /tmp/c_a.txt /tmp/o10.json --data-urlencode "accion=guardarDB" "${ARGS10[@]}" --data-urlencode "pago=Yape")
eq "10 productos distintos -> 200" "200" "$code"
OID10=$(sed -n 's/.*"id":"\([^"]*\)".*/\1/p' /tmp/o10.json)
eq "10 productos: subtotal 50 y envío gratis" "50.00|0.00|50.00" "$(q "SELECT CONCAT(subtotal,'|',envio,'|',total) FROM pedidos WHERE id='$OID10'")"
po /tmp/c_a.txt /tmp/c10.json --data-urlencode "accion=cancelarPedido" --data-urlencode "idPedido=$OID10" >/dev/null

echo
echo "== QA-09: stock insuficiente y payload malformado =="
PEDIDOS1=$(q 'SELECT COUNT(*) FROM pedidos')
code=$(po /tmp/c_a.txt /tmp/stock.json --data-urlencode "accion=guardarDB" --data-urlencode "item_id=13" --data-urlencode "item_qty=3" --data-urlencode "pago=Yape")
eq "Stock insuficiente -> 400" "400" "$code"
contains "Mensaje de stock insuficiente" "stock" "$(cat /tmp/stock.json)"
eq "Stock no se modifica" "2" "$(q 'SELECT stock FROM productos WHERE id=13')"
eq "No se crea pedido sin stock" "$PEDIDOS1" "$(q 'SELECT COUNT(*) FROM pedidos')"

code=$(po /tmp/c_a.txt /tmp/m1.json --data-urlencode "accion=guardarDB" --data-urlencode "item_id=1" --data-urlencode "pago=Yape")
eq "item_id sin item_qty -> 400" "400" "$code"
notcontains "Sin mensajes internos de JVM" "Exception" "$(cat /tmp/m1.json)"
notcontains "Sin 'Index out of bounds'" "Index out of bounds" "$(cat /tmp/m1.json)"
notcontains "Sin 'Cannot load from object array'" "Cannot load from object array" "$(cat /tmp/m1.json)"

code=$(po /tmp/c_a.txt /tmp/m2.json --data-urlencode "accion=guardarDB" --data-urlencode "item_id=abc" --data-urlencode "item_qty=1" --data-urlencode "pago=Yape")
eq "item_id no numérico -> 400" "400" "$code"
code=$(po /tmp/c_a.txt /tmp/m3.json --data-urlencode "accion=guardarDB" --data-urlencode "item_id=1" --data-urlencode "item_qty=0" --data-urlencode "pago=Yape")
eq "Cantidad 0 -> 400" "400" "$code"
code=$(po /tmp/c_a.txt /tmp/m4.json --data-urlencode "accion=guardarDB" --data-urlencode "pago=Yape")
eq "Carrito vacío -> 400" "400" "$code"

echo
echo "== IT-07: pedido confirmado no se cancela =="
code=$(po /tmp/c_a.txt /tmp/order3.json --data-urlencode "accion=guardarDB" --data-urlencode "item_id=2" --data-urlencode "item_qty=1" --data-urlencode "pago=Yape")
OID3=$(sed -n 's/.*"id":"\([^"]*\)".*/\1/p' /tmp/order3.json)
code=$(curl -s -b /tmp/c_admin.txt -o /tmp/estado.html -w "%{http_code}" -X POST "$BASE/PedidoServlet" \
  --data-urlencode "accion=cambiarEstado" --data-urlencode "idPedido=$OID3" --data-urlencode "estado=CONFIRMADO")
eq "Admin confirma pedido -> 302" "302" "$code"
eq "Pedido CONFIRMADO en BD" "CONFIRMADO" "$(q "SELECT estado FROM pedidos WHERE id='$OID3'")"
code=$(po /tmp/c_a.txt /tmp/cancelconf.json --data-urlencode "accion=cancelarPedido" --data-urlencode "idPedido=$OID3")
eq "Cliente no cancela pedido confirmado -> 400" "400" "$code"
eq "Pedido confirmado sigue CONFIRMADO" "CONFIRMADO" "$(q "SELECT estado FROM pedidos WHERE id='$OID3'")"

echo
echo "=============================================="
echo "RESULTADO: PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf 'FALLIDOS:\n'; printf ' - %s\n' "${FAILS[@]}"
  exit 1
fi
exit 0
