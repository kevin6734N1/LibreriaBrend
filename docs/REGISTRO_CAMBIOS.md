# REGISTRO DE CAMBIOS — Librería Brenda

> **Convención del proyecto:** cada cambio funcional se documenta en este
> registro junto con sus pruebas, y se cierra con un commit de Git que queda
> anotado aquí como "estado actual del proyecto". Las evidencias de
> funcionamiento de cada pieza viven en [`EVIDENCIAS_PRUEBAS.md`](EVIDENCIAS_PRUEBAS.md).

## Estado actual del proyecto

| Fecha | Commit | Cambio |
|---|---|---|
| 2026-09-23 | `1a8c8af` | Primer commit — Librería Brenda (app web Java + MySQL) |
| 2026-09-27 | `65dce9f` | CU-03: validar máximo de 10 productos distintos en el carrito + informe de validación |
| 2026-09-27 | `84f4288` | **Pieza 1 accesibilidad:** perfil de accesibilidad en BD + filtro de corrección de color (Daltonize) + docs/ con registro y evidencias |
| 2026-09-27 | `ffcb909` | **Pieza 2 accesibilidad:** marcado ARIA / compatibilidad con lector de pantalla en las páginas de cliente |
| 2026-09-27 | `7c45421` | **Pieza 3 accesibilidad:** lectura en voz alta (Web Speech API) + corrección del filtro en `<html>` |
| 2026-09-27 | `b3a5aa1` | **Paso 2 — retiro del ODS10 antiguo:** una sola regla de negocio (envío ≥ S/30 gratis), `descuento` fijo en 0 para el paso 3 |
| 2026-09-27 | `b5337fd` | **Paso 3 — códigos promocionales:** tablas + DAO + revalidación en servidor + UI en carrito (solo con sesión, un uso por cliente) |
| 2026-09-27 | *(hash se anota al cerrar el paso)* | **Paso 3b — refuerzos:** rechazo de código que empeora el envío · liberación al cancelar · precios reales desde BD |

**Entorno vigente:** Java 21 · Tomcat 11.0.0-M24 · MariaDB 11.8.8 sobre Fedora
WSL2 · BD `libreria_brenda` (root/root, puerto 3306) · driver
`mysql-connector-j-9.7.0.jar` · Jakarta Servlet 6.

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

## Pendiente (roadmap de accesibilidad)

- Confirmar visualmente la corrección del filtro en `<html>` (scroll con el
  botón ♿ fijo).
- Validación manual con NVDA de las piezas 2 y 3.
- Marcado ARIA del panel de administración (incluye `productos.jsp`).
- Guardar el DDL en un script versionado `database/` para reproducir el schema.
