# Caso Práctico — Prueba Combinada (Caja Negra + Caja Blanca) con orquestación de agentes en herdr

**Proyecto:** LibreriaBrend — Calidad y Pruebas de Software (UPN)
**Insumo de la actividad:** `Caso_Practico_.pdf` (Sistema de Aprobación de Préstamos Bancarios)
**QA responsable de la ejecución:** Kevin David Urbe Bolo
**Versión:** 1.0 — 17/11/2026
**Herramientas:** herdr (`hc`) · Vibe CLI (GLM 5.3) · MiniMax Code (`mcode`) · Antigravity (`agy`) · JUnit 5.11.4 · JaCoCo 0.8.12 · Microsoft Edge headless (PDF)

---

## 1. Qué se evalúa y cómo se demuestra

La actividad pide **una sola evaluación de prueba combinada**: el mismo módulo se ataca desde dos ángulos complementarios y el informe final demuestra qué encontró cada técnica.

| Técnica | Pregunta que responde | Cómo se demuestra aquí |
|---|---|---|
| **Caja negra** | ¿El módulo cumple las reglas de negocio para las entradas de frontera y de cada partición? | Tabla de clases de equivalencia + valores límite → casos de prueba ejecutados contra la interfaz pública, sin mirar el código |
| **Caja blanca** | ¿La estructura interna (decisiones y ramas) queda ejercitada al 100 %? | JUnit 5 + JaCoCo con cobertura de **ramas** medida sobre la clase, camino por camino |

**Criterio de éxito de la actividad:** los dos conjuntos de pruebas se ejecutan en el proyecto grupal, se conservan sus evidencias crudas y el informe en PDF reproduce la estructura del caso de referencia (planteamiento → consigna → solución de caja negra → solución de caja blanca), añadiendo la matriz que une ambas técnicas.

---

## 2. Malla de agentes

| Rol | CLI / modelo | Terminal `hc` | Responsabilidad | Entregables |
|---|---|---|---|---|
| **Orquestador** | Vibe CLI — **GLM 5.3** | `glm` | Prepara el SUT, reparte el trabajo, espera y valida cada evidencia, ejecuta la regresión, **redacta el informe** en `.md` y lo convierte a PDF | `Informe_Caso_Combinado.md` / `.pdf`, `BITACORA.md`, veredicto de cada puerta de calidad |
| **Tester 1** | MiniMax Code (`mcode`) | `t1` | Diseña y ejecuta las pruebas de **caja blanca** (JUnit 5 + JaCoCo) | `EvaluadorPrestamoCajaBlancaTest.java`, evidencias T1, tabla de caminos |
| **Tester 2** | Antigravity (`agy`) | `t2` | Diseña y ejecuta las pruebas de **caja negra** (particiones de equivalencia + valores límite) | `EvaluadorPrestamoCajaNegraTest.java`, evidencias T2, tablas de particiones y casos |

> **Nota de asignación:** el encargo original mencionaba "caja blanca" para ambos testers. La consigna del PDF exige *las dos* técnicas, así que **T1 = caja blanca** y **T2 = caja negra**. Si el docente pidiera lo contrario, solo se intercambian las secciones 9.2 y 9.3 al despachar; los artefactos y las puertas de calidad no cambian.

Reglas de convivencia entre agentes:

1. **Nadie toca el SUT** salvo el orquestador en el paso 0. Si un tester "arregla" el código para que pase una prueba, la evidencia deja de valer.
2. **T2 no lee el fuente del SUT ni las pruebas de T1 antes de diseñar**: la caja negra se diseña desde las reglas del PDF, no desde el código. Puede compilar contra la clase, no leerla.
3. **T1 no lee los casos de T2** antes de cerrar su tabla de caminos: las dos técnicas deben llegar por caminos independientes y coincidir en el veredicto, eso es lo que se evalúa.
4. Solo el orquestador escribe en `Informe_Caso_Combinado.md` y `BITACORA.md`.

---

## 3. Decisión de herramientas (respuesta a "¿JUnit + JaCoCo o Postman?")

**Recomendación: JUnit 5 + JaCoCo para caja blanca y una suite JUnit dirigida por especificación para caja negra; Postman/Newman solo si el módulo se expone por HTTP.**

| Opción | Cuándo conviene | Veredicto en este caso |
|---|---|---|
| **JUnit 5 (caja negra, `@ParameterizedTest` + `@CsvSource`)** | El módulo es una clase pura sin endpoint: los casos se escriben como tabla entrada→salida tomada de las reglas | **Sí, opción principal.** Reproducible, versionable, sin servidor ni base de datos, y la salida de consola es evidencia válida |
| **Postman / Newman** | Hay que probar el comportamiento observable por HTTP (login, catálogo, carrito, permisos) | **Opcional.** El `EvaluadorPrestamo` no tiene endpoint; montar un servlet solo para la entrega añade código de producción que la consigna no pide. Útil como *variante B* si el docente exige la herramienta |
| **JaCoCo 0.8.12** | Se necesita cobertura de ramas medida, no estimada | **Sí.** Ya es la herramienta del proyecto (Sprint 4) y mide **ramas de subexpresión**, que es justo lo que exige el punto 2 de la consigna |

El proyecto ya tiene el patrón montado: JUnit Platform Console 1.11.4 en `WebContent/WEB-INF/lib/` y evidencia JaCoCo en `docs/QA/evidencias/sprint4-jacoco-cobertura-2026-11-09.txt`. Se reutiliza, no se inventa nada nuevo.

### 3.1. Variante B (solo si el docente exige Postman)

1. Crear `src/libreria/servlets/EvaluarPrestamoServlet.java` (`POST`, JSON de entrada, JSON de salida) y mapearlo en `WebContent/WEB-INF/web.xml`.
2. Desplegar en el Tomcat del proyecto (`:8082`) o de pruebas (`:8091`).
3. Colección `docs/QA/caso-combinado/postman/Caso_Combinado.postman_collection.json` con los mismos 6 casos de la sección 5 y un entorno con `{{baseUrl}}`.
4. Ejecutar: `npm i -g newman && newman run docs/QA/caso-combinado/postman/Caso_Combinado.postman_collection.json -e docs/QA/caso-combinado/postman/entorno.json --reporters cli,json --reporter-json-export docs/QA/caso-combinado/evidencias/T2-postman.json | tee docs/QA/caso-combinado/evidencias/T2-postman.txt`

En ese escenario el PDF se construye igual: la tabla de la sección 5 es la misma; solo cambia el ejecutor.

---

## 4. Reglas de negocio (fuente de verdad, copiadas del PDF)

| Id | Regla |
|---|---|
| **R1** | Edad del solicitante entre **21 y 65 años**, ambos inclusive |
| **R2** | Ingreso mensual neto **≥ 1 500** |
| **R3** | Puntaje crediticio **> 600** |
| **R4** | Excepción interna: **antigüedad > 5 años** y **sin deudas vencidas** → aprueba aunque el ingreso sea **≥ 1 200** |
| **R5** | Cualquier otro caso → **Rechazado** |

Código de referencia del enunciado (Python):

```python
def evaluar_prestamo(edad, ingreso, puntaje, antiguedad, tiene_deudas):
    if 21 <= edad <= 65 and puntaje > 600:
        if ingreso >= 1500:
            return "Aprobado"
        elif antiguedad > 5 and not tiene_deudas and ingreso >= 1200:
            return "Aprobado por antigüedad"
    return "Rechazado"
```

**SUT en el proyecto grupal:** `src/libreria/util/EvaluadorPrestamo.java`, traducción fiel a Java 21 del fragmento anterior, con esta firma y este contrato:

```java
public static String evaluar(int edad, double ingreso, int puntaje, int antiguedad, boolean tieneDeudas)
```
Devuelve exactamente `"Aprobado"`, `"Aprobado por antigüedad"` o `"Rechazado"`. Sin validaciones extra, sin `null`, sin excepciones: si el orquestador añade matices que el PDF no pide, la comparación con el solucionario se rompe. Se documenta como **ejercicio académico dentro del proyecto** (mismo criterio que `libreria.util.CalculadoraMorosidad`): no forma parte de los 17 RF implementados ni se integra con servlets, DAO ni base de datos.

**Salida esperada de la sección 0 (orquestador):** `src/libreria/util/EvaluadorPrestamo.java` compilando aislado, y **ninguna** modificación a `src/libreria` más allá de ese archivo nuevo (verificar con `git status --porcelain`).

---

## 5. Criterios de aceptación (solucionario interno del orquestador)

> Esta sección la usa **solo GLM** para validar lo que entregan los testers. **No se incluye en los prompts de T1 ni de T2**: si el tester copia el solucionario, la entrega pierde el sentido.

### 5.1. Caja negra — 3 casos obligatorios (los de la consigna)

| # | Técnica aplicada | Entrada (edad, ingreso, puntaje, antigüedad, deudas) | Salida esperada |
|---|---|---|---|
| 1 | Valor límite inferior válido (edad e ingreso) | 21, 1500, 601, 1, `false` | `Aprobado` |
| 2 | Valor límite superior inválido (edad fuera de rango) | 66, 2000, 750, 2, `false` | `Rechazado` |
| 3 | Partición inválida (puntaje en la frontera) | 35, 1800, 600, 0, `false` | `Rechazado` |

### 5.2. Caja negra — 3 casos complementarios (amplían las particiones)

| # | Técnica aplicada | Entrada | Salida esperada |
|---|---|---|---|
| 4 | Valor límite inferior inválido de edad | 20, 2000, 700, 3, `false` | `Rechazado` |
| 5 | Valor límite de la excepción (ingreso reducido exacto) | 40, 1200, 650, 6, `false` | `Aprobado por antigüedad` |
| 6 | Partición de excepción bloqueada por deuda vencida | 40, 1200, 650, 6, `true` | `Rechazado` |

### 5.3. Caja blanca — 4 caminos de decisión (mínimo de la consigna)

| Camino | Recorrido | Entrada | Salida esperada |
|---|---|---|---|
| 1 | Primer `if` falso (edad fuera de rango) | 18, 2000, 700, 6, `false` | `Rechazado` |
| 2 | Primer `if` verdadero + segundo `if` verdadero | 30, 1600, 650, 1, `false` | `Aprobado` |
| 3 | Primer `if` verdadero + segundo falso + `elif` verdadero | 40, 1300, 650, 6, `false` | `Aprobado por antigüedad` |
| 4 | Primer `if` verdadero + segundo falso + `elif` falso | 40, 1300, 650, 2, `true` | `Rechazado` |

### 5.4. Caja blanca — por qué 4 no bastan para JaCoCo y hacen falta 8

JaCoCo mide **ramas de subexpresión**, no solo el resultado de la decisión. La clase tiene **7 saltos condicionales = 14 ramas**:

- `if (edad >= 21 && edad <= 65 && puntaje > 600)` → 3 condiciones → 6 ramas
- `if (ingreso >= 1500)` → 2 ramas
- `else if (antiguedad > 5 && !tieneDeudas && ingreso >= 1200)` → 3 condiciones → 6 ramas

Los 4 caminos anteriores dejan sin cubrir la rama "edad > 65", la de "puntaje ≤ 600" con edad válida, la de `antiguedad > 5` falsa con `deudas = true` y la de `ingreso < 1200` con antigüedad suficiente. Con cuatro casos más se cierran las 14 ramas:

| Caso | Entrada | Salida | Rama que cierra |
|---|---|---|---|
| 5 | 66, 2000, 750, 2, `false` | `Rechazado` | `edad <= 65` falsa |
| 6 | 35, 1800, 600, 0, `false` | `Rechazado` | `puntaje > 600` falsa |
| 7 | 40, 1300, 650, 6, `true` | `Rechazado` | `!tieneDeudas` falsa |
| 8 | 40, 1100, 650, 6, `false` | `Rechazado` | `ingreso >= 1200` falsa |

**Criterio de aceptación de T1:** JaCoCo debe reportar `BRANCH_COVERED = 14`, `BRANCH_MISSED = 0` (100 %) **para `libreria.util.EvaluadorPrestamo`**, con 0 fallos de ejecución y mínimo 8 casos. El informe explica la diferencia entre los 4 caminos de la consigna (nivel decisión) y las 8 pruebas necesarias a nivel de rama medida.

---

## 6. Preparación del entorno (una sola vez, la hace el operador)

Comandos verificados en este repositorio (Git Bash en Windows; el separador de classpath es `;`).

```bash
# 0.1 Carpeta de trabajo de la actividad
mkdir -p docs/QA/caso-combinado/{insumos,evidencias,prompts}

# 0.2 Insumos del caso: el PDF original y/o su texto extraído
#     (ya está el texto del caso en insumos/Caso_Practico_.txt; copia el PDF si lo tienes)
cp "Caso_Practico_.pdf" docs/QA/caso-combinado/insumos/Caso_Practico_.pdf 2>/dev/null \
  || echo "AVISO: deja el PDF del aula virtual en docs/QA/caso-combinado/insumos/"

# 0.3 Rama de trabajo (el proyecto usa qa/**)
git checkout -b qa/caso-combinado

# 0.4 Herramientas JaCoCo (out/ está en .gitignore: no se versionan)
mkdir -p out/tools
curl -L -o out/tools/jacocoagent.jar \
  https://repo1.maven.org/maven2/org/jacoco/org.jacoco.agent/0.8.12/org.jacoco.agent-0.8.12-runtime.jar
curl -L -o out/tools/jacococli.jar \
  https://repo1.maven.org/maven2/org/jacoco/org.jacoco.cli/0.8.12/org.jacoco.cli-0.8.12-nodeps.jar
ls -l out/tools
```

Comprobaciones rápidas antes de lanzar agentes:

```bash
javac -version          # 21.x
java -jar WebContent/WEB-INF/lib/junit-platform-console-standalone-1.11.4.jar --version
"/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --version   # generador de PDF
hc --version
```

---

## 7. Lanzamiento de la malla (`hc`)

Cada agente vive en su propia terminal de herdr y **sobrevive** al cierre del shell que lo lanzó.

```bash
# Orquestador: GLM 5.3 en Vibe CLI
hc run --bg --outlive-parent --name glm --cwd "$(pwd)" \
  --label rol=orquestador --label modelo="GLM 5.3" vibe

# Tester 1: caja blanca (MiniMax Code)
hc run --bg --outlive-parent --name t1 --cwd "$(pwd)" \
  --label rol=caja-blanca --label modelo="MiniMax Code" mcode

# Tester 2: caja negra (Antigravity)
hc run --bg --outlive-parent --name t2 --cwd "$(pwd)" \
  --label rol=caja-negra --label modelo="Antigravity" agy

hc ls            # los tres deben aparecer como running
```

Si un CLI pide *onboarding* (login, tema, permisos) la primera vez: `hc attach t1`, completarlo a mano, y salir con **Ctrl+\\**. Después ya se puede despachar sin intervención.

**Arranque del orquestador** (único mensaje que escribe el humano en toda la sesión):

```bash
hc send glm "Eres el ORQUESTADOR (GLM 5.3) del caso 'Prueba Combinada Caja Negra + Caja Blanca' del proyecto LibreriaBrend. Lee completo el archivo docs/QA/CASO_COMBINADO_ORQUESTACION.md y ejecuta tu rol tal como está descrito: prepara el SUT (sección 4), despacha a t1 y t2 (sección 9), valida cada puerta de calidad (sección 10), y redacta el informe .md y el PDF (sección 11). Usa hc para hablar con t1 y t2. No pidas confirmación y no hagas el trabajo de los testers."
```

---

## 8. Protocolo de despacho y espera

Reglas que el orquestador cumple sí o sí:

| Situación | Comando |
|---|---|
| Entregar un prompt largo a un tester | `hc put t1 docs/QA/caso-combinado/prompts/01-tester-caja-blanca.md` y luego `hc send t1 "Ejecuta el encargo del archivo que acabo de dejarte. Empieza ahora."` |
| No interrumpir a un agente que aún trabaja | `hc send t1 "..." --if idle` (si no está idle, el envío falla: esperar y reintentar) |
| Esperar el turno de un agente | `hc wait t1 --timeout 600` (repetir mientras siga `working`; `hc wait` no sirve con `--output` para agentes, eso es solo para programas) |
| Ver qué está haciendo / rescatar su salida | `hc read t1 --lines 200` |
| Revisar estado y etiquetas | `hc ls --json` |
| Agente bloqueado en un diálogo | `hc keys t1 enter`, o `hc send t1 "continúa" --force` |
| Agente desbocado | `hc interrupt t1`; si insiste, `hc kill t1` y relanzar |
| Cerrar la sesión | `for t in glm t1 t2; do hc kill "$t"; done` (o dejarlos vivos y `hc ls` para retomar) |

**Contrato de evidencias (la fuente de verdad no es la pantalla, son los archivos).** Cada tester escribe en `docs/QA/caso-combinado/evidencias/`:

```
T1-caja-blanca-junit.txt     salida real de la ejecución JUnit
T1-jacoco-ramas.txt          fila CSV de la clase + resumen de ramas
T1-caminos.md                tabla camino → datos → salida → rama cubierta
T2-caja-negra-junit.txt      salida real de la ejecución JUnit
T2-clases-equivalencia.md    particiones, valores límite y justificación
T2-casos.md                  los 6 casos con resultado observado vs esperado
```

Cada tester cierra su turno con una línea exacta para que sea fácil de localizar en `hc read`:

```
=== FIN T1 :: EVIDENCIA_CAJA_BLANCA_OK ===
=== FIN T2 :: EVIDENCIA_CAJA_NEGRA_OK ===
```

**Presupuesto de tiempo:** preparación 5 min · T1 20-30 min · T2 15-25 min · validación y regresión 10 min · informe y PDF 15 min. Si un tester pasa de 45 min sin evidencia escrita, el orquestador lo interrumpe y le pide entregar lo que tenga con su alcance declarado.

---

## 9. Prompts de los agentes

El orquestador los materializa como archivos (contenido literal de las secciones 9.2 y 9.3) y los entrega con `hc put`. Así queda una copia versionada de lo que se le pidió a cada agente.

### 9.1. Encargo del orquestador (contenido de la sección 7, ya enviado)

Además de lo indicado, el orquestador debe, en este orden:

1. Verificar la preparación de la sección 6 (jars, rama, PDF en `insumos/`).
2. Crear el SUT de la sección 4 y comprobarlo aislado:
   `javac -encoding UTF-8 -d out/caso-cb src/libreria/util/EvaluadorPrestamo.java`
3. Escribir `docs/QA/caso-combinado/BITACORA.md` y anotar ahí cada despacho, espera, veredicto y comando ejecutado (con hora).
4. Despachar 9.2 y 9.3, validar con las secciones 5 y 10, ejecutar la regresión, redactar el informe (sección 11) y generar el PDF.
5. **Prohibido:** inventar cifras de cobertura, copiar el solucionario dentro de los prompts de los testers, reescribir las pruebas de un tester desde su propio criterio, o marcar una puerta como superada sin el archivo de evidencia correspondiente.

### 9.2. PROMPT — Tester 1 (caja blanca, MiniMax Code)

```markdown
Eres el TESTER 1 (caja blanca) del caso "Prueba Combinada Caja Negra + Caja Blanca"
del proyecto LibreriaBrend (Java 21, JUnit 5, JaCoCo 0.8.12). Trabajas en la raíz del
repositorio, en la rama qa/caso-combinado.

## Insumos (léelos antes de empezar)
- Reglas de negocio: docs/QA/caso-combinado/insumos/Caso_Practico_.pdf
  (si no está el PDF, usa el texto extraído insumos/Caso_Practico_.txt: mismo contenido)
- Módulo bajo prueba: src/libreria/util/EvaluadorPrestamo.java
- Guía de la actividad: docs/QA/CASO_COMBINADO_ORQUESTACION.md (secciones 4, 5.3, 5.4 y 8)

## Tu tarea
1. Analiza la estructura de decisiones de EvaluadorPrestamo.evaluar(...) y determina
   cuántos caminos hacen falta como mínimo para cubrir el 100 % de las ramas.
2. Crea test/libreria/util/EvaluadorPrestamoCajaBlancaTest.java (JUnit 5, paquete
   libreria.util). Un método de prueba por camino, con nombre que describa el camino
   y un mensaje de aserción que explique la regla que se está ejerciendo.
3. Compila y ejecuta solo esa clase:

   L=WebContent/WEB-INF/lib
   JUNIT="$L/junit-platform-console-standalone-1.11.4.jar"
   mkdir -p out/caso-cb
   javac -encoding UTF-8 -cp "$JUNIT" -d out/caso-cb \
     src/libreria/util/EvaluadorPrestamo.java \
     test/libreria/util/EvaluadorPrestamoCajaBlancaTest.java 2>&1 \
     | tee docs/QA/caso-combinado/evidencias/T1-compilacion.txt
   java -jar "$JUNIT" -cp "out/caso-cb" \
     --select-class libreria.util.EvaluadorPrestamoCajaBlancaTest --disable-banner 2>&1 \
     | tee docs/QA/caso-combinado/evidencias/T1-caja-blanca-junit.txt

4. Mide cobertura de ramas con el agente JaCoCo:

   java -javaagent:out/tools/jacocoagent.jar=destfile=out/caso-cb/jacoco.exec \
     -jar "$JUNIT" -cp "out/caso-cb" \
     --select-class libreria.util.EvaluadorPrestamoCajaBlancaTest --disable-banner
   java -jar out/tools/jacococli.jar report out/caso-cb/jacoco.exec \
     --classfiles out/caso-cb/libreria/util/EvaluadorPrestamo.class \
     --sourcefiles src --csv out/caso-cb/jacoco.csv \
     --html out/caso-cb/jacoco-html

   Extrae y guarda la fila de la clase:
   head -1 out/caso-cb/jacoco.csv > docs/QA/caso-combinado/evidencias/T1-jacoco-ramas.txt
   grep EvaluadorPrestamo out/caso-cb/jacoco.csv >> docs/QA/caso-combinado/evidencias/T1-jacoco-ramas.txt

5. Si la cobertura de ramas es menor al 100 %, añade los casos que falten y documenta
   en T1-caminos.md qué rama quedaba descubierta y con qué entrada se cerró.

## Entregables
- test/libreria/util/EvaluadorPrestamoCajaBlancaTest.java
- docs/QA/caso-combinado/evidencias/T1-caja-blanca-junit.txt
- docs/QA/caso-combinado/evidencias/T1-jacoco-ramas.txt
- docs/QA/caso-combinado/evidencias/T1-caminos.md con esta tabla:
  | Camino | Condiciones evaluadas | Entrada | Salida esperada | Salida observada | Rama(s) que cubre |

## Reglas
- NO modifiques src/libreria/util/EvaluadorPrestamo.java ni ninguna otra clase de
  producción. Si crees que el SUT está mal, repórtalo al orquestador: tu trabajo es
  medirlo, no corregirlo.
- NO leas las pruebas de T2 (EvaluadorPrestamoCajaNegraTest).
- Prohibido assertTrue(true), pruebas sin aserción o casos duplicados para inflar el número.
- El número de casos debe justificarse por cobertura de ramas, no por cantidad.

## Cierre
Resume: casos totales, ramas cubiertas/total, veredicto (CUMPLE / NO CUMPLE) y rutas de
las evidencias. Termina con la línea exacta:
=== FIN T1 :: EVIDENCIA_CAJA_BLANCA_OK ===
```

### 9.3. PROMPT — Tester 2 (caja negra, Antigravity)

```markdown
Eres el TESTER 2 (caja negra) del caso "Prueba Combinada Caja Negra + Caja Blanca"
del proyecto LibreriaBrend (Java 21, JUnit 5). Trabajas en la raíz del repositorio, en
la rama qa/caso-combinado.

## Insumos (léelos antes de empezar)
- Reglas de negocio: docs/QA/caso-combinado/insumos/Caso_Practico_.pdf
  (si no está el PDF, usa el texto extraído insumos/Caso_Practico_.txt: mismo contenido)
- Guía de la actividad: docs/QA/CASO_COMBINADO_ORQUESTACION.md (secciones 4, 5.1, 5.2 y 8)

## Regla de independencia
Diseña los casos ÚNICAMENTE desde las reglas de negocio del PDF. No abras
src/libreria/util/EvaluadorPrestamo.java ni el test de T1 antes de tener tu tabla de
casos escrita; puedes compilar contra la clase, no leerla. La caja negra vale por lo
que descubre desde la especificación.

## Tu tarea
1. Tabla de clases de equivalencia (válidas e inválidas) para edad, ingreso, puntaje,
   antigüedad y deudas, con los valores límite de cada partición.
2. Redacta 3 casos obligatorios usando análisis de valores límite y partición de
   equivalencia (frontera inferior válida, frontera superior inválida y una partición
   inválida), más 3 casos complementarios de tu diseño. Cada caso debe indicar qué
   técnica lo origina y por qué ese valor (no "porque sí").
3. Impleméntalos en test/libreria/util/EvaluadorPrestamoCajaNegraTest.java
   (JUnit 5, paquete libreria.util), preferentemente con @ParameterizedTest +
   @CsvSource, de modo que el test sea la tabla: entrada → salida esperada.
4. Compila y ejecuta:

   L=WebContent/WEB-INF/lib
   JUNIT="$L/junit-platform-console-standalone-1.11.4.jar"
   mkdir -p out/caso-cn
   javac -encoding UTF-8 -cp "$JUNIT" -d out/caso-cn \
     src/libreria/util/EvaluadorPrestamo.java \
     test/libreria/util/EvaluadorPrestamoCajaNegraTest.java 2>&1 \
     | tee docs/QA/caso-combinado/evidencias/T2-compilacion.txt
   java -jar "$JUNIT" -cp "out/caso-cn" \
     --select-class libreria.util.EvaluadorPrestamoCajaNegraTest --disable-banner 2>&1 \
     | tee docs/QA/caso-combinado/evidencias/T2-caja-negra-junit.txt

5. Si algún caso no coincide con lo esperado, NO lo ajustes para que pase: registra la
   diferencia como hallazgo con la entrada exacta, el esperado, el obtenido y la regla
   incumplida (R1..R5).

## Entregables
- test/libreria/util/EvaluadorPrestamoCajaNegraTest.java
- docs/QA/caso-combinado/evidencias/T2-caja-negra-junit.txt
- docs/QA/caso-combinado/evidencias/T2-clases-equivalencia.md
- docs/QA/caso-combinado/evidencias/T2-casos.md con esta tabla:
  | # | Técnica | Edad | Ingreso | Puntaje | Antigüedad | Deudas | Esperado | Observado | Estado |

## Reglas
- NO modifiques src/libreria/util/EvaluadorPrestamo.java ni clases de producción.
- NO leas el test de T1 ni copies su lista de caminos.
- Prohibido usar valores al azar o casos sin justificación de partición/frontera.

## Cierre
Resume: casos totales, casos conformes, hallazgos, veredicto (CUMPLE / NO CUMPLE) y
rutas de las evidencias. Termina con la línea exacta:
=== FIN T2 :: EVIDENCIA_CAJA_NEGRA_OK ===
```

---

## 10. Puertas de calidad (el orquestador no avanza sin ellas)

| Puerta | Cuándo | Criterio verificable | Evidencia |
|---|---|---|---|
| **G0 — Preparación** | Antes de despachar | SUT compila aislado; `out/tools/*.jar` presentes; insumos del caso en `insumos/` (PDF y/o `.txt`); `git status` solo muestra el SUT nuevo | `evidencias/G0-preparacion.txt` |
| **G1 — Caja blanca** | Al volver T1 | 0 fallos; `BRANCH_MISSED = 0` para `EvaluadorPrestamo`; ≥ 8 casos con nombre y aserción; tabla de caminos completa | `T1-*.txt`, `T1-caminos.md` |
| **G2 — Caja negra** | Al volver T2 | Los 3 casos obligatorios presentes y conformes con 5.1; ≥ 3 complementarios; cada caso justificado por partición/límite | `T2-*.md`, `T2-caja-negra-junit.txt` |
| **G3 — Coherencia cruzada** | Con ambas evidencias | Los veredictos coinciden con 5.1–5.4; ningún caso de T1/T2 fue reescrito para "hacerlo pasar"; el SUT sigue intacto (`git diff --stat src/`) | `evidencias/G3-coherencia.txt` |
| **G4 — Regresión** | Antes del informe | La suite del proyecto sigue en verde sin base de datos: `JUNIT_EXCLUDE='libreria\.dao\..*' bash test/run-junit-tests.sh` → 0 fallos, incluyendo las pruebas nuevas | `evidencias/G4-regresion.txt` |
| **G5 — Informe** | Al final | `.md` + `.pdf` con las 8 secciones de 11.1, tablas completas, cifras que coinciden con las evidencias y fecha/entorno declarados | `Informe_Caso_Combinado.pdf` |

Si una puerta falla, el orquestador devuelve el trabajo con **una** instrucción concreta (`hc send t1 "…"`), no con un "revisa todo". Máximo dos reintentos por tester; al tercero se entrega con el alcance declarado y el hueco anotado como límite.

---

## 11. Informe final (estructura idéntica a la referencia del caso)

### 11.1. Secciones obligatorias del documento

1. **Planteamiento del problema** — sistema de aprobación de préstamos personales, reglas R1–R5 y el fragmento de código; ubicación del SUT dentro de Librería Brenda y advertencia de que es un ejercicio académico, no uno de los 17 RF.
2. **Consigna de evaluación** — qué se pidió: (1) 3 casos de caja negra con partición de equivalencia y valores límite; (2) caja blanca con el mínimo de casos para 100 % de cobertura de decisiones/ramas, justificando cada camino.
3. **Solución de caja negra** — tabla de clases de equivalencia, valores límite y los casos con su resultado observado.
4. **Solución de caja blanca** — tabla de caminos (los 4 de la consigna) + los 4 casos adicionales que cierran las 14 ramas, con la cobertura JaCoCo real por clase y por rama.
5. **Prueba combinada: matriz de trazabilidad** — fila por caso, columnas: caso, técnica que lo originó, regla(s) R1–R5, rama(s)/camino que ejercita y veredicto. Cierra con un párrafo de lectura: qué cubre cada técnica y qué no (la caja negra puede aprobar un módulo con ramas muertas; la caja blanca puede cubrir el 100 % de ramas de un módulo que incumple una regla de negocio).
6. **Evidencias y trazabilidad** — tabla con archivo, comando que lo produjo, fecha y resultado; enlace relativo a cada archivo de `docs/QA/caso-combinado/evidencias/`.
7. **Conclusiones y límites** — cobertura medida ≠ calidad total; una sola clase; datos ficticios; no se certifica el producto ni se extrapola a los módulos del sistema.
8. **Anexos** — código del SUT, código de las dos suites, CSV de JaCoCo y salida cruda de las ejecuciones.

**Reglas de redacción:** primera persona institucional ("se ejecutó", "se observó"); nunca afirmar resultados no presentes en un archivo de evidencia; fechas reales; sin capturas inventadas; español con tildes; tablas antes que párrafos largos.

### 11.2. De Markdown a PDF (comando verificado en este equipo)

No hay `pandoc` ni LibreOffice instalados; sí hay Microsoft Edge y Chrome. Se usa el motor de impresión de Edge sobre un HTML autocontenido:

```bash
# 1) El orquestador escribe el informe en Markdown (fuente versionable)
#    docs/QA/caso-combinado/Informe_Caso_Combinado.md

# 2) Y su versión imprimible con las mismas tablas y el CSS de la sección 11.3
#    docs/QA/caso-combinado/Informe_Caso_Combinado.html

# 3) Conversión a PDF
"/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
  --headless=new --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$(pwd -W)/docs/QA/caso-combinado/Informe_Caso_Combinado.pdf" \
  "file:///$(pwd -W)/docs/QA/caso-combinado/Informe_Caso_Combinado.html"

ls -l docs/QA/caso-combinado/Informe_Caso_Combinado.pdf
```

`$(pwd -W)` entrega la ruta estilo Windows que Edge necesita en Git Bash. Si `pwd -W` no existe (Linux/macOS), usar `$(pwd)`.

### 11.3. CSS de impresión (evita tablas cortadas y hojas en blanco)

```html
<style>
  @page { size: A4; margin: 16mm 15mm 18mm 15mm; }
  body { font-family: "Segoe UI", Arial, sans-serif; font-size: 10.5pt; line-height: 1.45;
         color: #1d1d1f; margin: 0; }
  h1 { font-size: 17pt; margin: 0 0 4mm; border-bottom: 2px solid #1f4e79; padding-bottom: 2mm; }
  h2 { font-size: 13pt; color: #1f4e79; margin: 7mm 0 2mm; page-break-after: avoid; }
  h3 { font-size: 11pt; margin: 5mm 0 1.5mm; page-break-after: avoid; }
  table { border-collapse: collapse; width: 100%; margin: 2mm 0 4mm; font-size: 9pt;
          page-break-inside: avoid; }
  th, td { border: 0.4pt solid #8a8a8a; padding: 1.6mm 2mm; text-align: left; vertical-align: top; }
  th { background: #e8eef5; }
  code, pre { font-family: Consolas, monospace; font-size: 8.6pt; }
  pre { background: #f5f6f8; border-left: 3px solid #1f4e79; padding: 2.5mm 3mm;
        white-space: pre-wrap; page-break-inside: avoid; }
  .portada { text-align: center; margin-top: 45mm; }
  .seccion { page-break-before: always; }
  footer { font-size: 8pt; color: #666; }
</style>
```

Después de generar el PDF, el orquestador verifica que exista, pese más de 30 KB y abra sin páginas vacías al inicio (`Informe_Caso_Combinado.pdf`, una portada + 6-9 páginas de contenido).

---

## 12. Cierre y checklist de entrega

- [ ] `src/libreria/util/EvaluadorPrestamo.java` creado y compilando aislado
- [ ] `test/libreria/util/EvaluadorPrestamoCajaBlancaTest.java` (≥ 8 casos, 14/14 ramas)
- [ ] `test/libreria/util/EvaluadorPrestamoCajaNegraTest.java` (3 obligatorios + 3 complementarios)
- [ ] Evidencias T1 y T2 en `docs/QA/caso-combinado/evidencias/` con salida real
- [ ] `BITACORA.md` con despachos, esperas y veredictos con hora
- [ ] `Informe_Caso_Combinado.md` con las 8 secciones de 11.1
- [ ] `Informe_Caso_Combinado.pdf` generado con Edge headless y revisado
- [ ] Regresión del proyecto en verde (`run-junit-tests.sh` sin BD)
- [ ] `git status` sin cambios ajenos a los archivos de la actividad

---

## Anexo A — Chuleta de `hc`

```bash
hc ls                                  # terminales vivas (--all incluye terminadas)
hc get t1                              # ficha de una terminal
hc read t1 --lines 200                 # pantalla + historial (para evidencias)
hc send t1 "texto"                     # pegar y Enter (--if idle: solo si está libre)
hc send t1 "texto" --wait --timeout 900 # enviar y esperar ese turno
hc wait t1 --timeout 600               # esperar a que deje de trabajar
hc keys t1 enter                       # confirmar un diálogo
hc interrupt t1                        # detener sin matar
hc put t1 ruta/archivo.md              # dejar un archivo junto al agente
hc file write ruta/x.md < plano.md     # escribir un archivo (--on máquina: en otra)
hc label t1 estado=bloqueado           # etiquetar para seguimiento
hc kill t1                             # terminar el programa de la terminal
hc events                              # flujo de cambios en vivo
```

## Anexo B — Problemas frecuentes

| Síntoma | Causa probable | Salida |
|---|---|---|
| `hc ls` muestra `blocked` | El CLI pide login, permiso o confirmación | `hc attach t1`, resolver a mano, Ctrl+\\ |
| El tester "terminó" pero no hay evidencias | Escribió un resumen sin ejecutar | `hc read t1 --lines 300`, reenviar el paso de ejecución concreto |
| JaCoCo reporta `BRANCH_MISSED > 0` | Faltan casos de subexpresión | Añadir el caso que cierra esa rama y documentarlo (5.4) |
| `javac` falla por `;` vs `:` | Shell distinto de Git Bash | En Linux/macOS usar `:` como separador |
| El PDF sale sin estilos | HTML sin CSS embebido o ruta `file:///` mal formada | Repetir con `$(pwd -W)` y el CSS de 11.3 |
| Un agente empieza a tocar `src/` | Se salió de su rol | `hc interrupt`, `git checkout -- src/`, reenviar el prompt con las reglas |
