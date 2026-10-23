# RF03 — Bloqueo temporal por intentos fallidos

## Requisito oficial

> **RF03 — Bloqueo temporal por intentos fallidos** (Prioridad: ALTA)
> El sistema debe bloquear el inicio de sesión de un correo durante 2 minutos
> tras 5 intentos fallidos, informar los minutos restantes y reiniciar el
> contador tras un acceso exitoso.

Numeración oficial RF01–RF17 (no usar la numeración preliminar del informe T2,
donde el bloqueo tenía otro identificador).

## Trazabilidad

| Nivel | Referencia | Estado |
|---|---|---|
| RF | `RF03` | Oficial (matriz académica RF01–RF17) |
| HU | `HU-N03*` | **Provisional**: referencia tomada del documento de reinicio; no aparece en los documentos del repositorio, verificar antes de citarla en el informe T3 |
| CU | `CU-LOG-001` | **Provisional**: relación extend (mismo origen) |
| CP | `CP01`, `CP06`, `CP21` | **Provisional**: no están definidos en el repositorio; se usan solo como ancla de la matriz |
| Componentes | `ControlIntentosLogin`, `LoginServlet` | Verificados en `main` |
| Persistencia | memoria del servidor (`ConcurrentHashMap`) | Verificada; se reinicia con el servidor |

> Las referencias HU/CU/CP están marcadas como provisionales porque ningún
> documento versionado las contiene (búsqueda `CP01|CP06|CP21|HU-N03` en
> `docs/` = 0 resultados). No se inventa su contenido.

## 1. Estado previo y cobertura existente

Antes de RF03, `main` ya implementaba el bloqueo completo:

- `src/libreria/util/ControlIntentosLogin.java`: límite de 5 intentos,
  bloqueo de 120 000 ms, contador por correo, normalización
  `trim().toLowerCase()`, `ConcurrentHashMap`, expiración, cálculo de minutos
  restantes y reinicio tras éxito.
- `src/libreria/servlets/LoginServlet.java`: consulta el bloqueo **antes** de
  autenticar por DAO, registra fallos y éxitos, y **no** registra fallos
  cuando el correo está bloqueado (el temporizador no se extiende).
- `test/libreria/util/ControlIntentosLoginTest.java`: 12 pruebas.
- `test/integration/rf02-login-tests.sh`: sección `RF02-BR` con 4
  comprobaciones de bloqueo.

**No se reimplementó nada de lo que ya funcionaba ni se duplicaron pruebas
existentes para inflar cantidades.**

## 2. Matriz RF03 (FASE A — auditoría de cobertura)

| # | Criterio de aceptación | CP (prov.) | Prueba automatizada | Caracterización | Brecha | Tipo | ¿Producción? |
|---|---|---|---|---|---|---|---|
| 1 | 0 fallos → sin bloqueo | CP01 | `emailSinHistorial_noEstaBloqueado` | PASS | — | caracterización | No |
| 2 | 1–4 fallos → permite seguir | CP01 | `cuatroFallos_noBloquea` + HTTP `RF03-BL-01` | PASS | — | frontera | No |
| 3 | 5.º fallo → bloqueo de 2 min | CP06 | `cincoFallos_bloquea`, `minutosRestantes_recienBloqueado_sonDos` + fronteras con reloj (119 999/120 000 ms) + HTTP `RF03-BL-02` | PASS | Sin fronteras temporales | frontera con reloj | No |
| 4 | 6.º intento → rechazado por bloqueo | CP06 | `masDeCincoFallos_sigueBloqueado` + HTTP `RF03-BL-03` | PASS | — | caracterización | No |
| 5 | Contraseña correcta durante bloqueo → no autentica | CP21 | HTTP `RF03-BL-05` (**nueva**) | **No existía cobertura** | G2 | HTTP de integración | No |
| 6 | Tras expirar 2 min → permite nuevo intento | CP21 | `ControlIntentosLoginExpiracionTest` (**nueva**, reloj) | **BRECHA G1** | G1 | **TDD RED→GREEN** | **Sí (corregido)** |
| 7 | Éxito antes de 5 fallos → reinicia contador | CP01 | `loginExitoso_reiniciaElContador` + HTTP `RF03-BL-06` | PASS | — | caracterización | No |
| 8 | Correos distintos → bloques independientes | — | `bloqueo_esPorEmail_noAfectaAOtrosUsuarios` + HTTP `RF03-BL-07` | PASS | — | caracterización | No |
| 9 | Mayúsculas/espacios → misma identidad | — | `email_ignoraMayusculasYEspacios` | PASS | Sin eco HTTP (no duplicado: la normalización está probada en unidad y RF02 ya cubre trim/mayúsculas en login) | — | No |
| 10 | Cliente y administrador comparten bloqueo por correo | CP06 | HTTP `RF03-BL-08` (**nueva**) | **No existía cobertura** | G3 | HTTP de integración | No |

## 3. Brechas detectadas y evidencia

### RF03-G1 — defecto real (corregido con TDD)

`minutosRestantes()` aplicaba `Math.max(1, (restanteMs + 59_999) / 60_000)`,
de modo que **para un bloqueo ya vencido informaba 1 minuto** (nunca 0),
contradiciendo a `estaBloqueado()`, que devuelve `false` para el mismo estado.
La inconsistencia era observable en la consulta directa al instante del
vencimiento y por detrás de la carrera micro entre `estaBloqueado()` y
`minutosRestantes()` en `LoginServlet`.

- Evidencia RED: [evidencias/rf03-red-2026-10-23.txt](evidencias/rf03-red-2026-10-23.txt)
  (`expected: <0> but was: <1>` en2 pruebas, resto en verde).
- Corrección: `minutosRestantes()` devuelve 0 cuando `restanteMs <= 0`; para
  restantes positivos el techo de minutos es idéntico al anterior.

### RF03-G2 — cobertura ausente (añadida)

No existía prueba de que **una contraseña correcta esté rechazada mientras el
correo está bloqueado** (requisito explícito: el bloqueo se evalúa antes de
autenticar). Añadida `RF03-BL-05` (HTTP).

### RF03-G3 — cobertura ausente (añadida)

No existía prueba del **bloqueo compartido entre roles** (mismo correo como
cliente y como administrador). Añadida `RF03-BL-08`:5 fallos con rol cliente,
luego credenciales correctas de cliente y de administrador → ambas rechazadas
por el bloqueo, con control negativo de otro correo.

### RF03-G4 — fronteras temporales ausentes (añadidas)

No había forma determinista de observar el vencimiento (los120 s reales no se
pueden esperar en la suite). Añadida la abstracción mínima de reloj y6 pruebas
de frontera (§5).

### RF03-G5 — condición de carrera (limitación, NO defecto afirmado)

`estaBloqueado()` hace `intentos.remove(clave)` al detectar el vencimiento
mientras otro hilo puede estar en `registrarFallo()` con un `Registro` ya
obtenido por `computeIfAbsent()`: ese incremento caería sobre un objeto
huérfano y se perdería. La ventana es mínima y **no se pudo reproducir de
forma determinista** (no hay puntos de inyección dentro del método), por lo
que **no se afirma como defecto** ni se toca la política; se documenta como
riesgo residual.

### RF03-G6/G7 — decisiones de borde (documentadas, sin cambio)

- **G6:** si se llama `registrarFallo()` sobre un correo vencido **sin pasar
  antes** por `estaBloqueado()`, el contador hereda6 intentos y re-bloquea de
  inmediato. Por `LoginServlet` es inalcanzable (siempre consulta
  `estaBloqueado()` primero, que limpia el registro). La especificación no
  define la semántica del contador tras el vencimiento, así que **no se impone
  una nueva**: se documenta. Con G1 corregido, `minutosRestantes()` ya
  informa 0 en ese estado.
- **G7:** el bloqueo se levanta en el instante exacto (`now >= bloqueadoHasta`):
  "2 minutos" = `[t0, t0+120 s)`. En la carrera entre las dos llamadas del
  servlet, los minutos pueden informar 0 (antes: incorrectamente 1).

## 4. TDD real (FASE B)

| Fase | Qué ocurrió |
|---|---|
| **RED** | `ControlIntentosLoginExpiracionTest` (6 pruebas, reloj inyectado) sobre el código con defecto → **78 iniciadas,76 OK,2 fallidas** exactamente por G1 (`expected: <0> but was: <1>`). SHA inicial `e9ec839`. Infraestructura de reloj añadida antes (conducta neutra) para que el fallo fuera de aserción y no de compilación. |
| **GREEN** | Corrección mínima en `minutosRestantes()` → **78/78**. Regresión inmediata de las72 pruebas preexistentes: ninguna afectada. |
| **REFACTOR** | Sin cambios adicionales justificados: se eliminó el `Math.max(1, …)` muerto en el propio GREEN y el comportamiento público se conserva (misma fórmula de techo para restantes positivos, mismas firmas). Se volvió a ejecutar la suite completa:78/78. |

**No se fabricó la RED:** la única afirmación de fallo corresponde al defecto
investigado; las otras4 pruebas nuevas pasaron ya en RED (caracterización).

## 5. Nuevas pruebas y casos límite

### Unitarias (nueva clase `test/libreria/util/ControlIntentosLoginExpiracionTest.java`,6 pruebas)

1. `anteDelVencimiento_sigueBloqueado_eInformaUnMinuto` —119999 ms.
2. `minutos_seGunElRangoDelRestante` — techo2 en60001 ms,1 en60000 ms.
3. `enElVencimiento_estaBloqueado_seLevanta` —120000 ms exactos.
4. `enElVencimiento_minutosRestantes_esCero` — **RED→GREEN (G1)**.
5. `trasElVencimiento_minutosRestantes_esCero_sinConsultaPrevia` — **RED→GREEN (G1)**.
6. `trasElVencimiento_laConsultaLimpiaYArrancaUnNuevoCiclo` — limpieza,1 fallo
   no re-bloquea,5 fallos del nuevo ciclo vuelven a bloquear.

Reloj: `LongSupplier` paquete-private en `ControlIntentosLogin`
(`fijarRelojParaPruebas` / `restaurarRelojReal`), por defecto
`System::currentTimeMillis`; restaurado en `@AfterEach` para no contaminar el
estado estático compartido. Sin `Thread.sleep`, sin frameworks, comportamiento
público intacto.

Casos límite complementarios ya existentes que se mantienen: correo nulo,
mayúsculas/espacios,5 fallos concurrentes,6+ fallos.

### HTTP (nueva suite `test/integration/rf03-bloqueo-tests.sh`,27 comprobaciones)

- `RF03-BL-01`:4 fallos y autenticación posible.
- `RF03-BL-02`: el5.º fallo procesa credenciales y activa el bloqueo.
- `RF03-BL-03`:6.º intento bloqueado, JSON `ok:false`, **HTTP200** (contrato
  existente intacto, sin cambiar a401/429).
- `RF03-BL-04`: el JSON informa `en 2 minuto(s)`.
- `RF03-BL-05`: contraseña correcta rechazada durante el bloqueo.
- `RF03-BL-06`: el acceso exitoso reinicia el contador.
- `RF03-BL-07`: independencia entre correos.
- `RF03-BL-08`: coherencia entre roles con el mismo correo + control negativo.

**La expiración real de120 s NO se prueba por HTTP**: se valida de forma
determinista en unidad con reloj inyectado (misma especificación, sin
esperas, sin tocar el servidor). Cuentas sintéticas `rf03.*@test.local` con
limpieza automática: no contamina RF02 ni otras suites.

## 6. Resultados ejecutados (2026-10-23, local)

| Suite | Resultado | Evidencia |
|---|---|---|
| JUnit sin BD | **78/78** (97 detectadas;19 DAO omitidas por `Assumptions`) | [junit-unit-rf03-2026-10-23.txt](evidencias/junit-unit-rf03-2026-10-23.txt) |
| JUnit con `libreria_brenda_test` | **97/97** | [junit-db-rf03-2026-10-23.txt](evidencias/junit-db-rf03-2026-10-23.txt) |
| HTTP RF03 | **27/27** | [rf03-http-2026-10-23.txt](evidencias/rf03-http-2026-10-23.txt) |
| RED (antes de la corrección) |2 fallidas de78 (G1) | [rf03-red-2026-10-23.txt](evidencias/rf03-red-2026-10-23.txt) |

Aislamiento verificado antes y dentro de las suites: MariaDB11.8.9 propia en
`127.0.0.1:3307` con datadir del respaldo (sin `libreria_brenda`, sin
`libreria_brenda_demo`, sin bases de LibaaS), Tomcat11 propio en `:8091` con
`DB_*` de entorno hacia la base de pruebas. **Nunca se escribió en la base
comercial ni en la demo.**

## 7. Regresión (mismo día, mismo entorno)

| Suite | Baseline histórico | Resultado actual | Evidencia |
|---|---|---|---|
| JUnit sin BD |72/72 | **78/78** (+6 nuevas) | [junit-unit-rf03-2026-10-23.txt](evidencias/junit-unit-rf03-2026-10-23.txt) |
| JUnit con BD |91/91 | **97/97** (+6) | [junit-db-rf03-2026-10-23.txt](evidencias/junit-db-rf03-2026-10-23.txt) |
| HTTP RF02 |62/62 | **62/62** | [rf02-http-regresion-2026-10-23.txt](evidencias/rf02-http-regresion-2026-10-23.txt) |
| HTTP general |80/80 | **80/80** | [http-general-regresion-2026-10-23.txt](evidencias/http-general-regresion-2026-10-23.txt) |

**0 regresiones.** RF01/RF02 no se modificaron (el único cambio funcional es
`minutosRestantes()` de RF03).

## 8. Pruebas locales vs CI (diferencia obligatoria)

- `.github/workflows/junit.yml` ejecuta **solo** dos jobs de JUnit: sin BD
  (`JUNIT_EXCLUDE=libreria.dao.*`) y con BD (MariaDB de servicio en3306,
  `schema_test.sql` + `fixtures_test.sql`). En CI correrán las78 (unitario) y
 97 (DAO) pruebas.
- **Las suites HTTP (RF0327, RF0262, general80) NO se ejecutan en GitHub
  Actions**: se corren exclusivamente en local contra el Tomcat aislado. No
  deben citarse como "CI verde".
- La expiración de120 s tampoco se ejercita en CI más allá de las pruebas
  unitarias con reloj (deterministas y instantáneas).

## 9. Riesgos y limitaciones

1. Estado en memoria: un reinicio del servidor limpia contadores y bloqueos
   (aceptado en el alcance; sin tablas ni Redis).
2. Bloqueo por correo compartido entre roles: un atacante puede bloquear
   temporalmente una cuenta (limitación conocida de la política actual; **no
   se modifica sin autorización**).
3. Carrera residual G5 (ventana mínima de limpieza concurrente, no
   reproducible de forma determinista).
4. Semántica del contador tras el vencimiento sin consulta previa (G6) no
   está definida por la especificación: documentada, sin cambio.
5. `HU-N03*`, `CU-LOG-001`, `CP01/CP06/CP21` siguen siendo referencia
   provisional no verificable en el repositorio.
6. Los minutos restantes pueden informar "0 minuto(s)" en la ventana
   microsegundos si el bloqueo vence entre las dos llamadas del servlet (G7;
   antes de la corrección informaba erróneamente "1 minuto(s)").

## 10. Reproducción

```bash
# 1) JUnit sin BD (78)
bash test/run-junit-tests.sh

# 2) JUnit con BD sobre la base de PRUEBAS aislada (97)
DB_HOST=127.0.0.1 DB_PORT=3307 DB_NAME=libreria_brenda_test \
DB_USER=root DB_PASSWORD= bash test/run-junit-tests.sh

# 3) HTTP RF03 (27) — Tomcat de pruebas con el contexto /LibreriaBrend
BASE=http://localhost:8091/LibreriaBrend DB_PORT=3307 DB_USER=root \
DB_PASSWORD= bash test/integration/rf03-bloqueo-tests.sh

# 4) Regresiones HTTP (RF02 62, general80)
BASE=http://localhost:8091/LibreriaBrend DB_PORT=3307 DB_USER=root \
DB_PASSWORD= bash test/integration/rf02-login-tests.sh
BASE=http://localhost:8091/LibreriaBrend DB_PORT=3307 DB_USER=root \
DB_PASSWORD= bash test/integration/http-tests.sh
```

Nunca apuntar estas ejecuciones a `libreria_brenda` ni a
`libreria_brenda_demo`; las suites verifican el esquema antes de escribir.

## 11. Archivos modificados

| Archivo | Cambio |
|---|---|
| `src/libreria/util/ControlIntentosLogin.java` | Corrección G1 + reloj inyectable (paquete-private) |
| `test/libreria/util/ControlIntentosLoginExpiracionTest.java` | Nuevo:6 pruebas de frontera/expiración |
| `test/integration/rf03-bloqueo-tests.sh` | Nuevo:27 comprobaciones HTTP |
| `docs/QA/RF03_BLOQUEO_LOGIN.md` | Este documento |
| `docs/QA/README.md` | Índice y última ejecución |
| `docs/REGISTRO_CAMBIOS.md` | Entrada RF03 |
| `README.md` | Enlace a la matriz RF03 y cifras de tests |
| `docs/QA/evidencias/rf03-*.txt`, `junit-*-rf03-*.txt`, `*-regresion-2026-10-23.txt` | Salidas crudas |

No se modificaron: RF01/RF02, workflows de GitHub Actions, evidencias
históricas, respaldos ni `screenshots/`.

## 12. SHA de los commits de implementación

| Commit | Contenido |
|---|---|
| `f813536` | `fix(rf03)`: corrección G1 + reloj +6 pruebas unitarias (RED→GREEN) |
| `772c54d` | `test(rf03)`: suite HTTP `rf03-bloqueo-tests.sh` (27 comprobaciones) |

(El commit de documentación se añade después; los SHA de implementación son
los que certifican código y pruebas.)
