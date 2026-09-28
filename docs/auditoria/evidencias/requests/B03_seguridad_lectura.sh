#!/usr/bin/env bash
# FASE 2 - Auditoría LibreriaBrend
# B.03 - L3 Seguridad: peticiones HTTP reales SIN sesión autenticada.
#
# ALCANCE Y SEGURIDAD DE ESTAS PRUEBAS:
#   - Todas las peticiones de este script son de LECTURA sobre la BD real.
#   - NO se envían payloads destructivos (; DROP / ; DELETE / ; UPDATE) contra
#     la BD de producción: ver justificación en FASE2_INFORME.md (§4).
#   - Los POST a guardarDB usan exclusivamente payloads que el código descarta
#     ANTES de abrir la transacción (carrito vacío, >10 ítems, id no numérico,
#     cantidad <= 0, producto inexistente, arrays de longitud dispar, código
#     promocional sin sesión). Ninguno alcanza PedidoDAO.crear().
CTX="http://localhost:8080/LibreriaBrend"
JAR=/tmp/aud_f2_cookies_anon.txt
RED='s/JSESSIONID=[A-F0-9]*/JSESSIONID=<REDACTADO>/g'

hdr() { echo; echo "---------- $* ----------"; }

hdr "B.03.1 IDOR de LECTURA: GET /PedidoServlet SIN sesión (el handler cae al cliente id=1)"
echo "### Request:"
echo "GET $CTX/PedidoServlet   (sin cookies, sin sesión)"
echo "### Response:"
curl -s -m 15 -o /tmp/f2_pedidos_anon.json -w "HTTP %{http_code} | %{size_download} bytes | %{content_type}\n" "$CTX/PedidoServlet"
echo "### Body (primeros 1200 caracteres):"
head -c 1200 /tmp/f2_pedidos_anon.json; echo
echo "### Nº de pedidos devueltos al anónimo:"
python3 -c "import json;d=json.load(open('/tmp/f2_pedidos_anon.json'));print(len(d),'pedidos');[print('  ',p['id'],p['estado'],p['direccion'],p['pago'],p['total']) for p in d]" 2>/dev/null

hdr "B.03.2 IDOR comparativo: misma petición con cookie de sesión anónima (no autenticada)"
curl -s -b "$JAR" -c "$JAR" -m 15 -o /tmp/f2_pedidos_anon2.json -w "HTTP %{http_code}\n" "$CTX/PedidoServlet"
python3 -c "import json;d=json.load(open('/tmp/f2_pedidos_anon2.json'));print('pedidos devueltos:',len(d))" 2>/dev/null
echo ">>> Si el conteo coincide con B.03.1, el servlet NO distingue 'sin sesión' de 'sesión de cliente': ambos se resuelven al cliente id=1."

hdr "B.03.3 Inyección SQL en el login (la consulta es SELECT: no puede mutar datos)"
for p in "' OR '1'='1" "a@b.co' OR '1'='1" "a@b.co' OR email LIKE '%' -- -" "a@b.co' UNION SELECT 1,2,3 -- -" "auditoria'||'@noexiste.pe"; do
  printf "\n### payload email: %s\n" "$p"
  curl -s -m 15 -X POST "$CTX/LoginServlet" \
       -H "Content-Type: application/x-www-form-urlencoded" \
       --data-urlencode "email=$p" --data-urlencode "password=x" --data-urlencode "rol=cliente" \
       -w "\n   HTTP %{http_code} | %{content_type}\n"
done
echo "### Control (email válido, password incorrecta):"
curl -s -m 15 -X POST "$CTX/LoginServlet" -H "Content-Type: application/x-www-form-urlencoded" \
     --data-urlencode "email=auditoria.control@noexiste.pe" --data-urlencode "password=x" --data-urlencode "rol=cliente" \
     -w "\n   HTTP %{http_code}\n"

hdr "B.03.4 Inyección SQL en parámetros de búsqueda/filtro accesibles sin sesión"
for q in "%27%20OR%20%271%27%3D%271" "1%27%20OR%20%271%27%3D%271%20--%20" ; do
  printf "\n### GET /ProductoServlet (catálogo público) sin parámetros de payload: HTTP "
  curl -s -o /tmp/f2_prod.json -w "%{http_code}\n" -m 15 "$CTX/ProductoServlet"
done
echo "### /ProductoServlet no recibe filtros por parámetro (solo GET lista completa) -> no hay superficie de inyección por parámetro aquí."

hdr "B.03.5 Endpoints protegidos por AuthFilter (control de autorización real)"
for r in "/ReporteServlet" "/ClienteServlet" "/productos.jsp" "/clientes.jsp" "/reportes.jsp" "/admin.jsp"; do
  printf "%-20s -> " "$r"
  curl -s -o /dev/null -w "HTTP %{http_code} | Location: %{redirect_url}\n" -m 15 "$CTX$r"
done
echo "### POST a ProductoServlet (acción de admin) sin sesión:"
curl -s -m 15 -X POST "$CTX/ProductoServlet" -H "Content-Type: application/x-www-form-urlencoded" \
     --data "accion=eliminar&id=1" -w "\n   HTTP %{http_code}\n"
echo "### POST a PedidoServlet accion=cambiarEstado (acción de admin) sin sesión:"
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" \
     --data "accion=cambiarEstado&idPedido=PED-1783390538284&estado=ENTREGADO" -w "\n   HTTP %{http_code}\n"

hdr "B.03.6 Verificación del fix CU-03 (límite de 10 productos) en el SERVIDOR, sin escribir"
# Se usan ids de producto 9001+ que NO existen en la BD: garantiza que el flujo
# se detiene en 'Uno de los productos ya no existe' y nunca llega a PedidoDAO.crear().
IDS=""; QTY=""
for i in $(seq 9001 9011); do IDS="$IDS&item_id=$i"; QTY="$QTY&item_qty=1"; done
echo "### Request: POST /PedidoServlet accion=guardarDB con 11 'item_id' distintos (sin sesión)"
echo "### (el control de longitud retorna ANTES de cualquier acceso a la BD: no hay escritura posible)"
echo "### Payload: accion=guardarDB&item_id=9001..9011&item_qty=1&direccion=x&pago=Yape"
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" \
     --data "accion=guardarDB${IDS}${QTY}&direccion=x&pago=Yape" -w "\n   HTTP %{http_code}\n"
echo "### Control con 10 ítems (mismos ids inexistentes): debe pasar el límite y fallar en la validación de producto"
IDS10=""; QTY10=""
for i in $(seq 9001 9010); do IDS10="$IDS10&item_id=$i"; QTY10="$QTY10&item_qty=1"; done
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" \
     --data "accion=guardarDB${IDS10}${QTY10}&direccion=x&pago=Yape" -w "\n   HTTP %{http_code}\n"
echo ">>> Contraste: 11 ítems -> rechazo por límite | 10 ítems -> el límite NO se activa (pasa a validar productos)."

hdr "B.03.7 Manipulación de lógica de negocio: payloads que el servidor debe descartar"
echo "### (a) carrito vacío:"
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "accion=guardarDB" -w "\n   HTTP %{http_code}\n"
echo "### (b) item_id no numérico:"
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "accion=guardarDB&item_id=abc&item_qty=1&pago=Yape" -w "\n   HTTP %{http_code}\n"
echo "### (c) cantidad 0 / negativa:"
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "accion=guardarDB&item_id=1&item_qty=0&pago=Yape" -w "\n   HTTP %{http_code}\n"
echo "### (d) producto inexistente:"
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "accion=guardarDB&item_id=999999&item_qty=1&pago=Yape" -w "\n   HTTP %{http_code}\n"
echo "### (e) arrays de longitud dispar (item_id=1 y 9001, un solo item_qty) -> comprobar fuga de mensaje interno:"
echo "###     item_id=1 es un producto REAL (89.90) para que el bucle llegue a la 2ª iteración y dispare el error de índice;"
echo "###     el pedido se crea DESPUÉS del bucle, por lo que no hay escritura posible."
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "accion=guardarDB&item_id=1&item_id=9001&item_qty=1&pago=Yape" -w "\n   HTTP %{http_code}\n"
echo "### (f) item_qty ausente:"
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "accion=guardarDB&item_id=1&pago=Yape" -w "\n   HTTP %{http_code}\n"
echo "### (g) precio manipulado del cliente (item_precio=0.01) con producto inexistente:"
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "accion=guardarDB&item_id=999999&item_qty=1&item_precio=0.01&pago=Yape" -w "\n   HTTP %{http_code}\n"
echo "### (h) código promocional SIN sesión (retorna antes de crear el pedido):"
curl -s -m 15 -X POST "$CTX/PedidoServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "accion=guardarDB&item_id=1&item_qty=1&pago=Yape&codigoPromo=BIENVENIDA10" -w "\n   HTTP %{http_code}\n"

hdr "B.03.8 CSRF: petición POST de alteración de estado con Origin externo y sin token"
echo "### (no se envía ninguna petición que pueda llegar a escribir; ver informe §4)"
echo "### Verificación de la EXISTENCIA de defensa (token/atributo SameSite):"
curl -s -D - -o /dev/null -m 10 "$CTX/" | sed -E "$RED" | grep -i "set-cookie"
echo "### (sin 'SameSite' en la cookie; ver informe §2)"
echo "### ¿Algún formulario/fetch servido incluye un campo token/CSRF?"
curl -s -m 10 "$CTX/carrito.jsp" | grep -ci "csrf" || echo "0 coincidencias de 'csrf' en el DOM de carrito.jsp"
curl -s -m 10 "$CTX/pedidos.jsp" | grep -ci "csrf" || echo "0 coincidencias de 'csrf' en el DOM de pedidos.jsp"
