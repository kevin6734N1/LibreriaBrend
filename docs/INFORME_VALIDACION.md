# INFORME DE VALIDACIÓN

**Actividad Práctica de Campo — Caso de Uso Principal (verificación parcial: ver sección 7)**

_"Implementación web para la gestión de pedidos en la Librería Brenda", Lima 2026_

- **Curso:** Calidad y Pruebas de Software
- **Cliente / Empresa:** Librería Brenda
- **Product Owner:** Sra. Brenda Erika Bolo Vergara
- **Scrum Master:** Nicolas Favio Quiroz Salvador
- **Fecha de validación:** 27/09/2026

## 1. Objetivo

Determinar, contra la especificación de Casos de Uso definida en el Sprint 0 (sección 4.7 del Modelo e Informe de Calidad), el estado real del caso de uso principal del sistema — el flujo completo de compra en línea — sobre el código fuente actual del proyecto LibreriaBrend, diferenciando lo efectivamente verificado de lo que queda abierto (ver sección 7).

## 2. Caso de Uso Principal Seleccionado

Se seleccionó el flujo de compra en línea del cliente por ser la historia de usuario de mayor prioridad y estimación del Product Backlog (HU-02, 8 puntos de historia: "Agregar productos al carrito y confirmar un pedido en línea"). Este flujo integra de forma secuencial los casos de uso CU-01, CU-02, CU-03, CU-04, CU-05 y CU-06 definidos en el modelo de calidad del Sprint 0.

## 3. Metodología de Validación

Se realizó una revisión directa del código fuente (servlets, DAOs y vistas JSP) del proyecto, contrastando cada flujo principal descrito en la especificación de casos de uso contra su implementación real, sin asumir funcionalidad no verificada en el código.

## 4. Resultados por Caso de Uso

| CU | Nombre | Estado | Evidencia (código) |
| --- | --- | --- | --- |
| CU-01 | Consultar catálogo de productos | **CUMPLE** | index.jsp -> ProductoServlet (GET), filtra activo=true |
| CU-02 | Registrar identificación del cliente (DNI) | **CUMPLE** | RegistroServlet: valida DNI/email únicos, dentro de registro con hash |
| CU-03 | Gestionar carrito de compras | **CUMPLE (corregido)** | carrito.js: agregar/quitar + límite de 10 productos añadido |
| CU-04 | Confirmar pedido | **CUMPLE** | carrito.jsp: resumen y total antes de enviar, con descuentos ODS10 |
| CU-05 | Registrar pedido con datos del cliente | **CUMPLE** | PedidoServlet.guardarPedidoEnDB() + PedidoDAO.crear() transaccional |
| CU-06 | Consultar pedidos realizados (admin) | **CUMPLE** | admin-pedidos.jsp: lista completa con cambio de estado (AuthFilter) |

## 5. Defecto Encontrado y Corrección Aplicada

**Defecto:** el flujo principal de CU-03 exige que "el sistema valida que no se supere el máximo de 10 productos" en el carrito. Esta validación no existía ni en el cliente (carrito.js) ni en el servidor (PedidoServlet), por lo que un usuario podía agregar una cantidad ilimitada de productos distintos.

**Corrección:** se agregó la validación de máximo 10 productos distintos en dos capas: en el cliente, dentro de `agregarCarrito()` (carrito.js), bloqueando el agregado de un producto nuevo cuando ya hay 10 líneas distintas en el carrito; y en el servidor, como respaldo, dentro de `PedidoServlet.guardarPedidoEnDB()`, rechazando la creación del pedido si se reciben más de 10 productos distintos, para no depender únicamente de la validación del navegador.

## 6. Conclusión

Tras aplicar la corrección del punto 5, el caso de uso principal (flujo de compra: CU-01 a CU-06) queda **implementado y verificado hasta aquí — esto queda abierto**, en los términos que precisa la **sección 7**. Esta versión del documento sustituye la afirmación original de "validado al 100% contra su especificación, sin deuda técnica pendiente", que la auditoría independiente no pudo sostener.

---

## 7. freebuff aclaración de la auditoría — 2026-09-28

**Este documento no puede sostener la afirmación de "100%" ni la de "sin deuda técnica pendiente" sobre el flujo CU-01 a CU-06.** La auditoría técnica independiente (`docs/auditoria/FASE2_INFORME.md` y `docs/auditoria/FASE2_CIERRE_LIMITACIONES.md`) verificó sobre la aplicación en ejecución (`http://localhost:8080/LibreriaBrend`, commit `291741c`) que:

- **`GET /PedidoServlet` sin cookies devuelve `200 OK` con los 8 pedidos del cliente `id=1`**, incluyendo dirección de entrega, método de pago y líneas de detalle: cualquier visitante anónimo puede leerlos. El mismo handler permite cancelar pedidos de ese cliente sin sesión (hallazgo **R-01 / C-02, Crítico**).
- El servidor devuelve **mensajes internos de la JVM** al cliente: `{"ok":false,"error":"Index 1 out of bounds for length 1"}` y `{"ok":false,"error":"Cannot load from object array because \"qtys\" is null"}` (hallazgo **R-02, Alto**).
- La cookie de sesión se emite **sin atributo `SameSite`** y no existe token CSRF en ninguna operación de escritura (hallazgo **R-07, Alto**).
- La **contraseña de la base de datos está embebida y versionada** en el repositorio (`src/libreria/util/ConexionBD.java:29-30`) y la **base de datos de producción está compilada dentro de la clase** (`ConexionBD.class`), sin configuración externa ni `DataSource` JNDI (hallazgo **C-01, Crítico**).
- **No existe ningún test automatizado permanente**, ni gestor de build, ni CI. Las pruebas citadas en el registro se ejecutaron con programas temporales que no están versionados y **no son reproducibles** (hallazgo **M-07, Medio**).

**Correcciones aplicadas a este documento en esta fecha:** el subtítulo y la conclusión dejan de afirmar una validación total. El estado real es **verificado hasta aquí — esto queda abierto**.

**Lo que sí quedó verificado y se mantiene:** CU-01, CU-02 y CU-03 se confirmaron por petición HTTP real; el límite de 10 productos se aplica **en el servidor** (11 ítems se rechazan, 10 pasan) y no depende del navegador; el control de acceso administrativo (`AuthFilter`) responde 302/401 correctamente; los 5 payloads de inyección SQL probados fueron refutados; el servidor recalcula los precios e ignora el `item_precio` enviado por el cliente; y el filtro de accesibilidad se aplica sobre `<html>`, no sobre `<body>`.

**CU-04 (confirmar pedido) y CU-05 (registrar pedido en BD) NO fueron verificados de forma independiente:** no existe base de datos de prueba y la aplicación apunta a producción, por lo que no se ejecutó ninguna escritura. Permanecen como *Aún no verificado* hasta que exista un entorno de pruebas.

**Nota de consistencia interna:** la fila de CU-04 de la tabla de la sección 4 menciona "descuentos ODS10", lógica que fue **retirada del sistema en el paso 2** (ver `docs/REGISTRO_CAMBIOS.md`). Esa referencia está desactualizada a la fecha de esta aclaración.

**No se afirma conformidad WCAG de ningún nivel:** no hubo validación con lector de pantalla real (NVDA/JAWS/VoiceOver) ni con navegador.
