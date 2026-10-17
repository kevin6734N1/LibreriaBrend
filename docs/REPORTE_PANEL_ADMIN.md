# Panel administrativo y carga de imágenes — cambios aplicados

**Fecha:** 17/10/2026
**Entorno de verificación:** OpenJDK 21 · Tomcat 11.0.26 (instancia aislada en `http://localhost:8091/LibreriaBrend`) · MariaDB 11.8 (`libreria_brenda_test`, docker `libreria-brenda-mariadb`)
**Alcance:** consistencia visual del panel, menú compartido, navegación por rol, separación pedidos de comprador/administración y subida de imágenes de producto por arrastrar y soltar.

---

## 1. Causas encontradas

| Síntoma | Causa real |
|---|---|
| Unos paneles se veían «más pálidos» que otros | El CSS administrativo estaba **duplicado** en `WebContent/css/style.css` y en estilos en línea de cada JSP. Las reglas de `style.css` se aplicaban después de las de cada página y se pisaban entre sí (`opacity`, `filter`, colores de sidebar/topbar). |
| Iconos como cuadrados blancos | Los PNG del proyecto son en realidad **JPEG/WebP sin transparencia** (`images/pendiente.png` es JPEG, `images/check.png` es WebP). Aplicarles `filter: brightness(10)` teñía también el fondo blanco y lo convertía en un bloque sólido. |
| Menús distintos según la página | Cada JSP repetía su propio `<aside class="sidebar">` con enlaces y clase `active` fija. `admin.jsp` tenía 5 opciones, otras páginas omitían «Clientes» o «Reportes». |
| «Pedidos» abría la pantalla equivocada | Enlaces copiados a mano: desde `productos.jsp` el ítem «Pedidos» apuntaba a `admin.jsp`; desde `clientes.jsp` y `reportes.jsp` apuntaba al `pedidos.jsp` **del comprador**. La administración de pedidos vive en `admin-pedidos.jsp`. |
| La opción activa no coincidía con la pantalla | La clase `active` estaba escrita en el HTML de cada página; al incluir un fragmento común había que calcularla. |
| «Librería» se veía como «LibrerÃ­a» | El fragmento incluido no declaraba `pageEncoding="UTF-8"`; el `include` se compilaba con la codificación por defecto. |
| Tablas y cabeceras cortadas en móvil | El layout usaba `min-width` fijos en tablas y `toolbar` sin `flex-wrap`, sin reglas específicas para pantallas pequeñas. |

## 2. Cambios aplicados

### 2.1 Un solo origen para los estilos

- `WebContent/css/admin.css` es ahora la **única** fuente del layout administrativo (sidebar, topbar, tarjetas, tablas, modal, formularios y responsive). Se eliminaron las reglas administrativas duplicadas de `style.css`, que queda solo con la tienda pública.
- Se quitaron los `<style>` locales que redefinían `.icon-img`, `.stat-card`, `.sidebar`, etc.
- Los iconos del menú pasaron a **SVG inline** (heredan `currentColor`); se eliminó el `filter: brightness(10)` que producía cuadrados blancos. En los filtros de estado de `pedidos.jsp` el icono activo se muestra sobre una ficha blanca redondeada en vez de teñirse.
- El `filter` de accesibilidad (daltonismo) se mantiene intacto: sigue aplicándose solo a `<html>` desde `js/accesibilidad.js`.

### 2.2 Menú compartido

- Nuevo fragmento `WebContent/WEB-INF/jspf/admin-sidebar.jspf`, incluido por `admin.jsp`, `admin-pedidos.jsp`, `productos.jsp`, `clientes.jsp` y `reportes.jsp`.
- Contiene **solo las opciones que existen en este proyecto**: Dashboard, Pedidos, Productos, Clientes, Reportes, Ver tienda y Cerrar sesión.
- Los enlaces se construyen con `request.getContextPath()`: no hay `localhost`, puertos ni nombres de tienda fijos, por lo que funciona igual en otro contexto o dominio.
- La opción activa se calcula con `request.getServletPath()` y se marca con `class="active"` + `aria-current="page"`.
- El nombre y el rol del encabezado salen de la sesión (`adminNombre`, `rol`) y el `pageEncoding="UTF-8"` del fragmento corrige los acentos.

### 2.3 Roles y permisos

- El proyecto **solo define el rol `admin`** en base de datos y en `AuthFilter`; no existen VENDEDOR ni SUPERADMIN. En lugar de inventar roles se documentó la situación y se dejó el punto único de extensión en `AuthFilter` (patrón de URLs) y en el fragmento del menú.
- `AuthFilter` sigue siendo el único punto de control: sin sesión `admin` las páginas redirigen a `login.jsp?error=sesion` y los servlets responden `401` JSON. Se añadió `/ImagenProductoServlet` a la lista protegida.
- Verificado con sesión de **cliente**: `productos.jsp` → `302` a login; `POST /ImagenProductoServlet` → `401`; `POST /ProductoServlet` (crear/editar) → `401`.
- El comprador conserva su propia pantalla `pedidos.jsp` («Mis Pedidos», solo sus pedidos vía `PedidoServlet`), separada de `admin-pedidos.jsp` (todos los pedidos y cambio de estado).

### 2.4 Navegación

- Todos los enlaces del panel apuntan a la pantalla correcta y conservan el contexto; se revisaron los `href` de las cinco páginas.
- En la tienda, el badge del carrito y el saludo del usuario se actualizan con `js/carrito.js` y el nombre de sesión; el enlace «Mis Pedidos» sigue llevando a `pedidos.jsp` (comprador), nunca al panel.
- El botón «Nuevo pedido» del comprador vuelve al catálogo (`index.jsp`).

### 2.5 Responsive

- `admin.css` incluye puntos de corte en 900/768/640/480 px: sidebar compacto, `toolbar` con `flex-wrap`, `stats-grid` de 2 columnas, tablas convertidas en tarjetas (`tabla-cards` con `data-label`) y modal a pantalla completa con botones al 100 %.
- Las tres tablas del panel (pedidos, productos y clientes) usan `tabla-cards`: por debajo de 640 px cada fila pasa a ser una ficha con etiqueta y las acciones quedan visibles sin desplazamiento horizontal.
- Verificado en navegador real (viewport móvil y 1280×900): `scrollWidth == clientWidth` en las tres pantallas (sin desborde horizontal) y botones de acción dentro del ancho de la ficha.

### 2.6 Carga de imágenes de producto (nuevo)

Antes, para asignar una imagen había que copiar el archivo a mano dentro del proyecto y escribir su ruta. Ahora:

- `WebContent/productos.jsp` muestra una **zona de arrastrar y soltar** (también accesible con teclado: `Enter`/`Espacio` abre el selector). Acepta JPG, PNG, GIF y WEBP de hasta 3 MB, muestra vista previa inmediata y guarda la ruta devuelta por el servidor en el campo «Ruta guardada en el proyecto» (que sigue siendo editable).
- Nuevo `src/libreria/servlets/ImagenProductoServlet.java` (`POST /ImagenProductoServlet`, `@MultipartConfig`):
  - exige sesión `admin` (además del `AuthFilter`);
  - lista blanca de `Content-Type` **y** verificación de los bytes de cabecera (magic numbers), de modo que un `.txt` renombrado a `.png` se rechaza;
  - límite de 3 MB (responde `413`), nombre saneado + sufijo aleatorio (evita traversal y colisiones) y carpeta `images/productos` del contexto;
  - responde `{"ok":true,"imagen":"images/productos/archivo.png"}` o `{"ok":false,"error":...}`.
- SVG se rechaza a propósito: puede contener `<script>` y se serviría desde el mismo origen.
- El botón «Guardar producto» se deshabilita mientras la imagen se está subiendo, para que no se guarde el producto con la ruta anterior.

## 3. Comprobaciones realizadas

### 3.1 Servidor (curl, sesión real)

| Caso | Resultado |
|---|---|
| `POST /ImagenProductoServlet` sin sesión | `401` `{"ok":false,...}` |
| Sesión de cliente | `401` |
| Sesión admin + PNG válido | `200`, archivo creado y servido con `Content-Type: image/png` |
| Texto renombrado a `.png` | `400` «El archivo no es una imagen valida…» |
| SVG | `400` «Formato no permitido…» |
| Archivo de 4 MB | `413` |
| `filename=../../evil.png` | guardado como `evil-<uuid>.png` dentro de `images/productos` |
| Petición sin el campo `archivo` | `400` |

### 3.2 Navegador real (Chromium del panel Preview)

- Login como `admin@test.local` → recorrido de Dashboard, Pedidos (admin), Productos, Clientes, Reportes: los cinco responden `200`, el menú es idéntico y la opción activa coincide con la pantalla.
- Arrastrar un PNG al modal de productos: vista previa inmediata, mensaje «Guardada en images/productos/…», ruta escrita en el formulario y producto creado con la imagen visible en la tabla (`naturalWidth > 0`). El producto de prueba se eliminó después; la base quedó con sus 15 productos originales.
- Formatos inválidos en el navegador: mensajes «Formato no permitido…» y «La imagen pesa demasiado…».
- Móvil: modal apilado, zona de carga centrada, botones al 100 %; tablas de pedidos, productos y clientes en formato ficha con las acciones a la vista.
- Comprador: `pedidos.jsp` muestra «Mis Pedidos», el filtro activo se ve correctamente y no hay enlaces al panel.

### 3.3 Pruebas automatizadas

- **52/52** tests unitarios JUnit 5 (`PedidoTest`, `CodigoPromoTest`, `PasswordUtilTest`, `ControlIntentosLoginTest`, `ValidadorProductoTest`).
- **80/80** comprobaciones de integración HTTP/BD de `test/integration/http-tests.sh` contra `libreria_brenda_test`.

## 4. Limitaciones y pendientes

- **No existen roles VENDEDOR/SUPERADMIN** en este proyecto (ni en `administradores` ni en `AuthFilter`). El menú muestra solo lo que el rol `admin` puede usar; añadir roles requiere decidir permisos y ampliar el filtro antes de mostrar nuevas opciones.
- Las imágenes se guardan en la carpeta del **contexto desplegado** (WAR explotado). Un redespliegue que reemplace `WebContent` borra los archivos subidos. Para producción conviene definir `UPLOAD_DIR` (propiedad del sistema o variable de entorno) apuntando a una carpeta persistente, o mover el almacenamiento a un servicio de objetos.
- No se comprimen ni redimensionan las imágenes, y no se borran los archivos huérfanos si se cancela la edición o se elimina el producto.
- Sigue pendiente el control CSRF (QA-15); la subida exige sesión admin y mismo origen implícito del navegador, pero no lleva token.
- El archivo `libreria_brenda_backup.sql` se deja intacto por decisión del equipo: contiene datos históricos y no se usa en pruebas.
