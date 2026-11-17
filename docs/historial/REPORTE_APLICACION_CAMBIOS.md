# Reporte: aplicación de cambios de `cambios de Claude.zip`

**Fecha:** 02/10/2026
**Origen:** `cambios de Claude.zip` (raíz del proyecto)
**Resultado final:** ✅ **52 tests ejecutados, 52 exitosos, 0 fallidos, 0 omitidos**

---

## 1. Qué contenía el zip

4 clases de prueba JUnit 5, sin estructura de carpetas interna (archivos planos):

| Archivo en el zip | Paquete declarado | Destino en el proyecto | Tests |
|---|---|---|---|
| `PedidoTest.java` | `libreria.models` | `test/libreria/models/PedidoTest.java` | 15 |
| `CodigoPromoTest.java` | `libreria.models` | `test/libreria/models/CodigoPromoTest.java` | 7 |
| `PasswordUtilTest.java` | `libreria.util` | `test/libreria/util/PasswordUtilTest.java` | 10 |
| `ControlIntentosLoginTest.java` | `libreria.util` | `test/libreria/util/ControlIntentosLoginTest.java` | 11 |

Los paquetes declarados coinciden con la estructura de paquetes de `src/`, por lo que cada archivo se colocó en el directorio espejo bajo `test/`. **Ninguno de los 4 existía previamente en el proyecto** (se verificó con `find test -type f`); no se sobrescribió nada.

## 2. Compatibilidad verificada antes de aplicar

- Las clases de producción que los tests usan existen y exponen las firmas requeridas:
  - `Pedido` (con `ItemPedido`, `Estado.PENDIENTE`, `calcularSubtotal`, `calcularTotal`, `getEnvio`, `setDescuento`, `getId`, `getFecha`).
  - `CodigoPromo` (`calcularDescuento`, `setTipo`, `setValor`).
  - `PasswordUtil` (`hash`, `verificar`).
  - `ControlIntentosLogin` (`registrarFallo`, `registrarExito`, `estaBloqueado`, `minutosRestantes`).
- Codificación de los archivos: ASCII/UTF-8 → compatible con `javac -encoding UTF-8`. Los comentarios con acentos se conservan bien.
- Jars necesarios presentes en `WebContent/WEB-INF/lib/`: `junit-platform-console-standalone-1.11.4.jar` y `jbcrypt-0.4.jar`.

## 3. Compilación y ejecución

Compilación limpia (sin warnings ni errores) de las 6 clases de producción involucradas + los 5 archivos de prueba de `test/`.

⚠️ **Nota de entorno (Windows):** el comando del laboratorio usa `:` como separador de classpath, que es válido en Linux/macOS. En Windows (Git Bash) `javac`/`java` exigen `;`. Con `:` la compilación fallaba con *"package org.junit.jupiter.api does not exist"* y *"package org.mindrot.jbcrypt does not exist"*. Corregido usando `;`:

```bash
L=WebContent/WEB-INF/lib

javac -encoding UTF-8 -cp "$L/junit-platform-console-standalone-1.11.4.jar;$L/jbcrypt-0.4.jar" -d out \
  src/libreria/models/Producto.java src/libreria/models/CodigoPromo.java src/libreria/models/Pedido.java \
  src/libreria/util/ValidadorProducto.java src/libreria/util/PasswordUtil.java src/libreria/util/ControlIntentosLogin.java \
  $(find test -name '*.java')

java -jar "$L/junit-platform-console-standalone-1.11.4.jar" -cp "out;$L/jbcrypt-0.4.jar" --scan-class-path out --disable-banner
```

## 4. Resultados de la ejecución

```
[         8 containers found      ]
[         8 containers successful ]
[        52 tests found           ]
[        52 tests started         ]
[        52 tests successful      ]
[         0 tests failed          ]
```

Duración: ~770 ms. Desglose por clase de prueba:

| Clase | Tests | Resultado |
|---|---:|---|
| `libreria.models.PedidoTest` | 15 | ✅ todos |
| `libreria.models.CodigoPromoTest` | 7 | ✅ todos |
| `libreria.util.PasswordUtilTest` | 10 | ✅ todos |
| `libreria.util.ControlIntentosLoginTest` | 11 | ✅ todos |
| `libreria.util.ValidadorProductoTest` (lab 7) | 9 | ✅ todos |
| **Total** | **52** | **✅ 52/52** |

## 5. Impacto en el código

- Cambio **puramente aditivo**: 4 archivos nuevos bajo `test/` (+1 carpeta nueva `test/libreria/models/`).
- **Cero modificaciones** en clases de producción, servlets, DAOs o configuración (verificado con `git status`: solo archivos nuevos sin seguimiento).
- El zip quedó en la raíz; puede eliminarse o agregarse a `.gitignore` si no se versionará.

## 6. Cobertura y limitaciones (igual que se informó al crear los tests)

- No cubren DAOs ni servlets (requieren MySQL/Tomcat).
- `minutosRestantes_recienBloqueado_sonDos` depende del reloj real (margen suficiente para no ser flaky).
- Son pruebas de caracterización/regresión (código preexistente), no de un ciclo TDD Rojo→Verde.
