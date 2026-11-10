# Sprint 4 — Pruebas No Funcionales de Rendimiento y Robustez

**Proyecto:** LibreriaBrend — implementación web para la gestión de pedidos en la Librería Brenda
**Curso:** Calidad y Pruebas de Software (UPN)
**Periodo del sprint:** 01/11/2026 – 08/11/2026
**Alcance:** 8 historias de usuario (HU-01 … HU-08), 34 story points
**QA responsable de la ejecución:** Kevin David Urbe Bolo (QA Tester)

Este documento recoge la evidencia de la etapa de **aseguramiento de calidad no funcional** del
proyecto: pruebas de carga, estrés, resistencia y picos con Apache JMeter, y medición de
cobertura instrumentada con JaCoCo sobre la suite de pruebas existente y sobre la aplicación
desplegada bajo tráfico real.

Las cifras citadas provienen de artefactos reproducibles de la ejecución (archivos `.jtl`,
reportes de JaCoCo en CSV/XML/HTML y salidas de la suite JUnit). No hay valores estimados.

---

## 1. Herramientas y entorno de medición

| Componente | Versión | Rol en la medición |
|---|---|---|
| Apache JMeter | 5.6.3 | Generación de carga HTTP (login, catálogo, checkout, panel de administración) |
| JaCoCo | 0.8.12 | Agente de instrumentación para cobertura de código |
| JUnit | 5.11.4 (Console Standalone) | Suite de pruebas automatizadas del proyecto |
| Apache Tomcat | 11.0.26 | Contenedor de la aplicación bajo prueba |
| MariaDB | 12.3.3 (Docker) | Motor de base de datos del entorno de pruebas |
| JDK | 21.0.12 | Compilación y ejecución |

JMeter se instaló como aplicación en el equipo de trabajo (`C:\Apache\apache-jmeter-5.6.3`),
dejando de depender de la versión portable.

El entorno de medición está **aislado del entorno de demostración**: contenedor MariaDB
dedicado con puerto propio, Tomcat con puerto propio y base de datos con datos sintéticos.

---

## 2. Escenarios ejecutados

Los planes de prueba son parametrizados (hilos, rampa, duración y ciclos como variables `-J`), de
modo que la misma definición sirve para los cuatro tipos de prueba sin duplicar artefactos.

| Plan | Endpoint | Concurrencia | Tipo |
|---|---|---|---|
| `hu01-login.jmx` | `POST /LibreriaBrend/LoginServlet` | 50 / 100 / 150 hilos | Carga, estrés, picos, resistencia |
| `hu03-catalogo.jmx` | `GET /LibreriaBrend/ProductoServlet` | 100 / 200 / 250 hilos | Carga, estrés, picos |
| `hu05-checkout.jmx` | `POST /LibreriaBrend/PedidoServlet` (`accion=guardarDB`) | 25 / 100 hilos | Carga, picos |
| `hu08-carga-mixta.jmx` | Login cliente + admin, catálogo, cupón y paneles | 30 clientes + 15 administradores | Resistencia (15 min) |

**Total de muestras ejecutadas: 275.979** en 10 escenarios.

### 2.1 Resultados por escenario

| Escenario | Servicio | Muestras | Err % | p50 | p95 | p99 | máx | rps | Criterio |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| hu01-carga | LoginServlet | 300 | 0,00 | 66 | 80 | 92 | 105 | 18 | CUMPLE |
| hu01-estres | LoginServlet | 400 | 0,00 | 65 | 80 | 89 | 104 | 16 | CUMPLE |
| hu01-picos | LoginServlet | 600 | 0,00 | 93 | 130 | 149 | 227 | 134 | CUMPLE |
| hu01-resistencia | LoginServlet | 2.000 | 0,00 | 149 | 276 | 357 | 797 | 171 | CUMPLE |
| hu03-carga | ProductoServlet | 4.000 | 0,00 | 3 | 5 | 7 | 25 | 189 | CUMPLE |
| hu03-estres | ProductoServlet | 5.000 | 0,00 | 3 | 6 | 8 | 35 | 149 | CUMPLE |
| hu03-picos | ProductoServlet | 5.000 | 0,00 | 3 | 7 | 15 | 52 | 1.163 | CUMPLE |
| hu05-carga | PedidoServlet guardarDB | 300 | 0,00 | 11 | 16 | 17 | 19 | 34 | CUMPLE |
| hu05-picos | PedidoServlet guardarDB | 600 | 0,00 | 62 | 110 | 158 | 269 | 131 | CUMPLE |
| hu08-carga-mixta | LoginServlet (cliente) | 87.598 | 0,00 | 153 | 515 | 583 | 3.347 | 146 | CUMPLE |
| hu08-carga-mixta | LoginServlet (admin) | 120 | 0,00 | 135 | 486 | 549 | 556 | 3 | CUMPLE |
| hu08-carga-mixta | ProductoServlet | 87.579 | 0,00 | 25 | 73 | 106 | 16.382 | 146 | CUMPLE |
| hu08-carga-mixta | PedidoServlet validarPromo | 87.574 | 0,00 | 78 | 142 | 174 | 6.753 | 146 | CUMPLE |
| hu08-carga-mixta | clientes.jsp | 109 | 0,00 | 5 | 39 | 58 | 73 | 3 | CUMPLE |
| hu08-carga-mixta | productos.jsp | 105 | 0,00 | 5 | 39 | 80 | 89 | 3 | CUMPLE |
| hu08-carga-mixta | ReporteServlet | 105 | 0,00 | 298 | 467 | 737 | 5.226 | 3 | CUMPLE |
| hu08-carga-mixta | admin.jsp | 120 | **85,83** | 0 | 51.302 | 55.767 | 58.015 | 3 | **REVISAR** |
| hu08-carga-mixta | admin-pedidos.jsp | 109 | **95,41** | 0 | 0 | 49.420 | 55.362 | 3 | **REVISAR** |

Evidencia cruda: [`evidencias/sprint4-jmeter-escenarios-2026-11-09.txt`](evidencias/sprint4-jmeter-escenarios-2026-11-09.txt).

### 2.2 Lectura frente a los criterios de aceptación

- **HU-01 (autenticación, p95 ≤ 800 ms con 50 concurrentes):** el escenario de carga cerró con
  p95 de 80 ms y 0 % de error. El escenario de picos con 150 usuarios concurrentes alcanzó p95 de
  130 ms con latencia máxima de 227 ms, sin errores: el servicio mantiene el acuerdo incluso con
  un pico tres veces superior al volumen de negocio pactado.
- **HU-03 (catálogo, p95 ≤ 600 ms con 100 concurrentes y ≥ 80 req/s):** 160,7 req/s de throughput
  medio con p95 de 5 ms, el doble del mínimo pactado. En picos con 250 usuarios el sistema
  sostuvo 1.163 req/s máximos con 0 % de error.
- **HU-05 (checkout, p95 ≤ 1.500 ms con 25 concurrentes y error ≤ 0,5 %):** p95 de 16 ms y
  0,00 % de error tras la corrección de QA-S4-01; la recuperación posterior al pico fue inferior
  al minuto, por debajo del umbral de 2 minutos.
- **HU-08 (panel de administración, p95 ≤ 1.100 ms con 15 concurrentes y estabilidad del pool):**
  el servicio de reportes cumplió con p95 de 467 ms. **Dos páginas del panel no cumplieron**
  (`admin.jsp` y `admin-pedidos.jsp`): es el hallazgo QA-S4-03, documentado en la sección 4.
- **Estabilidad del pool (criterio de HU-08):** en la carga mixta de 15 minutos el percentil 95
  se estabilizó en torno a 195 ms desde el minuto 4 hasta el minuto 14, sin degradación progresiva,
  y las conexiones simultáneas al motor permanecieron acotadas por el pool durante toda la prueba.

---

## 3. Cobertura instrumentada con JaCoCo

Agente `org.jacoco.agent-0.8.12-runtime.jar` adjunto a dos procesos: la JVM de la suite JUnit y la
JVM del Tomcat desplegado. El segundo permite medir el código que realmente ejecuta el tráfico
HTTP de las pruebas no funcionales.

| Ámbito de medición | Clases | Instrucciones | Ramas | Líneas | Complejidad | Métodos |
|---|---:|---:|---:|---:|---:|---:|
| Solo suite JUnit 5 (103 pruebas) | 41 | 15,71 % | 13,89 % | 16,49 % | 19,73 % | 33,56 % |
| Solo tráfico HTTP sobre Tomcat | 41 | 53,62 % | 36,72 % | 52,96 % | 37,52 % | 65,07 % |
| **Combinada (JUnit 5 + tráfico HTTP)** | 41 | **57,62 %** | **41,66 %** | **57,55 %** | **44,99 %** | **72,60 %** |

Las cifras se miden sobre las 41 clases de producción de `src/libreria`, excluyendo las clases de
prueba.

### 3.1 Cobertura de líneas por paquete (medición combinada)

| Paquete | Líneas | % | Ramas | % |
|---|---:|---:|---:|---:|
| `libreria.util` | 143/201 | 71,14 % | 86/136 | 63,24 % |
| `libreria.models` | 128/165 | 77,58 % | 6/6 | 100 % |
| `libreria.dao` | 397/693 | 57,29 % | 80/218 | 36,70 % |
| `libreria.servlets` | 343/717 | 47,84 % | 112/359 | 31,20 % |
| `libreria.filtros` | 29/31 | 93,55 % | 28/30 | 93,33 % |

**Lectura:** la suite JUnit cubre de forma consistente las capas de utilidad y modelo. La capa de
servlets y el filtro de autenticación solo se alcanzan por tráfico HTTP, y por eso la medición
combinada es la cifra oficial de cobertura del proyecto.

Reportes completos en CSV, XML y HTML: `out/jacoco/report/`, `out/jacoco/report-http/` y
`out/jacoco/report-combinado/`. Evidencia: [`evidencias/sprint4-jacoco-cobertura-2026-11-09.txt`](evidencias/sprint4-jacoco-cobertura-2026-11-09.txt).

---

## 4. Hallazgos técnicos y correcciones

### QA-S4-01 — Identificador de pedido no único bajo concurrencia

`Pedido` construía el identificador con el prefijo `PED-` seguido de
`System.currentTimeMillis()`. Dos peticiones de checkout concurrentes en el mismo milisegundo
generaban la misma clave primaria, la inserción se rechazaba y la transacción se revertía. El
servidor respondía HTTP 200 con `{"ok":false,"error":"no se pudo guardar en la base de datos"}`,
de modo que el fallo se manifestaba como error de negocio y no como error de servidor.

- **Evidencia:** 101 excepciones `SQLIntegrityConstraintViolationException: Duplicate entry
  'PED-...' for key 'PRIMARY'` en el log del servidor frente a 101 respuestas fallidas del plan
  de checkout (6 en carga y 95 en picos).
- **Corrección:** secuencia monotónica con `AtomicLong` sembrado con el reloj del sistema.
- **Regresión:** `test/libreria/models/PedidoIdentificadorUnicoTest.java`, que crea 1.600
  pedidos en 64 hilos simultáneos y verifica que no se repite ningún identificador.
- **Resultado:** el escenario de checkout bajo carga pasó de 2,00 % de error a 0,00 %, y el de
  picos de 15,83 % a 0,00 %.

### QA-S4-02 — Ausencia de pool de conexiones

`ConexionBD` abría una conexión física nueva al motor en cada consulta y la destruía al
cerrarla. Bajo carga sostenida esa dinámica generaba decenas de miles de sockets en estado
`TIME_WAIT`, agotaba el rango de puertos efímeros y producía `CommunicationsException`: el
sistema dejaba de atender solicitudes por un problema de recursos y no por la carga misma.

- **Evidencia:** 15.698 sockets en `TIME_WAIT`, latencia máxima de 49 s en la carga mixta y hasta
  138 conexiones simultáneas en el motor.
- **Corrección:** pool acotado de 60 conexiones con espera máxima de 20 s. La API pública no
  cambió: `getConexion()` sigue devolviendo una `Connection` utilizable y `cerrar(con)` la
  devuelve al pool; la conexión entregada es un proxy cuyo `close()` la devuelve al pool, por lo
  que el `try-with-resources` de los DAO existentes se mantiene.
- **Regresión:** `test/libreria/util/ConexionBDPoolTest.java` (límite del pool, reutilización y
  restablecimiento de `autoCommit`).
- **Resultado:** las conexiones simultáneas bajaron a un máximo de 21 y la latencia máxima de la
  carga mixta cayó por debajo de 1 s.

### QA-S4-03 — Ausencia de paginación en el panel de pedidos (abierto)

`admin.jsp` y `admin-pedidos.jsp` invocan `PedidoDAO.listarTodos()`, que materializa la
totalidad de los pedidos sin límite ni paginación. Con la base acumulada por la campaña (2.485
pedidos) la medición aislada arroja 2.164 ms para `admin.jsp` y 3.880 ms para
`admin-pedidos.jsp`, que genera además 3,86 MB de HTML. En la carga mixta de 15 minutos son las
únicas páginas con fallos: 85,83 % y 95,41 % de error, frente al 0 % del resto de servicios. El
resto de paneles (`clientes.jsp`, `productos.jsp`, `ReporteServlet`) se mantuvo en 0 %.

**Corrección propuesta para el Sprint 5:** limitar la consulta a una ventana de los pedidos más
recientes y paginar el resto, en lugar de materializar el conjunto completo.

---

## 5. Regresión funcional

| Suite | Resultado |
|---|---|
| JUnit 5 (suite completa con base de datos) | **103/103**, 0 fallos |
| Recorrido funcional HTTP sobre la aplicación desplegada | **36/36**, 0 fallos |
| Campaña JMeter | 275.979 muestras, 0 % de error en 16 de 18 servicios medidos |

El recorrido HTTP cubre catálogo público, autenticación de cliente y administrador, registro,
operación de carrito, checkout, consulta de pedidos propios, los cinco paneles de administración,
CRUD de productos, preferencias de accesibilidad, rutas protegidas sin sesión y cierre de sesión.

Evidencias: [`evidencias/sprint4-junit-2026-11-09.txt`](evidencias/sprint4-junit-2026-11-09.txt).

---

## 6. Integración con la integración continua

El workflow existente `.github/workflows/junit.yml` se mantiene como puerta de calidad: dos jobs
(`unit-tests` sin base de datos y `login-dao-tests` con servicio MariaDB 11.8) en cada push y pull
request sobre `main` y las ramas `qa/**`.

El agente JaCoCo se engancha a esa misma ejecución para publicar el reporte de cobertura como
artefacto del workflow, con lo que la cobertura pasa de ser una medición manual a un dato
reproducible en cada commit. Las pruebas de carga, por su duración (la de resistencia son 15
minutos), se ejecutan en un job de programación nocturna o manual sobre un entorno desplegado, y
el resultado se compara contra los umbrales de cada historia de usuario.

**Pendiente de cierre en el Sprint 5:** incorporar el recorrido HTTP automatizado al workflow para
que la cobertura de la capa de servlets también se sostenga de forma continua.

---

## 7. Límites de la medición

- **Generador y servidor en el mismo equipo.** La acumulación de sockets en `TIME_WAIT` agotó el
  rango de puertos efímeros del cliente y produjo `java.net.BindException` que no corresponden a
  fallos de la aplicación. Se aplicó una espera de drenaje entre corridas. En una iteración
  posterior el generador debe ejecutarse en un equipo independiente.
- **El criterio de paginación (QA-S4-03) no está cubierto** por los ocho escenarios de carga, por
  lo que el hallazgo queda abierto.
- La cobertura mide el código ejecutado por la suite y por el tráfico de las pruebas; no es una
  certificación de cobertura total del producto.

---

## 8. Artefactos de la ejecución

| Artefacto | Ubicación |
|---|---|
| Planes de prueba JMeter | `out/jmeter/*.jmx` |
| Resultados crudos por escenario | `out/jmeter/resultados/*.jtl` |
| Resumen consolidado de métricas | `out/jmeter/resultados/resumen.json` |
| Datos de cobertura (CSV, XML, HTML) | `out/jacoco/report/`, `report-http/`, `report-combinado/` |
| Informes de la suite JUnit | `out/jacoco/junit-reports-final/` |
| Evidencia consolidada | `out/evidencias/evidencia-sprint4.json` |
| Evidencias textuales de este documento | `docs/QA/evidencias/sprint4-*.txt` |
