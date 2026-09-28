#!/usr/bin/env bash
# FASE 2 - Auditoría LibreriaBrend
# B.05 - Controles verificables por HTTP sin escrituras:
#       (a) limitador de intentos de login (ControlIntentosLogin, en memoria)
#       (b) controles presentes en los artefactos REALMENTE servidos
CTX="http://localhost:8080/LibreriaBrend"
EMAIL="auditoria.bruteforce@noexiste.pe"   # email inexistente: no afecta a ninguna cuenta real

hdr() { echo; echo "---------- $* ----------"; }

hdr "B.05.1 Limitador de intentos fallidos de login (5 intentos -> bloqueo de 2 min)"
echo "### Se usa el email inexistente $EMAIL (no afecta a ninguna cuenta real)."
for i in $(seq 1 7); do
  printf "intento #%d -> " "$i"
  curl -s -m 15 -X POST "$CTX/LoginServlet" -H "Content-Type: application/x-www-form-urlencoded" \
       --data-urlencode "email=$EMAIL" --data-urlencode "password=incorrecta$i" --data-urlencode "rol=cliente"
  echo
done
echo ">>> El bloqueo es POR EMAIL (no global) y vive en memoria del contenedor: se pierde al reiniciar Tomcat."

hdr "B.05.2 Controles presentes en los artefactos servidos (no en el código fuente JSP/JS)"
echo "### A-05: regla de envío por PRECIO DE PRODUCTO en el DOM servido de index.jsp"
grep -c "p.precio >= 30" /tmp/f2_dom_index.jsp.html
echo "    (líneas del JS inline servido que deciden el envío gratis por precio de producto)"
echo
echo "### M-01: ¿existe manejo de Escape o gestión de foco en el DOM servido de pedidos.jsp?"
printf "occurrencias de 'Escape': "; grep -c "Escape" /tmp/f2_dom_pedidos.jsp.html
printf "occurrencias de 'focus(': "; grep -c "focus(" /tmp/f2_dom_pedidos.jsp.html
printf "atributo aria-modal      : "; grep -c 'aria-modal="true"' /tmp/f2_dom_pedidos.jsp.html
echo
echo "### M-02: alert() bloqueantes en el flujo de compra (DOM servido de carrito.jsp)"
printf "carrito.jsp  -> "; grep -c "alert(" /tmp/f2_dom_carrito.jsp.html
printf "pedidos.jsp  -> "; grep -c "alert(" /tmp/f2_dom_pedidos.jsp.html
printf "registro.jsp -> "; grep -c "alert(" /tmp/f2_dom_registro.jsp.html
echo
echo "### M-03: referencias a variables no declaradas en el DOM servido de carrito.jsp"
grep -o "btnHtmlOriginal" /tmp/f2_dom_carrito.jsp.html | sort | uniq -c
echo "    ('btnHtmlOriginal' se usa pero no se declara: 2 usos detectados en Fase 1)"
echo
echo "### Fix CU-03 en el CLIENTE: control de 10 productos en el JS servido"
curl -s -m 10 "$CTX/js/carrito.js" -o /tmp/f2_carrito_servido.js
grep -o "carrito.length >= 10" /tmp/f2_carrito_servido.js | head -1
echo
echo "### PreferenciaAccesibilidadServlet sin sesión (contraste con el fallback del Cliente Demo)"
printf "GET -> "; curl -s -m 10 "$CTX/PreferenciaAccesibilidadServlet"; echo
printf "GET /PedidoServlet (misma situación, sin sesión) -> %s bytes de datos de cliente\n" \
  "$(curl -s -m 10 "$CTX/PedidoServlet" | wc -c)"
