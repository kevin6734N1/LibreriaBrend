# Documentación QA — LibreriaBrend

Esta carpeta reúne la documentación y las evidencias de aseguramiento de calidad del proyecto. No duplica los informes académicos que viven en `docs/`; actúa como punto de entrada para revisar qué se probó, con qué evidencia y qué límites siguen abiertos.

## Mapa de documentos

| Documento | Contenido |
|---|---|
| [SPRINT4_PRUEBAS_NO_FUNCIONALES.md](SPRINT4_PRUEBAS_NO_FUNCIONALES.md) | Pruebas de carga, estrés, resistencia y picos con JMeter, cobertura instrumentada con JaCoCo, hallazgos QA-S4-01 a QA-S4-03 y límites de la medición. |
| [RF02_LOGIN.md](RF02_LOGIN.md) | Matriz de login de cliente/administrador, TDD, resultados JUnit y HTTP, y riesgos abiertos. |
| [RF03_BLOQUEO_LOGIN.md](RF03_BLOQUEO_LOGIN.md) | Bloqueo temporal por intentos fallidos: matriz de cobertura, brecha G1 con TDD real, fronteras con reloj inyectado, corrección de revisión (precondiciones fatales) y suite HTTP de 29 comprobaciones. |
| [SEGURIDAD_REPOSITORIO.md](SEGURIDAD_REPOSITORIO.md) | Saneamiento del backup, datos sintéticos, restauración del entorno local y riesgo residual del historial público. |
| [evidencias/](evidencias/) | Salidas crudas de JUnit, suites HTTP, CI, TDD, JMeter, JaCoCo y capturas de la demo. |
| [../../README.md](../../README.md) | Puesta en marcha, demo local, stack, CI y limitaciones del proyecto. |
| [../../.github/workflows/junit.yml](../../.github/workflows/junit.yml) | Workflow de integración continua con jobs unitario y DAO + MariaDB. |

## Competencias demostradas

| Competencia | Dónde se evidencia |
|---|---|
| Diseño de casos de prueba y valores límite | Matriz de RF02, correos inválidos, 121 caracteres, precios/stock negativos y payloads malformados. |
| JUnit 5 | 103 pruebas: 80 sin base de datos (job `unit-tests`) y las 103 con `libreria_brenda_test` (job `login-dao-tests`). |
| TDD Red–Green–Refactor | Ciclos de `ValidadorEmail`, hash BCrypt truncado, session fixation y `minutosRestantes()` de RF03 (bloqueo vencido), con salidas RED conservadas. |
| Integración HTTP | 62 comprobaciones de RF02, 29 de RF03 (bloqueo, con precondiciones de aislamiento fatales) y 80 de regresión general. |
| Pruebas negativas y de autorización | Acceso anónimo/cliente/admin, cuentas inactivas, roles cruzados, stock insuficiente y cancelaciones. |
| Regresión | Suite general de carrito, pedidos, cupones, stock y permisos. |
| Pruebas de rendimiento | 10 escenarios JMeter (carga, estrés, resistencia y picos) con 275.979 muestras y percentiles p50/p95/p99, throughput y tasa de error por servicio. |
| Cobertura instrumentada | JaCoCo 0.8.12 sobre la suite JUnit y sobre la aplicación desplegada: 57,55 % de líneas, 41,66 % de ramas y 72,60 % de métodos sobre las 41 clases de producción. |
| Detección de defectos de concurrencia | Hallazgos QA-S4-01 (identificador de pedido no único) y QA-S4-02 (ausencia de pool de conexiones), corregidos y con prueba de regresión propia. |
| Automatización y CI | GitHub Actions con dos jobs; MariaDB de servicio para los DAO. |
| Documentación y trazabilidad | Este índice, RF02, Sprint 4, registro de cambios y salidas crudas en `evidencias/`. |

## Última ejecución registrada

- **Sprint 4 — NFR (09/11/2026):** **103/103** pruebas JUnit, **36/36** comprobaciones del
  recorrido funcional HTTP y **275.979** muestras en 10 escenarios JMeter (carga, estrés,
  resistencia y picos). Cobertura instrumentada JaCoCo sobre las 41 clases de producción:
  **57,55 % de líneas, 41,66 % de ramas y 72,60 % de métodos**. Detalle en
  [SPRINT4_PRUEBAS_NO_FUNCIONALES.md](SPRINT4_PRUEBAS_NO_FUNCIONALES.md).
- **JUnit (23/10/2026):** 78 pruebas ejecutadas sin BD, 0 fallos; **97/97** con `libreria_brenda_test`.
- **HTTP (23/10/2026):** RF03 **29/29** (corregido tras revisión; 1.ª corrida27/27); RF02 **62/62**; regresión general **80/80**. Pruebas negativas de aislamiento: **2/2 abortos sin escrituras**.
- **CI (29/10/2026):** dos jobs de JUnit en el workflow `junit.yml`, en verde en el PR #4 (runs #17 y #18) y en el merge sobre `main` (run #19). La suite HTTP **no** corre en GitHub Actions.
- **Demo local:** `:8080`, base `libreria_brenda_demo`, 16 clientes sintéticos y modal de pedidos con 8 registros del cliente 01.

Evidencias del Sprint 4 (09/11/2026):

- [Campaña JMeter por escenario](evidencias/sprint4-jmeter-escenarios-2026-11-09.txt)
- [Cobertura JaCoCo por ámbito y por paquete](evidencias/sprint4-jacoco-cobertura-2026-11-09.txt)
- [Suite JUnit final](evidencias/sprint4-junit-2026-11-09.txt)
- [Auditoría de datos del motor](evidencias/sprint4-auditoria-datos-motor-2026-11-09.txt)

Evidencias de la corrida anterior (23/10/2026 — RF03 y regresión):

- [CI del merge de RF03 en `main` (runs #17–#19)](evidencias/ci-2026-10-29-rf03-main.txt)
- [RF03 corregido (29/29, tras revisión del PR #4)](evidencias/rf03-http-corregido-2026-10-23.txt)
- [Pruebas negativas de aislamiento (abortos sin escrituras)](evidencias/rf03-aislamiento-negativo-2026-10-23.txt)
- [RED RF03 (2 fallos antes de la corrección)](evidencias/rf03-red-2026-10-23.txt)
- [JUnit sin BD](evidencias/junit-unit-rf03-2026-10-23.txt)
- [JUnit con BD](evidencias/junit-db-rf03-2026-10-23.txt)
- [HTTP RF03](evidencias/rf03-http-2026-10-23.txt)
- [HTTP RF02 (regresión)](evidencias/rf02-http-regresion-2026-10-23.txt)
- [HTTP general (regresión)](evidencias/http-general-regresion-2026-10-23.txt)
- [HTTP RF02 (reconfirmado r2)](evidencias/rf02-http-regresion-2026-10-23-r2.txt)
- [HTTP general (reconfirmado r2)](evidencias/http-general-regresion-2026-10-23-r2.txt)

Corrida anterior conservada (21/10/2026 — RF02):

- [JUnit sin BD](evidencias/junit-unit-2026-10-21-final.txt)
- [JUnit con BD](evidencias/junit-db-2026-10-21-final.txt)
- [HTTP RF02](evidencias/rf02-http-2026-10-21-final.txt)
- [HTTP general](evidencias/http-general-2026-10-21-final.txt)
- [CI](evidencias/ci-2026-10-21.txt)

## Atribución

LibreriaBrend es un proyecto grupal del curso **Calidad y Pruebas de Software** de la UPN. La atribución de roles está en el [README principal](../../README.md#roles-académicos). La documentación QA y las pruebas de esta etapa corresponden al trabajo de QA del equipo; no se atribuye todo el desarrollo del sistema a una sola persona.

## Límites

- El Sprint 4 **sí** declara cobertura instrumentada y pruebas de carga, con su alcance y sus
  límites en [SPRINT4_PRUEBAS_NO_FUNCIONALES.md](SPRINT4_PRUEBAS_NO_FUNCIONALES.md). No se declara
  certificación de producción ni demo pública.
- El hallazgo **QA-S4-03** (ausencia de paginación en `admin.jsp` y `admin-pedidos.jsp`) queda
  abierto y su corrección está propuesta para el Sprint 5.
- El generador de carga y el servidor de aplicación se ejecutaron en el mismo equipo, lo que
  limitó la medición por el agotamiento del rango de puertos efímeros del cliente.
- El historial antiguo de Git puede conservar datos previos al saneamiento; la situación y las
  opciones están descritas en [SEGURIDAD_REPOSITORIO.md](SEGURIDAD_REPOSITORIO.md).
