# REGISTRO DE CAMBIOS — Librería Brenda

> **Convención del proyecto:** cada cambio funcional se documenta en este
> registro junto con sus pruebas, y se cierra con **un solo commit** que
> incluye todo el conjunto: código, clases compiladas, documentación y
> evidencias. El commit se sube con `git push` a
> `github.com/kevin6734N1/LibreriaBrend` y su hash queda anotado aquí como
> "estado actual del proyecto". Las evidencias de funcionamiento de cada
> pieza viven en [`EVIDENCIAS_PRUEBAS.md`](EVIDENCIAS_PRUEBAS.md).

## Estado actual del proyecto

| Fecha | Commit | Cambio |
|---|---|---|
| 2026-09-23 | `829cdbc` | Primer commit — Librería Brenda (app web Java + MySQL) |
| 2026-09-27 | `c4852ce` | CU-03: validar máximo de 10 productos distintos en el carrito + informe de validación |
| 2026-09-27 | `9715fab` | **Pieza 1 accesibilidad:** perfil de accesibilidad en BD + filtro de corrección de color (Daltonize) + docs/ con registro y evidencias |
| 2026-09-27 | `3289939` | **Pieza 2 accesibilidad:** marcado ARIA / compatibilidad con lector de pantalla en las páginas de cliente |
| 2026-09-27 | `37404a3` | **Pieza 3 accesibilidad:** lectura en voz alta (Web Speech API) + corrección del filtro en `<html>` |
| 2026-09-27 | `9c0ea3b` | **Paso 2 — retiro del ODS10 antiguo:** una sola regla de negocio (envío ≥ S/30 gratis), `descuento` fijo en 0 para el paso 3 |
| 2026-09-27 | `f1dd3a1` | **Paso 3 — códigos promocionales:** tablas + DAO + revalidación en servidor + UI en carrito (solo con sesión, un uso por cliente) |
| 2026-09-27 | `80910aa` | **Paso 3b — refuerzos:** rechazo de código que empeora el envío · liberación al cancelar · precios reales desde BD |
| 2026-09-28 | *(pendiente de commit)* | **Laboratorio de calidad — TDD (H0007):** `ValidadorProducto` construido test-first (9 tests JUnit 5) + validación en servidor de crear/editar producto (HTTP 400 con errores) |
| 2026-10-21 | `4db4786` | **RF02 — inicio de sesión:** validación de correo, BCrypt tolerante a hashes malformados, cuentas inactivas, separación de roles, rotación de sesión y 62 comprobaciones HTTP |
| 2026-10-21 | `47b73db` | **Demo local:** base aislada `libreria_brenda_demo` con 16 clientes sintéticos; `clientes.jsp` sin datos embebidos y panel de `:8080` verificado |
| 2026-10-21 | `4db4786` | **Entorno aislado:** Tomcat 11.0.26 propio en `:8082`, usuario SQL limitado a `libreria_brenda_demo` y modal de clientes alimentado por pedidos reales |
| 2026-10-23 | `f813536` + `772c54d` | **RF03 — bloqueo temporal:** corrección de `minutosRestantes()` en bloqueo vencido (RED→GREEN), 6 pruebas de frontera con reloj inyectado y 27 comprobaciones HTTP de integración |
| 2026-10-23 | *(commit correctivo en `qa/rf03-bloqueo-login`, ver PR #4)* | **RF03 corrección de revisión:** precondiciones de aislamiento fatales antes de escribir (`DB_NAME` literal, `SELECT DATABASE()`, `BASE :8091`), `trap` posterior, cleanup acotado a la ejecución y BL-02 con el5.º fallo real —29/29 + pruebas negativas |

**Entorno vigente:** Java 21 · Tomcat 11.0.26 en `:8080` sirviendo LibreriaBrend
con la base `libreria_brenda_demo` y el usuario `libreria_demo_app`; el Tomcat
aislado de `:8082` queda disponible pero detenido · MariaDB 11.8.9 en `3306`
para la demo y `3307` para pruebas · credenciales locales no versionadas ·
driver `mysql-connector-j-9.7.0.jar` · Jakarta Servlet 6.

---

## [Pieza 1] Perfil de accesibilidad en BD + filtro de corrección de color

**Fecha:** 2026-09-27
**Motivación:** ODS 10 (reducción de desigualdades) / Ley 29973 — accesibilidad
visual para usuarios con daltonismo dentro del flujo de compra.

### Qué se implementó

1. **Base de datos** — nueva tabla `preferencias_accesibilidad` (una fila por
   cliente, creada con FK `ON DELETE CASCADE` hacia `clientes`):
   el ENUM garantiza a nivel de BD que solo se guarden los 4 valores válidos.

2. **Modelo / DAO** — `PreferenciaAccesibilidad` +
   `PreferenciaAccesibilidadDAO` con `obtenerPorCliente()` (devuelve valores
   por defecto si el cliente aún no tiene fila, sin tocar la BD) y `guardar()`
   (upsert con `ON DUPLICATE KEY UPDATE`).

3. **Servlet** — `PreferenciaAccesibilidadServlet` (`GET`/`POST` JSON):
   - Autenticado por sesión (`clienteEmail` → `ClienteDAO.buscarPorEmail`).
   - Valida el tipo contra la lista blanca antes de tocar la BD.

4. **Frontend** — `WebContent/js/accesibilidad.js`: botón flotante ♿ con
   panel de radios; aplica el filtro al `<body>` vía matrices SVG
   (`feColorMatrix`). Persistencia: en BD si hay sesión, en `localStorage`
   si es visitante anónimo. Filtros de **corrección** (algoritmo Daltonize
   publicado en daltonize.org, matrices RGB→LMS→RGB calculadas, no simulación).

5. **Enganche** — `<script src="js/accesibilidad.js"></script>` agregado antes
   de `</body>` en los 6 JSPs de cliente: `index`, `productos`, `carrito`,
   `pedidos`, `login`, `registro`. Los JSPs del panel admin no se tocan.

### Decisiones de diseño

- **Corrección, no simulación:** un filtro que "simula" daltonismo sirve para
  diseñadores pero no ayuda al usuario real; se implementó Daltonize real para
  correr los colores que el usuario no distingue hacia canales que sí percibe.
- **Sin fallback a cliente demo:** a diferencia de `PedidoServlet`, un
  visitante anónimo NO escribe sobre el cliente id=1; su preferencia es local
  (localStorage). Evita que todos los anónimos se pisen la misma fila.
- **`lectura_voz_activa` reservada:** la columna existe desde ya (piezas
  futuras de lectura en voz alta) pero no se expone en la UI hasta que active
  algo real — nada de controles decorativos.
- **Validación en dos capas:** lista blanca en el servlet + ENUM en la BD.

### DDL aplicado a `libreria_brenda`

```sql
CREATE TABLE preferencias_accesibilidad (
  cliente_id INT NOT NULL,
  tipo_daltonismo ENUM('ninguno','protanopia','deuteranopia','tritanopia') NOT NULL DEFAULT 'ninguno',
  lectura_voz_activa TINYINT(1) NOT NULL DEFAULT 0,
  fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (cliente_id),
  CONSTRAINT fk_pref_accesibilidad_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Pruebas

Compilación completa del proyecto sin errores + **7/7 pruebas funcionales
contra la BD real** (defaults, insert, upsert, rechazo ENUM, cascade) con
cliente temporal de QA eliminado al terminar. Evidencias completas en
[`EVIDENCIAS_PRUEBAS.md`](EVIDENCIAS_PRUEBAS.md).

---

## [Pieza 2] Marcado ARIA / compatibilidad con lector de pantalla

**Fecha:** 2026-09-27
**Motivación:** misma línea ODS 10 / Ley 29973: que el flujo de compra sea
usable con lector de pantalla (NVDA/JAWS/VoiceOver) y navegable con teclado.

### Hallazgos del audit y corrección aplicada

| Hallazgo | Corrección |
|---|---|
| Botones de solo ícono/emoji (🔍, ✕, +/−) sin nombre accesible | `aria-label` en buscadores (index, carrito, pedidos), cerrar modal, botones +/− y Eliminar del carrito |
| `alt` redundantes ("Pendiente Pendiente", "Carrito Carrito") | `alt=""` cuando el texto ya está junto al ícono (logo, ícono de carrito, íconos de estado) |
| Sin `<main>` ni `<nav>` etiquetado: imposible saltar al contenido | `<main id="contenido-principal">` en las 5 páginas + `aria-label="Navegación principal"` en el navbar + skip-link visible al enfocar |
| Contenido dinámico sin `aria-live` (no se anuncia) | `role="status" aria-live="polite"` en badge del carrito; `aria-live` en resumen (`aria-atomic`), lista de ítems, lista de pedidos, grid de productos (`aria-busy`) y toast |
| Tarjetas de pago `<div onclick>` inutilizables con teclado | `role="radiogroup"` + `role="radio"` + `aria-checked` + `tabindex="0"` + Enter/Espacio en las 6 tarjetas |
| `<label>` de registro sin asociar a su input | 9 `label for=` + `autocomplete` (given-name, family-name, email, tel, street-address, new-password) + `inputmode="numeric"` en DNI |
| Errores con `alert()` (interrumpe y varía entre lectores) | `#msg-reg` con `role="alert"` + helper `mostrarMensaje()`; los 9 `alert()` del registro reemplazados |
| Mensaje de login sin semántica | `role="alert"` en `#msg-login` |
| Tabs Cliente/Admin sin semántica | `role="tablist"`/`role="tab"` + `aria-selected` actualizado en `cambiarTab()` |
| Filtros de estado sin estado accesible | `aria-pressed` en los 6 botones, actualizado en `setFiltro()` |
| Modal de detalle sin semántica | `role="dialog" aria-modal="true" aria-labelledby="modal-titulo"` |
| Dropdown de cuenta sin estado | `aria-haspopup` + `aria-expanded` actualizado (incluye reset al cerrar por clic fuera) |
| Categorías de index: enlaces disfrazados de botón | `role="button"` (sin romper el CSS) + `aria-current="true"` en la activa, gestionado en `filtrar()` |
| Widget ♿ sin cierre por teclado | Escape cierra el panel y devuelve el foco al botón |
| `aria-current`/`aria-busy` | `filtrar()` marca la categoría activa; el grid limpia `aria-busy` al terminar de cargar |

### Alcance (decisión documentada)

- Se aplicó a las **páginas de cliente**: `index`, `carrito`, `pedidos`,
  `login`, `registro` (y `js/carrito.js`, `js/accesibilidad.js`, `css/style.css`).
- **`productos.jsp` resulta ser del panel de administración** (sidebar +
  gestión de catálogo), no del cliente: no recibió los cambios globales de
  cliente (no tiene navbar de cliente y ya usa su propio `<main class="admin-main">`).
  Su marcado ARIA queda como mejora futura junto al resto del panel interno.
- CSS agregado a `css/style.css`: `.skip-link` (oculto salvo foco) y
  `:focus-visible` con contorno amarillo para navegación por teclado.

### Límites honestos (para el informe y el QA)

- Esto deja el sitio **compatible** con lectores de pantalla; **no** se debe
  afirmar que "cumple WCAG": falta validación manual con un lector real
  (NVDA en Windows es gratuito; VoiceOver viene en macOS/iOS).
- El modal de detalle anuncia su rol pero **no implementa focus trap**
  completo (capturar Tab dentro del modal); queda como mejora futura.

### Verificación

`node --check` de los 2 JS externos y de los 5 scripts inline (extraídos con
awk), greps de marcado por página (aria-checked=6, aria-pressed=8,
label for=9, etc.) y compilación Java de sanidad. Evidencias completas en
[`EVIDENCIAS_PRUEBAS.md`](EVIDENCIAS_PRUEBAS.md) (E10–E12).

---

## [Pieza 3] Lectura en voz alta (Web Speech API)

**Fecha:** 2026-09-27
**Motivación:** completar el paso 1 de accesibilidad. Sin cambios en la BD ni
en el servlet: la columna `lectura_voz_activa` y `PreferenciaAccesibilidadServlet`
ya la soportaban desde la pieza 1 — solo faltaba que el frontend dejara de
mandar `false` fijo.

### Qué se implementó

1. **`WebContent/js/accesibilidad.js`** (reescrito alrededor de un estado
   compartido `estado = { tipoDaltonismo, lecturaVozActiva, autenticado }`):
   - El panel ♿ gana el checkbox "Lectura en voz alta" (si
     `speechSynthesis` no está disponible, muestra un aviso en su lugar).
   - Al activarlo, cada tarjeta de producto muestra un botón 🔊 Escuchar;
     segundo clic sobre el mismo botón detiene, e iniciar otra lectura corta
     la anterior (`speechSynthesis.cancel()`).
   - Un único listener por delegación cubre también las tarjetas creadas
     dinámicamente; `pagehide` corta la lectura al salir de la página.
   - `guardarPreferencia()` ahora envía el estado real de ambos campos
     (antes enviaba `lecturaVozActiva: 'false'` fijo y habría pisado el
     checkbox). Anónimos: `localStorage` (`accesibilidad_lecturaVoz`).
   - Voz `es-PE` con fallback a cualquier voz `es*` del sistema.
2. **`WebContent/index.jsp`** — `crearTarjetaProducto()`: botón 🔊 con
   `aria-pressed` y `aria-label` por producto; el texto a leer va en
   `card.dataset.textoVoz` (no en `onclick`, para no pelear con comillas).
   El precio se sintetiza como "12 con 50 soles" en vez de "12.50".
3. **Corrección del filtro (paso 3 del plan):** el filtro Daltonize pasa de
   `<body>` a `<html>`. En CSS un `filter` convierte al elemento en
   *containing block* de los `position:fixed` descendientes (excepto en la
   raíz del documento): con el filtro en `<body>`, el botón ♿ y el toast del
   carrito podrían desplazarse con la página al hacer scroll.

### Pruebas

- **10/10 pruebas QA contra la BD real** del round-trip completo del nuevo
  campo: checkbox → `guardar()` → `TINYINT = 1` en BD cruda → JSON booleano
  sin comillas (`"lecturaVozActiva":true`) → parseo JS `!!data.lecturaVozActiva`;
  además desactivado → `false` conservando el filtro, ambos campos persisten
  juntos sin pisarse, y cascade de limpieza. Cliente temporal eliminado.
- `node --check` de `accesibilidad.js` y del script inline de `index.jsp`.
- Greps: `btn-leer-voz` presente, 3 selectores `html.accesibilidad-*`,
  0 referencias a `body.accesibilidad-*`. Compilación Java OK.
- Evidencias completas en [`EVIDENCIAS_PRUEBAS.md`](EVIDENCIAS_PRUEBAS.md) (E13–E14).

### Límites honestos (para el informe y el QA)

- **Pendiente de validación manual** (igual que la pieza 2): la voz en
  español depende de las voces instaladas en el sistema operativo; probar en
  Chrome/Edge y Firefox. Si no hay voz `es`, se usa la voz por defecto.
- Pendiente de confirmación visual de la corrección del filtro: activar un
  filtro, hacer scroll en `index.jsp` y verificar que el ♿ permanece fijo.
- Con NVDA activo, verificar que el botón se anuncie como "Leer en voz alta:
  {producto}, botón" y que no compita con la voz sintetizada.
- La pieza lee **tarjetas de producto**; el resto de la página se sigue
  navegando con el lector de pantalla (esta función es un complemento, no un
  reemplazo de NVDA/JAWS).

---

## [Paso 2] Retiro del ODS10 antiguo (lógica de beneficios en runtime)

**Fecha:** 2026-09-27
**Motivación:** los beneficios ODS10 (checkboxes de -15% estudiante y envío
gratis por discapacidad) se aplicaban en runtime fuera del alcance definido
en el Sprint 0. Se retira esa lógica para dejar **una sola regla de negocio**
y preparar el terreno para los códigos promocionales (paso 3).

### Decisiones de diseño (qué se conserva)

- **Regla general de la tienda:** envío gratis si el subtotal ≥ S/30, sino S/10.
- **El campo `descuento` se conserva** (fila del resumen en el carrito,
  `Pedido.descuento` y su columna en BD) pero queda fijo en `0`: el paso 3 lo
  llenará con el módulo de códigos promocionales vía `setDescuento()`.
- La validación de "método de pago" en `realizarPedido()` se mantiene tal cual.

### Qué se quitó

| Archivo | Cambio |
|---|---|
| `carrito.jsp` | Sección HTML "Inclusión y Equidad (ODS 10)" con sus 2 checkboxes, CSS `.inclusion-box`/`.ods10-check`, rótulo "Descuento estudiante (ODS10, -15%)" → "Descuento", `mensajeBeneficios` del alert de éxito, parámetros `beneficio*` del POST |
| `carrito.js` | `calcularTotales()` simplificado (sin checkboxes ni -15%), `esDiscapacidad` eliminado del render, envío solo por la regla general |
| `PedidoServlet.java` | Lectura de `beneficioEstudiante`/`beneficioDiscapacidad` eliminada; `calcularSubtotal()` + `aplicarBeneficiosODS10()` reemplazados por `calcularTotal()` (recalculado en el servidor, sin confiar en montos del navegador) |
| `Pedido.java` | `aplicarBeneficiosODS10()` eliminado; `calcularTotal()` unificado (subtotal, envío ≥30, `descuento` se respeta tal cual) |
| `PedidoDAO.java` | Comentario actualizado (el total ya viene de `Pedido.calcularTotal()`) |
| `images/planeta.png` | Eliminada: quedó huérfana tras retirar la sección (verificado con grep en jsp/js/java/html/css) |

### Compatibilidad

Los pedidos antiguos con descuento distinto de 0 **siguen mostrándose
correctamente**: no se toca la columna `descuento` ni los `SELECT` del DAO.

### Verificación

Grep de lógica ODS10/beneficios en cero (solo quedan comentarios normativos
de la Ley 29973 en las piezas de accesibilidad, que no son código),
`node --check` de `carrito.js` y del inline de `carrito.jsp`, compilación
Java, y **8/8 pruebas de cálculo** (S/20 → envío 10/total 30; S/35 → gratis;
borde S/30; descuento seteado antes de `calcularTotal()` se respeta). Evidencias
en [`EVIDENCIAS_PRUEBAS.md`](EVIDENCIAS_PRUEBAS.md) (E15–E17).

---

## [Paso 3] Códigos promocionales

**Fecha:** 2026-09-27
**Motivación:** el campo `descuento` quedado en 0 en el paso 2 se llena ahora
con códigos promocionales validados por el servidor.

### Decisiones de diseño

1. **Solo con sesión:** aplicar un código exige sesión de cliente real (sin
   fallback al "Cliente Demo" id=1, mismo criterio que el perfil de
   accesibilidad). Si fuera anónimo, el primer visitante gastaría el
   "único uso" de todos.
2. **El "un solo uso por cliente" lo garantiza la BD:** `codigos_promo_usos`
   tiene `PRIMARY KEY (codigo, cliente_id)` y el uso se registra dentro de la
   misma transacción del pedido; si dos pestañas confirman a la vez, la
   segunda recibe duplicate-key, hace **rollback completo** (incluido el
   descuento de stock) y devuelve un mensaje claro.
3. **El servidor recalcula todo:** el navegador solo previsualiza (rama
   `validarPromo`, que no consume el código); al confirmar, `guardarPedidoEnDB`
   vuelve a validar el código y recalcula descuento, envío y total.

### Qué se implementó

- **BD:** tablas `codigos_promo` (tipo `PORCENTAJE`/`MONTO_FIJO`, CHECK de
  valor > 0 y ≤ 100 en porcentaje) y `codigos_promo_usos` (PK compuesta, FK a
  `codigos_promo` y a `clientes` con cascade). Seed: `BIENVENIDA10` (10% sin
  vencimiento), `LIBRO5` (S/5 fijo, vence 2026-12-31), `VERANO20` (vencido a
  propósito para probar ese caso). Los códigos se crean por SQL (sin pantalla
  admin por ahora).
- **Modelo/DAO:** `CodigoPromo.calcularDescuento()` (misma fórmula que el JS;
  monto fijo nunca supera el subtotal), `CodigoPromoDAO` con `validar()`
  (existencia, activo, vencimiento por zona America/Lima, uso previo) y
  `registrarUso()` transaccional, más `CodigoPromoInvalidoException`.
- **`PedidoDAO.crear(pedido, clienteId, codigoPromo)`:** overload con el
  registro del uso en la misma transacción (rollback total si la PK rechaza).
- **`Pedido.calcularTotal()`:** el envío ahora se evalúa sobre
  `(subtotal - descuento) >= 30`.
- **`PedidoServlet`:** rama `validarPromo` para la previsualización,
  revalidación al confirmar, `setDescuento()` y catch de la nueva excepción.
- **Carrito:** caja de código con Aplicar/Quitar (Enter también aplica),
  mensaje accesible (`role="status" aria-live="polite"`), descuento y envío
  recalculados en vivo, reset si el carrito queda vacío, y envío de
  `codigoPromo` al confirmar.

### Verificación

**19/19 pruebas de integración contra la BD real** (casos 2–9 del plan +
extras: carrito vacío, y fallo de stock no consume el código), incluyendo el
rollback completo del caso de las dos pestañas y la persistencia de
`descuento=4.00` / `total=36.00` en `pedidos`. Cliente, productos y usos
temporales eliminados al terminar; la BD quedó sin filas de prueba.
Evidencias en [`EVIDENCIAS_PRUEBAS.md`](EVIDENCIAS_PRUEBAS.md) (E19–E20).

### Decisiones confirmadas y aplicadas (ver [Paso 3b])

Las tres decisiones abiertas del diseño (rechazo del código que empeora el
envío, liberación del código al cancelar, y precios reales desde BD) fueron
confirmadas y aplicadas: ver la sección [Paso 3b].

---

## [Paso 3b] Refuerzos de seguridad y usabilidad sobre el paso 3

**Fecha:** 2026-09-27
**Motivación:** cerrar los tres puntos que el QA del paso 3 dejó como
abiertos, tras confirmación del usuario.

### 1. Rechazo del código que empeora el envío

`CodigoPromoDAO.validar()` rechaza ahora el código si el subtotal ya
alcanzaba el envío gratis y el descuento lo deja por debajo de S/30 (el
cliente pagaría más con código que sin él, ej. `LIBRO5` sobre S/32):
"Este código haría que pagues más por el envío. Prueba con otro."

### 2. Liberar el código al cancelar un pedido PENDIENTE

`PedidoDAO.cancelarPedidoCliente()` ahora es transaccional: si el UPDATE de
cancelación aplica (pedido del cliente y en PENDIENTE), borra en la misma
transacción la fila de `codigos_promo_usos` de ese pedido, y el código queda
disponible para reuso. La verificación y la liberación son atómicas; un
intento de cancelación ajena no modifica nada.

### 3. Precio real desde la BD (defecto preexistente corregido)

`PedidoServlet.guardarPedidoEnDB` ya **no confía** en `item_precio` del
navegador: lee el precio real de cada producto desde `productos` con el
nuevo `ProductoDAO.obtenerPrecio(Connection, int)` y rechaza el pedido si el
producto no existe o la cantidad es inválida. El subtotal, el descuento y el
total ahora son imposibles de manipular desde el cliente.

### Verificación

**16/16 pruebas contra la BD real** de los tres fixes (rechazo en los
subtotales límite, liberación y reuso del código, cancelación ajena
rechazada, precios reales y producto inexistente). Limpieza verificada: 0
filas de prueba. Evidencias en [`EVIDENCIAS_PRUEBAS.md`](EVIDENCIAS_PRUEBAS.md)
(E21).

---

## [Laboratorio TDD] Validaciones de producto en servidor (H0007)

**Fecha:** 2026-09-28
**Motivación:** laboratorio de calidad de la semana con TDD. El Sprint 2 declaró
"validaciones de formulario (precio, stock, campos requeridos)" como tarea 5,
pero en el servidor no existían: el servlet convertía precio/stock inválidos en
`0` sin avisar, aceptaba precios negativos y un nombre `null` llegaba directo
a la BD.

### Qué se implementó

1. **`ValidadorProducto`** (`src/libreria/util/`), construido test-first con
   ciclos Rojo → Verde → Refactor: nombre obligatorio, precio > 0, stock no
   negativo y categoría obligatoria. Los errores se **acumulan** (una sola
   pasada reporta todas las reglas incumplidas) y el refactor final usa
   helper `vacio()` + constantes `ERR_*`.
2. **9 tests JUnit 5** en `test/libreria/util/ValidadorProductoTest.java`
   (helper `productoValido()`: cada test cambia un solo campo; incluye el
   test de borde `stockCero_noDevuelveError`, que pasa desde el inicio para
   proteger contra `<= 0`, y los de regresión de producto válido y
   acumulación de 4 errores). Primer test automatizado permanente del
   proyecto: responde parcialmente al hallazgo M-07 de la auditoría
   (pruebas no reproducibles).
3. **`ProductoServlet`:** `crear` y `editar` validan antes de tocar el DAO;
   si hay errores responden **HTTP 400** con `{"ok":false,"error":...}` y el
   producto no llega a la BD. `productos.jsp` ya mostraba `data.error` en el
   modal, no requirió cambios.
4. **Entorno:** `junit-platform-console-standalone-1.11.4.jar` en
   `WEB-INF/lib` + registro en `.classpath` (fuente `test/`).

### Verificación

Rojo y verde documentados **por ciclo y por corrida** (se corrió JUnit después
de cada Rojo y antes de cada Verde; ciclos 1-5 en secciones 3-7 del informe).
9/9 en verde al cerrar, también tras el refactor. Compilación completa del
proyecto OK. Evidencias completas, reproducción y límites honestos en
[`LABORATORIO_TDD.md`](LABORATORIO_TDD.md).

**Pendiente:** republish en Tomcat y prueba HTTP end-to-end (400 con payload
inválido) — Tomcat estaba detenido al cerrar la sesión. El fallback silencioso
a categoría 1 en `ProductoDAO.obtenerCategoriaId()` queda como refactor futuro.

---

## [RF02] Inicio de sesión de cliente y administrador

**Fecha:** 2026-10-21
**Motivación:** convertir el login en un incremento de portafolio QA verificable
y cerrar defectos reales de autenticación y sesión.

### Qué se implementó

1. **`ValidadorEmail`** (`src/libreria/util/`), construido test-first: formato
   y límite de 120 caracteres (el de la columna `email`). Reemplaza las dos
   regex duplicadas de `LoginServlet` y `RegistroServlet`.
2. **`SesionAutenticada`** (`src/libreria/servlets/`): crea la sesión, rota el
   `JSESSIONID` con `request.changeSessionId()` y limpia atributos previos.
   Se usa en login y registro.
3. **`PasswordUtil.verificar`:** valida el formato BCrypt completo antes de
   llamar a jBCrypt. Un hash truncado ya no puede lanzar
   `StringIndexOutOfBoundsException` y tumbar el login.
4. **Pruebas:** 18 JUnit de DAO (caracterización contra `libreria_brenda_test`),
   16 JUnit de `ValidadorEmail` (TDD), 2 de hash malformado, 1 de concurrencia
   del contador de intentos y 62 comprobaciones HTTP de RF02.

### Verificación

**72/72 JUnit sin BD · 91/91 JUnit con BD · 62/62 HTTP RF02 · 80/80 HTTP
general.** Evidencias, matriz y límites en
[`docs/QA/RF02_LOGIN.md`](QA/RF02_LOGIN.md).

### Pendiente

- CI ejecutado en GitHub sobre `4db4786`: **2/2 jobs en success** (unitarios y DAO con MariaDB), ver [evidencia](QA/evidencias/ci-2026-10-21.txt).
- Bloqueo de login en memoria, por correo y compartido entre roles (riesgo de
  DoS sobre una cuenta admin); sin límite por IP ni TTL de entradas.
- Saneamiento aplicado en el árbol actual (DNI, correos, nombre personal y
  hashes sensibles). El historial anterior conserva los valores antiguos porque
  no se reescribió: ver [`docs/QA/SEGURIDAD_REPOSITORIO.md`](QA/SEGURIDAD_REPOSITORIO.md).

---

## [Demo] Panel administrativo con datos sintéticos aislados

**Fecha:** 2026-10-21
**Motivación:** el Tomcat que sirve `localhost:8080` mostraba clientes
originales aunque el backup SQL ya estaba saneado. El problema no era la JSP:
la aplicación leía de la base real de la instancia `libaas-mysql` en el puerto
3307 (`libreria_brenda`, 32 clientes), no del backup del repositorio.

### Diagnóstico

- `setenv.bat` definía `DB_HOST=127.0.0.1`, `DB_PORT=3307` y
  `DB_NAME=libreria_brenda`; esas variables tienen prioridad sobre
  `WEB-INF/db.properties`.
- `clientes.jsp` además conservaba un arreglo de 10 clientes de ejemplo que se
  mostraba antes de que `fetch('ClienteServlet')` respondiera.
- La base de 3307 no se modificó: sigue con 32 clientes y 29 pedidos; no se
  le aplicó ningún `UPDATE`, `DELETE` ni cambio de esquema.

### Cambios

- **`database/demo/libreria_brenda_demo.sql`:** seed estático que crea
  `libreria_brenda_demo` en MariaDB, con 16 clientes ficticios
  (`Cliente Demo`, DNI `99900001`–`99900016`, correos `@example.com`,
  teléfonos `9000001xx`, direcciones `Av. Demo ...`), 16 pedidos, 31 ítems y
  8 comprobantes. Conserva los IDs y las claves foráneas; no toca
  `libreria_brenda` ni `libreria_brenda_test`.
- **`WebContent/clientes.jsp`:** se eliminó el arreglo de clientes embebido;
  el listado depende solo de `ClienteServlet`/`ClienteDAO`. El historial del
  modal se alineó con los pedidos del seed.
- **`WebContent/login.jsp`:** la pista de demo ahora muestra las cuentas
  sintéticas (`admin@example.com` / `Admin#2026` / `EMP-DEMO` y
  `cliente01@example.com` / `Cliente#2026`).
- **Configuración local (fuera del repositorio):** el Tomcat de `:8080` quedó
  apuntando a `libreria_brenda_demo` en 3306. Se respaldaron `setenv.bat` y
  `db.properties` antes del cambio; la contraseña se dejó solo en
  `db.properties`, no en `setenv.bat`.

### Verificación

| Comprobación | Resultado |
|---|---|
| Carga del seed | 16 clientes, 16 pedidos, 31 ítems, 8 comprobantes, 0 huérfanos |
| `ClienteServlet` autenticado | 16 filas; 16 nombres/`@example.com`/DNI/teléfonos/direcciones sintéticos |
| Panel `clientes.jsp` en navegador | 16 filas, 0 coincidencias con nombres o direcciones antiguas; modal con 8 pedidos del cliente 01 |
| JUnit sin BD | **72/72** |
| JUnit con `libreria_brenda_test` | **91/91** |
| HTTP RF02 | **62/62** |
| HTTP general | **80/80** |

Evidencia: [`docs/QA/evidencias/demo-sintetica-2026-10-21.txt`](QA/evidencias/demo-sintetica-2026-10-21.txt).

### Límites

- La demo es local y no sustituye a la base real; para volver a ella se
  restauran los respaldos de configuración y se reinicia Tomcat.
- El saneamiento sigue sin reescribir el historial de Git: los valores antiguos
  permanecen en commits anteriores, como se advierte en
  [`SEGURIDAD_REPOSITORIO.md`](QA/SEGURIDAD_REPOSITORIO.md).
- No se hizo merge del PR #3 ni se modificó `libreria_brenda_test` más allá de
  las suites de prueba.

---

## [Aislamiento] Tomcat propio y usuario SQL exclusivo para LibreriaBrend

**Fecha:** 2026-10-21
**Motivación:** LibreriaBrend dependía de la instalación de LibaaS, de su
Tomcat y de credenciales compartidas. El objetivo fue levantar una instancia
propia, en otro puerto, conectada solo a `libreria_brenda_demo`, sin detener
ni modificar el entorno antiguo.

### Cambios

- **`.gitignore`:** se agregó `.tools-libreria/`; la instalación local y sus
  credenciales no se versionan.
- **Tomcat aislado:** Apache Tomcat 11.0.26 en
  `.tools-libreria/apache-tomcat-11.0.26`, HTTP `8082`, shutdown `8006` y AJP
  `8010`. El Tomcat de `:8080` no se reinició ni se editó.
- **Usuario SQL:** `libreria_demo_app`, sin privilegios globales y con
  `SELECT, INSERT, UPDATE, DELETE, EXECUTE, SHOW VIEW` solo sobre
  `libreria_brenda_demo`. El host es `%` porque la conexión del host llega a
  MariaDB como `172.17.0.1` por el NAT de Docker; no se reutilizó `root` ni
  `libaas_app`.
- **Credenciales:** solo en el `db.properties` del contexto desplegado, que
  está ignorado por Git. `setenv.bat` únicamente define `JAVA_HOME`, UTF-8 y
  zona horaria, sin variables `DB_*` que puedan redirigir la conexión.
- **Modal de clientes:** `ClienteServlet?accion=pedidos` devuelve el historial
  real desde `ClienteDAO.listarPedidosRecientes` (DTO `PedidoResumen`), con
  filtro por cliente, orden descendente y límite acotado. `clientes.jsp` ya no
  usa un historial estático.
- **Prueba de integración:** `ClienteDAOPedidosTest` crea dos clientes y tres
  pedidos temporales en `libreria_brenda_test`, verifica el filtro y el orden,
  y limpia los datos al terminar.

### Verificación

| Comprobación | Resultado |
|---|---|
| Login admin en `:8082` | HTTP 200, `{"ok":true,"redirect":"admin.jsp"}` |
| Login cliente en `:8082` | HTTP 200, `{"ok":true,"redirect":"index.jsp"}` |
| `ClienteServlet` | 16 clientes, 16 `Cliente Demo`, 16 correos `@example.com` |
| `pedidos.jsp` / `PedidoServlet` | HTTP 200; 8 pedidos propios del cliente 01 |
| Modal cliente 01 | 8 pedidos reales; primero `PED-1788638730511` · 05/09/2026 |
| `admin-pedidos.jsp` | 16 IDs `PED-*` |
| Catálogo | HTTP 200; 11 productos, 11 activos |
| SQL aislado | `libreria_brenda` y `libreria_brenda_test` denegadas (ERROR 1142) |
| JUnit con BD | **91/91** (0 fallos) |
| JUnit sin BD | **72 ejecutadas**, 0 fallos; 3 clases DAO omitidas |
| HTTP RF02 | **62/62** |
| HTTP general | **80/80** |

Evidencia: [`docs/QA/evidencias/entorno-aislado-2026-10-21.txt`](QA/evidencias/entorno-aislado-2026-10-21.txt)
y captura del modal: [`entorno-aislado-2026-10-21.png`](QA/evidencias/entorno-aislado-2026-10-21.png).

### Límites

- No se migró el puerto `8080`: el Tomcat antiguo sigue disponible y la
  decisión de retirarlo queda para una etapa posterior.
- El host `%` del usuario demo es más amplio que `localhost`; el permiso sigue
  acotado al esquema `libreria_brenda_demo` y no incluye administración.
- No se hizo merge del PR #3 ni se modificaron volúmenes o credenciales de
  LibaaS.

---

## [Corrección] El :8080 volvió a apuntar a la demo

**Fecha:** 2026-10-21
**Síntoma:** al reabrir el proyecto desde VS Code, `admin@example.com` /
`Admin#2026` / `EMP-DEMO` respondía "Credenciales de empleado incorrectas".

**Causa:** VS Code lanza Java directamente (`Code.exe` → `cmd.exe` → `java.exe`)
y no ejecuta `bin/setenv.bat`. El contexto de `:8080` tomaba
`WEB-INF/db.properties`, que seguía apuntando a `libreria_brenda`; por eso la
cuenta comercial autenticaba y la demo no. Además, la JSP de clientes era nueva
pero el `ClienteServlet.class` desplegado era del 17/10 y no tenía
`accion=pedidos`.

### Corrección local aplicada

- `db.properties` del contexto de `:8080` ahora apunta a
  `libreria_brenda_demo` con el usuario `libreria_demo_app`; la contraseña solo
  vive en ese archivo ignorado.
- `setenv.bat` quedó coherente con el mismo nombre de base y usuario.
- Se publicaron las clases actuales desde `src/` (incluido `PedidoResumen`).
- Se conservaron copias locales de la configuración comercial anterior
  (`*.bak-comercial-20261021`) dentro de `.tools`, sin versionar.

### Verificación en :8080

| Comprobación | Resultado |
|---|---|
| Login admin demo | HTTP 200, `{"ok":true,"redirect":"admin.jsp"}` |
| `ClienteServlet` | 16 clientes, 16 `Cliente Demo`, 16 `@example.com` |
| Modal cliente 01 | 8 pedidos reales; primero `PED-1788638730511` · 05/09/2026 |
| Navegador | 16 filas y modal con 8 pedidos |

El puerto `8080` no se migró: sigue siendo la misma instancia, ahora con la base
demo y el código actual. Detalle en
[`entorno-aislado-2026-10-21.txt`](QA/evidencias/entorno-aislado-2026-10-21.txt)
y captura en [`8080-demo-2026-10-21.png`](QA/evidencias/8080-demo-2026-10-21.png).

---

## [RF03] Bloqueo temporal por intentos fallidos

**Fecha:** 2026-10-23
**Commits:** `f813536` (corrección + pruebas unitarias) y `772c54d`
(suite HTTP), en la rama `qa/rf03-bloqueo-login`.
**Requisito oficial:** bloquear el login de un correo durante 2 minutos tras
5 intentos fallidos, informar los minutos restantes y reiniciar el contador
tras un acceso exitoso (RF03, prioridad ALTA; numeración oficial RF01–RF17).

### Qué cambió

- **Defecto corregido (RED→GREEN):** `minutosRestantes()` aplicaba
  `Math.max(1, …)` e informaba **1 minuto para un bloqueo ya vencido**,
  contradiciendo `estaBloqueado()` (que lo daba por levantado). Ahora devuelve
  0 cuando el restante ya venció; el techo de minutos para restantes
  positivos (2 y 1) no cambió.
- **Pruebas deterministas:** nueva abstracción mínima de reloj
  (`LongSupplier` paquete-private, por defecto el reloj real) y6 pruebas
  nuevas en `ControlIntentosLoginExpiracionTest` que cubren119 999 /
  120 000 / 120 001 ms, el techo de60 001/60 000 ms, la limpieza del
  registro expirado y el nuevo ciclo de intentos — sin esperas reales.
- **Suite HTTP nueva:** `test/integration/rf03-bloqueo-tests.sh` con29
  comprobaciones (4 fallos, activación en el5.º fallo propio, rechazo en
  el6.º, minutos en el JSON, contraseña correcta durante bloqueo, reinicio
  tras éxito, independencia por correo y coherencia entre roles), siempre
  sobre `libreria_brenda_test` con limpieza acotada a los correos de la
  ejecución actual. Tras la revisión del PR #4, las precondiciones de
  aislamiento son fatales (`abortar`, exit1) y el `trap` se instala
  únicamente después de superarlas.

### Pruebas y regresión (23/10/2026)

| Suite | Resultado |
|---|---|
| JUnit sin BD | **78/78** (antes72) |
| JUnit con `libreria_brenda_test` | **97/97** (antes91) |
| HTTP RF03 | **29/29** (corregido; 1.ª corrida27/27) |
| HTTP RF02 (regresión) | **62/62** |
| HTTP general (regresión) | **80/80** |

Sin regresiones; RF01/RF02, workflows de CI, respaldos y evidencias
históricas intactos. Matriz completa, decisiones de borde y riesgos en
[`QA/RF03_BLOQUEO_LOGIN.md`](QA/RF03_BLOQUEO_LOGIN.md); salidas crudas en
`QA/evidencias/rf03-*` y `QA/evidencias/*-rf03-2026-10-23.txt`.

### Sprint 4 — Pruebas no funcionales y cobertura instrumentada (09/11/2026)

Etapa de aseguramiento de calidad no funcional: 8 historias de usuario (HU-01 … HU-08),
34 story points, del 01/11/2026 al 08/11/2026.

**Herramientas incorporadas:** Apache JMeter 5.6.3 instalado como aplicación en el equipo
(`C:\Apache\apache-jmeter-5.6.3`) y JaCoCo 0.8.12 para la cobertura instrumentada.

**Correcciones sobre el código de producción:**

| Código | Hallazgo | Corrección | Regresión |
|---|---|---|---|
| QA-S4-01 | El identificador de pedido se generaba con `System.currentTimeMillis()`, lo que colisionaba bajo concurrencia (101 claves primarias duplicadas) | Secuencia monotónica con `AtomicLong` | `PedidoIdentificadorUnicoTest` (1.600 pedidos en 64 hilos) |
| QA-S4-02 | `ConexionBD` abría y destruía una conexión física por consulta: 15.698 sockets en `TIME_WAIT` y 49 s de latencia máxima | Pool acotado de 60 conexiones, con API pública sin cambios mediante un proxy que devuelve la conexión al pool | `ConexionBDPoolTest` |

**Hallazgo abierto:** QA-S4-03 — `admin.jsp` y `admin-pedidos.jsp` no aplican paginación y
materializan la totalidad de los pedidos (85,83 % y 95,41 % de error en la carga mixta).
Corrección propuesta para el Sprint 5.

**Medición ejecutada:**

| Medición | Resultado |
|---|---|
| Campaña JMeter (10 escenarios) | 275.979 muestras; 0 % de error en 16 de 18 servicios medidos |
| Cobertura JaCoCo (JUnit + tráfico HTTP) | 57,55 % de líneas, 41,66 % de ramas, 72,60 % de métodos sobre 41 clases de producción |
| JUnit 5 | **103/103**, 0 fallos |
| Recorrido funcional HTTP | **36/36**, 0 fallos |

**CI:** el job `unit-tests` excluye ahora `libreria.util.ConexionBDPoolTest`, que abre
conexiones reales contra el motor y no puede ejecutarse sin base de datos. Verificado en local:
**80/80** sin BD y **103/103** con BD.

**Entorno y datos:** la base local fue restaurada desde `libreria_brenda_backup.sql` (respaldo
saneado) porque había vuelto a una versión anterior al saneamiento, y la aplicación quedó
apuntando a `libreria_brenda_demo`, la copia íntegramente sintética. Los ajustes del botón de
ejecución de VS Code (extensión Tomcat) se corrigieron para apuntar al Tomcat propio del
proyecto, en el puerto 8082. Detalle en
[`QA/SEGURIDAD_REPOSITORIO.md`](QA/SEGURIDAD_REPOSITORIO.md).

**Documentación nueva:** [`QA/SPRINT4_PRUEBAS_NO_FUNCIONALES.md`](QA/SPRINT4_PRUEBAS_NO_FUNCIONALES.md)
y evidencias textuales en `QA/evidencias/sprint4-*`.

---

## Pendiente (roadmap de accesibilidad)

- Confirmar visualmente la corrección del filtro en `<html>` (scroll con el
  botón ♿ fijo).
- Validación manual con NVDA de las piezas 2 y 3.
- Marcado ARIA del panel de administración (incluye `productos.jsp`).
- Guardar el DDL en un script versionado `database/` para reproducir el schema.
