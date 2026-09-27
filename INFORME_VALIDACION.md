# INFORME DE VALIDACIÓN

**Actividad Práctica de Campo — Caso de Uso Principal al 100%**

_"Implementación web para la gestión de pedidos en la Librería Brenda", Lima 2026_

- **Curso:** Calidad y Pruebas de Software
- **Cliente / Empresa:** Librería Brenda
- **Product Owner:** Sra. Brenda Erika Bolo Vergara
- **Scrum Master:** Nicolas Favio Quiroz Salvador
- **Fecha de validación:** 27/09/2026

## 1. Objetivo

Validar, contra la especificación de Casos de Uso definida en el Sprint 0 (sección 4.7 del Modelo e Informe de Calidad), que el caso de uso principal del sistema — el flujo completo de compra en línea — se encuentra implementado y funcionando al 100% sobre el código fuente actual del proyecto LibreriaBrend.

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

Tras aplicar la corrección del punto 5, el caso de uso principal (flujo completo de compra: CU-01 a CU-06) queda implementado y validado al 100% contra su especificación original, sin deuda técnica pendiente sobre este flujo.
