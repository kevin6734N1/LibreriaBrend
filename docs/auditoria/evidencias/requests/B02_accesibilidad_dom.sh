#!/usr/bin/env bash
# FASE 2 - Auditoría LibreriaBrend
# B.02 - L5 Accesibilidad + verificación de despliegue (solo GET, sin escrituras)
# Los JSESSIONID se redactan al volcar la evidencia (higiene: no commitear credenciales de sesión).
CTX="http://localhost:8080/LibreriaBrend"
DEPLOY="/home/kevin/apache-tomcat-11.0.0-M24/webapps/LibreriaBrend"
JAR=/tmp/aud_f2_cookies.txt
RED='s/JSESSIONID=[A-F0-9]*/JSESSIONID=<REDACTADO>/g'

echo "===== B.02.1 Sesión HTTP real: captura de cookie ====="
curl -s -D - -o /dev/null -m 10 -c "$JAR" "$CTX/" | sed -E "$RED"
echo "-- cookie jar --"
sed -E 's/(JSESSIONID[[:space:]]+)[A-F0-9]+/\1<REDACTADO>/' "$JAR"

echo
echo "===== B.02.2 Reutilización de la cookie (misma sesión) ====="
curl -s -b "$JAR" -c "$JAR" -o /dev/null -w "index.jsp   -> HTTP %{http_code}\n" -m 10 "$CTX/index.jsp"
curl -s -b "$JAR" -o /dev/null -w "carrito.jsp -> HTTP %{http_code}\n" -m 10 "$CTX/carrito.jsp"

echo
echo "===== B.02.3 DOM REALMENTE SERVIDO: atributos ARIA/role y landmarks por vista ====="
printf "%-16s %-6s %-7s %-7s %s\n" "VISTA" "HTTP" "aria-*" "role=" "landmarks"
for v in index.jsp carrito.jsp pedidos.jsp login.jsp registro.jsp productos.jsp admin.jsp clientes.jsp reportes.jsp; do
  BODY="/tmp/f2_dom_$v.html"
  CODE=$(curl -s -b "$JAR" -o "$BODY" -w "%{http_code}" -m 15 "$CTX/$v")
  ARIA=$(grep -o 'aria-[a-z]*' "$BODY" 2>/dev/null | wc -l)
  ROLE=$(grep -o 'role="[a-z]*"' "$BODY" 2>/dev/null | wc -l)
  LM=$(grep -o 'contenido-principal\|skip-link' "$BODY" 2>/dev/null | sort -u | tr '\n' ',')
  printf "%-16s %-6s %-7s %-7s %s\n" "$v" "$CODE" "$ARIA" "$ROLE" "${LM:--}"
done
echo "(302 = redirección de AuthFilter a login.jsp; el cuerpo va vacío)"

echo
echo "===== B.02.4 Cabecera Location de las vistas protegidas ====="
for v in productos.jsp admin.jsp clientes.jsp reportes.jsp; do
  printf "%-16s -> " "$v"
  curl -s -o /dev/null -w "HTTP %{http_code} | Location: %{redirect_url}\n" -m 15 "$CTX/$v"
done

echo
echo "===== B.02.5 Filtro Daltonize: ¿el CSS se aplica a <html> o a <body>? (JS servido por Tomcat) ====="
curl -s -m 10 "$CTX/js/accesibilidad.js" -o /tmp/f2_acc_servido.js
echo "-- selectores html.accesibilidad-* en el JS servido --"
grep -o 'html\.accesibilidad-[a-z]*' /tmp/f2_acc_servido.js | sort -u
echo "-- selectores body.accesibilidad-* en el JS servido --"
grep -o 'body\.accesibilidad-[a-z]*' /tmp/f2_acc_servido.js | sort -u
echo "-- elemento al que se añade la clase en runtime --"
grep -n "documentElement\|document.body.classList" /tmp/f2_acc_servido.js | head -5
echo "-- ¿qué elemento recibe la clase de lectura en voz alta? --"
grep -n "classList.toggle('lectura-voz-activa'\|lectura-voz-activa" /tmp/f2_acc_servido.js | head -3
echo "-- ¿el markup servido incluye el widget? (js/accesibilidad.js) --"
grep -c 'js/accesibilidad.js' /tmp/f2_dom_index.jsp.html
echo "-- ¿el CSS del filtro viene ya en el HTML servido o se inyecta por JS? --"
grep -c 'accesibilidad-protanopia' /tmp/f2_dom_index.jsp.html

echo
echo "===== B.02.6 Derivación de despliegue: ficheros servidos vs repositorio (integridad commit<->runtime) ====="
printf "%-24s %-12s %-12s %s\n" "FICHERO" "DESPLEGADO" "REPO" "IGUAL"
for f in index.jsp carrito.jsp pedidos.jsp login.jsp registro.jsp productos.jsp css/style.css js/carrito.js js/accesibilidad.js WEB-INF/web.xml; do
  D=$(sha256sum "$DEPLOY/$f" 2>/dev/null | cut -c1-12)
  R=$(sha256sum "WebContent/$f" 2>/dev/null | cut -c1-12)
  if [ -n "$D" ] && [ "$D" = "$R" ]; then I="SI"; else I="NO"; fi
  printf "%-24s %-12s %-12s %s\n" "$f" "${D:--}" "${R:--}" "$I"
done
echo "-- clases Java desplegadas vs build/classes del repositorio --"
for c in libreria/servlets/PedidoServlet.class libreria/dao/CodigoPromoDAO.class libreria/dao/PedidoDAO.class libreria/util/ConexionBD.class; do
  D=$(sha256sum "$DEPLOY/WEB-INF/classes/$c" 2>/dev/null | cut -c1-12)
  R=$(sha256sum "build/classes/$c" 2>/dev/null | cut -c1-12)
  if [ -n "$D" ] && [ "$D" = "$R" ]; then I="SI"; else I="NO"; fi
  printf "%-42s %-12s %-12s %s\n" "$c" "${D:--}" "${R:--}" "$I"
done
