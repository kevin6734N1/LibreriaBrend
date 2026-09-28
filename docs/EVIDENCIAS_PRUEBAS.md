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

## Paso 2 — Retiro del ODS10 antiguo

### E15. Grep de lógica ODS10/beneficios (resultado real)

```text
$ grep -rniE "ods ?10|beneficio|esEstudiante|esDiscapacidad|chk-estudiante|chk-discapacidad|ods10-check|inclusion-box" \
    --include="*.java" --include="*.jsp" --include="*.js" . | grep -v "^./docs/"
./TestPaso2QA.java:6: * verifica el recalculo del servidor con la logica ODS10 retirada.   ← test temporal, ya eliminado
./WebContent/js/accesibilidad.js:2://  ACCESIBILIDAD VISUAL (ODS10 / Ley 29973) - Libreria Brenda
./src/libreria/dao/PreferenciaAccesibilidadDAO.java:10: * Acceso a datos ... (ODS10 / Ley 29973).
./src/libreria/servlets/PreferenciaAccesibilidadServlet.java:18: * Lee/guarda el perfil ... (ODS10 / Ley 29973).
```

Las 3 coincidencias restantes son **comentarios normativos** de las piezas de
accesibilidad (citando la Ley 29973 como motivación), no código ejecutable.
Cero lógica ODS10 en JSP/JS/Java.

### E16. Sintaxis JS y compilación Java

```text
$ node --check WebContent/js/carrito.js
carrito.js OK
$ node --check /tmp/inline_carrito.js   (inline extraído de carrito.jsp)
carrito.jsp inline OK
$ javac ... $(find src -name "*.java")
COMPILACION OK
```

### E17. Pruebas de cálculo del servidor (8/8 OK, sin tocar la BD)

```text
[OK]    S/20: envio = 10
[OK]    S/20: total = 30
[OK]    S/20: descuento = 0 (quedo listo para codigos promocionales)
[OK]    S/35: envio = 0 (gratis desde S/30)
[OK]    S/35: total = 35
[OK]    S/20 con descuento 5: total = 25
[OK]    S/20 con descuento 5: descuento conservado = 5
[OK]    S/30 (borde): envio = 0
RESULTADO: 8 OK, 0 fallos
```

El caso "descuento 5" confirma el camino del paso 3: `setDescuento()` antes
de `calcularTotal()` se respeta (el método ya no pisa el descuento).

### E18. Imagen huérfana

```text
$ grep -rl "planeta.png" --include="*.jsp" --include="*.js" --include="*.java" \
    --include="*.html" --include="*.css" . | grep -v docs
planeta.png ya no se usa en ninguna pagina (solo en docs/)
```

Se eliminó `WebContent/images/planeta.png` (3,9 KB) conforme al plan.

Pendiente de validación manual (igual que las piezas 2 y 3): flujo completo
de compra en el navegador con carrito de S/20 y de S/35, y confirmación en
BD de `descuento = 0.00` en los pedidos nuevos.

---

## Paso 3 — Códigos promocionales

### DDL y seed aplicados a `libreria_brenda`

```sql
CREATE TABLE codigos_promo (
  codigo VARCHAR(30) NOT NULL,
  tipo ENUM('PORCENTAJE','MONTO_FIJO') NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  fecha_expiracion DATE NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (codigo),
  CONSTRAINT chk_promo_valor CHECK (valor > 0 AND (tipo <> 'PORCENTAJE' OR valor <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE codigos_promo_usos (
  codigo VARCHAR(30) NOT NULL,
  cliente_id INT NOT NULL,
  pedido_id VARCHAR(30) NOT NULL,
  fecha_uso DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (codigo, cliente_id),
  CONSTRAINT fk_promo_uso_codigo  FOREIGN KEY (codigo) REFERENCES codigos_promo(codigo),
  CONSTRAINT fk_promo_uso_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Seed verificado en BD:

```text
codigo        tipo         valor  fecha_expiracion
BIENVENIDA10  PORCENTAJE   10.00  NULL
LIBRO5        MONTO_FIJO    5.00  2026-12-31
VERANO20      PORCENTAJE   20.00  2026-01-31   (vencido a propósito)
```

### E19. Pruebas de integración contra la BD real (19/19 OK)

Cliente temporal id=26 y 3 productos temporales creados y eliminados en la
misma corrida (limpieza en orden de FKs). Caso 1 (sin sesión) se resuelve en
el servlet antes de tocar el DAO.

```text
Cliente temporal id=26
Usando categoria_id=1
[OK]    C2: BIENVENIDA10 sobre S/40 descuenta 4.00
[OK]    C3: 'bienvenida10' en minusculas funciona
[OK]    C4: VERANO20 rechazado por vencido
[OK]    C5: codigo inexistente rechazado
[OK]    C6: LIBRO5 sobre S/3 descuenta 3.00 (no supera subtotal)
[OK]    C-extra: codigo con carrito vacio rechazado
[OK]    C7a: revalidacion al confirmar da 4.00
[OK]    C7b: envio gratis porque (40 - 4) >= 30
[OK]    C7c: total = 36.00
[OK]    C7d: pedido creado con codigo promocional
[OK]    C7e: BD pedidos.descuento = 4.00
[OK]    C7f: BD pedidos.total = 36.00
[OK]    C7g: una fila en codigos_promo_usos
[OK]    C7h: reintento dice 'Ya usaste este codigo...'
[OK]    C8a: excepcion con mensaje claro
[OK]    C8b: segundo uso lanza CodigoPromoInvalidoException
[OK]    C8c: rollback completo - el pedido duplicado NO existe en BD
[OK]    C-extra2: pedido sin stock lanza StockInsuficienteException
[OK]    C-extra2b: el codigo no se consumio por el fallo de stock
Limpieza completada (cliente, pedidos, usos y productos temporales eliminados)
RESULTADO: 19 OK, 0 fallos
```

Estado de la BD tras la limpieza (verificado por query):

```text
qa_clientes = 0    qa_productos = 0    usos_restantes = 0    codigos = 3
```

### E20. Sintaxis y compilación

```text
$ javac ... $(find src -name "*.java")
=== COMPILACION OK ===
$ node --check WebContent/js/carrito.js
carrito.js OK
$ node --check /tmp/inline_carrito.js   (inline extraído de carrito.jsp)
carrito.jsp inline OK
```

Pendiente de validación manual: flujo real en navegador con sesión (casos 1,
7 y 9 de la tabla del plan: aplicar/quitar, recálculo al cambiar cantidades,
reintento tras confirmar).

---

## Nota de despliegue

Tras cada cambio hay que **republicar la aplicación en Tomcat**.
La pieza 1 requiere republish para registrar el servlet nuevo
(`/PreferenciaAccesibilidadServlet`). Las piezas 2 y 3 modifican JSP/CSS/JS
y el paso 2 modifica clases Java (`PedidoServlet`, `Pedido`): en todos los
casos aplica republish para que se sirvan/ejecuten las versiones nuevas.
