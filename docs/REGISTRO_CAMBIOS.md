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

## Pendiente (roadmap de accesibilidad)

- **[Paso 2]** Retiro del ODS10 antiguo: eliminar la lógica vieja de
  `carrito.jsp`, `carrito.js`, `PedidoServlet` y `Pedido.java` (dejar solo la
  vigente definida en el Sprint 0).
- Confirmar visualmente la corrección del filtro en `<html>` (scroll con el
  botón ♿ fijo).
- Validación manual con NVDA de las piezas 2 y 3.
- Marcado ARIA del panel de administración (incluye `productos.jsp`).
- Guardar el DDL en un script versionado `database/` para reproducir el schema.
