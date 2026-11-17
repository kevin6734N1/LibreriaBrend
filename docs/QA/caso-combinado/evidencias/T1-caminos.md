# T1 — Caja blanca: tabla de caminos de `EvaluadorPrestamo.evaluar(...)`

**SUT:** `src/libreria/util/EvaluadorPrestamo.java` (intacto: no se modificó ninguna clase de producción)
**Suite:** `test/libreria/util/EvaluadorPrestamoCajaBlancaTest.java` (JUnit 5, 8 métodos de prueba, uno por camino)
**Rama:** `qa/caso-combinado` · **Java:** 21.0.12.1 · **JUnit:** 1.11.4 · **JaCoCo:** 0.8.12

---

## 1. Estructura de decisiones del SUT

```java
public static String evaluar(int edad, double ingreso, int puntaje, int antiguedad, boolean tieneDeudas) {
    if (edad >= 21 && edad <= 65 && puntaje > 600) {                                  // D1
        if (ingreso >= 1500) {                                                        // D2
            return "Aprobado";
        } else if (antiguedad > 5 && !tieneDeudas && ingreso >= 1200) {               // D3
            return "Aprobado por antigüedad";
        }
    }
    return "Rechazado";
}
```

| Decisión | Condiciones (subexpresiones) | Saltos condicionales | Ramas |
|---|---|---|---|
| D1 (`if` externo) | `edad >= 21`, `edad <= 65`, `puntaje > 600` | 3 | 6 |
| D2 (`if` interno) | `ingreso >= 1500` | 1 | 2 |
| D3 (`else if`) | `antiguedad > 5`, `!tieneDeudas`, `ingreso >= 1200` | 3 | 6 |
| **Total** | 7 condiciones | **7** | **14** |

## 2. Caminos a nivel de decisión (los 4 de la consigna)

| Camino | Recorrido | Salida |
|---|---|---|
| C1 | D1 falso | `Rechazado` |
| C2 | D1 verdadero + D2 verdadero | `Aprobado` |
| C3 | D1 verdadero + D2 falso + D3 verdadero | `Aprobado por antigüedad` |
| C4 | D1 verdadero + D2 falso + D3 falso | `Rechazado` |

## 3. Por qué 4 caminos no bastan: mínimo de 8 casos para el 100 % de ramas

JaCoCo mide **ramas de subexpresión** (cada condición de una expresión `&&` es un salto
condicional con dos resultados), no solo el resultado de la decisión completa. Para cubrir
las 14 ramas, cada una de las 7 condiciones debe evaluarse **verdadera en al menos un caso
y falsa en al menos otro**. Argumento de minimalidad:

- Las tres salidas falsas de D1 (`edad < 21`, `edad > 65`, `puntaje <= 600`) son
  **mutuamente excluyentes**: cada una exige su propio caso → 3 casos.
- Las cuatro salidas de D3 (`antiguedad <= 5`, `tieneDeudas`, `ingreso < 1200`, todas
  verdaderas) también son mutuamente excluyentes y solo se alcanzan con D2 falso → 4 casos.
- D2 verdadero (`ingreso >= 1500`) no puede darse en ninguno de los 4 casos anteriores
  (todos requieren `ingreso < 1500`) → 1 caso adicional.

**Mínimo: 3 + 4 + 1 = 8 casos.** Con 8 casos se cierran exactamente las 14 ramas
(1 + 2 + 2 + 2 + 2 + 2 + 2 + 1 = 14 ramas nuevas por caso, sin duplicados de entrada).

## 4. Tabla de caminos (entregable requerido)

Entrada en el orden `(edad, ingreso, puntaje, antiguedad, tieneDeudas)`.

| Camino | Condiciones evaluadas | Entrada | Salida esperada | Salida observada | Rama(s) que cubre |
|---|---|---|---|---|---|
| 1 | D1: `edad >= 21` **falsa** (cortocircuito: no se evalúa el resto de D1) | (18, 2000.0, 700, 6, false) | `Rechazado` | `Rechazado` ✔ | `edad >= 21` → falsa |
| 2 | D1: `edad >= 21` verdadera, `edad <= 65` **falsa** | (66, 2000.0, 750, 2, false) | `Rechazado` | `Rechazado` ✔ | `edad >= 21` → verdadera; `edad <= 65` → falsa |
| 3 | D1: `edad <= 65` verdadera, `puntaje > 600` **falsa** (frontera 600) | (35, 1800.0, 600, 0, false) | `Rechazado` | `Rechazado` ✔ | `edad <= 65` → verdadera; `puntaje > 600` → falsa |
| 4 | D1 completa verdadera; D2: `ingreso >= 1500` **verdadera** | (30, 1600.0, 650, 1, false) | `Aprobado` | `Aprobado` ✔ | `puntaje > 600` → verdadera; `ingreso >= 1500` → verdadera |
| 5 | D2: `ingreso >= 1500` **falsa**; D3: `antiguedad > 5` **falsa** | (40, 1300.0, 650, 2, false) | `Rechazado` | `Rechazado` ✔ | `ingreso >= 1500` → falsa; `antiguedad > 5` → falsa |
| 6 | D3: `antiguedad > 5` verdadera, `!tieneDeudas` **falsa** | (40, 1300.0, 650, 6, true) | `Rechazado` | `Rechazado` ✔ | `antiguedad > 5` → verdadera; `!tieneDeudas` → falsa |
| 7 | D3: `!tieneDeudas` verdadera, `ingreso >= 1200` **falsa** | (40, 1100.0, 650, 6, false) | `Rechazado` | `Rechazado` ✔ | `!tieneDeudas` → verdadera; `ingreso >= 1200` → falsa |
| 8 | D3 completa **verdadera** (excepción interna R4) | (40, 1300.0, 650, 6, false) | `Aprobado por antigüedad` | `Aprobado por antigüedad` ✔ | `ingreso >= 1200` → verdadera |

**Trazabilidad con la suite:** cada camino es un método `caminoN_...` de
`EvaluadorPrestamoCajaBlancaTest` con `@DisplayName` descriptivo y aserción
`assertEquals` cuyo mensaje cita la regla de negocio ejercitada (R1–R5). Sin
`assertTrue(true)`, sin pruebas sin aserción y sin entradas duplicadas.

**Reglas de negocio ejercitadas por camino:** R1 (caminos 1–3), R2 (camino 4),
R3 (caminos 3–4), R4 (caminos 5–8), R5 (caminos 1–3, 5–7).

## 5. Resultado de la medición (paso 5 del encargo)

- **JUnit:** 8 tests encontrados, 8 exitosos, 0 fallidos (evidencia:
  `T1-caja-blanca-junit.txt`).
- **JaCoCo 0.8.12** (evidencia: `T1-jacoco-ramas.txt`, fila CSV de la clase):
  `BRANCH_COVERED = 14`, `BRANCH_MISSED = 0` → **14/14 ramas = 100 %**.
  Además: 28/28 instrucciones, 6/6 líneas y 1/1 método cubiertos.

**Ramas descubiertas tras la primera ejecución: ninguna.** El análisis previo de la
estructura de decisiones (sección 3) ya determinó los 8 casos mínimos, de modo que la
primera medición JaCoCo cerró las 14 ramas y **no fue necesario añadir casos extra**
(el paso condicional "si la cobertura es menor al 100 %" no aplicó). La diferencia entre
los 4 caminos de la consigna (nivel decisión) y los 8 casos ejecutados (nivel rama) queda
justificada en la sección 3: los caminos 1, 3, 5 y 6 de la tabla corresponden a los
C1, C3 y C4 de la consigna desglosados por subexpresión, y los caminos 2, 6 y 7 cierran
las ramas de subexpresión que el nivel decisión deja fuera.

## 6. Veredicto

**CUMPLE**: 8 casos (mínimo justificado por ramas), 14/14 ramas cubiertas (100 %),
0 fallos de ejecución, SUT sin modificar.
