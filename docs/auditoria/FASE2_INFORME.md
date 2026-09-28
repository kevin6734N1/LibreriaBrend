# AUDITORÍA FASE 2 — Verificación en Runtime

**Commit auditado:** `291741c3181010fe9a171e900954bdf22fe7a7cb` (short `291741c`) — `main`
**Contexto desplegado:** `/LibreriaBrend` (exploded, `webapps/LibreriaBrend`) sobre `/home/kevin/apache-tomcat-11.0.0-M24`
**Rama de trabajo:** `audit/fase-2-runtime`
**Fecha de ejecución:** 2026-09-28 (01:26 – 01:30 -05:00)
**Base de datos de la aplicación:** `libreria_brenda` — **base de datos de producción**

---

## 0. Verificación de Entorno

| Ítem | Estado | Evidencia |
|---|---|---|
| Despliegue (`webapps/`) | **OK** — carpeta `LibreriaBrend` exploded (12 JSP, `WEB-INF/classes`, `WEB-INF/lib`) | `evidencias/logs/A01_entorno.txt` §A.01.4 |
| Puerto 8080 | **A la escucha** — `java` pid=107662 | `evidencias/logs/A01_entorno.txt` §A.01.2 |
| Respuesta del servidor | **OK** — `HEAD /LibreriaBrend/` → `HTTP/1.1 200`, `Content-Type: text/html;charset=UTF-8` | `evidencias/logs/A01_entorno.txt` §A.01.6 |
| Sesión HTTP real + cookie | **OK** — `JSESSIONID` capturado, reutilizado y válido (`Path=/LibreriaBrend; HttpOnly`) | `evidencias/responses/B02_accesibilidad_dom.txt` §B.02.1–B.02.2 |
| Logs de arranque (`catalina.out` / `localhost.<fecha>.log`) | **NO EXISTEN** — no hay log persistente de errores; stdout/stderr del contenedor van a un `socket` | `evidencias/logs/A01_entorno.txt` §A.01.9 · `evidencias/logs/C01_logs_tomcat.txt` §C.03 |
| Base de datos de prueba | **NO EXISTE** — única BD en el servidor: `libreria_brenda` | `evidencias/logs/A01_entorno.txt` §A.01.8 |
| **BD apuntada por la aplicación** | 🔴 **BLOQUEANTE — APUNTA A PRODUCCIÓN** | ver abajo |

### 0.1 CONTROL CRÍTICO: la aplicación apunta a la base de datos real

La clase compilada y desplegada contiene la URL de conexión y las credenciales **embebidas en el bytecode**:

```text
$ grep -a -o -E 'jdbc:mysql://[^" ]*' \
    $TC/webapps/LibreriaBrend/WEB-INF/classes/libreria/util/ConexionBD.class
jdbc:mysql://localhost:3306/libreria_brenda?useSSL=false&serverTimezone=America/Lima&allowPublicKeyRetrieval=true
[usuario]     root
[contraseña]  <REDACTADO — valor omitido por política de higiene del repositorio>
```

- **No existe configuración externa**: `find webapps/LibreriaBrend -name "context.xml" -o -name "*.properties"` → vacío.
- **No hay `DataSource` JNDI** con la BD de la aplicación en `conf/context.xml` ni `conf/server.xml`.
- **No existe base de datos de prueba** en el servidor MariaDB (`information_schema.SCHEMATA` solo devuelve `libreria_brenda`).

**Decisión aplicada (mandato del encargo):** *"¿La aplicación está apuntando a la base de datos de prueba o a la real? Si apunta a la real, detén la auditoría y repórtalo como un impedimento bloqueante."*
→ **Se detuvo toda prueba ofensiva con capacidad de escritura antes de ejecutarla.**

**Por qué no se redirigió la aplicación a una BD de prueba:** los permisos concedidos para esta fase son `curl`, `mysql/mariadb-cli`, `git` y lectura de logs, con creación de ficheros limitada a `docs/auditoria/`. Repuntar la aplicación exigiría **recompilar `ConexionBD.java` y redeployar el artefacto** (fuera de los permisos concedidos) o editar `context.xml` (no existe, y crearlo sería modificar el entorno de ejecución). Crear `libreria_brenda_test` habría sido posible con el cliente SQL, pero **inútil**: ningún flujo HTTP habría cambiado de destino. Además, poblarla con datos reales habría supuesto copiar datos personales de clientes a una BD nueva, operación no autorizada. **La decisión técnicamente correcta fue no crear la BD de prueba y detenerse.**

**Consecuencia:** se ejecutaron **156 peticiones HTTP reales** (110 `GET`, 6 `HEAD`, 41 `POST` según el access log; **98 dirigidas a JSP/servlets**), todas de **solo lectura** o descartadas por validación **antes** de abrir transacción. Resultados agregados observados: 23 respuestas `302`, 4 `401`, 4 `404`. La BD de producción quedó verificada como intacta (hash de estado idéntico antes/después — ver `FASE2_ANEXO_LIMPIEZA.md`).

---

## 1. Cierre de Limitaciones Fase 1

| Limitación F1 | Estado Actual | Evidencia |
|---|---|---|
| **Sin prueba HTTP e2e** | **Aún no verificado** (parcialmente habilitado) | Se ejecutó HTTP real (156 peticiones) y se cerraron los vectores anónimos (R-01, R-02). El flujo autenticado de compra NO se pudo ejercer: no hay BD de prueba utilizable (bloqueante §0.1) y no se dispone de credenciales de cliente válidas; obtenerlas exigiría adivinar contraseñas de cuentas reales. Ver §4. |
| **Sin lector de pantalla** | **Aún no verificado** | No existe NVDA/JAWS/VoiceOver ni navegador en el entorno (Chrome no instalado). Todo lo relativo a foco, orden de tabulación, contraste percibido y sintetizado de voz permanece sin validar. **No se afirma conformidad WCAG de ningún nivel.** |
| **Filtro Daltonize `html` vs `body`** | **Confirmado** | El JS **servido por Tomcat** aplica la clase a la raíz del documento: `documentElement` (línea 124) + 3 selectores `html.accesibilidad-*` + **0** selectores `body.accesibilidad-*`. `evidencias/responses/B02_accesibilidad_dom.txt` §B.02.5. *El efecto visual (que el botón ♿ permanezca fijo) sigue **Aún no verificado**: requiere navegador.* |
| **Repo remoto no verificado** | **Confirmado (cerrado)** | `git ls-remote origin` → `refs/heads/main = 291741c3181010fe9a171e900954bdf22fe7a7cb`, idéntico al HEAD local. El remoto **sí** contiene exactamente el commit auditado. `evidencias/logs/A01_entorno.txt` §A.01.11. |
| **Concurrencia no probada** | **Aún no verificado** | L6 (dos sesiones consumiendo el mismo código promocional / excediendo stock) exige escrituras contra `libreria_brenda`. Bloqueado por §0.1. La PK compuesta `(codigo, cliente_id)` y la atomicidad del `UPDATE ... WHERE cliente_id=? AND estado='PENDIENTE'` quedan verificadas **solo por análisis estático** (Fase 1). |
| **Escrituras no ejecutadas** | **Confirmado (sigue así, por mandato)** | No se ejecutó ninguna escritura en ninguna BD. Se descartó incluso el payload terminado en escritura: todos los POST a `guardarDB` retornan antes de `PedidoDAO.crear()`. Verificación de integridad en `FASE2_ANEXO_LIMPIEZA.md`. |

---

## 2. Nuevos Hallazgos (Runtime)

### [R-01] IDOR de lectura sobre la identidad "Cliente Demo": confirmado por HTTP — Severidad: **Crítico** — Área: Autorización

- **Petición HTTP (Request):**
  ```http
  GET /LibreriaBrend/PedidoServlet HTTP/1.1
  Host: localhost:8080
  (sin cookies, sin sesión)
  ```
- **Respuesta (Response):**
  ```http
  HTTP/1.1 200
  Content-Type: application/json;charset=UTF-8

  [{"id":"PED-1788638730511","fecha":"05/09/2026","hora":"03:05 PM","estado":"Confirmado",
    "direccion":"jiron manco inca 6767","pago":"Yape","subtotal":120.0,"descuento":18.0,
    "envio":0.0,"total":102.0,"items":[{"nombre":"Pizarra Acrilica 60x80cm con Marco Aluminio",
    "img":"images/productos/pizarra-acrilica.png","qty":1,"precio":120.0}]}, ... 8 objetos ...]
  ```
  → **8 pedidos completos** con dirección de entrega, método de pago, montos y líneas de detalle.
  La misma petición **con cookie de sesión anónima** devuelve los **mismos 8 pedidos**: el servlet no distingue "sin sesión" de "cliente autenticado", ambos colapsan al cliente `id=1`.
  Evidencia: `evidencias/responses/B03_seguridad_lectura.txt` §B.03.1–B.03.2.
- **Contraste que aísla la causa:** `GET /PreferenciaAccesibilidadServlet` sin sesión responde `{"autenticado":false,...}` (73 bytes) — el mismo proyecto **sí** sabe rechazar al anónimo cuando quiere. El fallback es una decisión de diseño de `PedidoServlet`, no una limitación del marco.
- **Impacto:** divulgación de datos personales (domicilios y medios de pago) de un cliente real a cualquier visitante anónimo, sin credenciales y sin traza de autorización. Elevado a Crítico en Fase 1 (C-02), **ahora confirmado con respuesta HTTP cruda**, no por deducción.
- **Recomendación de Mitigación:** eliminar `CLIENTE_DEMO_ID`; en `doGet`, responder `401` JSON si no hay sesión de cliente; exigir sesión en `accion=guardarDB` y `accion=cancelarPedido`. Documentar la regla de negocio resultante (el carrito anónimo no podrá confirmar pedidos) y resolver el carrito anónimo con un identificador de carrito firmado, no con una identidad de cliente compartida.

### [R-02] Fuga de mensajes internos de la JVM en respuestas HTTP — Severidad: **Alto** — Área: Manejo de errores

- **Petición HTTP (Request):**
  ```http
  POST /LibreriaBrend/PedidoServlet HTTP/1.1
  Content-Type: application/x-www-form-urlencoded

  accion=guardarDB&item_id=1&item_id=9001&item_qty=1&pago=Yape
  ```
- **Respuesta (Response):**
  ```json
  {"ok":false,"error":"Index 1 out of bounds for length 1"}
  ```
  Y con `item_id=1&pago=Yape` (sin `item_qty`):
  ```json
  {"ok":false,"error":"Cannot load from object array because \"qtys\" is null"}
  ```
  Evidencia: `evidencias/responses/B03_seguridad_lectura.txt` §B.03.7 (e) y (f).
- **Impacto:** el servidor devuelve al cliente el `getMessage()` de la excepción de la JVM, revelando el **nombre de la variable interna** (`qtys`), la estructura del array de parámetros y, con ello, el contrato interno del endpoint. Facilita la construcción de payloads dirigidos. Ninguna otra respuesta presentó stack traces ni rutas del servidor (`evidencias/responses/B04_errores_validacion.txt` §B.04.8), lo que confirma que el problema es el mensaje de excepción reflejado, no el contenedor.
- **Recomendación de Mitigación:** sustituir el `catch (Exception e) { out.print(e.getMessage()) }` por un mensaje genérico al cliente (`"No se pudo procesar el pedido."`) y registrar el detalle **solo** en el log del servidor; validar la estructura del carrito (longitudes de `item_id`/`item_qty`, tipos, cantidades) antes de iterar.

### [R-03] Nivel de inventario publicado sin autenticación — Severidad: **Bajo** — Área: Exposición de datos

- **Petición/Respuesta:**
  ```http
  GET /LibreriaBrend/ProductoServlet HTTP/1.1   →  HTTP 200 (2544 bytes)
  {"id":1,...,"stock":15,...}  → 11 productos, todos con el stock exacto
  ```
  Evidencia: `evidencias/responses/B04_errores_validacion.txt` §B.04.7.
- **Impacto:** cualquier visitante puede enumerar el stock real (p. ej. `Resma Papel Bond A4` con 4 unidades) y detectar qué artículos están por agotarse o agotarse deliberadamente. No es dato personal, pero es inteligencia comercial y habilita abuso de inventario.
- **Recomendación de Mitigación:** publicar solo un indicador derivado (`disponible` / `agotado`) o el stock únicamente cuando provenga de una sesión autenticada.

### [R-04] Ausencia de log persistente de errores en el contenedor — Severidad: **Medio** — Área: Operación / Observabilidad

- **Evidencia:**
  ```text
  $ ls logs/catalina.out                    → NO EXISTE
  $ ls logs/localhost.<fecha>.log           → NO EXISTE
  $ ls -l /proc/107662/fd/1 /proc/107662/fd/2
    -> socket:[854758]   -> socket:[854760]
  ```
  El contenedor se lanzó con `org.apache.catalina.startup.Bootstrap start` desde una terminal, y **toda** su salida (stdout/stderr) va a un socket, no a un fichero. Evidencia: `evidencias/logs/C01_logs_tomcat.txt` §C.03.
- **Impacto:** (a) la verificación L1 exigida por el encargo (*"arranque sin excepciones inspeccionando `logs/catalina.out` y `logs/localhost.<fecha>.log`"*) **es imposible de ejecutar** y no puede reconstruirse retrospectivamente; (b) las excepciones que el servlet captura con `e.printStackTrace()` **se pierden al cerrar la terminal que lanzó Tomcat**: no hay evidencia forense de errores en producción ni capacidad de diagnóstico post-incidente. El único rastro persistente es el *access log*, que no registra el cuerpo de la respuesta ni el error.
- **Recomendación de Mitigación:** arrancar Tomcat con `bin/catalina.sh run` redirigiendo a `logs/catalina.out`, o configurar `logging.properties` con un `FileHandler` para `catalina`/`localhost`; añadir una política de rotación.

### [R-05] Autenticación no ejercitable sin credenciales (bloqueo estructural del alcance autenticado) — Severidad: **Informativo** — Área: Metodología

Todo el panel administrativo y las acciones de cliente autenticado (`guardarDB`, `cancelarPedido`, `validarPromo`, `PreferenciaAccesibilidadServlet` POST, `ClienteServlet`, `ReporteServlet`) no pudieron probarse con una sesión legítima: no se dispone de credenciales y **no existe BD de prueba** que permita crearlas (§0.1). Un intento de `rol=admin` sin código de empleado fue correctamente rechazado (`evidencias/responses/B04_errores_validacion.txt` §B.04.6), lo que confirma que no hay camino de autenticación trivial — y por tanto que **el único camino realista para completar L2/L6 es habilitar un entorno con BD de prueba y un usuario de pruebas**.

### [R-06] La página de error 404 sirve el catálogo con estado 404 — Severidad: **Bajo** — Área: Configuración

- **Evidencia:**
  ```http
  GET /LibreriaBrend/noexiste.jsp  →  HTTP/1.1 404, Content-Type: text/html;charset=UTF-8, 10181 bytes
  ```
  El cuerpo corresponde a `index.jsp` (mapeo `<error-page><error-code>404</error-code><location>/index.jsp</location>` de `web.xml`). **No hay stack trace ni ruta interna** (`evidencias/responses/B04_errores_validacion.txt` §B.04.1).
- **Impacto:** sin impacto de seguridad; sí de operación y SEO: un 404 devuelve el catálogo (el usuario no entiende que la ruta no existe) y los rastreadores ven contenido duplicado bajo URLs inexistentes. Además el `ErrorReportValve` de Tomcat queda enmascarado, lo que contribuye a R-04 (errores sin traza útil).
- **Recomendación de Mitigación:** una página `404.jsp` propia con el código de estado correcto y sin contenido de catálogo.

### [R-07] Sin defensa CSRF verificable (sin token y cookie sin `SameSite`) — Severidad: **Alto** — Área: Seguridad

- **Evidencia:**
  ```http
  Set-Cookie: JSESSIONID=<REDACTADO>; Path=/LibreriaBrend; HttpOnly      ← sin atributo SameSite
  $ grep -ci csrf sobre el DOM de carrito.jsp  → 0
  $ grep -ci csrf sobre el DOM de pedidos.jsp  → 0
  ```
  Evidencia: `evidencias/responses/B03_seguridad_lectura.txt` §B.03.8.
- **Impacto:** ninguna de las 6 operaciones de escritura lleva token anti-CSRF y no hay `SameSite` explícito ni `cookie-config` en `web.xml`. En Fase 1 (A-01) se dedujo del código; aquí queda **confirmado en el artefacto en ejecución**.
- **Alcance de la confirmación (honesto):** se confirma la **ausencia de defensa**, no la **explotabilidad efectiva**: el POST cross-site con `JSESSIONID` depende del comportamiento del navegador (con cookies sin `SameSite`, los navegadores actuales aplican `Lax` por defecto y **no** enviarían la cookie en un POST de terceros). No se reprodujo la explotación porque exigiría una escritura contra producción (§0.1). Para los endpoints de `PedidoServlet` que **no** requieren sesión (ver R-01), la cookie es irrelevante y el vector no depende del navegador.
- **Recomendación de Mitigación:** token *synchronizer* por sesión validado en un filtro para todo POST de escritura, `SameSite=Lax` explícito vía `<cookie-config>`, y verificaciones de `Origin`/`Referer`.

### [R-08] El límite de "10 productos distintos" cuenta entradas de array, no productos distintos — Severidad: **Bajo** — Área: Lógica de negocio

- **Petición/Respuesta:**
  ```http
  POST PedidoServlet  accion=guardarDB&item_id=9001..9011&item_qty=1&pago=Yape
  → {"ok":false,"error":"El carrito supera el maximo de 10 productos distintos permitido."}

  POST PedidoServlet  accion=guardarDB&item_id=9001..9010&item_qty=1&pago=Yape
  → {"ok":false,"error":"Uno de los productos ya no existe. Actualiza tu carrito."}
  ```
  Evidencia: `evidencias/responses/B03_seguridad_lectura.txt` §B.03.6.
- **Interpretación:** el fix de CU-03 **sí se aplica en el servidor** (11 entradas → rechazo; 10 → el límite no se activa). Pero el control usa `ids.length > 10`, es decir **entradas del array**, no productos distintos: 11 entradas con ids repetidos se rechazan aunque representen menos de 10 productos reales. Es un criterio **más restrictivo** que la especificación, no un bypass de seguridad.
- **Recomendación de Mitigación:** deduplicar por `producto_id` en el servidor (y sumar cantidades), validando además que las longitudes de `item_id` e `item_qty` coincidan.

### [R-09] Desajuste de trazabilidad: HEAD ≠ commit declarado en el registro — Severidad: **Bajo** — Área: Trazabilidad

```text
$ git rev-parse HEAD                       → 291741c3181010fe9a171e900954bdf22fe7a7cb
$ git status --porcelain                   → (vacío, árbol limpio)
$ git branch --show-current                → main
$ git ls-remote origin refs/heads/main     → 291741c3181010fe9a171e900954bdf22fe7a7cb
```
`docs/REGISTRO_CAMBIOS.md` declara como "estado actual del proyecto" el commit `54a810c`, que es **cuatro commits anterior** a HEAD (`1936029`, `44c344f`, `c09cfa5`, `291741c`, todos de build/docs). Se confirma en runtime el hallazgo B-01 de la Fase 1. **Recomendación:** actualizar la tabla del registro al cerrar cada conjunto de cambios, conforme a su propia convención.

---

## 3. Controles Exitosos (Conformidad Verificada)

| # | Control | Resultado | Evidencia |
|---|---|---|---|
| 1 | **Integridad despliegue ↔ repositorio** | **10/10** ficheros (JSP, CSS, JS, `web.xml`) y **4/4** clases (`.class`) con **hash idéntico** al árbol auditado → el runtime atacado **es** el commit `291741c` | `B02_accesibilidad_dom.txt` §B.02.6 |
| 2 | **Control de acceso administrativo (`AuthFilter`)** | JSP protegidos → `302 → /login.jsp?error=sesion` (`productos`, `admin`, `clientes`, `reportes`); servlets → `401` JSON (`ReporteServlet`, `ClienteServlet`, POST `ProductoServlet`, POST `PedidoServlet accion=cambiarEstado`) | `B03_seguridad_lectura.txt` §B.03.5 · `B02…` §B.02.4 |
| 3 | **Inyección SQL en el login** | **5/5 payloads rechazados**; la respuesta es idéntica al control con credenciales incorrectas (no hay bypass de autenticación ni diferencial observable) | `B03_seguridad_lectura.txt` §B.03.3 |
| 4 | **Límite CU-03 en el servidor** | 11 ítems → rechazo por límite; 10 ítems → el límite no se activa (no dependía del JS) | `B03…` §B.03.6 |
| 5 | **Validación de entrada del carrito** | Carrito vacío, id no numérico, cantidad ≤ 0, producto inexistente y código promocional sin sesión → mensajes controlados, sin escritura | `B03…` §B.03.7 (a)(b)(c)(d)(g)(h) |
| 6 | **Validación de entrada del registro** | Campos vacíos, email malformado y contraseña < 8 → rechazados **en el servidor** (no solo en el JS) | `B04_errores_validacion.txt` §B.04.5 |
| 7 | **Validación del login** | Rol inexistente, campos faltantes y `rol=admin` sin código de empleado → rechazados | `B04…` §B.04.6 |
| 8 | **Recalculación de precios en el servidor** | `item_precio=0.01` enviado por el cliente es **ignorado** (no se alcanza a comprobar el total final porque el payload se descarta antes, pero el servlet no lee `item_precio` — verificado además estáticamente) | `B03…` §B.03.7 (g) |
| 9 | **Ausencia de stack traces y rutas del servidor** | Ninguna de las respuestas capturadas expone `catalina.base`, `/home/kevin`, ni trazas `at java…` | `B04…` §B.04.8 |
| 10 | **Filtro Daltonize corregido en runtime** | El JS **servido** usa `documentElement` y 3 selectores `html.accesibilidad-*`; **0** referencias a `body.accesibilidad-*` | `B02…` §B.02.5 |
| 11 | **Cookie de sesión con `HttpOnly`** | `Set-Cookie: JSESSIONID=…; Path=/LibreriaBrend; HttpOnly` | `A01_entorno.txt` §A.01.6 |
| 12 | **Marcado ARIA en el DOM servido** | `index` 16 `aria-*`/8 `role=`, `carrito` 22/9, `pedidos` 20/2, `login` 5/4, `registro` 0/2; `<main id="contenido-principal">` + skip-link en las 5 vistas de cliente | `B02…` §B.02.3 |
| 13 | **Base de datos de producción intacta** | Estado (conteos + huella de contenido) **idéntico** antes y después: 16 pedidos, 31 ítems, 16 clientes, 0 usos de promoción, 0 preferencias | `db/00_baseline_antes.txt` vs `db/01_baseline_despues.txt` (diff = 0 líneas) |
| 14 | **Remoto verificado** | `refs/heads/main` remoto = HEAD local (`291741c`) | `A01_entorno.txt` §A.01.11 |
| 15 | **Limitador de intentos de login** | 5 fallos consecutivos → bloqueo por email con mensaje explícito (intentos 6 y 7 rechazados); el control **existe y funciona** | `B05_controles_servidos.txt` §B.05.1 |
| 16 | **El anónimo NO obtiene perfil de accesibilidad** | `GET /PreferenciaAccesibilidadServlet` sin sesión → `{"autenticado":false,…}` (73 bytes), frente a los **3492 bytes** de datos de cliente que devuelve `GET /PedidoServlet` en la misma situación | `B05_controles_servidos.txt` §B.05.2 |

---

## 4. Limitaciones Remanentes

1. **Flujo de compra end-to-end (L2) — Aún no verificado.** *Justificación técnica estricta:* ejercerlo requiere llegar a `PedidoDAO.crear()`, y eso **es una escritura**. La aplicación apunta a `libreria_brenda` (§0.1) y los permisos concedidos no permiten repuntarla (compilar/redeployar o crear `context.xml`), ni existe BD de prueba. No se ejecutó ningún payload que alcanzara `crear()`, y se diseñaron explícitamente para descartarse antes. Concretamente **no se pudo verificar en runtime**: la persistencia de `pedidos`/`pedido_items`, el descuento de stock, el registro del uso de un código promocional, el cálculo final `subtotal − descuento + envio`, ni el comportamiento de `StockInsuficienteException` con rollback. Todo eso sigue apoyado **solo** en el análisis estático y en las evidencias declaradas por el propio proyecto (no reproducibles: los scripts de prueba no están versionados).
2. **Payloads destructivos NO enviados — Aún no verificado (decisión deliberada).** El encargo menciona `; DROP…` como payload de prueba. **No se envió ningún payload destructivo** contra `libreria_brenda`. *Justificación:* el daño de un falso negativo invertido es asimétrico e irreversible — si la hipótesis de concatenación fuera cierta, el efecto sería la destrucción de datos de producción reales. La cobertura se compensa con (a) 5 payloads de inyección **no destructivos** por HTTP (§B.03.3, todos refutados) y (b) la verificación estática de Fase 1: 54 coincidencias de `PreparedStatement` y **0** `Statement` con concatenación en todos los DAO y servlets. La recomendación es repetir esta batería contra una BD de prueba, donde `DROP` es inocuo.
3. **CSRF: explotación efectiva — Aún no verificado** (solo se confirma la ausencia de defensa). Reproducir la explotación requiere una operación de escritura y un navegador real; ninguno de los dos está disponible de forma segura.
4. **Concurrencia transaccional (L6) — Aún no verificado.** No se ejecutó: exige escrituras concurrentes contra producción. No se generaron dos sesiones autenticadas independientes porque no hay credenciales ni BD de prueba.
5. **Autorización/IDOR de escritura — Aún no verificado** (se confirmó el **IDOR de lectura**, R-01). Cancelar un pedido ajeno o crear un pedido a nombre del Cliente Demo exige POST con efecto de escritura.
6. **Accesibilidad — Aún no verificado más allá del marcado.** Sin navegador ni lector de pantalla: foco, *focus trap* del modal, orden de tabulación, contraste percibido, síntesis de voz (`es-PE`) y el efecto visual del filtro Daltonize sobre elementos `position: fixed` **permanecen sin validar**. **Este informe no afirma conformidad WCAG en ningún nivel.**
7. **L1 (arranque sin excepciones) — No verificable retrospectivamente.** No existen `catalina.out` ni `localhost.<fecha>.log` (R-04), y el proceso lleva en ejecución desde antes del inicio de la auditoría; no se reinició el contenedor porque su ciclo de vida está fuera de los permisos concedidos.

---

## 5. Anexo Documental

| Artefacto | Ruta |
|---|---|
| Verificación de entorno y bloqueante | [`evidencias/logs/A01_entorno.txt`](evidencias/logs/A01_entorno.txt) |
| Script de entorno (reproducible) | [`evidencias/requests/A01_entorno.sh`](evidencias/requests/A01_entorno.sh) |
| Logs de Tomcat y análisis de SEVERE/ERROR/WARN | [`evidencias/logs/C01_logs_tomcat.txt`](evidencias/logs/C01_logs_tomcat.txt) |
| Peticiones de accesibilidad y DOM servido (B.02) | [`evidencias/requests/B02_accesibilidad_dom.sh`](evidencias/requests/B02_accesibilidad_dom.sh) · [`evidencias/responses/B02_accesibilidad_dom.txt`](evidencias/responses/B02_accesibilidad_dom.txt) |
| Peticiones de seguridad (B.03) | [`evidencias/requests/B03_seguridad_lectura.sh`](evidencias/requests/B03_seguridad_lectura.sh) · [`evidencias/responses/B03_seguridad_lectura.txt`](evidencias/responses/B03_seguridad_lectura.txt) |
| Peticiones de errores y validación (B.04) | [`evidencias/requests/B04_errores_validacion.sh`](evidencias/requests/B04_errores_validacion.sh) · [`evidencias/responses/B04_errores_validacion.txt`](evidencias/responses/B04_errores_validacion.txt) |
| Limitador de intentos y controles en artefactos servidos (B.05) | [`evidencias/requests/B05_controles_servidos.sh`](evidencias/requests/B05_controles_servidos.sh) · [`evidencias/responses/B05_controles_servidos.txt`](evidencias/responses/B05_controles_servidos.txt) |
| Estado de BD: consultas | [`evidencias/db/estado_bd.sql`](evidencias/db/estado_bd.sql) |
| Estado de BD: antes / después | [`evidencias/db/00_baseline_antes.txt`](evidencias/db/00_baseline_antes.txt) · [`evidencias/db/01_baseline_despues.txt`](evidencias/db/01_baseline_despues.txt) |
| Cierre de limitaciones Fase 1 | [`FASE2_CIERRE_LIMITACIONES.md`](FASE2_CIERRE_LIMITACIONES.md) |
| Registro de operaciones y limpieza | [`FASE2_ANEXO_LIMPIEZA.md`](FASE2_ANEXO_LIMPIEZA.md) |

> **Nota de higiene:** los `JSESSIONID` capturados en las respuestas y el valor literal de la contraseña detectada en el bytecode están **redactados** en toda la evidencia versionada, conforme a la política de "no commitear credenciales en texto plano". Los comandos para reproducir ambos hallazgos se documentan en su lugar, de modo que el hallazgo es verificable sin exponer el secreto.
