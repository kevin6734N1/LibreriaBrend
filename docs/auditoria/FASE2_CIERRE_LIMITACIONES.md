# FASE 2 — Cierre de Limitaciones y Resolución de Hallazgos de la Fase 1

**Commit auditado:** `291741c3181010fe9a171e900954bdf22fe7a7cb`
**Referencia:** [`FASE2_INFORME.md`](FASE2_INFORME.md) · Fase 1: `docs/REGISTRO_CAMBIOS.md`, `docs/EVIDENCIAS_PRUEBAS.md`, `docs/INFORME_VALIDACION.md`
**Fecha:** 2026-09-28

Estados admitidos: **Confirmado** (verificado empíricamente en runtime) · **Refutado** (la hipótesis no se sostiene con evidencia de ejecución) · **Aún no verificado** (no ejecutable en este entorno, con justificación técnica).

---

## 1. Matriz de Limitaciones de la Fase 1

| # | Limitación declarada en Fase 1 | Estado actual | Evidencia (request/response o salida de comando) |
|---|---|---|---|
| 1 | Sin prueba HTTP end-to-end | **Aún no verificado** | Se ejecutaron **156 peticiones HTTP reales** (110 GET / 6 HEAD / 41 POST; 98 a JSP/servlets) en las evidencias B.02–B.05 y se cerraron todos los vectores alcanzables **sin autenticación**. El flujo de compra autenticado no pudo ejercerse: la aplicación apunta a `libreria_brenda` (bloqueante §0.1 de `FASE2_INFORME.md`), los permisos concedidos no permiten repuntarla y no hay credenciales de cliente. Justificación estricta: cualquier intento de llegar a `PedidoDAO.crear()` es una escritura en producción. |
| 2 | Sin lector de pantalla | **Aún no verificado** | No hay NVDA/JAWS/VoiceOver ni navegador instalado en el entorno. **No se afirma conformidad WCAG de ningún nivel.** |
| 3 | Filtro Daltonize: ¿`<html>` o `<body>`? | **Confirmado** | El `accesibilidad.js` **servido por Tomcat** (`sha256 7b83647bcee7…`, idéntico al del repositorio) aplica la clase con `document.documentElement` y declara 3 selectores `html.accesibilidad-*`; **0** selectores `body.accesibilidad-*`. `evidencias/responses/B02_accesibilidad_dom.txt` §B.02.5. |
| 4 | Repositorio remoto no verificado | **Refutado / cerrado** | `git ls-remote origin` → `refs/heads/main = 291741c3181010fe9a171e900954bdf22fe7a7cb`, igual al HEAD local. El remoto **sí** contiene el commit auditado. `evidencias/logs/A01_entorno.txt` §A.01.11. |
| 5 | Concurrencia transaccional no probada | **Aún no verificado** | L6 exige escrituras concurrentes en producción. No se generaron dos sesiones autenticadas independientes por falta de credenciales y de BD de prueba. Sigue apoyado solo en análisis estático (PK compuesta `(codigo, cliente_id)`; `UPDATE … WHERE cliente_id=? AND estado='PENDIENTE'`). |
| 6 | Escrituras no ejecutadas | **Confirmado** | Se mantiene por mandato del bloqueante §0.1. Ninguna petición alcanzó una operación de escritura; el estado de la BD es idéntico antes y después (`FASE2_ANEXO_LIMPIEZA.md`). |
| 7 | *(nueva)* Logs de arranque / errores | **Confirmado como defecto** | No existen `catalina.out` ni `localhost.<fecha>.log`; stdout/stderr del contenedor van a un `socket`. La inspección L1 encomendada **no es ejecutable** y no puede reconstruirse. Hallazgo **R-04**. |

---

## 2. Resolución de los Hallazgos de la Fase 1

| ID F1 | Hallazgo | Estado en Fase 2 | Evidencia runtime |
|---|---|---|---|
| **C-01** | Credenciales `root/root` embebidas en el código | **Confirmado** | Presentes en el **bytecode desplegado**: la clase `ConexionBD.class` contiene la URL `jdbc:mysql://localhost:3306/libreria_brenda…` y los literales de usuario/contraseña. No existe configuración externa ni DataSource JNDI. `A01_entorno.txt` §A.01.7. |
| **C-02** | Autorización rota: fallback al "Cliente Demo" (id=1) | **Confirmado (vector de lectura)** | `GET /PedidoServlet` sin sesión → `HTTP 200` con **8 pedidos** del cliente id=1 (direcciones, métodos de pago, montos, líneas). Idéntico resultado con cookie anónima. `B03_seguridad_lectura.txt` §B.03.1–B.03.2. **Vector de escritura (cancelar / crear): Aún no verificado** por el bloqueante. |
| **A-01** | Sin protección CSRF | **Confirmado (ausencia de defensa)** | Cookie `Set-Cookie: JSESSIONID=…; Path=/LibreriaBrend; HttpOnly` **sin `SameSite`**; 0 coincidencias de `csrf` en el DOM servido de `carrito.jsp` y `pedidos.jsp`. `B03…` §B.03.8. **Explotación efectiva: Aún no verificado** (requiere navegador real + escritura). |
| **A-02** | `Pedido.id` por `System.currentTimeMillis()` → colisión de PK | **Aún no verificado en runtime** | Requiere crear dos pedidos en el mismo milisegundo = dos escrituras en producción. Reproducido en Fase 1 a nivel de clase (dos `new Pedido()` → mismo id). |
| **A-03** | Cancelar un pedido no repone stock | **Aún no verificado en runtime** | Requiere cancelar un pedido = escritura. Confirmado por lectura de código en Fase 1 (no existe `UPDATE productos SET stock = stock + ?`). |
| **A-04** | Datos de entrega y método de pago validados solo en el cliente | **Aún no verificado en runtime** | La sustitución `"Por confirmar"` ocurre **después** del bucle de validación de productos y justo antes de `PedidoDAO.crear()`: comprobarlo exige una escritura. Confirmado por lectura de código (`PedidoServlet.java:221-222`). |
| **A-05** | Segunda regla de envío contradictoria en `index.jsp` (por precio de producto) | **Confirmado** | El **DOM servido** de `index.jsp` contiene **2** veces `p.precio >= 30` (badge y texto de lectura en voz alta), frente a la regla del servidor `(subtotal − descuento) >= 30`. `B05_controles_servidos.txt` §B.05.2. |
| **A-06** | Carrito sin validar estructura + fuga de mensajes internos | **Confirmado** | `{"ok":false,"error":"Index 1 out of bounds for length 1"}` y `{"ok":false,"error":"Cannot load from object array because \"qtys\" is null"}` devueltos al cliente. `B03…` §B.03.7 (e)(f). Elevado a hallazgo **R-02**. |
| **M-01** | Modal de detalle sin *focus trap* ni Escape | **Confirmado (en el artefacto servido)** | El DOM servido de `pedidos.jsp` tiene `aria-modal="true"` (1×) pero **0** ocurrencias de `Escape` y **0** de `focus(`. `B05_controles_servidos.txt` §B.05.2. *La experiencia con teclado/lector sigue **Aún no verificada** (sin navegador).* |
| **M-02** | `alert()` bloqueantes en el flujo de compra | **Confirmado** | DOM servido: `carrito.jsp` → **6** `alert(`; `pedidos.jsp` → **2**; `registro.jsp` → 1 (que es la mención dentro de un comentario explicativo, no una llamada). `B05…` §B.05.2. |
| **M-03** | `btn` / `btnHtmlOriginal` no declarados; botón nunca deshabilitado | **Confirmado (en el artefacto servido)** | El DOM servido de `carrito.jsp` referencia `btnHtmlOriginal` **2 veces** sin declararlo. `B05…` §B.05.2. El `ReferenceError` en sí requiere un navegador para observarse. |
| **M-04** | `ClienteServlet.escapar()` insuficiente → JSON inválido | **Aún no verificado en runtime** | Se necesitaría un cliente registrado con `\` o salto de línea en el nombre; crearlo es una **escritura**, y listar clientes exige sesión de administrador (no disponible). El defecto sigue acreditado por reflexión sobre la clase compilada en Fase 1. |
| **M-05** | XSS almacenado en `index.jsp` vía nombre/etiqueta de producto | **Aún no verificado en runtime** | Requiere crear/editar un producto (POST de administración) = escritura, y sesión de admin inexistente. |
| **M-06** | Contraste insuficiente en 4 pares de color | **Aún no verificado** | Requiere renderizado y medición en navegador (no disponible). Los ratios WCAG calculados en Fase 1 son un cómputo normativo sobre valores estáticos, no una medición. |
| **M-07** | Ausencia total de tests automatizados | **Confirmado** | El repositorio sigue sin gestor de build, sin framework de pruebas, sin CI y sin ningún `*Test*.java`. Los scripts de prueba del proyecto no están versionados (su propia evidencia E15 los cita como ya eliminados). |
| **M-08** | Tomcat 11.0.0-M24 (milestone, no estable) | **Confirmado** | Es la versión que **está en ejecución** (`/home/kevin/apache-tomcat-11.0.0-M24`, pid 107662). `A01_entorno.txt` §A.01.2–A.01.3. |
| **M-09** | Sin pool de conexiones (`DriverManager` por request) | **Aún no verificado en runtime** | No es observable sin carga concurrente con escrituras. Confirmado estáticamente (`ConexionBD.java:60`). |
| **M-10** | `ControlIntentosLogin`: mapa sin purga + bloqueo dirigido | **Confirmado (el control; no el agotamiento de memoria)** | 5 fallos consecutivos → bloqueo con `"Demasiados intentos fallidos. Intenta de nuevo en 2 minuto(s)."` en los intentos 6 y 7, **por email**. `B05_controles_servidos.txt` §B.05.1. El crecimiento sin cota del mapa **Aún no verificado** (requeriría agotar memoria). |
| **M-11** | Totales duplicados (JS vs Java) sin fuente única | **Aún no verificado en runtime** | Comparar el total mostrado con el cobrado exige un pedido real (escritura). Fórmulas verificadas idénticas en Fase 1 (5/5). |
| **M-12** | Brecha de accesibilidad del panel admin | **Confirmado** | DOM servido: `productos.jsp`, `admin.jsp`, `clientes.jsp`, `reportes.jsp` → `302` a login (no accesible sin sesión de admin); el recuento de ARIA del panel no pudo obtenerse sin credenciales. La brecha sigue documentada y sin cerrar. |
| **B-01 / R-09** | Índice de trazabilidad desactualizado | **Confirmado** | HEAD `291741c` frente a `54a810c` declarado en el registro: **4 commits de diferencia**. `A01_entorno.txt` §A.01.11. |
| **B-03** | DDL / schema sin versionar | **Confirmado** | Sigue sin existir ningún `.sql` versionado en el repositorio. |
| **B-09** | Sin `.gitignore`; `.class` y `.jar` versionados | **Mitigado parcialmente** | Se añade `.gitignore` en esta rama. **Advertencia:** `.gitignore` **no** destrackea ficheros ya versionados — los 32 `build/classes/*.class` y los 2 `.jar` siguen en el índice y requerirían un `git rm --cached` explícito (fuera del alcance autorizado de esta fase). |
| **I-04** | Repositorio remoto no verificable | **Refutado / cerrado** | Ver fila 4 de la matriz de limitaciones. |

---

## 3. Estado Global del Flujo de Compra (CU-01 a CU-06)

| CU | Verificación runtime en Fase 2 | Estado |
|---|---|---|
| CU-01 Consultar catálogo | `GET /ProductoServlet` → 200, 11 productos (incluido `stock`) | **Confirmado** |
| CU-02 Registro del cliente (DNI) | Validaciones de servidor confirmadas (campos, email, longitud de contraseña); **validación de formato de DNI inexistente** (también en servidor) | **Confirmado (con defecto A-04/B-04 heredado)** |
| CU-03 Gestionar carrito | Límite de 10 aplicado **en el servidor** (11 → rechazo) y en el cliente (`carrito.length >= 10` en el JS servido) | **Confirmado** |
| CU-04 Confirmar pedido (totales/envío) | Vista previa inaccesible sin sesión; el servidor recalcula, pero no se pudo observar el total final | **Aún no verificado** |
| CU-05 Registrar pedido en BD | Requiere escritura | **Aún no verificado** |
| CU-06 Consultar pedidos | **Ejercido y fallando el control de autorización**: `GET /PedidoServlet` sin sesión devuelve los pedidos del cliente id=1 (R-01) | **Confirmado (con defecto Crítico)** |

> La afirmación de `docs/INFORME_VALIDACION.md` de que el flujo "se encuentra implementado y funcionando al 100% sin deuda técnica pendiente" **no se sostiene**: CU-06 responde con datos de otro cliente a un visitante anónimo, y CU-04/CU-05 permanecen sin verificación empírica alguna en toda la historia del proyecto (sus pruebas declaradas no son reproducibles).

---

## 4. Prioridad de Corrección Derivada de la Fase 2

| Prioridad | Acción | Hallazgo |
|---|---|---|
| 1 | Eliminar el fallback `id=1`; exigir sesión en `doGet`, `guardarDB` y `cancelarPedido` | R-01 / C-02 |
| 2 | Sacar credenciales a configuración externa (externa al repositorio) y rotarlas | C-01 |
| 3 | Devolver mensajes genéricos y registrar el detalle solo en el servidor; validar la estructura del carrito | R-02 / A-06 |
| 4 | Habilitar un logging persistente del contenedor (`catalina.out` / `FileHandler`) | R-04 |
| 5 | Token CSRF + `SameSite=Lax`; unificar la regla de envío; dejar de publicar `stock` sin sesión | R-07 / A-05 / R-03 |
| 6 | Provisionar un entorno con **BD de prueba** y un usuario de pruebas para poder cerrar CU-04, CU-05, L2, L6 y las escrituras | Bloqueante §0.1 |
