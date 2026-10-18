# PLANTILLA DE DISEÑO TDD - SPRINT 3
## Curso: Calidad y Pruebas de Software
### Caso de Estudio: Empresa de Seguridad Águilas del Perú S.A.C.

**Código de Requerimiento Funcional Asociado:** RF del caso hipotético (proceso de facturas por cobrar / morosidad de Águilas del Perú S.A.C.; el grupo no dispone de su número de folio). **En Librería Brenda no existe RF equivalente**: la función es un ejercicio académico TDD independiente y no forma parte de los 17 requisitos funcionales implementados por el equipo.

**Nombre del Módulo/Componente Técnico:** `libreria.util.CalculadoraMorosidad` (función de cálculo de morosidad, `src/libreria/util/CalculadoraMorosidad.java`), verificada por `libreria.util.CalculadoraMorosidadTest` (`test/libreria/util/CalculadoraMorosidadTest.java`).

---

## 1. FASE RED (Prueba Unitaria Fallida)
*Instrucciones: Redacte la lógica de la prueba unitaria automatizada (usando JUnit, PHPUnit, o similar) que defina el ejemplo de uso antes de implementar la solución en el código fuente. Recuerde incluir la aserción esperada que provocará el fallo lícito inicial.*

**Requisito o comportamiento académico asociado:** Regla de negocio de morosidad (ejercicio TDD, Sprint 3): una factura/cliente se clasifica como **Moroso** cuando (1) el saldo pendiente es mayor que cero **y** (2) la fecha de evaluación es posterior a la fecha de vencimiento. Casos de referencia con datos simulados: S/ 100.00 vencido 10/10/2026 evaluado 17/10/2026 → Moroso; S/ 100.00 con vencimiento 17/10/2026 evaluado 17/10/2026 → No moroso; saldo S/ 0.00 con vencimiento 10/10/2026 → No moroso; S/ 100.00 con vencimiento 20/10/2026 → No moroso. Ninguna de estas reglas está implementada hoy en Librería Brenda.

**Componente bajo prueba:** `CalculadoraMorosidad.esMoroso(BigDecimal saldoPendiente, LocalDate fechaVencimiento, LocalDate fechaEvaluacion)` — clase utilitaria de la capa `libreria.util`, sin integración con Servlets, DAO, base de datos ni interfaz. Se usan `LocalDate` y `BigDecimal` para fechas e importes.

**Nota de alcance:** este documento corresponde a la **simulación del caso hipotético Águilas del Perú S.A.C.** Las pruebas reales de Librería Brenda (contratos de `PasswordUtil`, login, catálogo, pedidos) son las 52 pruebas unitarias existentes y su ejecución queda registrada en el informe de Etapa A, no en esta plantilla. Fechas e importes de esta plantilla son datos ficticios, no información de clientes reales.

**Código JUnit 5 (escrito ANTES de la implementación):**

```java
package libreria.util;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Prueba RED de la función académica de morosidad (ejercicio TDD Sprint 3).
 *
 * Regla de negocio: un cliente/factura es moroso cuando el saldo pendiente
 * es mayor que cero Y la fecha de evaluación es posterior al vencimiento.
 *
 * Los datos son simulados (caso hipotético Águilas del Perú S.A.C.); no
 * pertenecen a clientes reales de Librería Brenda ni a los 17 RF del proyecto.
 */
class CalculadoraMorosidadTest {

    @Test
    void facturaVencidaConSaldoPendiente_esMoroso() {
        BigDecimal saldoPendiente = new BigDecimal("100.00");
        LocalDate fechaVencimiento = LocalDate.of(2026, 10, 10);
        LocalDate fechaEvaluacion = LocalDate.of(2026, 10, 17);

        assertTrue(
                CalculadoraMorosidad.esMoroso(saldoPendiente, fechaVencimiento, fechaEvaluacion),
                "Saldo S/ 100.00 vencido el 10/10/2026 y evaluado el 17/10/2026 debe clasificarse como Moroso");
    }
}
```

**Esqueleto mínimo de compilación (no implementa la regla de negocio):**

```java
// src/libreria/util/CalculadoraMorosidad.java  —  ESQUELETO RED, sin lógica
public static boolean esMoroso(BigDecimal saldoPendiente, LocalDate fechaVencimiento, LocalDate fechaEvaluacion) {
    return false; // la regla (saldo > 0 Y fechaEvaluacion > fechaVencimiento) se implementa en GREEN
}
```

**Justificación técnica del fallo inicial:** La aserción espera `true` porque, según la regla de negocio, un saldo de S/ 100.00 (> 0) evaluado el 17/10/2026 con vencimiento el 10/10/2026 (fecha de evaluación posterior al vencimiento) debe clasificarse como **Moroso**. Se obtiene `false` porque la clase es solo un esqueleto de compilación que devuelve una constante sin evaluar ni el saldo ni las fechas: la prueba falla por una **aserción de comportamiento** legítima (`expected: <true> but was: <false>`), sin usar `fail()` y sin alterar la aserción. El fallo demuestra que la prueba describe el comportamiento de negocio esperado y que dicho comportamiento aún no existe en el código fuente.

**Evidencia real de la ejecución (17/10/2026, OpenJDK 21.0.12.1, JUnit Platform Console 1.11.4, Windows/Git Bash):**

1. *Compilación previa al esqueleto* (prueba escrita sin clase `CalculadoraMorosidad`) → error real de compilación, evidencia adicional:

```text
test\libreria\util\CalculadoraMorosidadTest.java:28: error: cannot find symbol
                CalculadoraMorosidad.esMoroso(saldoPendiente, fechaVencimiento, fechaEvaluacion),
  symbol:   variable CalculadoraMorosidad
  location: class CalculadoraMorosidadTest
1 error
COMPILE_EXIT=1
```

2. *Compilación con el esqueleto mínimo* → `COMPILE_EXIT=0`.

3. *Ejecución JUnit 5 real* (`java -jar WebContent/WEB-INF/lib/junit-platform-console-standalone-1.11.4.jar -cp "out/sprint3-red;WebContent/WEB-INF/lib/jbcrypt-0.4.jar" --scan-class-path out/sprint3-red --disable-banner`), salida resumida tal como se obtuvo:

```text
Failures (1):
  JUnit Jupiter:CalculadoraMorosidadTest:facturaVencidaConSaldoPendiente_esMoroso()
    => org.opentest4j.AssertionFailedError: Saldo S/ 100.00 vencido el 10/10/2026 y evaluado el 17/10/2026 debe clasificarse como Moroso ==> expected: <true> but was: <false>
       libreria.util.CalculadoraMorosidadTest.facturaVencidaConSaldoPendiente_esMoroso(CalculadoraMorosidadTest.java:27)

Test run finished after 1042 ms
[        53 tests found           ]
[        52 tests successful      ]
[         1 tests failed          ]
JUNIT_EXIT=1
```

Las 52 pruebas existentes de Librería Brenda siguieron en verde durante la ejecución RED: la nueva prueba es la única que falla y no introdujo regresión.

**Estado de la fase:** **COMPLETADA** (fase RED finalizada y demostrada el 17/10/2026; fases subsiguientes GREEN y REFACTOR autorizadas y completadas en secciones 2 y 3).

---

## 2. FASE GREEN (Implementación de Código Mínimo)
*Instrucciones: Inserte estrictamente el código mínimo indispensable para lograr que la prueba redactada en la Fase Red cambie a un estado exitoso (Verde). Evite agregar lógicas de optimización o abstracciones en este paso.*

**Código mínimo implementado** (solo cambió el cuerpo de `esMoroso`; firma intacta, Java 21):

```java
// src/libreria/util/CalculadoraMorosidad.java
public static boolean esMoroso(BigDecimal saldoPendiente, LocalDate fechaVencimiento, LocalDate fechaEvaluacion) {
    return saldoPendiente.compareTo(BigDecimal.ZERO) > 0
            && fechaEvaluacion.isAfter(fechaVencimiento);
}
```

**Justificación de por qué es suficiente:** la condición implementa exactamente las dos cláusulas de la regla y nada más: (1) `saldoPendiente.compareTo(BigDecimal.ZERO) > 0` verifica saldo pendiente positivo (comparación por valor de `BigDecimal`, robusta ante distintas escalas) y (2) `fechaEvaluacion.isAfter(fechaVencimiento)` verifica que la evaluación sea estrictamente posterior al vencimiento (evaluación el mismo día del vencimiento → no moroso, según el caso de referencia S/ 100.00 vencida 17/10/2026 evaluada 17/10/2026 → No moroso). No se añadieron auxiliares, constantes, abstracciones ni validaciones de `null`, porque la única prueba existente no los exige: cualquier código adicional sería complejidad sin demanda de una prueba.

**Prueba que anteriormente fallaba:** `libreria.util.CalculadoraMorosidadTest.facturaVencidaConSaldoPendiente_esMoroso()` — en RED falló con `AssertionFailedError: ... expected: <true> but was: <false>`.

**Resultado real de la ejecución individual (17/10/2026, OpenJDK 21.0.12.1, JUnit Platform Console 1.11.4)** — compilación `COMPILE_EXIT=0`, luego `java -jar ...junit-platform-console-standalone-1.11.4.jar -cp "out/sprint3-green" --select-class libreria.util.CalculadoraMorosidadTest --disable-banner` (exit 0):

```text
│  └─ CalculadoraMorosidadTest ✔
│     └─ facturaVencidaConSaldoPendiente_esMoroso() ✔
Test run finished after 91 ms
[         1 tests found           ]
[         1 tests successful      ]
[         0 tests failed          ]
JUNIT_EXIT=0
```

**Resultado real de la batería completa** — procedimiento documentado en el README (2 clases de producción + 6 unidades + `$(find test -name '*.java')`, JUnit Console, exit 0):

```text
Test run finished after 1055 ms
[         9 containers successful ]
[        53 tests found           ]
[        53 tests successful      ]
[         0 tests failed          ]
JUNIT_EXIT=0
```

**Explicación de la transición RED → GREEN:** la prueba no se tocó (mismo archivo, misma aserción `assertTrue` y mismo mensaje); la única entrada cambiada fue el código de producción, sustituyendo la constante `return false` del esqueleto (que no evaluaba nada) por la condición de negocio. Con ella, la clasificación que en RED era `false` pasa a `true` correctamente y la aserción se satisuelve: la prueba pasa de fallida a exitosa. Las otras 52 pruebas permanecen verdes, lo que confirma que el cambio es aditivo y no introdujo regresión.

**Nota de trazabilidad:** el ciclo RED inicial de la sección 1 dio paso ordenado a las fases GREEN y REFACTOR tras la autorización respectiva. Solo se modificó `src/libreria/util/CalculadoraMorosidad.java` para sustituir el esqueleto por la lógica mínima y, posteriormente, refactorizarla preservando el cortocircuito, sin alterar firma, estructura ni lógica ajena.

**Estado de la fase:** **COMPLETADA** (GREEN ejecutado y verificado el 17/10/2026: 1/1 individual y 53/53 batería completa).

---

## 3. FASE REFACTOR (Optimización y Diseño Limpio)
*Instrucciones: Aplique refactorización para transformar el código tosco en un diseño modular altamente reutilizable ("Código Ravioli"). Explique qué técnicas utilizó para eliminar la duplicidad o mejorar la legibilidad sin romper la prueba existente.*

**Código anterior (fin de la FASE GREEN):**

```java
public static boolean esMoroso(BigDecimal saldoPendiente, LocalDate fechaVencimiento, LocalDate fechaEvaluacion) {
    return saldoPendiente.compareTo(BigDecimal.ZERO) > 0
            && fechaEvaluacion.isAfter(fechaVencimiento);
}
```

**Código refactorizado (solo cambió este cuerpo; firma, lógica y pruebas intactas):**

```java
// src/libreria/util/CalculadoraMorosidad.java
public static boolean esMoroso(BigDecimal saldoPendiente, LocalDate fechaVencimiento, LocalDate fechaEvaluacion) {
    boolean tieneDeuda = saldoPendiente.compareTo(BigDecimal.ZERO) > 0;
    if (!tieneDeuda) {
        return false;
    }

    boolean plazoVencido = fechaEvaluacion.isAfter(fechaVencimiento);
    return plazoVencido;
}
```

**Explicación de las mejoras de legibilidad y preservación de cortocircuito:** las dos condiciones de la regla de negocio se expresan de forma explícita y auto-documentada. Primero se evalúa `tieneDeuda` (`saldoPendiente.compareTo(BigDecimal.ZERO) > 0`); si no hay deuda (`!tieneDeuda`), el método sale de inmediato con `return false;` (cláusula de guarda / cortocircuito explícito), garantizando que las fechas no se evalúen innecesariamente cuando el saldo no es positivo. Esta estructura preserva estrictamente la semántica de cortocircuito del operador `&&` de la fase GREEN. Si existe deuda positiva, se evalúa `plazoVencido` (`fechaEvaluacion.isAfter(fechaVencimiento)`), retornando directamente su valor. El lector entiende el dominio en términos de negocio sin lidiar con comparaciones técnicas anidadas. La refactorización **no elimina duplicación porque no existe**: el método ya era de una sola responsabilidad. El cambio perfecciona la **expresividad** y la **robustez** de ejecución sin fragmentar artificialmente un método conciso.

**Criterios de Diseño Aplicados (¿Por qué cumple con la tolerancia al cambio?):** (1) *Extracción de variables con nombre y cláusula de guarda* (`Extract Variable` + `Guard Clause`) preservando el cortocircuito sin alterar el comportamiento; (2) *responsabilidad única*: la clase expone una sola operación pura, sin estado ni dependencias; (3) *sin acoplamiento añadido*: cero dependencias externas, cero nuevos métodos, firma pública idéntica (compatibilidad Java 21); (4) *tolerancia al cambio*: si la regla evoluciona (p. ej. días de gracia), basta con modificar la condición de plazo o deuda en un único punto, sin rastrear lógica dispersa, y la prueba existente seguirá protegiendo el contrato. **Relación académica Spaghetti vs. Ravioli:** GREEN no era código Spaghetti (era una instrucción `return` directa y legible, no flujo enredado con lógica mezclada); por tanto esta fase no "desenreda" nada. La idea de "Código Ravioli" aplica en sentido proporcional: cada pieza (condición con nombre) tiene una responsabilidad clara y comestible por separado, sin fragmentar un método breve en abstracciones artificiales. La refactorización es deliberadamente pequeña porque la complejidad real del método lo era.

**Evidencia real de las pruebas después del refactor inicial (17/10/2026, OpenJDK 21.0.12.1, JUnit Platform Console 1.11.4, compilación `COMPILE_IND_EXIT=0` / `COMPILE_ALL_EXIT=0`):**

Prueba individual (`--select-class libreria.util.CalculadoraMorosidadTest`, salida real, exit 0):

```text
│  └─ CalculadoraMorosidadTest ✔
│     └─ facturaVencidaConSaldoPendiente_esMoroso() ✔
Test run finished after 131 ms
[         1 tests found           ]
[         1 tests successful      ]
[         0 tests failed          ]
JUNIT_IND_EXIT=0
```

Batería completa (README del repo, salida resumida real): 

```text
[         9 containers successful ]
[         0 containers failed     ]
[        53 tests found           ]
[         0 tests aborted         ]
[        53 tests successful      ]
[         0 tests failed          ]
JUNIT_ALL_EXIT=0
```

**Verificación posterior a la auditoría QA independiente (17/10/2026):**

Tras la auditoría QA y la incorporación de la cláusula de guarda para garantizar el cortocircuito estricto sobre fechas con saldo no positivo, se reejecutó la verificación automatizada en OpenJDK 21.0.12.1 con JUnit Platform Console 1.11.4:

1. *Compilación:* `COMPILE_EXIT=0`.
2. *Prueba individual* (`--select-class libreria.util.CalculadoraMorosidadTest`, 151 ms, exit 0):
```text
│  └─ CalculadoraMorosidadTest ✔
│     └─ facturaVencidaConSaldoPendiente_esMoroso() ✔
Test run finished after 151 ms
[         1 tests found           ]
[         1 tests successful      ]
[         0 tests failed          ]
JUNIT_IND_EXIT=0
```
3. *Batería completa* (`--scan-class-path`, 53 pruebas, 1172 ms, exit 0):
```text
[         9 containers successful ]
[         0 containers failed     ]
[        53 tests found           ]
[         0 tests aborted         ]
[        53 tests successful      ]
[         0 tests failed          ]
JUNIT_ALL_EXIT=0
```

**Confirmación de que el comportamiento funcional se conservó:** las mismas 53 pruebas (0 fallos, 0 errores/abortadas) pasaron antes y después de cada cambio, con ninguna prueba modificada: el sha256 de `CalculadoraMorosidadTest.java` conserva intacta la prueba y `git diff` sobre archivos versionados = 0. Las condiciones preservan el cortocircuito de GREEN, garantizando equivalencia de comportamiento y ausencia total de regresiones.

**Estado de la fase:** **COMPLETADA** (REFACTOR ejecutado, verificado y validado tras auditoría el 17/10/2026).

---

## 4. RESUMEN DE CIERRE DEL CICLO TDD

| Etapa | Resultado |
|---|---|
| RED | 52 exitosas, 1 fallida (`expected: <true> but was: <false>`) |
| GREEN | 53 exitosas, 0 fallidas |
| REFACTOR | 53 exitosas, 0 fallos y 0 errores (individual 1/1, 131 ms; ejecución real del 17/10/2026) |

**Descripción del ciclo:** primero **definimos el comportamiento** escribiendo la prueba antes que el código (RED: el fallo demostró que la regla no existía); después **implementamos la solución mínima** que satisfizo exactamente esa prueba sin complejidad extra (GREEN: la prueba pasó y las otras 52 siguieron verdes); finalmente **mejoramos el diseño sin alterar los resultados**, nombrando las condiciones de negocio y conservando la lógica y las pruebas intactas (REFACTOR: misma batería, mismos resultados). El ciclo completo demuestra que en TDD las pruebas mandan sobre el código, no al revés.

**Precisiones necesarias:**

- La función de morosidad es una **simulación académica** inspirada en el caso hipotético de facturas por cobrar de Águilas del Perú S.A.C.; sus fechas e importes son datos ficticios.
- **Librería Brenda no tiene implementado un módulo operativo de morosidad**: la función vive aislada en `libreria.util` y no está integrada con Servlets, DAO, base de datos ni interfaz, ni cuenta entre los 17 requisitos funcionales del proyecto.
- Las **53 pruebas son unitarias** de clases Java puras; **no equivalen a pruebas de integración** de todo el sistema (la suite HTTP/MariaDB no se ejecutó en este ciclo TDD).
- El **trabajo de regresión del RF01** (Registro de Clientes) se mantiene como **actividad separada** de este ciclo TDD y no fue modificado por estas etapas.