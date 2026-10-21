# LibreriaBrend

Maqueta académica de una tienda en línea para la **Librería Brenda** (Lima, 2026), desarrollada para el curso **Calidad y Pruebas de Software** de la UPN. Incluye catálogo, cuentas de cliente, carrito, pedidos y un panel administrativo.

Este repositorio contiene solo el producto y sus pruebas. Los informes, rúbricas, capturas y entregas del curso se conservan **fuera** del repositorio.

## Enfoque QA (portafolio)

- **JUnit 5:** 90 pruebas. 72 corren sin motor de base de datos; 18 prueban los DAO de login contra `libreria_brenda_test`.
- **Integración HTTP:** 62 comprobaciones de RF02 (login, roles, sesión, bloqueo) y 80 comprobaciones generales de carrito, pedidos, cupones y permisos.
- **TDD real:** validador de correo, tolerancia a hashes BCrypt malformados y rotación de sesión. Los ciclos RED → GREEN están documentados con evidencia, sin fabricar fallos para código que ya funcionaba.
- **Herramientas:** Java 21, JUnit 5, Tomcat 11, MariaDB 11, Bash/curl y GitHub Actions (dos jobs verificados en el PR #3).
- **Detalle:** [matriz y evidencias de RF02](docs/QA/RF02_LOGIN.md) · [saneamiento y riesgo residual](docs/QA/SEGURIDAD_REPOSITORIO.md).

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
- Las librerías de `WebContent/WEB-INF/lib/` y las APIs de Tomcat de `lib/tomcat-11/` (no hace falta descargar nada más para compilar).

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

`ConexionBD` resuelve la conexión en este orden: **propiedad del sistema** (`-DDB_NAME=...`) → **variable de entorno** → **`WebContent/WEB-INF/db.properties`** → valor por defecto. No hay usuario ni contraseña embebidos en el código.

| Clave | Por defecto | Uso |
|---|---|---|
| `DB_URL` | — | URL JDBC completa; si existe, ignora las demás |
| `DB_HOST` | `localhost` | Host del motor |
| `DB_PORT` | `3306` | Puerto |
| `DB_NAME` | `libreria_brenda` | Nombre de la base |
| `DB_USER` | `root` | Usuario |
| `DB_PASSWORD` | vacío | Contraseña |

**Desde el IDE (VS Code/Eclipse) lo más simple es el archivo**, porque no hay que configurar variables en el servidor:

```bash
cp WebContent/WEB-INF/db.properties.example WebContent/WEB-INF/db.properties
# editar DB_USER / DB_PASSWORD / DB_NAME
```

`db.properties` está en `.gitignore`: cada entorno tiene el suyo y no se sube al repositorio. Si prefieres tenerlo fuera del proyecto, define `DB_CONFIG` con su ruta absoluta.

Ejemplo con variables de entorno (Linux/macOS):

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

Con Eclipse o VS Code: importar el proyecto como *Dynamic Web Project* y ejecutarlo en el servidor Tomcat 11. El `.classpath` ya incluye `src`, `test`, las librerías de `WEB-INF/lib` y las APIs de Tomcat de `lib/tomcat-11/`.

> Las APIs de Tomcat (`servlet-api`, `jsp-api`, `jasper-el`, `annotations-api`) están versionadas en `lib/tomcat-11/` **solo para compilar**: no se despliegan, porque el contenedor ya las aporta en tiempo de ejecución. No apuntes el `.classpath` a `.tools/` ni a una ruta absoluta del Tomcat instalado: el proyecto dejaría de compilar en otra máquina.

Alternativa manual (en Windows/Git Bash el separador de classpath es `;`, en Linux/macOS es `:`):

```bash
# compilar clases de producción
javac -encoding UTF-8 -cp "WebContent/WEB-INF/lib/mysql-connector-j-9.7.0.jar;WebContent/WEB-INF/lib/jbcrypt-0.4.jar;lib/tomcat-11/*" \
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
>
> Detalle de RF02 (matriz, TDD, evidencias y límites): [`docs/QA/RF02_LOGIN.md`](docs/QA/RF02_LOGIN.md).

## Cómo correr los tests

### JUnit 5 (72 sin BD / 90 con BD)

Un solo script compila todo el proyecto y ejecuta la suite. Sin `DB_NAME`, las pruebas de `libreria.dao` se omiten con `Assumptions`; con `DB_NAME=libreria_brenda_test` se ejecutan las 18 pruebas de los DAO de login.

```bash
# Suite rápida, sin motor de base de datos: 72/72
JUNIT_EXCLUDE='libreria\.dao\..*' bash test/run-junit-tests.sh

# Suite completa contra la base ficticia: 90/90
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=libreria_brenda_test \
DB_USER=root DB_PASSWORD=tu_clave bash test/run-junit-tests.sh
```

El script detecta el separador de classpath de Linux/macOS (`:`) y Git Bash en Windows (`;`). Las pruebas de DAO abortan si la conexión no apunta exactamente a `libreria_brenda_test`.

### Integración HTTP/BD

Requiere Tomcat con el contexto `/LibreriaBrend` y la base de prueba cargada. Los scripts cargan o crean sus propios datos ficticios; nunca usan la base comercial.

```bash
# RF02: login, roles, sesión y fuerza bruta (62 comprobaciones)
BASE=http://localhost:8091/LibreriaBrend \
DB_NAME=libreria_brenda_test DB_PASSWORD=tu_clave \
bash test/integration/rf02-login-tests.sh

# Regresión general: carrito, pedidos, cupones, stock y permisos (80 comprobaciones)
BASE=http://localhost:8091/LibreriaBrend \
DB_NAME=libreria_brenda_test DB_PASSWORD=tu_clave \
bash test/integration/http-tests.sh
```

La suite de RF02 crea correos `rf02.*@test.local` por ejecución y los elimina al terminar, para no acumular bloqueos ni depender de reiniciar Tomcat.

## Estado verificado y limitaciones

**Verificado en ejecución el 21/10/2026** (OpenJDK 21.0.12, Tomcat 11.0.26, MariaDB 11.8.9 en WSL2):

- **72/72 tests JUnit** sin base de datos y **90/90** con `libreria_brenda_test` (incluye 18 pruebas de DAO de login).
- **62/62 comprobaciones HTTP de RF02** y **80/80 comprobaciones HTTP generales** contra la base ficticia.
- RF02 cubre cliente activo/inactivo, contraseña incorrecta, correo inexistente y mal formado, límite de 120 caracteres, BCrypt, separación de roles, autorización y rotación de sesión en login y registro.
- Se corrigieron session fixation, el fallo con hashes BCrypt truncados y la aceptación de correos más largos que la columna.
- Regresión general en verde: acceso anónimo, validación de productos, compra, cupones, cancelación, stock, límite de 10 productos y payloads malformados.

**No ejecutado o fuera del alcance inmediato:**

- Validación integral de accesibilidad con lector de pantalla/contraste/WCAG (solo revisión parcial de DOM y teclado).
- Pruebas de carga y concurrencia; cobertura instrumentada (JaCoCo). No se afirma ningún porcentaje.
- Tokens CSRF y atributo `SameSite` en cookies (QA-15).
- Bloqueo de login en memoria: es por correo y compartido entre roles, por lo que cinco fallos pueden bloquear temporalmente a un administrador (DoS). Está documentado en [RF02](docs/QA/RF02_LOGIN.md#6-limitaciones-y-riesgos-abiertos).
- GitHub Actions: el workflow [`.github/workflows/junit.yml`](.github/workflows/junit.yml) se ejecutó en GitHub sobre el commit `32d7179`; los dos jobs terminaron en `success` ([evidencia](docs/QA/evidencias/ci-2026-10-21.txt)). La suite HTTP sigue fuera de CI.
- Funcionalidades de backlog sin evidencia: ficha individual de producto, administración de categorías y recuperación de contraseña.

**Saneamiento de datos:** el backup del árbol actual se saneó con datos sintéticos: 16 DNI de demostración, 17 correos `@example.com`, nombre y correo personal reemplazados, y todos los hashes de clientes y del admin sustituidos por hashes sintéticos de fixtures. El backup no contiene credenciales en texto plano. **El historial de Git no se reescribió**, así que los valores anteriores siguen en commits públicos; el alcance y el riesgo residual están en [docs/QA/SEGURIDAD_REPOSITORIO.md](docs/QA/SEGURIDAD_REPOSITORIO.md).

## Roles académicos

| Rol | Integrante |
|---|---|
| Product Owner | Brenda Erika Bolo Vergara |
| Scrum Master | Nicolás Favio Quiroz Salvador |
| QA / analista de calidad | Kevin David Urbe Bolo |
| Equipo de desarrollo | Harold Alexis Córdova Ascarza, José Luis Rodríguez Navarro, Jeeicson Youfre Vise Soto |
