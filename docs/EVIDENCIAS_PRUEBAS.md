# EVIDENCIAS DE PRUEBAS — Librería Brenda

> Salidas reales capturadas al ejecutar cada verificación. Entorno: MariaDB
> 11.8.8 sobre Fedora WSL2, BD `libreria_brenda`, Java 21, Tomcat 11.0.0-M24.
> Fecha de ejecución: 2026-09-27.

---

## Pieza 1 — Perfil de accesibilidad en BD + filtro de color

### E1. Servicio MariaDB activo

```text
$ pgrep -a mariadbd
16999 /usr/libexec/mariadbd --basedir=/usr

$ systemctl is-active mariadb
active
```

### E2. Conexión con las credenciales del proyecto (root/root, puerto 3306)

```text
$ mariadb -h 127.0.0.1 -P 3306 -u root -proot -e "SELECT VERSION() ..."
version
11.8.8-MariaDB

Database (libreria_brenda)
libreria_brenda
```

### E3. Tablas visibles en `libreria_brenda` (antes del cambio)

```text
Tables_in_libreria_brenda
administradores
categorias
clientes
comprobantes
pedido_items
pedidos
productos
vista_clientes_resumen
vista_top_productos
vista_ventas_categoria
```

### E4. Conexión desde el código Java del proyecto (`ConexionBD.main`)

```text
$ javac -encoding UTF-8 -cp "WebContent/WEB-INF/lib/*" -d /tmp/libreria_bin src/libreria/util/ConexionBD.java
$ java -cp "/tmp/libreria_bin:WebContent/WEB-INF/lib/*" libreria.util.ConexionBD
Conexion exitosa a la base de datos: libreria_brenda
```

### E5. Compilación completa del proyecto (incluida la pieza nueva)

```text
$ javac -encoding UTF-8 -cp "WebContent/WEB-INF/lib/*:/home/kevin/apache-tomcat-11.0.0-M24/lib/servlet-api.jar" \
    -d /tmp/libreria_bin $(find src -name "*.java")
=== COMPILACION OK ===
```

### E6. Tabla creada (verificación con SHOW CREATE TABLE)

```sql
CREATE TABLE `preferencias_accesibilidad` (
  `cliente_id` int(11) NOT NULL,
  `tipo_daltonismo` enum('ninguno','protanopia','deuteranopia','tritanopia') NOT NULL DEFAULT 'ninguno',
  `lectura_voz_activa` tinyint(1) NOT NULL DEFAULT 0,
  `fecha_actualizacion` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`cliente_id`),
  CONSTRAINT `fk_pref_accesibilidad_cliente` FOREIGN KEY (`cliente_id`)
    REFERENCES `clientes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
```

### E7. Pruebas funcionales del DAO contra la BD real (7/7 OK)

Se usó un **cliente temporal de QA** (id=23) creado y eliminado dentro de la
misma corrida, para no alterar los datos reales. El stack trace del test 4 es
el comportamiento esperado: el ENUM de la BD rechaza el valor inválido y el
DAO lo captura devolviendo `false`.

```text
Cliente temporal de QA creado con id=23
[OK]    sin fila -> defaults (ninguno/false)
[OK]    guardar (insert) devuelve true
[OK]    lectura tras insert = deuteranopia
[OK]    guardar (upsert/update) devuelve true
[OK]    lectura tras upsert = protanopia
[OK]    valor invalido rechazado por ENUM (guardar=false)
        java.sql.SQLException: Data truncated for column 'tipo_daltonismo' at row 1  ← esperado (test 4)
[OK]    ON DELETE CASCADE elimino la preferencia del cliente borrado
Filas totales en preferencias_accesibilidad al terminar: 0
RESULTADO: 7 OK, 0 fallos
```

| # | Prueba | Resultado |
|---|---|---|
| 1 | Cliente sin fila guardada → `obtenerPorCliente()` devuelve defaults (`ninguno`/`false`) sin insertar nada | ✅ |
| 2 | `guardar()` inserta una preferencia nueva y devuelve `true` | ✅ |
| 3 | Lectura posterior confirma el valor insertado (`deuteranopia`) | ✅ |
| 4 | `guardar()` sobre fila existente actúa como update (upsert) y devuelve `true` | ✅ |
| 5 | Lectura posterior confirma el valor actualizado (`protanopia`) | ✅ |
| 6 | Valor inválido (`"tritanomia-invalida"`) rechazado por el ENUM de la BD; `guardar()` devuelve `false` sin corromper datos | ✅ |
| 7 | `ON DELETE CASCADE`: al borrar el cliente se elimina su preferencia (0 filas huérfanas) | ✅ |

### E8. Sintaxis del JavaScript de accesibilidad

```text
$ node --check WebContent/js/accesibilidad.js
=== JS OK ===
```

### E9. Limpieza posterior a las pruebas (datos reales intactos)

```text
$ mariadb ... -D libreria_brenda -e "SELECT COUNT(*) FROM clientes; SELECT COUNT(*) FROM preferencias_accesibilidad;"
clientes_reales
16
prefs
0
```

El cliente temporal de QA (id=23) fue eliminado; los 16 clientes reales
quedaron intactos y la tabla quedó vacía a la espera del uso real.

---

## Pieza 2 — Marcado ARIA / compatibilidad con lector de pantalla

### E10. Sintaxis de JavaScript: externos + inline extraídos de cada JSP

```text
$ node --check WebContent/js/carrito.js && node --check WebContent/js/accesibilidad.js
=== JS externos OK ===

$ for f in index carrito pedidos login registro; do
    awk '/<script>/{flag=1;next}/<\/script>/{flag=0}flag' "WebContent/$f.jsp" > "/tmp/inline_$f.js"
    node --check "/tmp/inline_$f.js" && echo "$f.jsp: scripts inline OK"
  done
index.jsp: scripts inline OK
carrito.jsp: scripts inline OK
pedidos.jsp: scripts inline OK
login.jsp: scripts inline OK
registro.jsp: scripts inline OK
```

### E11. Verificación del marcado ARIA por grep (salida real)

```text
== skip-link ==
carrito.jsp index.jsp login.jsp pedidos.jsp registro.jsp

== main id="contenido-principal" (esperado 1 por página) ==
index.jsp:1  carrito.jsp:1  pedidos.jsp:1  login.jsp:1  registro.jsp:1

== nav aria-label="Navegación principal" (páginas con navbar de cliente) ==
index.jsp:1  carrito.jsp:1  pedidos.jsp:1

== role="alert" ==
login.jsp:1  registro.jsp:2        (registro: 1 div real + 1 mención en comentario JS)

== aria-checked="false" en carrito.jsp (6 métodos de pago) ==
6

== aria-pressed en pedidos.jsp (6 botones + 2 referencias en setFiltro) ==
8

== label for= en registro.jsp (8 campos + checkbox términos) ==
9

== autocomplete= ==
login.jsp:2  registro.jsp:7

== role="radiogroup" en carrito.jsp ==
1

== role="tab" en login.jsp (tablist + 2 tabs) ==
3

== :focus-visible en css/style.css ==
1
```

### E12. Compilación Java de sanidad (la pieza no toca src/)

```text
$ javac -encoding UTF-8 -cp "WebContent/WEB-INF/lib/*:<tomcat11>/lib/servlet-api.jar" \
    -d /tmp/libreria_bin $(find src -name "*.java")
=== COMPILACION OK (sin cambios Java, sanity check) ===
```

### Límite de la verificación (honestidad de QA)

Las evidencias E10–E12 prueban que el marcado ARIA está presente, que los
scripts compilan y que la app sigue construyendo. **No** prueban la
experiencia real con un lector de pantalla: esa validación requiere prueba
manual con NVDA/JAWS/VoiceOver, no disponible en este entorno. El registro
documenta la pieza como "implementado, pendiente de validación manual con
NVDA", no como "cumple WCAG".

---

## Pieza 3 — Lectura en voz alta (Web Speech API)

### E13. Round-trip de `lectura_voz_activa` contra la BD real (10/10 OK)

Se usó un cliente temporal de QA (id=24, creado y eliminado en la misma
corrida). El test ejercita el mismo DAO que usa el servlet, simulando
exactamente el flujo del checkbox de la pieza 3.

```text
Cliente temporal de QA creado con id=24
[OK]    sin fila -> defaults (ninguno/false)
[OK]    guardar (checkbox activado) devuelve true
[OK]    BD cruda: lectura_voz_activa = 1 (TINYINT)
[OK]    BD cruda: tipo_daltonismo = deuteranopia
[OK]    JSON del servlet contiene "lecturaVozActiva":true sin comillas
        JSON simulado: {"autenticado":true,"tipoDaltonismo":"deuteranopia","lecturaVozActiva":true}
[OK]    parseo JS simulado !!data.lecturaVozActiva = true
[OK]    guardar (checkbox desactivado) devuelve true
[OK]    lectura tras desactivar = false y filtro se conserva
[OK]    filtro y voz se guardan juntos sin pisarse
[OK]    cascade elimino la fila del cliente temporal
RESULTADO: 10 OK, 0 fallos
```

Lo relevante: la pieza 1 enviaba `lecturaVozActiva: 'false'` fijo desde el
JS (habría pisado el checkbox); la pieza 3 lo corrige y el round-trip
completo queda probado, incluida la persistencia conjunta de ambos campos.

### E14. Sintaxis, marcado y compilación

```text
$ node --check WebContent/js/accesibilidad.js
accesibilidad.js OK

$ awk '/<script>/{flag=1;next}/<\/script>/{flag=0}flag' WebContent/index.jsp > /tmp/inline_index.js
$ node --check /tmp/inline_index.js
index.jsp inline OK

== GREPS ==
grep -c "btn-leer-voz"  -> index.jsp:1  accesibilidad.js:4
grep -c "textoVoz"      -> index.jsp:1
grep -c "chk-lectura-voz|lectura-voz-activa" -> accesibilidad.js:4
grep -c "html.accesibilidad-" -> accesibilidad.js:3   (selectores CSS nuevos)
grep -c "body.accesibilidad-" -> 0  (correcto: el filtro ya no va en body)

=== COMPILACION OK ===
```

### Límite de la verificación (honestidad de QA)

E13–E14 prueban la persistencia y la sintaxis. **No** prueban: la calidad de
la síntesis de voz (depende de las voces `es` instaladas en cada sistema),
que el botón ♿ permanezca fijo al hacer scroll con un filtro activo
(corrección `html` vs `body`, pendiente de confirmación visual), ni el
comportamiento real con NVDA. Queda documentado como "implementado, pendiente
de validación manual".

---

## Nota de despliegue

Tras cada cambio de WebContent hay que **republicar la aplicación en Tomcat**.
La pieza 1 requiere republish para registrar el servlet nuevo
(`/PreferenciaAccesibilidadServlet`). Las piezas 2 y 3 solo modifican
JSP/CSS/JS, pero también requieren republish para que se sirvan las
versiones nuevas.
