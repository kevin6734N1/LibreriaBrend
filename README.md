# LibreriaBrend

Aplicación web de una tienda en línea para la **Librería Brenda** (Lima, 2026). Incluye catálogo, cuentas de cliente, carrito, pedidos y panel administrativo.

Nació como proyecto del curso **Calidad y Pruebas de Software** de la UPN y se mantiene como **un único proyecto** que también sirve como entorno práctico de **QA Automation**. No hay una versión universitaria separada de una versión de portafolio: el mismo código, las mismas pruebas y las mismas evidencias se usan para ambos fines. La demo es local y reproducible; no se presenta como un servicio público ni como software certificado para producción.

Este repositorio contiene el producto, las pruebas y la documentación técnica. Los informes, rúbricas y entregas del curso se conservan **fuera** del repositorio.

## Origen y atribución

El desarrollo base fue un trabajo grupal del curso. La atribución completa está en [Roles académicos](#roles-académicos). Mi aporte principal en esta etapa fue el trabajo de **QA**: matriz de RF02, pruebas JUnit y HTTP, ciclos TDD, automatización de CI, saneamiento del backup y documentación de evidencias. El README no atribuye todo el desarrollo a una sola persona.

## Enfoque QA (portafolio)

- **JUnit 5:** 97 pruebas. 78 se ejecutan sin motor de base de datos; 19 prueban los DAO contra `libreria_brenda_test` (login e historial de pedidos del modal).
- **Integración HTTP:** 62 comprobaciones de RF02 (login, roles, sesión, bloqueo), 29 de RF03 (bloqueo por intentos fallidos: fronteras, minutos restantes y coherencia entre roles) y 80 comprobaciones generales de carrito, pedidos, cupones y permisos.
- **TDD real:** validador de correo, tolerancia a hashes BCrypt malformados, rotación de sesión y la corrección de `minutosRestantes()` en RF03 (bloqueo vencido). Los ciclos RED → GREEN están documentados con evidencia, sin fabricar fallos para código que ya funcionaba.
- **Herramientas:** Java 21, JUnit 5, Tomcat 11, MariaDB 11, Bash/curl y GitHub Actions (dos jobs verificados en `main`).
- **Mapa de evidencias:** [docs/QA/README.md](docs/QA/README.md) · [matriz RF02](docs/QA/RF02_LOGIN.md) · [matriz RF03](docs/QA/RF03_BLOQUEO_LOGIN.md) · [saneamiento y riesgo residual](docs/QA/SEGURIDAD_REPOSITORIO.md).

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

#### 3.1. Ejecución desde VS Code (extensión Tomcat)

El repositorio incluye `.vscode/settings.json` con la configuración de la extensión **Tomcat**
(`al-rimi.tomcat`), que es la que aparece el botón de ejecución en la vista *Tomcat* de la barra
lateral. El proyecto usa su propio Tomcat en `.tools-libreria/apache-tomcat-11.0.26`, con puerto
HTTP **8082** y puerto de apagado 8006.

> La carpeta `.tools` de este repositorio es un enlace simbólico a un directorio de otro
> proyecto de la misma máquina. Por eso el Tomcat propio del proyecto vive en `.tools-libreria`:
> son instalaciones físicas distintas y no se interfieren.

Al pulsar **Deploy** en el nodo de la aplicación, la extensión compila con Eclipse, publica el
contexto en `webapps/LibreriaBrend` y arranca el Tomcat. La aplicación queda disponible en
`http://localhost:8082/LibreriaBrend/`.

Dos ajustes de la extensión tienen alcance `machine` (`tomcat.home`, `tomcat.base`, `tomcat.port`
y `tomcat.javaHome`), por lo que VS Code los **ignora** en el ámbito del proyecto: deben
configurarse en los ajustes de usuario de VS Code.

```jsonc
// Ajustes de usuario de VS Code (File > Preferences > Settings > Open User Settings)
"tomcat.home": "<ruta>\\.tools-libreria\\apache-tomcat-11.0.26",
"tomcat.base": "<ruta>\\.tools-libreria\\apache-tomcat-11.0.26",
"tomcat.port": 8082,
"tomcat.javaHome": "C:\\Program Files\\Microsoft\\jdk-21.0.12.101-hotspot"
```

### 4. Demo local con datos sintéticos

El script [`database/demo/libreria_brenda_demo.sql`](database/demo/libreria_brenda_demo.sql) crea una base **independiente** llamada `libreria_brenda_demo` y la carga con 16 clientes ficticios, 16 pedidos, 31 ítems y 8 comprobantes. Conserva los IDs y las claves foráneas, pero **no toca** `libreria_brenda` ni `libreria_brenda_test`.

```bash
mysql -h 127.0.0.1 -P 3306 -u root -p < database/demo/libreria_brenda_demo.sql
```

El seed es reejecutable: recrea las tablas **dentro de `libreria_brenda_demo`** y vuelve a dejar los datos de demostración. No lo ejecutes contra una base comercial.

| Dato | Valor sintético |
|---|---|
| Nombres | `Cliente Demo` + `Apellido 01`…`Apellido 16` |
| DNI | `99900001`…`99900016` |
| Correos | `cliente01@example.com`…`cliente16@example.com` |
| Teléfonos | `900000101`…`900000116` |
| Direcciones | `Av. Demo 101, Lima`…`Av. Demo 116, Lima` |
| Pedidos | mismos IDs, montos y estados; dirección de entrega sintética |

Para que Tomcat use la demo, apunta `db.properties` **y cualquier variable de entorno o `setenv.bat` que defina `DB_*`** (las variables tienen prioridad sobre el archivo) a:

```properties
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=libreria_brenda_demo
DB_USER=libreria_demo_app
DB_PASSWORD=tu_clave_local
```

La cuenta de aplicación no debe ser `root` ni `libaas_app`: el paso 5 crea
`libreria_demo_app` con permisos solo sobre `libreria_brenda_demo`. Reinicia
Tomcat y abre `http://localhost:8080/LibreriaBrend/login.jsp`.

> Si arrancas Tomcat desde VS Code, la extensión lanza Java directamente y
> **no ejecuta `bin/setenv.bat`**. En ese caso manda `WEB-INF/db.properties`:
> comprueba que apunte a `libreria_brenda_demo` antes de probar las cuentas demo.

| Rol | Correo | Contraseña | Código |
|---|---|---|---|
| Administrador | `admin@example.com` | `Admin#2026` | `EMP-DEMO` |
| Cliente | `cliente01@example.com` | `Cliente#2026` | — |

`clientes.jsp` ya no contiene clientes embebidos: el listado sale siempre de `ClienteServlet`/`ClienteDAO`. Si la consulta falla, la tabla queda vacía en vez de mostrar datos viejos. La verificación de este procedimiento (login, 16 filas sintéticas, modal con pedidos y regresión) está en [la evidencia de demo](docs/QA/evidencias/demo-sintetica-2026-10-21.txt).

Para volver a la base real, restaura los valores anteriores de `db.properties`/`setenv.bat` y reinicia Tomcat; la demo no modifica ninguna otra base.

### 5. Entorno aislado con Tomcat propio (`:8082`)

Este entorno no reutiliza el Tomcat de LibaaS ni sus credenciales. Vive en
`.tools-libreria/` (ignorado por Git) y escucha en `8082`, así que puede
convivir con el Tomcat antiguo de `:8080` sin detenerlo.

```bash
# 1. Descarga y descomprime Apache Tomcat 11 en .tools-libreria/
#    (no reutilices .tools/: en este checkout es un symlink a LibaaS).
mkdir -p .tools-libreria
# descomprime apache-tomcat-11.0.26.zip o .tar.gz aquí

# 2. Ajusta los puertos en conf/server.xml: HTTP 8082, shutdown 8006, AJP 8010.

# 3. Carga la base demo y crea un usuario limitado a ella.
mysql -h 127.0.0.1 -P 3306 -u root -p < database/demo/libreria_brenda_demo.sql
mysql -h 127.0.0.1 -P 3306 -u root -p <<'SQL'
CREATE USER 'libreria_demo_app'@'%' IDENTIFIED BY 'CAMBIA_ESTA_CLAVE';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE, SHOW VIEW
  ON libreria_brenda_demo.* TO 'libreria_demo_app'@'%';
SQL
```

El host `%` es necesario cuando MariaDB corre en Docker y la conexión del host
llega como `172.17.0.1`; el permiso sigue limitado exclusivamente a
`libreria_brenda_demo` (sin `CREATE`, `DROP`, `ALTER` ni privilegios globales).

```bash
TOMCAT=.tools-libreria/apache-tomcat-11.0.26

# 4. Compila y publica el contexto.
javac -encoding UTF-8 -cp "WebContent/WEB-INF/lib/mysql-connector-j-9.7.0.jar;WebContent/WEB-INF/lib/jbcrypt-0.4.jar;lib/tomcat-11/*" \
  -d build/classes $(find src -name '*.java')
cp -r WebContent/. "$TOMCAT/webapps/LibreriaBrend/"
cp -r build/classes/. "$TOMCAT/webapps/LibreriaBrend/WEB-INF/classes/"

# 5. Credenciales solo en el contexto desplegado (nunca en Git).
cat > "$TOMCAT/webapps/LibreriaBrend/WEB-INF/db.properties" <<'EOF'
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=libreria_brenda_demo
DB_USER=libreria_demo_app
DB_PASSWORD=CAMBIA_ESTA_CLAVE
EOF

# 6. Define JAVA_HOME y arranca (Windows: startup.bat; Linux/macOS: startup.sh).
export JAVA_HOME=/ruta/a/jdk-21   # Windows: set "JAVA_HOME=C:\ruta\a\jdk-21"
"$TOMCAT/bin/startup.sh"
```

Comprueba `http://localhost:8082/LibreriaBrend/login.jsp`. No definas `DB_*`
en el entorno ni en `setenv.bat`: tienen prioridad sobre `db.properties` y
podrían redirigir la aplicación a otra base. Para detener este Tomcat usa su
`shutdown.sh`/`shutdown.bat`; no detengas el de `:8080`.

| Comprobación | Resultado esperado |
|---|---|
| Login admin | `admin@example.com` / `Admin#2026` / `EMP-DEMO` |
| Login cliente | `cliente01@example.com` / `Cliente#2026` |
| `clientes.jsp` | 16 filas `Cliente Demo`, DNI `999000xx` |
| Pedidos del cliente 01 | 8 pedidos en `pedidos.jsp` y en el modal |
| Catálogo | 11 productos activos desde `ProductoServlet` |
| Aislamiento SQL | `SELECT` sobre `libreria_brenda` y `libreria_brenda_test` denegado |

La evidencia de esta ejecución está en
[`docs/QA/evidencias/entorno-aislado-2026-10-21.txt`](docs/QA/evidencias/entorno-aislado-2026-10-21.txt).

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
>
> Detalle de RF03 — bloqueo temporal por intentos fallidos (matriz, TDD con reloj inyectado, evidencias y límites): [`docs/QA/RF03_BLOQUEO_LOGIN.md`](docs/QA/RF03_BLOQUEO_LOGIN.md).

## Cómo correr los tests

### JUnit 5 (78 sin BD / 97 con BD)

Un solo script compila todo el proyecto y ejecuta la suite. Sin `DB_NAME`, las 3 clases de `libreria.dao` se omiten con `Assumptions` (se ejecutan 78 pruebas); con `DB_NAME=libreria_brenda_test` se ejecutan las 19 pruebas de DAO, incluidas las de login y el historial del modal.

```bash
# Suite rápida, sin motor de base de datos: 78 ejecutadas, 0 fallos
JUNIT_EXCLUDE='libreria\.dao\..*' bash test/run-junit-tests.sh

# Suite completa contra la base ficticia: 97/97
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

# RF03: bloqueo temporal por intentos fallidos (29 comprobaciones)
BASE=http://localhost:8091/LibreriaBrend \
DB_NAME=libreria_brenda_test DB_PASSWORD=tu_clave \
bash test/integration/rf03-bloqueo-tests.sh

# Regresión general: carrito, pedidos, cupones, stock y permisos (80 comprobaciones)
BASE=http://localhost:8091/LibreriaBrend \
DB_NAME=libreria_brenda_test DB_PASSWORD=tu_clave \
bash test/integration/http-tests.sh
```

La suite de RF02 crea correos `rf02.*@test.local` por ejecución y la de RF03 correos `rf03.*@test.local`; todos se eliminan al terminar, para no acumular bloqueos ni depender de reiniciar Tomcat.

### CI en GitHub Actions

El workflow [`.github/workflows/junit.yml`](.github/workflows/junit.yml) se ejecuta en cada push a `main` o a ramas `qa/**`, en pull requests y de forma manual. Tiene dos jobs independientes:

1. **Tests unitarios (sin BD):** compila y ejecuta la suite excluyendo `libreria.dao`; no necesita MariaDB.
2. **Login de clientes y administradores (DAO + BD):** levanta MariaDB 11.8 como servicio, carga `database/schema_test.sql` y `database/fixtures_test.sql`, y ejecuta las pruebas de DAO contra `libreria_brenda_test`.

Los resultados de la última ejecución se consultan en la pestaña **Actions** de `main`; la corrida del merge de RF03 quedó registrada en [la evidencia de CI](docs/QA/evidencias/ci-2026-10-29-rf03-main.txt). La suite HTTP no está en CI porque requiere un Tomcat desplegado; se ejecuta localmente contra `:8091` y la base de pruebas.

## Estado verificado y limitaciones

**Verificado en ejecución el 23/10/2026** (OpenJDK 21.0.12; JUnit contra MariaDB 11.8.9 aislada en `127.0.0.1:3307`; suites HTTP contra Tomcat de pruebas en `:8091`):

- **78 tests JUnit ejecutados sin base de datos** (0 fallos) y **97/97** con `libreria_brenda_test` (incluye 19 pruebas de DAO: login y pedidos del modal).
- **62/62 comprobaciones HTTP de RF02**, **29/29 de RF03** y **80/80 comprobaciones HTTP generales** contra la base ficticia.
- **RF03:** fronteras de expiración probadas con reloj inyectado (sin esperas reales) y corrección de `minutosRestantes()` que informaba 1 minuto en un bloqueo ya vencido; detalle en [matriz RF03](docs/QA/RF03_BLOQUEO_LOGIN.md).
- **CI:** dos jobs de GitHub Actions en verde sobre el merge de RF03 en `main` (runs #17, #18 y #19); el detalle de la corrida está en [la evidencia de CI](docs/QA/evidencias/ci-2026-10-29-rf03-main.txt).
- RF02 cubre cliente activo/inactivo, contraseña incorrecta, correo inexistente y mal formado, límite de 120 caracteres, BCrypt, separación de roles, autorización y rotación de sesión en login y registro.
- Se corrigieron session fixation, el fallo con hashes BCrypt truncados y la aceptación de correos más largos que la columna.
- Regresión general en verde: acceso anónimo, validación de productos, compra, cupones, cancelación, stock, límite de 10 productos y payloads malformados.

**No ejecutado o fuera del alcance inmediato:**

- Validación integral de accesibilidad con lector de pantalla/contraste/WCAG (solo revisión parcial de DOM y teclado).
- Pruebas de carga y concurrencia; cobertura instrumentada (JaCoCo). No se afirma ningún porcentaje.
- Tokens CSRF y atributo `SameSite` en cookies (QA-15).
- Bloqueo de login en memoria: es por correo y compartido entre roles, por lo que cinco fallos pueden bloquear temporalmente a un administrador (DoS). Está documentado en [RF02](docs/QA/RF02_LOGIN.md#6-limitaciones-y-riesgos-abiertos) y en [RF03](docs/QA/RF03_BLOQUEO_LOGIN.md#9-riesgos-y-limitaciones).
- GitHub Actions cubre los jobs unitarios y DAO; la suite HTTP sigue fuera de CI porque requiere Tomcat. La corrida verificada del merge de RF03 se enlaza en [la evidencia de CI](docs/QA/evidencias/ci-2026-10-29-rf03-main.txt).
- La demo es local (`localhost`), no una URL pública; no se afirma disponibilidad para reclutadores ni despliegue en producción.
- Funcionalidades de backlog sin evidencia: ficha individual de producto, administración de categorías y recuperación de contraseña.

**Saneamiento de datos:** el árbol actual se saneó con datos sintéticos: 16 DNI de demostración, 17 correos `@example.com`, nombre y correo personal reemplazados, y todos los hashes de clientes y del admin sustituidos por hashes sintéticos de fixtures. El backup no contiene credenciales en texto plano. El **historial de `main` y de las ramas de trabajo fue reescrito** el 23/10/2026 para retirar los 41 valores anteriores; aun así, la reescritura no revoca clones, cachés ni referencias previas, por lo que el riesgo residual se mantiene documentado en [docs/QA/SEGURIDAD_REPOSITORIO.md](docs/QA/SEGURIDAD_REPOSITORIO.md).

## Estado del repositorio

`main` es la única rama de trabajo: RF01, RF02 (#3) y RF03 (#4) están integrados en ella y no se mantienen ramas paralelas de esas funcionalidades. El repositorio de GitHub es **público** por decisión del propietario (29/10/2026). Los respaldos del historial anterior son locales y no se publican. El riesgo residual de la reescritura histórica está en [docs/QA/SEGURIDAD_REPOSITORIO.md](docs/QA/SEGURIDAD_REPOSITORIO.md).

## Roles académicos

| Rol | Integrante |
|---|---|
| Product Owner | Brenda Erika Bolo Vergara |
| Scrum Master | Nicolás Favio Quiroz Salvador |
| QA / analista de calidad | Kevin David Urbe Bolo |
| Equipo de desarrollo | Harold Alexis Córdova Ascarza, José Luis Rodríguez Navarro, Jeeicson Youfre Vise Soto |
