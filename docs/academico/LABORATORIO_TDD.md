# LABORATORIO DE CALIDAD — TDD sobre H0007 (Registrar Producto)

**Curso:** Calidad y Pruebas de Software · **Fecha:** 2026-09-28
**Historia de usuario:** H0007 — Registrar Producto (módulo Catálogo, tarea 5 del Sprint 2: "validaciones de formulario: precio, stock, campos requeridos")
**Técnica:** TDD (Test-Driven Development) — ciclos Rojo → Verde → Refactor
**Framework:** JUnit 5 (`junit-platform-console-standalone-1.11.4.jar`), sin gestor de build.

---

## 1. Contexto

Librería Brenda es un comercio local de papelería, libros escolares y suministros de oficina, con un sistema web (JSP/Servlets/MariaDB) para gestionar catálogo, pedidos y clientes. El Sprint 2 (07/09–13/09/2026) implementó el módulo de Catálogo de Productos, donde el administrador registra, edita, inactiva y elimina productos.

Al aplicar TDD sobre la historia H0007 (Registrar Producto) se detectó que las reglas de validación de datos (nombre obligatorio, precio positivo, stock no negativo, categoría válida) **solo existían en el formulario del navegador y no en el servidor**, lo que permitía registrar productos con datos inválidos.

### Defecto confirmado en el código (previo a la corrección)

| Problema | Evidencia en el código |
|---|---|
| Precio o stock inválido se convertía en `0` sin avisar | `ProductoServlet.leerProductoDeRequest()`: `catch (NumberFormatException e) { p.setPrecio(0); }` |
| Un precio negativo pasaba sin problema | `ProductoDAO.crear()` insertaba `precio` tal cual, sin regla alguna |
| El nombre podía llegar `null` | El servlet no validaba nada antes de llamar al DAO |
| Una categoría inexistente caía silenciosamente a la categoría 1 | `ProductoDAO.obtenerCategoriaId()`: `return 1; // fallback` |

Se define entonces `ValidadorProducto`, construido test-first, para hacer cumplir esas reglas en el backend.

---

## 2. Preparación del entorno

- Descarga de JUnit 5 (console standalone) a las librerías del proyecto:

```text
$ curl -L -o WebContent/WEB-INF/lib/junit-platform-console-standalone-1.11.4.jar \
    https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.11.4/junit-platform-console-standalone-1.11.4.jar
```

- Registrado en `.classpath` de Eclipse (librería JUnit + carpeta fuente `test/`) para que VS Code/Eclipse resuelvan las anotaciones.
- Comando de trabajo usado en todo el laboratorio (se corrió tras cada Rojo y tras cada Verde):

```bash
javac -encoding UTF-8 -cp WebContent/WEB-INF/lib/junit-platform-console-standalone-1.11.4.jar \
  -d out src/libreria/models/Producto.java src/libreria/util/ValidadorProducto.java \
  test/libreria/util/ValidadorProductoTest.java
java -jar WebContent/WEB-INF/lib/junit-platform-console-standalone-1.11.4.jar \
  --class-path out --scan-class-path --disable-banner
```

- Helper del test (agregado antes del ciclo 2): cada test cambia **un solo campo** de un producto válido, para probar exactamente su regla:

```java
private Producto productoValido() {
    return new Producto(1, "Cuaderno A4", "Cuaderno cuadriculado", 12.5, 10, "Cuadernos", "img.png");
}
```

---

## 3. Ciclo 1 (Rojo → Verde) — nombre obligatorio

Test primero, con esqueleto que devuelve lista vacía, para que falle **por aserción y no por compilación**:

```java
@Test
void nombreVacio_devuelveError() {
    Producto p = new Producto(0, "  ", "desc", 10.0, 5, "Libros", "img.png");
    List<String> errores = ValidadorProducto.validar(p);
    assertTrue(errores.contains("El nombre es obligatorio"));
}
```

**Rojo (salida real):**

```text
│     └─ nombreVacio_devuelveError() ✘ expected: <true> but was: <false>
    => org.opentest4j.AssertionFailedError: expected: <true> but was: <false>
[         0 tests successful      ]
[         1 tests failed          ]
```

**Verde** — lo mínimo para pasar:

```java
if (p.getNombre() == null || p.getNombre().trim().isEmpty()) {
    errores.add("El nombre es obligatorio");
}
```

**Verde (salida real):**

```text
│     └─ nombreVacio_devuelveError() ✔
[         1 tests successful      ]
[         0 tests failed          ]
```

---

## 4. Ciclo 2 (Rojo → Verde) — precio mayor a 0

**Rojo** — tests agregados (con `productoValido()` y `setPrecio`, un solo campo por test):

```java
@Test void precioCero_devuelveError()      { ... p.setPrecio(0);    ... }
@Test void precioNegativo_devuelveError()  { ... p.setPrecio(-5.0); ... }
```

**Rojo (salida real):**

```text
│     ├─ precioCero_devuelveError() ✘ expected: <true> but was: <false>
│     └─ precioNegativo_devuelveError() ✘ expected: <true> but was: <false>
[         1 tests successful      ]
[         2 tests failed          ]
```

**Verde:**

```java
if (p.getPrecio() <= 0) {
    errores.add("El precio debe ser mayor a 0");
}
```

**Verde (salida real):**

```text
[         3 tests successful      ]
[         0 tests failed          ]
```

---

## 5. Ciclo 3 (Rojo → Verde) — stock no negativo, con test de borde

**Rojo** — dos tests: uno que debe fallar y un **test de borde**:

```java
@Test void stockNegativo_devuelveError() { ... p.setStock(-1); ... }
@Test void stockCero_noDevuelveError()   { ... p.setStock(0);  ... }
```

`stockCero_noDevuelveError` es un **test de borde que pasa desde el inicio** (todavía no existe ninguna regla de stock): protege contra el error clásico de escribir `<= 0` en vez de `< 0`. El que debe fallar en rojo es `stockNegativo_devuelveError`.

**Rojo (salida real — coincide con lo previsto):**

```text
│     ├─ stockCero_noDevuelveError() ✔
│     └─ stockNegativo_devuelveError() ✘ expected: <true> but was: <false>
[         4 tests successful      ]
[         1 tests failed          ]
```

**Verde:**

```java
if (p.getStock() < 0) {
    errores.add("El stock no puede ser negativo");
}
```

**Verde (salida real):**

```text
[         5 tests successful      ]
[         0 tests failed          ]
```

---

## 6. Ciclo 4 (Rojo → Verde) — categoría obligatoria

**Rojo:**

```java
@Test void categoriaNula_devuelveError()  { ... p.setCategoria(null); ... }
@Test void categoriaVacia_devuelveError() { ... p.setCategoria("   "); ... }
```

**Rojo (salida real):**

```text
│     ├─ categoriaNula_devuelveError() ✘ expected: <true> but was: <false>
│     └─ categoriaVacia_devuelveError() ✘ expected: <true> but was: <false>
[         5 tests successful      ]
[         2 tests failed          ]
```

**Verde:**

```java
if (p.getCategoria() == null || p.getCategoria().trim().isEmpty()) {
    errores.add("La categoría es obligatoria");
}
```

**Verde (salida real):**

```text
[         7 tests successful      ]
[         0 tests failed          ]
```

---

## 7. Ciclo 5 — producto válido y acumulación (tests de regresión, pasan de inmediato)

Estos dos tests **no agregan código de producción**: fijan que un producto correcto no genera falsos positivos y que los errores se acumulan en una sola pasada.

```java
@Test void productoValido_noDevuelveErrores() { ... assertTrue(errores.isEmpty()); ... }
@Test void variosCamposInvalidos_acumulaTodosLosErrores() { ... assertEquals(4, ...size()); ... }
```

**Salida real (verde de inmediato, como estaba previsto):**

```text
│     ├─ variosCamposInvalidos_acumulaTodosLosErrores() ✔
│     └─ productoValido_noDevuelveErrores() ✔
[         9 tests successful      ]
[         0 tests failed          ]
```

### Refactor (con los 9 tests en verde)

Versión final de `ValidadorProducto`: se elimina lo repetido de vacío/nulo con el helper `vacio()` y los mensajes pasan a constantes:

```java
public class ValidadorProducto {

    static final String ERR_NOMBRE    = "El nombre es obligatorio";
    static final String ERR_PRECIO    = "El precio debe ser mayor a 0";
    static final String ERR_STOCK     = "El stock no puede ser negativo";
    static final String ERR_CATEGORIA = "La categoría es obligatoria";

    public static List<String> validar(Producto p) {
        List<String> errores = new ArrayList<>();

        if (vacio(p.getNombre()))    errores.add(ERR_NOMBRE);
        if (p.getPrecio() <= 0)      errores.add(ERR_PRECIO);
        if (p.getStock() < 0)        errores.add(ERR_STOCK);
        if (vacio(p.getCategoria())) errores.add(ERR_CATEGORIA);

        return errores;
    }

    private static boolean vacio(String s) {
        return s == null || s.trim().isEmpty();
    }
}
```

**Corrida completa tras el refactor (salida real):**

```text
[         9 tests successful      ]
[         0 tests failed          ]
```

> Nota: durante una pasada intermedia se experimentó con constantes públicas (`MSG_*`) usadas también desde el test; la versión final usa constantes package-private (`ERR_*`) con los mensajes como literales en los tests, que es la forma que mejor enseña TDD (el test no depende de constantes de producción).

---

## 8. Ciclo 7 — Integración en el servidor (ProductoServlet)

La regla se hace cumplir **en el servidor**: `crear` y `editar` validan antes de tocar el DAO y responden **HTTP 400** con `{"ok":false,"error":...}` (errores unidos con `" | "`).

```java
if ("crear".equals(accion)) {
    Producto p = leerProductoDeRequest(request);
    List<String> errores = ValidadorProducto.validar(p);
    if (!errores.isEmpty()) {
        response.setStatus(400);
        out.print("{\"ok\":false,\"error\":\"" + esc(String.join(" | ", errores)) + "\"}");
        return;
    }
    ...
```

- El frontend del panel admin (`productos.jsp`, `guardarProducto()`) ya manejaba `if (!data.ok) { mostrarMsgModal(data.error, 'error'); return; }`, por lo que muestra los mensajes del servidor sin cambios en el JS.
- Nota: el fallback silencioso de `ProductoDAO.obtenerCategoriaId()` (categoría 1) se deja documentado como defecto separado; con la validación de categoría obligatoria en el servlet, hoy ya no se alcanza desde el flujo de crear/editar.
- Pendiente para un próximo laboratorio: refactor del propio `obtenerCategoriaId` para que una categoría inexistente sea un error explícito y no un fallback.

### Verificación de integración

- Compilación completa del proyecto (todas las clases de `src/`): **COMPILACION OK**.
- Prueba HTTP end-to-end: **pendiente** — Tomcat estaba detenido al cerrar esta sesión (el flujo de republish del proyecto requiere levantarlo y publicar la app; se lista en la sección 10).

---

## 9. Archivos creados/modificados

| Archivo | Cambio |
|---|---|
| `test/libreria/util/ValidadorProductoTest.java` | **Nuevo.** 9 tests JUnit 5 de `ValidadorProducto` con helper `productoValido()` |
| `src/libreria/util/ValidadorProducto.java` | **Nuevo.** Reglas de validación de H0007 (test-first) + refactor final |
| `src/libreria/servlets/ProductoServlet.java` | `crear`/`editar` validan con `ValidadorProducto`; responden 400 + JSON de error si hay errores |
| `WebContent/WEB-INF/lib/junit-platform-console-standalone-1.11.4.jar` | **Nuevo.** JUnit 5 console standalone |
| `.classpath` | Librería JUnit + carpeta fuente `test/` |

---

## 10. Cómo reproducir los tests

```bash
javac -encoding UTF-8 -cp WebContent/WEB-INF/lib/junit-platform-console-standalone-1.11.4.jar \
  -d out src/libreria/models/Producto.java src/libreria/util/ValidadorProducto.java \
  test/libreria/util/ValidadorProductoTest.java

java -jar WebContent/WEB-INF/lib/junit-platform-console-standalone-1.11.4.jar \
  --class-path out --scan-class-path --disable-banner
```

Salida esperada: `9 tests successful, 0 failed`.

### Estado y pendientes

| Ítem | Estado |
|---|---|
| 9/9 tests JUnit en verde | ✅ ejecutado |
| Compilación completa del proyecto | ✅ ejecutada |
| Republish en Tomcat + prueba HTTP 400 real (payload inválido sobre `/ProductoServlet`) | ⏳ pendiente (Tomcat detenido en esta sesión) |

### Límites honestos (para el informe)

- Los 9 tests prueban la lógica de `ValidadorProducto`, no la BD ni el servlet: el servlet se verificó por compilación y revisión de código; la prueba HTTP end-to-end queda pendiente del republish.
- No se afirma cobertura de código medida por herramienta (sin JaCoCo); la cobertura es la implícita en los 9 casos de prueba.
- La lista de categorías no se valida contra la BD (solo obligatoriedad y no-vacío); validar contra catálogo requiere integración con `categorias` y queda fuera de este ciclo.

---

## 11. Material para el envío de la actividad

- **Contexto:** sección 1 (defecto detectado + tabla de evidencias en código).
- **Captura roja y verde por ciclo:** secciones 3–7; la nota de qué tests pasan desde el inicio está en la sección 5 (borde, `stockCero`) y 7 (regresión, válido y acumulación).
- **Código final:** sección 7 (refactor) y `src/libreria/util/ValidadorProducto.java` / `test/libreria/util/ValidadorProductoTest.java`.
- **Hallazgo de origen:** el servlet no validaba en servidor (sección 1); el ciclo 7 (conexión del servlet) ya está aplicado y documentado en la sección 8, con la prueba HTTP pendiente del republish.
