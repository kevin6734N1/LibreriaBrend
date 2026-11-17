# Caso Práctico — Prueba Combinada (Caja Negra + Caja Blanca)

**Proyecto:** LibreriaBrend — Calidad y Pruebas de Software (UPN)
**Módulo evaluado:** Sistema de Aprobación de Préstamos Bancarios (`libreria.util.EvaluadorPrestamo`)
**QA responsable de la ejecución:** Kevin David Urbe Bolo
**Fecha de ejecución:** 16/11/2026 · **Versión del informe:** 1.0
**Entorno declarado:** Windows 11 · Git Bash · Java 21.0.12.1 (OpenJDK Microsoft) · JUnit Platform Console 1.11.4 · JaCoCo 0.8.12 · rama `qa/caso-combinado`

---

## 1. Planteamiento del problema

Una entidad financiera ha desarrollado un módulo de software encargado de evaluar de forma automática si un cliente califica para un préstamo personal. Las reglas de negocio del módulo son:

| Id | Regla |
|---|---|
| **R1** | Rango de edad: el solicitante debe tener entre **21 y 65 años** (ambos inclusive) |
| **R2** | Ingreso mensual: el ingreso mensual neto debe ser **mayor o igual a $1,500** |
| **R3** | Historial crediticio: el puntaje crediticio debe ser **superior a 600 puntos** |
| **R4** | Excepción interna: si el cliente tiene **más de 5 años de antigüedad** en el banco y **no posee deudas vencidas**, el sistema aprueba el préstamo automáticamente aunque su ingreso sea de **al menos $1,200** |
| **R5** | Cualquier otro caso: **"Rechazado"** |

Fragmento de código simplificado del enunciado (Python):

```python
def evaluar_prestamo(edad, ingreso, puntaje, antiguedad, tiene_deudas):
    if 21 <= edad <= 65 and puntaje > 600:
        if ingreso >= 1500:
            return "Aprobado"
        elif antiguedad > 5 and not tiene_deudas and ingreso >= 1200:
            return "Aprobado por antigüedad"
    return "Rechazado"
```

**Ubicación del SUT dentro de Librería Brenda.** El módulo bajo prueba se materializó como `src/libreria/util/EvaluadorPrestamo.java`: traducción fiel a Java 21 del fragmento anterior, con la firma `public static String evaluar(int edad, double ingreso, int puntaje, int antiguedad, boolean tieneDeudas)` y el contrato de devolver exactamente `"Aprobado"`, `"Aprobado por antigüedad"` o `"Rechazado"`, sin validaciones extra, sin `null` y sin excepciones.

**Advertencia de alcance.** `EvaluadorPrestamo` es un **ejercicio académico** del curso de Calidad y Pruebas de Software (mismo criterio que `libreria.util.CalculadoraMorosidad`): no forma parte de los 17 requisitos funcionales implementados de Librería Brenda ni se integra con Servlets, DAO, base de datos ni interfaz. Los datos manejados son ficticios.

## 2. Consigna de evaluación

Como ingeniero de calidad (QA), se pidió diseñar una estrategia de pruebas combinada para validar este módulo:

1. **Pruebas de Caja Negra:** definir 3 casos de prueba utilizando las técnicas de **Partición de Equivalencia** y **Análisis de Valores Límite**, basándose únicamente en las reglas de negocio.
2. **Pruebas de Caja Blanca:** analizar el código fuente y determinar **cuántos casos de prueba se necesitan como mínimo** para lograr una **cobertura de decisiones (ramas) del 100 %**, justificando cada camino elegido.

**Cómo se ejecutó la consigna.** La evaluación se orquestó con una malla de dos testers independientes que trabajaron por caminos separados y coincidieron en el veredicto: el **Tester 2 (caja negra, Antigravity)** diseñó sus casos únicamente desde las reglas R1–R5 del enunciado, sin leer el fuente del SUT antes de tener su tabla de casos; el **Tester 1 (caja blanca)** analizó la estructura de decisiones del código y construyó la suite mínima de cobertura de ramas sin leer los casos del Tester 2. El orquestador (Vibe CLI) preparó el SUT, despachó ambos encargos, validó cada puerta de calidad y redactó este informe. El detalle de despachos, esperas e incidencias queda en `BITACORA.md`.

## 3. Solución de caja negra

Diseño del Tester 2 **desde la especificación** (reglas R1–R5), sin mirar el código. La suite se implementó como tabla ejecutable (`@ParameterizedTest` + `@CsvSource`): cada fila es un caso entrada → salida esperada.

### 3.1 Clases de equivalencia identificadas

| Variable | Partición | Clase | Rango / valores representativos |
|---|---|---|---|
| Edad | Válida | CE1-V | 21 ≤ edad ≤ 65 (ej. 30, 35, 40) |
| | Inválida (baja) | CE1-I1 | edad < 21 (ej. 18, 20) |
| | Inválida (alta) | CE1-I2 | edad > 65 (ej. 66, 70) |
| Ingreso | Válida estándar | CE2-V1 | ingreso ≥ 1500 (ej. 1500, 2000) |
| | Válida por excepción | CE2-V2 | 1200 ≤ ingreso < 1500 (ej. 1200, 1300) |
| | Inválida | CE2-I | ingreso < 1200 (ej. 1100, 1199) |
| Puntaje | Válida | CE3-V | puntaje > 600, es decir ≥ 601 (ej. 601, 650, 750) |
| | Inválida | CE3-I | puntaje ≤ 600 (ej. 600, 500) |
| Antigüedad | Válida (excepción) | CE4-V | antigüedad > 5, es decir ≥ 6 (ej. 6, 10) |
| | Inválida (excepción) | CE4-I | antigüedad ≤ 5 (ej. 0, 1, 5) |
| Deudas | Válida (excepción) | CE5-V | `false` (sin deudas vencidas) |
| | Inválida (excepción) | CE5-I | `true` (con deudas vencidas) |

### 3.2 Valores límite analizados

| Variable | Frontera | Valor | Clasificación | Justificación |
|---|---|---|---|---|
| Edad | Inferior | 20 | Inválido (CE1-I1) | Inmediatamente por debajo del mínimo de 21 años: debe rechazar |
| | Inferior | 21 | Válido (CE1-V) | Límite inferior exacto inclusivo de R1 |
| | Superior | 65 | Válido (CE1-V) | Límite superior exacto inclusivo de R1 |
| | Superior | 66 | Inválido (CE1-I2) | Inmediatamente por encima del máximo de 65 años: debe rechazar |
| Ingreso | Estándar | 1500.0 | Válido (CE2-V1) | Umbral mínimo exacto de R2 |
| | Excepción | 1200.0 | Válido (CE2-V2) | Umbral mínimo exacto de la excepción R4 |
| | Excepción | 1199.0 | Inválido (CE2-I) | Inmediatamente inferior al piso de $1,200: rechazo absoluto |
| Puntaje | Frontera estricta | 600 | Inválido (CE3-I) | R3 exige estrictamente > 600: el valor exacto no califica |
| | Frontera estricta | 601 | Válido (CE3-V) | Primer entero que satisface puntaje > 600 |
| Antigüedad | Frontera excepción | 5 | Inválido para R4 (CE4-I) | R4 exige "más de 5 años": 5 exactos no califican |
| | Frontera excepción | 6 | Válido para R4 (CE4-V) | Primer entero que supera estrictamente los 5 años |
| Deudas | Dominio discreto | false / true | Válido / Inválido (CE5) | Habilita / bloquea la vía de excepción R4 |

### 3.3 Casos de prueba ejecutados y resultado observado

| # | Técnica | Edad | Ingreso | Puntaje | Antigüedad | Deudas | Esperado | Observado | Estado |
|---|---|:---:|:---:|:---:|:---:|:---:|---|---|:---:|
| 1 | BVA: frontera inferior válida (edad e ingreso) | 21 | 1500.0 | 601 | 1 | false | Aprobado | Aprobado | CONFORME |
| 2 | BVA: frontera superior inválida (edad > 65) | 66 | 2000.0 | 750 | 2 | false | Rechazado | Rechazado | CONFORME |
| 3 | EP inválida / BVA: puntaje en frontera (≤ 600) | 35 | 1800.0 | 600 | 0 | false | Rechazado | Rechazado | CONFORME |
| 4 | BVA: frontera inferior inválida (edad < 21) | 20 | 2000.0 | 700 | 3 | false | Rechazado | Rechazado | CONFORME |
| 5 | BVA: límite inferior de la excepción (R4) | 40 | 1200.0 | 650 | 6 | false | Aprobado por antigüedad | Aprobado por antigüedad | CONFORME |
| 6 | EP inválida: excepción con deuda vencida (R4) | 40 | 1200.0 | 650 | 6 | true | Rechazado | Rechazado | CONFORME |

Los casos 1–3 son los obligatorios de la consigna (frontera inferior válida, frontera superior inválida y partición inválida); los casos 4–6 son complementarios del propio diseño del Tester 2, cada uno justificado por partición o frontera en `evidencias/T2-casos.md`.

**Ejecución real:** JUnit Platform Console 1.11.4 reportó `6 tests found`, `6 tests successful`, `0 tests failed` (166 ms). Hallazgos: **0** — el módulo reprodujo la especificación en los 6 casos. Veredicto del Tester 2: **CUMPLE**.

## 4. Solución de caja blanca

Análisis del Tester 1 **sobre la estructura interna** del SUT, sin leer los casos del Tester 2.

### 4.1 Estructura de decisiones del SUT

```java
if (edad >= 21 && edad <= 65 && puntaje > 600) {        // D1: 3 condiciones -> 6 ramas
    if (ingreso >= 1500) {                              // D2: 1 condición  -> 2 ramas
        return "Aprobado";
    } else if (antiguedad > 5 && !tieneDeudas && ingreso >= 1200) {  // D3: 3 condiciones -> 6 ramas
        return "Aprobado por antigüedad";
    }
}
return "Rechazado";
```

| Decisión | Condiciones (subexpresiones) | Saltos condicionales | Ramas |
|---|---|:---:|:---:|
| D1 (`if` externo) | `edad >= 21`, `edad <= 65`, `puntaje > 600` | 3 | 6 |
| D2 (`if` interno) | `ingreso >= 1500` | 1 | 2 |
| D3 (`else if`) | `antiguedad > 5`, `!tieneDeudas`, `ingreso >= 1200` | 3 | 6 |
| **Total** | 7 condiciones | **7** | **14** |

### 4.2 Caminos a nivel de decisión (los 4 de la consigna)

| Camino | Recorrido | Salida |
|---|---|---|
| C1 | D1 falso | Rechazado |
| C2 | D1 verdadero + D2 verdadero | Aprobado |
| C3 | D1 verdadero + D2 falso + D3 verdadero | Aprobado por antigüedad |
| C4 | D1 verdadero + D2 falso + D3 falso | Rechazado |

### 4.3 Por qué 4 caminos no bastan: mínimo de 8 casos para el 100 % de ramas

JaCoCo mide **ramas de subexpresión** (cada condición de una expresión `&&` es un salto condicional con dos resultados), no solo el resultado de la decisión completa. Para cubrir las 14 ramas, cada una de las 7 condiciones debe evaluarse **verdadera en al menos un caso y falsa en al menos otro**:

- Las tres salidas falsas de D1 (`edad < 21`, `edad > 65`, `puntaje ≤ 600`) son **mutuamente excluyentes**: cada una exige su propio caso → 3 casos.
- Las cuatro salidas de D3 (`antiguedad ≤ 5`, `tieneDeudas`, `ingreso < 1200`, o todas verdaderas) también son mutuamente excluyentes y solo se alcanzan con D2 falso → 4 casos.
- D2 verdadero (`ingreso ≥ 1500`) no puede darse en ninguno de los 4 casos anteriores → 1 caso adicional.

**Mínimo: 3 + 4 + 1 = 8 casos.** Los 4 caminos de la consigna cubren el nivel decisión; los 4 casos adicionales cierran las ramas de subexpresión que el nivel decisión deja fuera.

### 4.4 Tabla de caminos ejecutados (8 casos)

Entrada en el orden `(edad, ingreso, puntaje, antigüedad, tieneDeudas)`.

| Camino | Condiciones evaluadas | Entrada | Salida esperada | Salida observada | Rama(s) que cubre |
|---|---|---|---|---|---|
| 1 | D1: `edad >= 21` falsa (cortocircuito) | (18, 2000.0, 700, 6, false) | Rechazado | Rechazado | `edad >= 21` → falsa |
| 2 | D1: `edad <= 65` falsa | (66, 2000.0, 750, 2, false) | Rechazado | Rechazado | `edad >= 21` → V; `edad <= 65` → F |
| 3 | D1: `puntaje > 600` falsa (frontera 600) | (35, 1800.0, 600, 0, false) | Rechazado | Rechazado | `edad <= 65` → V; `puntaje > 600` → F |
| 4 | D1 completa V; D2: `ingreso >= 1500` V | (30, 1600.0, 650, 1, false) | Aprobado | Aprobado | `puntaje > 600` → V; `ingreso >= 1500` → V |
| 5 | D2 F; D3: `antiguedad > 5` falsa | (40, 1300.0, 650, 2, false) | Rechazado | Rechazado | `ingreso >= 1500` → F; `antiguedad > 5` → F |
| 6 | D3: `!tieneDeudas` falsa | (40, 1300.0, 650, 6, true) | Rechazado | Rechazado | `antiguedad > 5` → V; `!tieneDeudas` → F |
| 7 | D3: `ingreso >= 1200` falsa | (40, 1100.0, 650, 6, false) | Rechazado | Rechazado | `!tieneDeudas` → V; `ingreso >= 1200` → F |
| 8 | D3 completa verdadera (excepción R4) | (40, 1300.0, 650, 6, false) | Aprobado por antigüedad | Aprobado por antigüedad | `ingreso >= 1200` → V |

Trazabilidad con la consigna: C1 = camino 1, C2 = camino 4, C3 = camino 8, C4 = camino 5. Cada camino es un método de prueba con nombre descriptivo y aserción `assertEquals` cuyo mensaje cita la regla de negocio ejercitada (R1–R5). Sin `assertTrue(true)`, sin pruebas sin aserción y sin entradas duplicadas.

### 4.5 Cobertura medida con JaCoCo (real, no estimada)

Ejecución con `-javaagent` (JaCoCo 0.8.12) y reporte CSV sobre la clase:

```csv
GROUP,PACKAGE,CLASS,INSTRUCTION_MISSED,INSTRUCTION_COVERED,BRANCH_MISSED,BRANCH_COVERED,LINE_MISSED,LINE_COVERED,COMPLEXITY_MISSED,COMPLEXITY_COVERED,METHOD_MISSED,METHOD_COVERED
JaCoCo Coverage Report,libreria.util,EvaluadorPrestamo,0,28,0,14,0,6,0,8,0,1
```

| Métrica (clase `libreria.util.EvaluadorPrestamo`) | Cubierto | Perdido | Total | % |
|---|:---:|:---:|:---:|:---:|
| **Ramas (BRANCH)** | **14** | **0** | **14** | **100 %** |
| Instrucciones | 28 | 0 | 28 | 100 % |
| Líneas | 6 | 0 | 6 | 100 % |
| Métodos | 1 | 0 | 1 | 100 % |

**Ejecución real:** JUnit reportó `8 tests found`, `8 tests successful`, `0 tests failed` (90 ms). El orquestador reprodujo la medición desde el `jacoco.exec` generado por el Tester 1 y obtuvo la fila CSV idéntica. Veredicto del Tester 1: **CUMPLE**.

## 5. Prueba combinada: matriz de trazabilidad

Fila por caso de las dos suites; ninguna prueba fue reescrita para "hacerla pasar" y el SUT permaneció intacto durante toda la actividad (`git diff --stat src/` vacío).

| Caso | Técnica que lo originó | Regla(s) | Rama(s) / camino que ejercita | Veredicto |
|---|---|---|---|:---:|
| N1 (21, 1500, 601, 1, F) | Caja negra — BVA frontera inferior válida | R1, R2, R3 | D1 V + D2 V (camino C2) | CONFORME |
| N2 (66, 2000, 750, 2, F) | Caja negra — BVA frontera superior inválida | R1, R5 | D1 F por `edad <= 65` falsa | CONFORME |
| N3 (35, 1800, 600, 0, F) | Caja negra — EP/BVA frontera de puntaje | R3, R5 | D1 F por `puntaje > 600` falsa | CONFORME |
| N4 (20, 2000, 700, 3, F) | Caja negra — BVA frontera inferior inválida | R1, R5 | D1 F por `edad >= 21` falsa | CONFORME |
| N5 (40, 1200, 650, 6, F) | Caja negra — BVA límite de la excepción | R4 | D1 V + D2 F + D3 V (camino C3) | CONFORME |
| N6 (40, 1200, 650, 6, T) | Caja negra — EP excepción bloqueada por deuda | R4, R5 | D1 V + D2 F + D3 F (`!tieneDeudas` falsa) | CONFORME |
| B1 (18, 2000, 700, 6, F) | Caja blanca — camino 1 (C1) | R1, R5 | `edad >= 21` falsa | OK |
| B2 (66, 2000, 750, 2, F) | Caja blanca — camino 2 | R1, R5 | `edad >= 21` V; `edad <= 65` F | OK |
| B3 (35, 1800, 600, 0, F) | Caja blanca — camino 3 | R3, R5 | `edad <= 65` V; `puntaje > 600` F | OK |
| B4 (30, 1600, 650, 1, F) | Caja blanca — camino 4 (C2) | R1, R2, R3 | `puntaje > 600` V; `ingreso >= 1500` V | OK |
| B5 (40, 1300, 650, 2, F) | Caja blanca — camino 5 (C4) | R4, R5 | `ingreso >= 1500` F; `antiguedad > 5` F | OK |
| B6 (40, 1300, 650, 6, T) | Caja blanca — camino 6 | R4, R5 | `antiguedad > 5` V; `!tieneDeudas` F | OK |
| B7 (40, 1100, 650, 6, F) | Caja blanca — camino 7 | R4, R5 | `!tieneDeudas` V; `ingreso >= 1200` F | OK |
| B8 (40, 1300, 650, 6, F) | Caja blanca — camino 8 (C3) | R4 | `ingreso >= 1200` V | OK |

**Lectura de la matriz.** La caja negra respondió "¿el módulo cumple las reglas de negocio para las fronteras y particiones de la especificación?" y la caja blanca respondió "¿la estructura interna queda ejercitada al 100 %?". Las dos técnicas llegaron por caminos independientes (el Tester 2 no leyó el fuente antes de diseñar; el Tester 1 no leyó los casos de caja negra) y coincidieron en el veredicto: 14 casos ejecutados, 0 fallos, 0 hallazgos. Ninguna técnica sustituye a la otra: la caja negra puede dar por bueno un módulo con ramas muertas (código que nunca se ejecuta pero que sus casos no visitan), y la caja blanca puede cubrir el 100 % de ramas de un módulo que incumple una regla de negocio (las ramas estarían ejercitadas, pero con salidas equivocadas). Combinadas, la caja negra aporta el oráculo correcto desde la especificación y la caja blanca garantiza que ninguna decisión del código quedó sin probar.

## 6. Evidencias y trazabilidad

| Archivo (en `docs/QA/caso-combinado/`) | Comando / origen que lo produjo | Fecha | Resultado |
|---|---|---|---|
| `evidencias/G0-preparacion.txt` | Preparación del orquestador (rama, jars, SUT compilado aislado) | 16/11/2026 19:47 | G0 superada |
| `prompts/01-tester-caja-blanca.md` | Encargo del Tester 1 (materializado por el orquestador) | 16/11/2026 19:51 | Despachado |
| `prompts/02-tester-caja-negra.md` | Encargo del Tester 2 (materializado por el orquestador) | 16/11/2026 19:51 | Despachado |
| `evidencias/T2-compilacion.txt` | `javac -encoding UTF-8 -cp $JUNIT -d out/caso-cn ...` | 16/11/2026 19:50 | 0 errores |
| `evidencias/T2-clases-equivalencia.md` | Diseño del Tester 2 (particiones y fronteras) | 16/11/2026 19:50 | Tabla completa |
| `evidencias/T2-caja-negra-junit.txt` | `java -jar $JUNIT -cp out/caso-cn --select-class ...CajaNegraTest` | 16/11/2026 19:52 | 6/6 exitosos, 0 fallos |
| `evidencias/T2-caja-negra-junit-utf8.txt` | Copia legible del anterior (UTF-16LE → UTF-8, contenido íntegro) | 16/11/2026 19:57 | 6/6 exitosos |
| `evidencias/T2-casos.md` | Matriz de casos del Tester 2 | 16/11/2026 19:52 | 6/6 conformes, 0 hallazgos |
| `evidencias/T1-compilacion.txt` | `javac -encoding UTF-8 -cp $JUNIT -d out/caso-cb ...` | 16/11/2026 19:58 | 0 errores |
| `evidencias/T1-caja-blanca-junit.txt` | `java -jar $JUNIT -cp out/caso-cb --select-class ...CajaBlancaTest` | 16/11/2026 19:58 | 8/8 exitosos, 0 fallos |
| `evidencias/T1-jacoco-ramas.txt` | `java -jar out/tools/jacococli.jar report out/caso-cb/jacoco.exec --classfiles ... --csv ...` | 16/11/2026 19:58 | BRANCH 14/14, MISSED 0 |
| `evidencias/T1-caminos.md` | Tabla de caminos del Tester 1 | 16/11/2026 19:59 | 8 caminos, 14 ramas |
| `evidencias/G3-coherencia.txt` | Validación cruzada del orquestador | 16/11/2026 20:05 | G3 superada |
| `evidencias/G4-regresion.txt` | `JUNIT_EXCLUDE='libreria\.dao\..*' bash test/run-junit-tests.sh` | 16/11/2026 20:03 | 94/98; 4 fallos por BD caída (pool) |
| `evidencias/G4-regresion-sin-bd.txt` | `JUNIT_EXCLUDE='libreria\.dao\..*\|libreria\.util\.ConexionBDPoolTest' bash test/run-junit-tests.sh` | 16/11/2026 20:06 | 94/94, 0 fallos |
| `evidencias/G4-veredicto.txt` | Análisis del orquestador de las dos corridas | 16/11/2026 20:06 | G4 superada (salvedad ambiental) |
| `BITACORA.md` | Registro de despachos, esperas, veredictos e incidencias | 16/11/2026 | Continua |

**Regresión del proyecto (G4).** La suite completa se ejecutó sin base de datos. En la corrida con el comando estándar, 94 de 98 pruebas pasaron; los 4 fallos corresponden a `libreria.util.ConexionBDPoolTest` (Sprint 4), que exige un MySQL/MariaDB vivo y en este entorno no había ningún proceso escuchando en 3306/3307. Es una condición ambiental preexistente: la actividad no modificó ningún archivo rastreado del proyecto. Excluida esa clase dependiente de BD, la suite quedó en verde con las 14 pruebas nuevas incluidas (94/94, 0 fallos).

## 7. Conclusiones y límites

**Conclusiones.**

1. El módulo `EvaluadorPrestamo` reprodujo las reglas R1–R5 en los **14 casos ejecutados** (6 de caja negra + 8 de caja blanca): 0 fallos, 0 hallazgos.
2. La suite de caja blanca alcanzó **100 % de cobertura de ramas medida** (14/14, `BRANCH_MISSED = 0`) con el mínimo de 8 casos justificado por estructura de decisiones; la de caja negra validó las fronteras y particiones de la especificación con 6 casos justificados por técnica.
3. Las dos técnicas, aplicadas por agentes independientes, **coincidieron en el veredicto**: el comportamiento observable cumple la especificación y la estructura interna queda totalmente ejercitada.
4. La combinación aporta lo que ninguna técnica da sola: la caja negra provee el oráculo desde la regla de negocio; la caja blanca garantiza que ninguna decisión del código quedó sin probar.

**Límites del alcance.**

- La cobertura medida no es calidad total: certifica que se ejecutaron las 14 ramas de esta clase, no que el módulo sea correcto para entradas no probadas ni para requisitos no especificados.
- Se evaluó **una sola clase** con datos ficticios, como ejercicio académico: no forma parte de los 17 RF de Librería Brenda y no se integra con Servlets, DAO ni base de datos.
- Este informe **no certifica el producto** Librería Brenda ni sus módulos reales; sus conclusiones no se extrapolan a otros componentes del sistema.
- Incidencia de la malla documentada en `BITACORA.md`: el CLI asignado originalmente a la caja blanca (MiniMax Code) quedó fuera de servicio por caída persistente de su proveedor de modelo (error 50113), por lo que el encargo se reasignó a un agente Vibe con el mismo prompt versionado y las mismas reglas de independencia; los entregables y puertas de calidad no cambiaron.
- Salvedad ambiental de la regresión: las 4 pruebas del pool de conexiones requieren MariaDB levantado; quedaron fuera del verde de esta corrida por ausencia de BD, no por la actividad.

## 8. Anexos

### Anexo A — Código del SUT (`src/libreria/util/EvaluadorPrestamo.java`)

```java
package libreria.util;

/**
 * Evaluador de aprobación de préstamos personales.
 *
 * Ejercicio académico del caso práctico "Prueba Combinada (Caja Negra +
 * Caja Blanca)" de Calidad y Pruebas de Software (UPN): traducción fiel
 * a Java 21 del fragmento Python del enunciado. Función independiente:
 * no forma parte de los 17 requisitos funcionales implementados de
 * Librería Brenda ni se integra con Servlets, DAO, base de datos ni
 * interfaz.
 *
 * Reglas de negocio del enunciado:
 * R1: edad del solicitante entre 21 y 65 años, ambos inclusive.
 * R2: ingreso mensual neto >= 1500.
 * R3: puntaje crediticio > 600.
 * R4: excepción interna: antigüedad > 5 años y sin deudas vencidas
 *     aprueba aunque el ingreso sea >= 1200.
 * R5: cualquier otro caso: "Rechazado".
 */
public final class EvaluadorPrestamo {

    private EvaluadorPrestamo() {
        // clase utilitaria, no se instancia
    }

    /**
     * Evalúa si un solicitante califica para un préstamo personal.
     * Devuelve exactamente "Aprobado", "Aprobado por antigüedad" o
     * "Rechazado": sin validaciones extra, sin null y sin excepciones.
     */
    public static String evaluar(int edad, double ingreso, int puntaje, int antiguedad, boolean tieneDeudas) {
        if (edad >= 21 && edad <= 65 && puntaje > 600) {
            if (ingreso >= 1500) {
                return "Aprobado";
            } else if (antiguedad > 5 && !tieneDeudas && ingreso >= 1200) {
                return "Aprobado por antigüedad";
            }
        }
        return "Rechazado";
    }
}
```

### Anexo B — Suite de caja blanca (`test/libreria/util/EvaluadorPrestamoCajaBlancaTest.java`)

```java
package libreria.util;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Pruebas de CAJA BLANCA (Tester 1) para
 * {@link EvaluadorPrestamo#evaluar(int, double, int, int, boolean)}.
 *
 * Objetivo: 100 % de cobertura de ramas medida con JaCoCo 0.8.12 sobre la clase
 * {@code libreria.util.EvaluadorPrestamo}.
 *
 * Estructura de decisiones del SUT (7 saltos condicionales = 14 ramas):
 *  - D1: if (edad >= 21 && edad <= 65 && puntaje > 600)  -> 3 condiciones -> 6 ramas
 *  - D2: if (ingreso >= 1500)                            -> 1 condición  -> 2 ramas
 *  - D3: else if (antiguedad > 5 && !tieneDeudas && ingreso >= 1200) -> 3 condiciones -> 6 ramas
 *
 * Caminos a nivel de decisión (los 4 de la consigna):
 *  1. C1: D1 falso -> "Rechazado"
 *  2. C2: D1 verdadero + D2 verdadero -> "Aprobado"
 *  3. C3: D1 verdadero + D2 falso + D3 verdadero -> "Aprobado por antigüedad"
 *  4. C4: D1 verdadero + D2 falso + D3 falso -> "Rechazado"
 *
 * Por qué 4 no bastan y hacen falta 8 casos: JaCoCo mide ramas de subexpresión,
 * no solo el resultado de la decisión. Cada una de las 7 condiciones debe
 * evaluarse verdadera en al menos un caso y falsa en al menos otro. Las tres
 * salidas falsas de D1 son mutuamente excluyentes (3 casos), las cuatro salidas
 * de D3 también lo son (4 casos, todos con D2 falso) y D2 verdadero exige un
 * caso propio: mínimo 3 + 4 + 1 = 8 casos para cerrar las 14 ramas.
 */
class EvaluadorPrestamoCajaBlancaTest {

    @Test
    @DisplayName("Camino 1: primer if falso por edad < 21 -> Rechazado (R1)")
    void camino1_primerIfFalsoPorEdadInferior_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(18, 2000.0, 700, 6, false);
        assertEquals("Rechazado", resultado,
                "R1: con edad=18 (< 21) la primera condicion del if externo es falsa"
                        + " y el modulo debe rechazar sin evaluar ingreso ni puntaje");
    }

    @Test
    @DisplayName("Camino 2: primer if falso por edad > 65 -> Rechazado (R1)")
    void camino2_primerIfFalsoPorEdadSuperior_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(66, 2000.0, 750, 2, false);
        assertEquals("Rechazado", resultado,
                "R1: con edad=66 (> 65) la segunda condicion del if externo es falsa"
                        + " y el modulo debe rechazar aunque ingreso y puntaje sean validos");
    }

    @Test
    @DisplayName("Camino 3: primer if falso por puntaje = 600 -> Rechazado (R3)")
    void camino3_primerIfFalsoPorPuntaje_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(35, 1800.0, 600, 0, false);
        assertEquals("Rechazado", resultado,
                "R3: con puntaje=600 (no > 600) la tercera condicion del if externo es falsa"
                        + " y el modulo debe rechazar aunque la edad y el ingreso sean validos");
    }

    @Test
    @DisplayName("Camino 4: if externo verdadero + ingreso >= 1500 -> Aprobado (R1+R2+R3)")
    void camino4_ingresoSuficiente_retornaAprobado() {
        String resultado = EvaluadorPrestamo.evaluar(30, 1600.0, 650, 1, false);
        assertEquals("Aprobado", resultado,
                "R1+R2+R3: edad=30 en [21,65], ingreso=1600 >= 1500 y puntaje=650 > 600"
                        + " cumplen las tres reglas y el modulo debe aprobar");
    }

    @Test
    @DisplayName("Camino 5: ingreso < 1500 + antigüedad <= 5 -> Rechazado (R4 no aplica)")
    void camino5_ingresoBajoAntiguedadCorta_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(40, 1300.0, 650, 2, false);
        assertEquals("Rechazado", resultado,
                "R4/R5: con ingreso=1300 (< 1500) y antigüedad=2 (<= 5) la excepcion interna"
                        + " no aplica y el modulo debe rechazar");
    }

    @Test
    @DisplayName("Camino 6: ingreso < 1500 + deudas vencidas -> Rechazado (R4 bloqueada por deudas)")
    void camino6_conDeudasVencidas_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(40, 1300.0, 650, 6, true);
        assertEquals("Rechazado", resultado,
                "R4: con antigüedad=6 (> 5) pero tieneDeudas=true la segunda condicion"
                        + " del elif es falsa y el modulo debe rechazar");
    }

    @Test
    @DisplayName("Camino 7: ingreso < 1200 con antigüedad suficiente -> Rechazado (R4 exige >= 1200)")
    void camino7_ingresoDebajoDe1200_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(40, 1100.0, 650, 6, false);
        assertEquals("Rechazado", resultado,
                "R4: con antigüedad=6 y sin deudas pero ingreso=1100 (< 1200) la tercera"
                        + " condicion del elif es falsa y el modulo debe rechazar");
    }

    @Test
    @DisplayName("Camino 8: excepción interna (antigüedad > 5, sin deudas, ingreso >= 1200) -> Aprobado por antigüedad (R4)")
    void camino8_excepcionAntiguedad_retornaAprobadoPorAntiguedad() {
        String resultado = EvaluadorPrestamo.evaluar(40, 1300.0, 650, 6, false);
        assertEquals("Aprobado por antigüedad", resultado,
                "R4: con antigüedad=6 (> 5), sin deudas vencidas e ingreso=1300 (>= 1200)"
                        + " la excepcion interna aprueba aunque el ingreso no llegue a 1500");
    }
}
```

### Anexo C — Suite de caja negra (`test/libreria/util/EvaluadorPrestamoCajaNegraTest.java`)

```java
package libreria.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Pruebas de Caja Negra para {@link EvaluadorPrestamo}.
 *
 * Diseñadas a partir de la especificación funcional (Reglas R1 a R5)
 * utilizando las técnicas de Partición de Equivalencia (EP) y
 * Análisis de Valores Límite (BVA).
 */
public class EvaluadorPrestamoCajaNegraTest {

    @ParameterizedTest(name = "Caso {0} [{1}]: edad={2}, ingreso={3}, puntaje={4}, antiguedad={5}, deudas={6} -> esperado={7}")
    @CsvSource(delimiter = '|', textBlock = """
        1 | BVA: Frontera inferior valida (edad e ingreso) | 21 | 1500.0 | 601 | 1 | false | Aprobado
        2 | BVA: Frontera superior invalida (edad > 65)    | 66 | 2000.0 | 750 | 2 | false | Rechazado
        3 | EP invalida / BVA: Puntaje en frontera (<=600) | 35 | 1800.0 | 600 | 0 | false | Rechazado
        4 | BVA: Frontera inferior invalida (edad < 21)    | 20 | 2000.0 | 700 | 3 | false | Rechazado
        5 | BVA: Limite inferior de excepcion (R4)         | 40 | 1200.0 | 650 | 6 | false | Aprobado por antigüedad
        6 | EP invalida: Excepcion con deuda vencida (R4)  | 40 | 1200.0 | 650 | 6 | true  | Rechazado
        """)
    @DisplayName("Tabla de decisiones de Caja Negra: Equivalencia + Valores Límite")
    void testEvaluarPrestamoCajaNegra(
            int caso,
            String tecnica,
            int edad,
            double ingreso,
            int puntaje,
            int antiguedad,
            boolean tieneDeudas,
            String resultadoEsperado) {

        String resultadoObtenido = EvaluadorPrestamo.evaluar(edad, ingreso, puntaje, antiguedad, tieneDeudas);
        assertEquals(resultadoEsperado, resultadoObtenido,
                () -> "Discrepancia en Caso " + caso + " (" + tecnica + "): esperado='"
                        + resultadoEsperado + "', obtenido='" + resultadoObtenido + "'");
    }
}
```

### Anexo D — CSV de JaCoCo (fila de la clase, salida real)

```csv
GROUP,PACKAGE,CLASS,INSTRUCTION_MISSED,INSTRUCTION_COVERED,BRANCH_MISSED,BRANCH_COVERED,LINE_MISSED,LINE_COVERED,COMPLEXITY_MISSED,COMPLEXITY_COVERED,METHOD_MISSED,METHOD_COVERED
JaCoCo Coverage Report,libreria.util,EvaluadorPrestamo,0,28,0,14,0,6,0,8,0,1
```

### Anexo E — Salida cruda de la ejecución de caja blanca (JUnit)

```text
╷
├─ JUnit Platform Suite ✔
├─ JUnit Jupiter ✔
│  └─ EvaluadorPrestamoCajaBlancaTest ✔
│     ├─ Camino 6: ingreso < 1500 + deudas vencidas -> Rechazado (R4 bloqueada por deudas... ✔
│     ├─ Camino 1: primer if falso por edad < 21 -> Rechazado (R1) ✔
│     ├─ Camino 5: ingreso < 1500 + antigüedad <= 5 -> Rechazado (R4 no aplica) ✔
│     ├─ Camino 2: primer if falso por edad > 65 -> Rechazado (R1) ✔
│     ├─ Camino 3: primer if falso por puntaje = 600 -> Rechazado (R3) ✔
│     ├─ Camino 8: excepción interna (antigüedad > 5, sin deudas, ingreso >= 1200) -> Apr... ✔
│     ├─ Camino 4: if externo verdadero + ingreso >= 1500 -> Aprobado (R1+R2+R3) ✔
│     └─ Camino 7: ingreso < 1200 con antigüedad suficiente -> Rechazado (R4 exige >= 120... ✔
└─ JUnit Vintage ✔

Test run finished after 90 ms
[         4 containers found      ]
[         0 containers skipped    ]
[         4 containers started    ]
[         0 containers aborted    ]
[         4 containers successful ]
[         0 containers failed     ]
[         8 tests found           ]
[         0 tests skipped         ]
[         8 tests started         ]
[         0 tests aborted         ]
[         8 tests successful      ]
[         0 tests failed          ]
```

### Anexo F — Salida cruda de la ejecución de caja negra (JUnit)

```text
╷
├─ JUnit Platform Suite ✔
├─ JUnit Jupiter ✔
│  └─ EvaluadorPrestamoCajaNegraTest ✔
│     └─ Tabla de decisiones de Caja Negra: Equivalencia + Valores Límite ✔
│        ├─ Caso 1 [BVA: Frontera inferior valida (edad e ingreso)]: edad=21, ingreso=1500.0... ✔
│        ├─ Caso 2 [BVA: Frontera superior invalida (edad > 65)]: edad=66, ingreso=2000.0, p... ✔
│        ├─ Caso 3 [EP invalida / BVA: Puntaje en frontera (<=600)]: edad=35, ingreso=1800.0... ✔
│        ├─ Caso 4 [BVA: Frontera inferior invalida (edad < 21)]: edad=20, ingreso=2000.0, p... ✔
│        ├─ Caso 5 [BVA: Limite inferior de excepcion (R4)]: edad=40, ingreso=1200.0, puntaj... ✔
│        └─ Caso 6 [EP invalida: Excepcion con deuda vencida (R4)]: edad=40, ingreso=1200.0,... ✔
└─ JUnit Vintage ✔
Test run finished after 166 ms
[         5 containers found      ]
[         0 containers skipped    ]
[         5 containers started    ]
[         0 containers aborted    ]
[         5 containers successful ]
[         0 containers failed     ]
[         6 tests found           ]
[         0 tests skipped         ]
[         6 tests started         ]
[         0 tests aborted         ]
[         6 tests successful      ]
[         0 tests failed          ]
```
