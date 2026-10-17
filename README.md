# LibreriaBrend

Maqueta académica de una tienda en línea para la **Librería Brenda** (Lima, 2026), desarrollada para el curso **Calidad y Pruebas de Software** de la UPN. Incluye catálogo, cuentas de cliente, carrito, pedidos y un panel administrativo.

Este repositorio contiene solo el producto y sus pruebas. Los informes, rúbricas, capturas y entregas del curso se conservan **fuera** del repositorio.

## Stack y arquitectura

- **Java 21** (probado con OpenJDK 21), JSP y Jakarta Servlets 6.
- **JDBC + DAOs** sobre **MariaDB 11** (compatible con MySQL 8).
- **Apache Tomcat 11** como contenedor web.
- **JavaScript y CSS** sin framework de frontend; las vistas llaman a los servlets por `fetch`.
- Autenticación con sesiones HTTP y contraseñas con **BCrypt** (`jbcrypt`).
- Librerías versionadas en `WebContent/WEB-INF/lib/` (conector MySQL, jBCrypt y JUnit Console).

Capas principales: `src/libreria/models` (modelo), `src/libreria/dao` (acceso a datos), `src/libreria/servlets` (controladores HTTP), `src/libreria/filtros` (control de acceso), `src/libreria/util` (conexión, validadores, contraseñas), `WebContent` (JSP, JS y CSS).

## Requisitos

- JDK 21.
- Apache Tomcat 11.
- MariaDB 11 o MySQL 8 en `localhost:3306`.
- Las librerías de `WebContent/WEB-INF/lib/` (no hace falta descargar nada más).

## Puesta en marcha local

### 1. Crear una base de datos de PRUEBA

Nunca ejecutes las pruebas de escritura contra la base comercial `libreria_brenda`.

```bash
mysql -u root -p < database/schema_test.sql
mysql -u root -p < database/fixtures_test.sql
```

- `database/schema_test.sql` crea `libreria_brenda_test` con tablas y vistas, **sin datos**.
- `database/fixtures_test.sql` carga datos **ficticios**: 14 productos, 3 clientes y 3 cupones.
- Usuarios de prueba: `admin@test.local` / `Admin#2026` (código `EMP-TEST`) y `cliente.a@test.local` / `Cliente#2026`.

### 2. Configurar la conexión sin editar código

`ConexionBD` lee la configuración de variables de entorno o de propiedades del sistema. No hay usuario ni contraseña embebidos en el código.

| Variable | Por defecto | Uso |
|---|---|---|
| `DB_URL` | — | URL JDBC completa; si existe, ignora las demás |
| `DB_HOST` | `localhost` | Host del motor |
| `DB_PORT` | `3306` | Puerto |
| `DB_NAME` | `libreria_brenda` | Nombre de la base |
| `DB_USER` | `root` | Usuario |
| `DB_PASSWORD` | vacío | Contraseña |

Ejemplo (Linux/macOS):

```bash
export DB_NAME=libreria_brenda_test
export DB_USER=root
export DB_PASSWORD=tu_clave
```

PowerShell:

```powershell
$env:DB_NAME="libreria_brenda_test"; $env:DB_USER="root"; $env:DB_PASSWORD="tu_clave"
```

### 3. Compilar y desplegar en Tomcat

Con Eclipse: importar el proyecto, marcarlo como *Dynamic Web Project* y ejecutarlo en el servidor Tomcat 11. El `.classpath` ya incluye `src`, `test` y las librerías de `WEB-INF/lib`.

Alternativa manual:

```bash
# compilar clases de producción (ajusta las rutas de Tomcat si hace falta)
javac -encoding UTF-8 -cp "WebContent/WEB-INF/lib/mysql-connector-j-9.7.0.jar:WebContent/WEB-INF/lib/jbcrypt-0.4.jar:<TOMCAT>/lib/servlet-api.jar:<TOMCAT>/lib/jsp-api.jar" \
  -d build/classes $(find src -name '*.java')

# publicar el contexto
cp -r WebContent/. <TOMCAT>/webapps/LibreriaBrend/
cp -r build/classes/. <TOMCAT>/webapps/LibreriaBrend/WEB-INF/classes/
```

Abrir `http://localhost:8080/LibreriaBrend/index.jsp`.

## Módulos principales

- **Catálogo y búsqueda:** `index.jsp` y `ProductoServlet` (GET público).
- **Cuentas:** registro, login con bloqueo tras 5 intentos fallidos y logout.
- **Carrito:** hasta 10 productos distintos; el servidor recalcula precios y envío.
- **Pedidos:** creación transaccional, descuento de stock, consulta de pedidos propios y cancelación con reposición de stock y liberación del cupón.
- **Administración:** productos, clientes, pedidos y reportes; menú compartido (`WEB-INF/jspf/admin-sidebar.jspf`) y control de acceso centralizado en `AuthFilter`.
- **Imágenes de producto:** el formulario de productos acepta arrastrar y soltar JPG/PNG/GIF/WEBP (máx. 3 MB). `ImagenProductoServlet` valida tipo y firma del archivo y lo guarda en `images/productos`; la ruta se envía con el producto. Se puede cambiar la carpeta con `UPLOAD_DIR` (propiedad del sistema o variable de entorno) si el WAR se despliega sin explotar.
- **Accesibilidad:** preferencias de daltonismo y lectura por voz (funcionalidad parcial).

> Detalle de los cambios del panel administrativo y de la carga de imágenes: [`docs/REPORTE_PANEL_ADMIN.md`](docs/REPORTE_PANEL_ADMIN.md).

## Cómo correr los tests

### Unitarios JUnit 5 (52 tests)

Linux/macOS (separador `:`):

```bash
L=WebContent/WEB-INF/lib
javac -encoding UTF-8 -cp "$L/junit-platform-console-standalone-1.11.4.jar:$L/jbcrypt-0.4.jar" -d out/junit-check \
  src/libreria/models/Producto.java src/libreria/models/CodigoPromo.java src/libreria/models/Pedido.java \
  src/libreria/util/ValidadorProducto.java src/libreria/util/PasswordUtil.java src/libreria/util/ControlIntentosLogin.java \
  $(find test -name '*.java')

java -jar "$L/junit-platform-console-standalone-1.11.4.jar" \
  -cp "out/junit-check:$L/jbcrypt-0.4.jar" --scan-class-path out/junit-check --disable-banner
```

En **Windows (Git Bash)** usa `;` como separador de classpath en ambos comandos.

### Integración HTTP/BD (80 comprobaciones)

Requiere un Tomcat apuntando a `libreria_brenda_test` y el script carga los fixtures antes de ejecutar. Nunca usa la base comercial.

```bash
DB_NAME=libreria_brenda_test DB_PASSWORD=tu_clave \
BASE=http://localhost:8091/LibreriaBrend \
bash test/integration/http-tests.sh
```

El script cubre acceso anónimo, login/bloqueo, validación de productos, compra, cupones, cancelación, stock, límite de 10 productos y payloads malformados.

## Estado verificado y limitaciones

**Verificado en ejecución el 17/10/2026** (OpenJDK 21, Tomcat 11.0.26, MariaDB 11.8):

- **52/52 tests unitarios** JUnit 5.
- **80/80 comprobaciones de integración HTTP/BD** contra `libreria_brenda_test`.
- Acceso anónimo a pedidos corregido (`401`), errores internos ya no se exponen, categoría inexistente y stock/precio malformados se rechazan con `400`, cancelación repone stock y libera cupón.

**No ejecutado o fuera del alcance inmediato:**

- Validación integral de accesibilidad con lector de pantalla/contraste/WCAG (solo revisión parcial de DOM y teclado).
- Pruebas de carga y concurrencia; cobertura instrumentada (JaCoCo).
- Tokens CSRF y atributo `SameSite` en cookies (QA-15).
- Funcionalidades de backlog sin evidencia: ficha individual de producto, administración de categorías y recuperación de contraseña.

**Deuda conocida:** `libreria_brenda_backup.sql` sigue versionado y contiene datos históricos. No debe usarse para pruebas ni publicarse; su retiro del repositorio e historial requiere aprobación del equipo y, si las credenciales fueron reales, rotación.

## Roles académicos

| Rol | Integrante |
|---|---|
| Product Owner | Brenda Erika Bolo Vergara |
| Scrum Master | Nicolás Favio Quiroz Salvador |
| QA / analista de calidad | Kevin David Urbe Bolo |
| Equipo de desarrollo | Harold Alexis Córdova Ascarza, José Luis Rodríguez Navarro, Jeeicson Youfre Vise Soto |
