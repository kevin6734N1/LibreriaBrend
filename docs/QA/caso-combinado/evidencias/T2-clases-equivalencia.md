# Análisis de Clases de Equivalencia y Valores Límite (Caja Negra)
**Proyecto:** LibreriaBrend — Módulo de Aprobación de Préstamos Bancarios (`EvaluadorPrestamo`)  
**Fase:** QA / Prueba Combinada — Tester 2 (Caja Negra)  
**Fecha:** 16/11/2026  
**Insumo de especificación:** `docs/QA/caso-combinado/insumos/Caso_Practico_.txt` (Reglas R1 a R5)

---

## 1. Reglas de Negocio Analizadas

* **R1 (Rango de edad):** El solicitante debe tener entre 21 y 65 años (ambos inclusive).
* **R2 (Ingreso mensual neto):** El ingreso mensual debe ser mayor o igual a $1,500.
* **R3 (Historial crediticio):** El puntaje crediticio debe ser estrictamente superior a 600 puntos (`puntaje > 600`).
* **R4 (Excepción interna por antigüedad y fidelidad):** Si el cliente tiene más de 5 años de antigüedad en el banco (`antiguedad > 5`) y no posee deudas vencidas (`tieneDeudas == false`), el sistema aprueba el préstamo automáticamente si su ingreso mensual es de al menos $1,200 (`ingreso >= 1200`), manteniendo los criterios generales de edad (R1) y puntaje (R3).
* **R5 (Caso por defecto):** Cualquier solicitud que no cumpla las condiciones de aprobación estándar (R1 + R2 + R3) ni de excepción (R1 + R3 + R4) es rechazada (`"Rechazado"`).

---

## 2. Tabla de Particiones de Equivalencia

| Variable | Tipo | Partición | Descripción | Clase | Rango / Valores Representativos |
|---|---|---|---|---|---|
| **Edad** | Entero (`int`) | **CE1-V** | Válida | Edad dentro del rango permitido | $21 \le \text{edad} \le 65$ (ej. 30, 35, 40) |
| | | **CE1-I1** | Inválida | Menor a la edad mínima permitida | $\text{edad} < 21$ (ej. 18, 20) |
| | | **CE1-I2** | Inválida | Mayor a la edad máxima permitida | $\text{edad} > 65$ (ej. 66, 70) |
| **Ingreso** | Real (`double`) | **CE2-V1** | Válida (Estándar) | Ingreso suficiente para aprobación estándar | $\text{ingreso} \ge 1500.0$ (ej. 1500, 2000) |
| | | **CE2-V2** | Válida (Excepción) | Ingreso aplicable únicamente bajo excepción R4 | $1200.0 \le \text{ingreso} < 1500.0$ (ej. 1200, 1300) |
| | | **CE2-I** | Inválida | Ingreso insuficiente bajo cualquier regla | $\text{ingreso} < 1200.0$ (ej. 1100, 1199) |
| **Puntaje** | Entero (`int`) | **CE3-V** | Válida | Puntaje crediticio aprobatorio | $\text{puntaje} > 600$ ($\text{puntaje} \ge 601$) (ej. 601, 650, 750) |
| | | **CE3-I** | Inválida | Puntaje insuficiente o en umbral no permitido | $\text{puntaje} \le 600$ (ej. 600, 500) |
| **Antigüedad** | Entero (`int`) | **CE4-V** | Válida (Excepción) | Antigüedad bancaria calificada para excepción | $\text{antiguedad} > 5$ ($\text{antiguedad} \ge 6$) (ej. 6, 10) |
| | | **CE4-I** | Inválida (Excepción) | Antigüedad insuficiente para activar excepción | $\text{antiguedad} \le 5$ (ej. 0, 1, 5) |
| **Deudas** | Booleano (`boolean`) | **CE5-V** | Válida (Excepción) | Sin deudas vencidas (permite excepción) | `false` |
| | | **CE5-I** | Inválida (Excepción) | Con deudas vencidas (bloquea excepción) | `true` |

---

## 3. Análisis de Valores Límite (BVA - Boundary Value Analysis)

| Variable | Frontera | Valor Justificado | Clasificación | Justificación de la Técnica |
|---|---|---|---|---|
| **Edad** | Inferior | `20` | Inválido (CE1-I1) | Inmediatamente por debajo del mínimo legal de 21 años. Debe rechazar. |
| | Inferior | `21` | Válido (CE1-V) | Límite inferior exacto estipulado en R1. Debe permitir aprobación si cumple demás reglas. |
| | Superior | `65` | Válido (CE1-V) | Límite superior exacto inclusivo de R1. |
| | Superior | `66` | Inválido (CE1-I2) | Inmediatamente por encima del límite máximo de 65 años. Debe rechazar. |
| **Ingreso** | Límite estándar | `1499.0` | Inválido para R2 estándar | Inmediatamente por debajo del umbral estándar de $1,500. Requiere excepción para aprobar. |
| | Límite estándar | `1500.0` | Válido (CE2-V1) | Umbral mínimo exacto para aprobación general según R2. |
| | Límite excepción | `1199.0` | Inválido (CE2-I) | Inmediatamente inferior al piso de $1,200. Rechazo absoluto. |
| | Límite excepción | `1200.0` | Válido (CE2-V2) | Umbral mínimo exacto para la excepción R4 con antigüedad > 5 y sin deudas. |
| **Puntaje** | Frontera estricta | `600` | Inválido (CE3-I) | Valor límite crítico. La regla exige "superior a 600" ($> 600$), por lo que 600 exacto no califica. |
| | Frontera estricta | `601` | Válido (CE3-V) | Primer valor entero que satisface estrictamente la condición $puntaje > 600$. |
| **Antigüedad** | Frontera excepción | `5` | Inválido para R4 (CE4-I) | La regla exige "más de 5 años" ($> 5$). 5 años exactos no califica para excepción. |
| | Frontera excepción | `6` | Válido para R4 (CE4-V) | Primer valor entero de años que supera estrictamente los 5 años exigidos. |
| **Deudas** | Dominio discreto | `false` | Válido para R4 (CE5-V) | Estado indispensable para habilitar la vía de excepción. |
| | Dominio discreto | `true` | Inválido para R4 (CE5-I) | Causal de exclusión directa de la vía de excepción. |
