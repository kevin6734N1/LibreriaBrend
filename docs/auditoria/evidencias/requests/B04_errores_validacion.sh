#!/usr/bin/env bash
# FASE 2 - Auditoría LibreriaBrend
# B.04 - L4 Manejo de errores + validación de entrada en el servidor (sin escrituras)
# Todos los payloads de este script son rechazados por validación ANTES de tocar la BD.
CTX="http://localhost:8080/LibreriaBrend"
JAR=/tmp/aud_f2_cookies.txt
RED='s/JSESSIONID=[A-F0-9]*/JSESSIONID=<REDACTADO>/g'

hdr() { echo; echo "---------- $* ----------"; }

hdr "B.04.1 Recurso inexistente (404) y mapeo de error de web.xml"
echo "### Request: GET $CTX/noexiste.jsp"
curl -s -D - -o /tmp/f2_404.html -m 15 "$CTX/noexiste.jsp" | sed -E "$RED" | head -8
echo "### ¿el cuerpo expone stack trace o rutas internas? (grep de firmas técnicas)"
grep -oE "java\.[a-z.]*|org\.apache\.[a-zA-Z.]*|libreria\.[a-zA-Z.]*|at [a-zA-Z.]+\(|Exception|StackTrace" /tmp/f2_404.html | sort -u | head
echo "### Tamaño del cuerpo devuelto: $(wc -c < /tmp/f2_404.html) bytes"

hdr "B.04.2 Servlet inexistente"
printf "GET $CTX/ServletInexistente -> "
curl -s -o /dev/null -w "HTTP %{http_code}\n" -m 15 "$CTX/ServletInexistente"

hdr "B.04.3 Acción desconocida en PedidoServlet (GET y POST)"
printf "GET  /PedidoServlet?accion=xxx  -> "
curl -s -o /dev/null -w "HTTP %{http_code} | Location: %{redirect_url}\n" -m 15 "$CTX/PedidoServlet?accion=xxx"
printf "POST /PedidoServlet  (sin cuerpo) -> "
curl -s -o /dev/null -w "HTTP %{http_code} | Location: %{redirect_url}\n" -m 15 -X POST "$CTX/PedidoServlet"

hdr "B.04.4 GET /LoginServlet y /LogoutServlet (comportamiento de redirección)"
printf "GET /LoginServlet  -> "
curl -s -o /dev/null -w "HTTP %{http_code} | Location: %{redirect_url}\n" -m 15 "$CTX/LoginServlet"
printf "GET /LogoutServlet -> "
curl -s -o /dev/null -w "HTTP %{http_code} | Location: %{redirect_url}\n" -m 15 "$CTX/LogoutServlet"

hdr "B.04.5 Validación de entrada en el servidor: RegistroServlet (payloads rechazados antes del INSERT)"
echo "### (a) todos los campos vacíos:"
curl -s -m 15 -X POST "$CTX/RegistroServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "nombres=&apellidos=&dni=&email=&password=" -w "\n   HTTP %{http_code}\n"
echo "### (b) email con formato inválido:"
curl -s -m 15 -X POST "$CTX/RegistroServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "nombres=Auditoria&apellidos=Fase2&dni=99999999&email=no-es-un-email&password=12345678" -w "\n   HTTP %{http_code}\n"
echo "### (c) contraseña por debajo del mínimo (8):"
curl -s -m 15 -X POST "$CTX/RegistroServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "nombres=Auditoria&apellidos=Fase2&dni=99999999&email=auditoria.fase2@noexiste.pe&password=123" -w "\n   HTTP %{http_code}\n"
echo "### (d) DNI con formato no numérico (¿se valida en servidor?):"
curl -s -m 15 -X POST "$CTX/RegistroServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "nombres=Auditoria&apellidos=Fase2&dni=NO-ES-DNI&email=auditoria.fase2@noexiste.pe&password=123" -w "\n   HTTP %{http_code}\n"
echo ">>> Nota: (d) también cae en el corte por contraseña corta, por lo que no llega al DAO. La validación de formato del DNI se evaluó en Fase 1 (no existe)."

hdr "B.04.6 Validación del login (payloads rechazados)"
echo "### rol no reconocido:"
curl -s -m 15 -X POST "$CTX/LoginServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "email=a@b.co&password=x&rol=superusuario" -w "\n   HTTP %{http_code}\n"
echo "### campos faltantes:"
curl -s -m 15 -X POST "$CTX/LoginServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "email=" -w "\n   HTTP %{http_code}\n"
echo "### rol=admin sin código de empleado (no debe autenticar):"
curl -s -m 15 -X POST "$CTX/LoginServlet" -H "Content-Type: application/x-www-form-urlencoded" --data "email=admin@brenda.pe&password=admin&rol=admin" -w "\n   HTTP %{http_code}\n"

hdr "B.04.7 ¿Alguna respuesta JSON expone información interna?"
echo "### Estructura de la respuesta de /PedidoServlet (solo claves, sin datos):"
python3 - <<'PY'
import json
try:
    d = json.load(open('/tmp/f2_pedidos_anon.json'))
    if d:
        print("claves de un pedido :", sorted(d[0].keys()))
        print("claves de un ítem   :", sorted(d[0]['items'][0].keys()))
        print("nº de pedidos       :", len(d))
except Exception as e:
    print("no evaluable:", e)
PY
echo "### Estructura de la respuesta de /ProductoServlet:"
curl -s -m 15 "$CTX/ProductoServlet" -o /tmp/f2_prod.json
python3 - <<'PY'
import json
try:
    d = json.load(open('/tmp/f2_prod.json'))
    print("nº de productos:", len(d))
    print("claves de un producto:", sorted(d[0].keys()))
    print(">>> 'stock' se publica sin sesión:", 'stock' in d[0], "| valor del 1º:", d[0].get('stock'))
except Exception as e:
    print("no evaluable:", e)
PY

hdr "B.04.8 Síntesis: búsqueda de stack traces / rutas internas en TODAS las respuestas capturadas"
grep -rIl -E "at (java|libreria|org\.apache)[a-zA-Z0-9_.]*\(|catalina\.base|/home/kevin" docs/auditoria/evidencias/responses/ 2>/dev/null || echo "(sin stack traces ni rutas del servidor en las respuestas capturadas)"
echo "### Fugas de mensajes internos de la JVM detectadas en B.03.7:"
grep -h "out of bounds\|qtys\|Cannot load" docs/auditoria/evidencias/responses/B03_seguridad_lectura.txt
