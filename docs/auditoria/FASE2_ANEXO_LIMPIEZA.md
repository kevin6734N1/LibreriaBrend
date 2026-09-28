# FASE 2 — Anexo de Limpieza y Prueba de Integridad de la Base de Datos

**Commit auditado:** `291741c3181010fe9a171e900954bdf22fe7a7cb`
**Base de datos implicada:** `libreria_brenda` (producción)
**Fecha:** 2026-09-28
**Evidencia de integridad:** [`evidencias/db/02_verificacion_integridad.txt`](evidencias/db/02_verificacion_integridad.txt)

---

## 1. Resultado en una línea

**No se creó ninguna base de datos de prueba y no se ejecutó ninguna operación de escritura. Ninguna fila fue insertada, modificada ni eliminada.** El estado de `libreria_brenda` es idéntico antes y después de la auditoría (0 diferencias entre los volcados de estado).

---

## 2. Registro de operaciones sobre bases de datos

### 2.1 Operaciones de ESCRITURA en la BD de prueba

| # | Operación | Filas afectadas |
|---|---|---|
| — | *(ninguna)* | **0** |

**No hubo ninguna fila insertada ni modificada en ninguna base de datos**, por lo que la tabla de "filas insertadas / modificadas a revertir" queda vacía. No se requirió ninguna operación de limpieza.

### 2.2 Decisión sobre la base de datos de prueba

El encargo autorizaba escribir **únicamente** en una BD de prueba creada por el auditor (p. ej. `libreria_brenda_test`). **No se creó**, por dos razones técnicas:

1. **Habría sido inoperante.** La aplicación desplegada tiene la URL de conexión y el nombre de la BD **compilados dentro de `ConexionBD.class`** (`jdbc:mysql://localhost:3306/libreria_brenda?...`), sin `context.xml`, sin fichero de propiedades y sin `DataSource` JNDI. Crear la BD de prueba **no cambiaría el destino de ninguna petición HTTP**. Redirigir la aplicación exigiría recompilar y redeployar el artefacto o crear un `context.xml` en el contenedor: ambas cosas quedan **fuera de los permisos concedidos** para esta fase (`curl`, `mysql/mariadb-cli`, `git`, lectura de logs; creación de ficheros solo bajo `docs/auditoria/`).
2. **Hospedarla habría exigido copiar datos personales.** Poblar la BD de prueba con el contenido de producción habría supuesto duplicar DNI, correos y direcciones de clientes reales en un nuevo esquema, operación no autorizada y contraria a minimización de datos.

Conclusión: crear la BD de prueba habría añadido riesgo (duplicación de datos personales y un esquema residual que limpiar) sin habilitar ni una sola prueba adicional. **Se optó por detener las pruebas ofensivas, tal como ordena el control crítico del encargo, y documentarlo.**

### 2.3 Operaciones de LECTURA ejecutadas (inventario completo, para trazabilidad)

Todas son `SELECT` / `SHOW`. Ninguna modifica estado.

| # | Sentencia | Propósito | Evidencia |
|---|---|---|---|
| 1 | `SELECT VERSION()` · `SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='libreria_brenda'` | Identificar motor y BD | §A.01.8 |
| 2 | `SELECT SCHEMA_NAME … WHERE SCHEMA_NAME LIKE 'libreria%'` | Confirmar que **no existe** BD de prueba | §A.01.8 · `02_verificacion_integridad.txt` §4 |
| 3 | `SHOW TABLES` | Inventario de esquema | Fase 1 |
| 4 | `SHOW CREATE TABLE pedidos` / `codigos_promo` / `codigos_promo_usos` / `preferencias_accesibilidad` | Verificar DDL contra lo documentado | Fase 1 |
| 5 | `SELECT codigo,tipo,valor,activo,fecha_expiracion FROM codigos_promo` | Verificar el seed de códigos | Fase 1 |
| 6 | `SELECT id,nombres,apellidos,email,activo FROM clientes ORDER BY id LIMIT 3` | Identificar al "Cliente Demo" (id=1) | Fase 1 |
| 7 | `SELECT cliente_id, estado, COUNT(*) FROM pedidos GROUP BY cliente_id, estado` | Cuantificar el alcance del IDOR (R-01) | Fase 1 |
| 8 | `SELECT id,nombre,precio,stock,activo FROM productos ORDER BY id` | Fijar qué `item_id` son reales, para diseñar payloads **no escribientes** | §3.1 |
| 9 | `SELECT id,nombre,email,codigo_empleado FROM administradores` | Contexto del panel administrativo | Fase 1 |
| 10 | `SELECT MAX(id) FROM productos` | Elegir ids inexistentes (9001+) para los payloads de control | §3.1 |
| 11 | `estado_bd.sql` (conteos + huella de contenido + pedidos del cliente 1 + último pedido) | Volcado de estado **antes** y **después** | `db/00_baseline_antes.txt`, `db/01_baseline_despues.txt` |
| 12 | Programa auxiliar de Fase 1 (`Harness`, fuera del repositorio) | Reglas de envío, códigos promocionales, escapado JSON — solo `SELECT` | (Fase 1) |

---

## 3. Garantía de no-escritura en las pruebas HTTP

### 3.1 Diseño de los payloads de escritura potencial

Los POST a `PedidoServlet accion=guardarDB` son la única operación que puede crear un pedido. Se diseñó **cada uno** para que el flujo retorne **antes** de `PedidoDAO.crear()`, apoyándose en el orden real del código:

```
guardarPedidoEnDB():
  1. leer parámetros                       <- (f) arrays de longitud dispar / nulos: error aquí
  2. si ids == null o vacío -> return       <- (a)
  3. si ids.length > 10 -> return           <- (b)
  4. por cada ítem: parseInt -> cantidad    <- (c)(d)(e) ids no numéricos / cantidad <= 0
  5. obtenerPrecio(con, productoId)         <- (g) producto inexistente
  6. si hay código promocional y no hay sesión -> return  <- (h)
  7. … calcularTotal() …
  8. PedidoDAO.crear()                      <- ÚNICA línea que escribe. NUNCA ALCANZADA.
```

Los ids de producto usados en los controles (`9001`–`9011`) **no existen** en la tabla (`MAX(id) = 11`), lo que garantiza la salida en el paso 5. El caso (e) usa un producto real (`item_id=1`) **solo** para que el bucle alcance la segunda iteración y dispare el error de índice del paso 4 — antes del paso 8. Ver `evidencias/responses/B03_seguridad_lectura.txt` §B.03.6–B.03.7.

### 3.2 Payloads destructivos descartados deliberadamente

**No se envió ningún payload `; DROP …`, `; DELETE …`, `; UPDATE …` contra `libreria_brenda`.** Justificación técnica estricta: el daño de un falso positivo es un evento **irreversible** sobre datos de producción reales (pérdida de pedidos y clientes), mientras que el beneficio es únicamente confirmar lo que ya está refutado por dos vías independientes: (i) 5 payloads de inyección no destructivos por HTTP, todos sin diferencial observable (§B.03.3), y (ii) 0 `Statement` con concatenación y 54 `PreparedStatement` en todos los DAO y servlets. La batería destructiva queda **pendiente y recomendada** para cuando exista una BD de prueba (ver §5).

---

## 4. Prueba de integridad de la base de datos de producción

Fuente: [`evidencias/db/02_verificacion_integridad.txt`](evidencias/db/02_verificacion_integridad.txt)

### 4.1 Volcados comparados

```text
1e8f03a5a8f3065c48ec93d9a7cf0eaf541fece7a137a66bc04cd0c82b7f4b94  db/00_baseline_antes.txt
d80a3edf71889e526830725017856d9ba2ac3ef16587d99488d4d7d651af7685  db/01_baseline_despues.txt
```
(los hashes difieren **únicamente** por la fila `momento_captura = NOW()`)

```text
$ diff <(grep -v "momento_captura\|^| 2026-" db/00_baseline_antes.txt) \
       <(grep -v "momento_captura\|^| 2026-" db/01_baseline_despues.txt)
RESULTADO: 0 diferencias -> el contenido de la BD es IDÉNTICO antes y después de la auditoría.
```

### 4.2 Conteos comparativos (antes / después)

| Tabla | Antes | Después | Δ |
|---|---:|---:|---:|
| `clientes` | 16 | 16 | **0** |
| `administradores` | 1 | 1 | **0** |
| `productos` | 11 | 11 | **0** |
| `pedidos` | 16 | 16 | **0** |
| `pedido_items` | 31 | 31 | **0** |
| `comprobantes` | 8 | 8 | **0** |
| `codigos_promo` | 3 | 3 | **0** |
| `codigos_promo_usos` | 0 | 0 | **0** |
| `preferencias_accesibilidad` | 0 | 0 | **0** |
| `categorias` | 6 | 6 | **0** |

### 4.3 Huella de contenido (detecta modificaciones invisibles a un `COUNT`)

Se calculó una huella por tabla (suma de `CRC32` de la clave/nombre, suma de importes en céntimos, suma de stock, longitud agregada de campos de texto) para detectar cualquier `UPDATE` que no alterase el número de filas:

| Tabla | `filas` | `suma_ids` / `CRC32` | huella de importes/stock |
|---|---:|---:|---:|
| `clientes` | 16 | 158 | 751 (longitudes agregadas) |
| `pedidos` | 16 | 35 205 428 789 | 124 692 (total+descuento en céntimos) |
| `productos` | 11 | 25 257 928 171 | 47 017 (precio + stock) |
| `comprobantes` | 8 | 38 | 73 910 (montos en céntimos) |
| `codigos_promo_usos` | 0 | 0 | 0 |

**La huella es idéntica antes y después** (forma parte del diff con 0 diferencias).

### 4.4 Controles específicos de operaciones prohibidas

```sql
SELECT COUNT(*) FROM pedidos
 WHERE id LIKE '%AUDIT%' OR direccion_entrega LIKE '%audit%' OR metodo_pago LIKE '%audit%';
-- pedidos_con_marca_auditoria = 0

SELECT COUNT(*) FROM codigos_promo_usos;
-- usos_promo_totales = 0
```

### 4.5 Base de datos de prueba residual

```sql
SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME LIKE 'libreria%';
-- libreria_brenda   (única)
```
**No hay esquema residual que eliminar**: `libreria_brenda_test` nunca se creó.

---

## 5. Limpieza del entorno del auditor

| Elemento | Ubicación | Estado |
|---|---|---|
| Cookie jars de sesión anónima | `/tmp/aud_f2_cookies.txt`, `/tmp/aud_f2_cookies_anon.txt` | Temporales, fuera del repositorio, se descartan con `/tmp` |
| Respuestas HTML/JSON crudas | `/tmp/f2_*.html`, `/tmp/f2_*.json`, `/tmp/f2_carrito_servido.js` | Temporales, fuera del repositorio |
| Programa auxiliar de Fase 1 | `/tmp/audit/Harness.java`, `/tmp/audit_classes/` | Temporales, fuera del repositorio |
| Nada escrito en el repositorio fuera de `docs/auditoria/` y `.gitignore` | — | Verificado con `git status --porcelain` |
| Nada escrito en bases de datos | — | Verificado en §4 |

**Recomendación operativa:** los `JSESSIONID` anónimos usados en esta auditoría siguen siendo válidos hasta que expiren (timeout de sesión: 30 min) o Tomcat se reinicie. No otorgan privilegios (no hubo autenticación), pero por higiene pueden invalidarse reiniciando el contenedor.

---

## 6. Acciones pendientes cuando exista un entorno de prueba

1. Crear `libreria_brenda_test` con el DDL versionado (hoy inexistente: hallazgo B-03).
2. Repuntar la aplicación a esa BD mediante `context.xml` + `DataSource` JNDI (elimina de paso el hallazgo C-01: credenciales fuera del repositorio).
3. Ejecutar entonces la batería completa: L2 (compra end-to-end), L6 (concurrencia con dos sesiones, código promocional de doble uso, sobreventa de stock), los payloads destructivos de inyección, la explotación efectiva de CSRF, y la verificación de A-02/A-03/A-04/M-04/M-05, hoy **Aún no verificados**.
