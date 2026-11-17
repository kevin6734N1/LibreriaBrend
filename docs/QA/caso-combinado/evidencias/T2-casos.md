# Matriz de Casos de Prueba de Caja Negra (T2)
**Proyecto:** LibreriaBrend — Sistema de Aprobación de Préstamos Bancarios  
**SUT:** `libreria.util.EvaluadorPrestamo`  
**Ejecutor:** Tester 2 (Caja Negra)  
**Fecha:** 16/11/2026  
**Resultado de ejecución:** 6 ejecutados, 6 conformes (0 discrepancias, 0 fallos)

---

## 1. Tabla de Casos de Prueba (Resumen de Ejecución)

| # | Técnica | Edad | Ingreso | Puntaje | Antigüedad | Deudas | Esperado | Observado | Estado |
|---|---|:---:|:---:|:---:|:---:|:---:|---|---|:---:|
| 1 | BVA: Frontera inferior válida (edad e ingreso) | 21 | 1500.0 | 601 | 1 | `false` | Aprobado | Aprobado | CONFORME |
| 2 | BVA: Frontera superior inválida (edad fuera de rango) | 66 | 2000.0 | 750 | 2 | `false` | Rechazado | Rechazado | CONFORME |
| 3 | Partición inválida / BVA: Puntaje en la frontera | 35 | 1800.0 | 600 | 0 | `false` | Rechazado | Rechazado | CONFORME |
| 4 | BVA: Frontera inferior inválida de edad | 20 | 2000.0 | 700 | 3 | `false` | Rechazado | Rechazado | CONFORME |
| 5 | BVA: Valor límite de la excepción (ingreso reducido) | 40 | 1200.0 | 650 | 6 | `false` | Aprobado por antigüedad | Aprobado por antigüedad | CONFORME |
| 6 | Partición inválida de excepción (bloqueo por deuda) | 40 | 1200.0 | 650 | 6 | `true` | Rechazado | Rechazado | CONFORME |

---

## 2. Detalle y Justificación Técnica de Cada Caso

### Caso 1 (Obligatorio 1) — Frontera inferior válida (edad e ingreso)
* **Técnica:** Análisis de Valores Límite (BVA) en las fronteras inferiores válidas de edad (R1) e ingreso (R2), junto con el puntaje mínimo aprobatorio (R3).
* **Entradas:** `edad = 21`, `ingreso = 1500.0`, `puntaje = 601`, `antiguedad = 1`, `tieneDeudas = false`.
* **Justificación del valor:**
  - `edad = 21`: Límite inferior exacto inclusivo de la regla R1 ($21 \le \text{edad} \le 65$).
  - `ingreso = 1500.0`: Límite inferior exacto de la regla R2 ($\text{ingreso} \ge 1500$).
  - `puntaje = 601`: Primer valor entero estrictamente mayor a 600 exigido por la regla R3 ($\text{puntaje} > 600$).
* **Salida esperada:** `"Aprobado"`.
* **Salida observada:** `"Aprobado"`.
* **Resultado:** CONFORME.

---

### Caso 2 (Obligatorio 2) — Frontera superior inválida de edad
* **Técnica:** Análisis de Valores Límite (BVA) en la frontera superior no permitida de edad.
* **Entradas:** `edad = 66`, `ingreso = 2000.0`, `puntaje = 750`, `antiguedad = 2`, `tieneDeudas = false`.
* **Justificación del valor:**
  - `edad = 66`: Primer valor entero adyacente que excede el límite máximo de 65 años estipulado en R1.
  - Las demás variables financieras (`ingreso = 2000`, `puntaje = 750`) se colocan deliberadamente en rangos óptimos para aislar la variable bajo prueba y comprobar que la infracción del límite etario genera rechazo inapelable (R5).
* **Salida esperada:** `"Rechazado"`.
* **Salida observada:** `"Rechazado"`.
* **Resultado:** CONFORME.

---

### Caso 3 (Obligatorio 3) — Partición inválida / Frontera crítica de puntaje
* **Técnica:** Partición de Equivalencia inválida y Análisis de Valores Límite sobre el historial crediticio (R3).
* **Entradas:** `edad = 35`, `ingreso = 1800.0`, `puntaje = 600`, `antiguedad = 0`, `tieneDeudas = false`.
* **Justificación del valor:**
  - `puntaje = 600`: Frontera superior crítica de la partición de rechazo. La regla de negocio R3 exige taxativamente que el puntaje sea "superior a 600 puntos" ($\text{puntaje} > 600$), por lo que 600 exacto no debe calificar para aprobación.
  - Edad e ingreso son plenamente válidos, confirmando que la denegación se debe estrictamente al umbral crediticio.
* **Salida esperada:** `"Rechazado"`.
* **Salida observada:** `"Rechazado"`.
* **Resultado:** CONFORME.

---

### Caso 4 (Complementario 1) — Frontera inferior inválida de edad
* **Técnica:** Análisis de Valores Límite (BVA) en la frontera inferior no permitida de edad.
* **Entradas:** `edad = 20`, `ingreso = 2000.0`, `puntaje = 700`, `antiguedad = 3`, `tieneDeudas = false`.
* **Justificación del valor:**
  - `edad = 20`: Primer valor entero inmediatamente por debajo del umbral mínimo de 21 años de la regla R1.
  - Garantiza que el sistema aplique el límite inferior estricto y no admita solicitantes de 20 años a pesar de contar con ingresos y puntaje aprobatorios.
* **Salida esperada:** `"Rechazado"`.
* **Salida observada:** `"Rechazado"`.
* **Resultado:** CONFORME.

---

### Caso 5 (Complementario 2) — Activación de excepción interna en valor límite
* **Técnica:** Análisis de Valores Límite (BVA) en los límites de la excepción R4 combinada con partición válida de edad y puntaje.
* **Entradas:** `edad = 40`, `ingreso = 1200.0`, `puntaje = 650`, `antiguedad = 6`, `tieneDeudas = false`.
* **Justificación del valor:**
  - `ingreso = 1200.0`: Límite inferior exacto admitido para la excepción interna ("al menos $1,200").
  - `antiguedad = 6`: Primer valor entero estrictamente superior a 5 años ("más de 5 años de antigüedad").
  - `tieneDeudas = false`: Condición obligatoria de ausencia de deudas vencidas.
  - `edad = 40` y `puntaje = 650`: Cumplen las condiciones generales R1 y R3.
* **Salida esperada:** `"Aprobado por antigüedad"`.
* **Salida observada:** `"Aprobado por antigüedad"`.
* **Resultado:** CONFORME.

---

### Caso 6 (Complementario 3) — Bloqueo de excepción interna por deuda vencida
* **Técnica:** Partición de Equivalencia (EP) inválida para la condición de fidelidad de la excepción interna R4.
* **Entradas:** `edad = 40`, `ingreso = 1200.0`, `puntaje = 650`, `antiguedad = 6`, `tieneDeudas = true`.
* **Justificación del valor:**
  - `tieneDeudas = true`: Representa la partición inválida para la excepción de fidelidad.
  - A pesar de que el cliente cuenta con 6 años de antigüedad y cumple el ingreso de $1,200, la existencia de deuda vencida inhabilita la excepción R4 y, al no alcanzar el ingreso estándar de $1,500 (R2), debe ser rechazado conforme a R5.
* **Salida esperada:** `"Rechazado"`.
* **Salida observada:** `"Rechazado"`.
* **Resultado:** CONFORME.

---

## 3. Registro de Hallazgos y Discrepancias

* **Total de discrepancias detectadas:** 0.
* **Cumplimiento de especificación:** 100 % de los casos ejecutados devolvieron exactamente la salida predicha por las reglas de negocio R1 a R5.
* **Veredicto:** CONFORME (Aceptado sin observaciones).
