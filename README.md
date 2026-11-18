# Librería Brenda — Plataforma Web de Comercio Electrónico y Gestión

[![Java 21](https://img.shields.io/badge/Java-21-orange.svg)](https://openjdk.org/)
[![Jakarta Servlet](https://img.shields.io/badge/Jakarta%20Servlet-6.0-blue.svg)](https://jakarta.ee/)
[![Apache Tomcat](https://img.shields.io/badge/Tomcat-11-yellow.svg)](https://tomcat.apache.org/)
[![MariaDB](https://img.shields.io/badge/MariaDB-11-003545.svg)](https://mariadb.org/)
[![JUnit 5](https://img.shields.io/badge/JUnit-5-25A162.svg)](https://junit.org/junit5/)
[![CI](https://github.com/kevinurbe/LibreriaBrend/actions/workflows/junit.yml/badge.svg)](.github/workflows/junit.yml)

**Librería Brenda** es una aplicación web integral de comercio electrónico y gestión comercial desarrollada bajo la arquitectura **MVC** en **Java EE / Jakarta EE** (Servlets 6, JSP, JDBC) con persistencia en **MariaDB / MySQL**. 

El sistema proporciona un canal digital de compras para clientes (catálogo de libros y artículos escolares, carrito de compras reactivo, cupones de descuento, emisión de comprobantes y seguimiento de órdenes) complementado por un panel de administración para la gestión de inventario, clientes, pedidos y reportes analíticos.

Adicionalmente, el proyecto incorpora un enfoque sistemático de **Aseguramiento de la Calidad del Software (QA)**, que abarca desarrollo guiado por pruebas (TDD), suites de pruebas automatizadas (unitarias, de integración DAO y pruebas HTTP de extremo a extremo), análisis de rendimiento (JMeter), medición de cobertura (JaCoCo) y un flujo de **Integración Continua (CI/CD)** con GitHub Actions.

---

## Índice

- [Características del Sistema](#características-del-sistema)
- [Arquitectura y Stack Tecnológico](#arquitectura-y-stack-tecnológico)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Requisitos Previos](#requisitos-previos)
- [Puesta en Marcha Local](#puesta-en-marcha-local)
  - [1. Configuración de Base de Datos](#1-configuración-de-base-de-datos)
  - [2. Configuración de la Conexión](#2-configuración-de-la-conexión)
  - [3. Compilación y Despliegue en Tomcat](#3-compilación-y-despliegue-en-tomcat)
  - [4. Credenciales de Demostración y Prueba](#4-credenciales-de-demostración-y-prueba)
- [Estrategia de Calidad y Pruebas (QA)](#estrategia-de-calidad-y-pruebas-qa)
  - [Pruebas Unitarias y de Persistencia (JUnit 5)](#pruebas-unitarias-y-de-persistencia-junit-5)
  - [Pruebas de Integración HTTP de Extremo a Extremo](#pruebas-de-integración-http-de-extremo-a-extremo)
  - [Pipeline de CI en GitHub Actions](#pipeline-de-ci-en-github-actions)
  - [Pruebas No Funcionales y Cobertura](#pruebas-no-funcionales-y-cobertura)
- [Navegación de la Documentación](#navegación-de-la-documentación)
- [Equipo y Contexto Académico](#equipo-y-contexto-académico)

---

## Características del Sistema

### 🛒 Portal de Clientes y Tienda Online
- **Catálogo Interactivo:** Búsqueda en tiempo real por título, autor o categoría, con filtrado dinámico y visualización de portadas y existencias.
- **Carrito de Compras:** Gestión de artículos en sesión con recálculo dinámico de subtotales, impuestos y costos de envío en el servidor.
- **Sistema de Promociones:** Validación y aplicación de cupones de descuento con reglas de vigencia y límites de uso.
- **Gestión de Pedidos:** Creación transaccional de órdenes, reserva y descuento automático de stock, generación de identificador único de compra y consulta del historial de pedidos del cliente.
- **Cancelación con Reposición:** Los clientes pueden cancelar pedidos en estado pendiente, reintegrando automáticamente el inventario y reactivando cupones consumidos.
- **Accesibilidad Web:** Módulo de preferencias que incluye modos de contraste/daltonismo y soporte preliminar para lectura de pantalla.

### 🛡️ Seguridad y Control de Acceso
- **Autenticación Segura:** Cifrado unidireccional de contraseñas mediante **BCrypt** (`jbcrypt`) con salt adaptativo.
- **Autorización Basada en Roles (RBAC):** Filtro centralizado (`AuthFilter`) que restringe el acceso a recursos protegidos según el rol del usuario (`CLIENTE` o `ADMINISTRADOR`).
- **Protección contra Fuerza Bruta:** Bloqueo temporal configurable tras 5 intentos fallidos consecutivos de inicio de sesión, con cálculo dinámico del tiempo restante para reintentar.
- **Prevención de Fijación de Sesión:** Regeneración y rotación automática del ID de sesión HTTP tras un inicio de sesión o registro exitoso.

### 📊 Panel de Administración
- **Gestión de Productos e Inventario:** CRUD integral de artículos con validación de categorías, control de existencias mínimas y subida de imágenes con validación de tipo MIME y firma binaria (JPG, PNG, GIF, WEBP) mediante arrastrar y soltar (*drag & drop*).
- **Gestión de Clientes:** Directorio administrativo para auditar clientes registrados, estados de cuenta y pedidos asociados.
- **Control y Despacho de Pedidos:** Monitorización de órdenes recibidas, cambio de estados (Pendiente, Procesado, Enviado, Entregado, Cancelado) y emisión de comprobantes digitales (Boleta / Factura).
- **Módulo de Reportes:** Métricas de ventas, productos más demandados e ingresos acumulados.

---

## Arquitectura y Stack Tecnológico

El proyecto implementa el patrón de arquitectura **MVC (Modelo-Vista-Controlador)** desacoplado en capas de responsabilidad:

```
┌────────────────────────────────────────────────────────┐
│               Capa de Presentación (Vista)             │
│   JSP 3.1 + JSPF + HTML5 + CSS3 + JavaScript nativo   │
└───────────────────────────┬────────────────────────────┘
                            │ Peticiones HTTP / Fetch API
┌───────────────────────────▼────────────────────────────┐
│            Capa de Controladores (Controlador)         │
│     Jakarta Servlets 6.0 + Filtros de Seguridad        │
└───────────────────────────┬────────────────────────────┘
                            │ Llamadas a métodos DAO
┌───────────────────────────▼────────────────────────────┐
│       Capa de Lógica de Negocio y Persistencia         │
│   Modelos de Dominio (POJO) + DAOs JDBC transaccionales │
└───────────────────────────┬────────────────────────────┘
                            │ Conexión JDBC (Driver MySQL/MariaDB)
┌───────────────────────────▼────────────────────────────┐
│                  Base de Datos Relacional              │
│                     MariaDB 11 / MySQL 8               │
└────────────────────────────────────────────────────────┘
```

### Componentes Tecnológicos
- **Lenguaje:** Java 21 (LTS) — probado en OpenJDK / Eclipse Temurin 21.
- **Servidor de Aplicaciones:** Apache Tomcat 11.
- **Estándares Web:** Jakarta EE 10 (Jakarta Servlet 6.0, Jakarta Server Pages 3.1).
- **Persistencia:** JDBC nativo con transacciones explícitas (`setAutoCommit(false)`), consultas preparadas (`PreparedStatement`) y pool de conexiones configurable.
- **Motor de Base de Datos:** MariaDB 11.x (compatible con MySQL 8.x).
- **Frontend:** HTML5 semántico, CSS3 sin dependencias pesadas y JavaScript nativo asíncrono (`fetch`).
- **Seguridad:** BCrypt (`jbcrypt-0.4.jar`).
- **Testing & Automatización:** JUnit 5 (Console Standalone 1.11.4), Apache JMeter 5.6, JaCoCo 0.8.12, cURL, Bash y GitHub Actions.

---

## Estructura del Proyecto

```
LibreriaBrend/
├── .github/workflows/          # Flujo de CI en GitHub Actions (JUnit en Ubuntu + MariaDB)
├── database/                   # Scripts de base de datos
│   ├── schema_test.sql         # DDL de tablas y vistas para pruebas
│   ├── fixtures_test.sql       # Datos de prueba controlados
│   ├── demo/                   # Datos sintéticos para demostración local
│   └── backup/                 # Respaldo histórico saneado
├── docs/                       # Documentación técnica, diseño y aseguramiento de calidad
│   ├── producto/               # Diagramas de casos de uso y reporte del panel de administración
│   ├── QA/                     # Matrices de prueba (RF02, RF03), TDD, evidencias y reportes
│   ├── auditoria/              # Auditorías de seguridad, integridad y verificación de datos
│   └── historial/              # Registro detallado de cambios y versiones
├── lib/tomcat-11/              # APIs de Tomcat 11 para compilación en entornos desacoplados
├── src/libreria/               # Código fuente Java
│   ├── dao/                    # Capa de acceso a datos (AdministradorDAO, ClienteDAO, PedidoDAO, etc.)
│   ├── filtros/                # Filtros HTTP (AuthFilter)
│   ├── models/                 # Entidades del modelo de negocio
│   ├── servlets/               # Controladores HTTP (Login, Catalogo, Carrito, Pedidos, etc.)
│   └── util/                   # Conexión JDBC, utilidades BCrypt, validadores y evaluadores
├── test/                       # Suites de pruebas automatizadas
│   ├── run-junit-tests.sh      # Script unificado para ejecutar pruebas unitarias y de integración
│   ├── integration/            # Pruebas HTTP de extremo a extremo con cURL
│   └── libreria/               # Clases de prueba JUnit 5 (unitarias, DAO, TDD, caja negra y blanca)
└── WebContent/                 # Recursos web del contenedor Servlet
    ├── css/                    # Hojas de estilo
    ├── js/                     # Lógica JavaScript cliente
    ├── images/                 # Recursos multimedia y catálogo de productos
    ├── WEB-INF/                # Configuración privada, jspf y librerías JAR de producción
    └── *.jsp                   # Vistas JSP principales (index, login, carrito, pedidos, admin, etc.)
```

---

## Requisitos Previos

1. **Java Development Kit (JDK):** Versión 21 o superior.
2. **Servidor de Aplicaciones:** Apache Tomcat 11.
3. **Servidor de Base de Datos:** MariaDB 11 o MySQL 8.
4. **Herramientas de Terminal (opcional para scripts):** Git Bash, WSL o terminal Unix con `curl` y `bash`.

> Todas las dependencias JAR de compilación y ejecución (`mysql-connector-j-9.7.0.jar`, `jbcrypt-0.4.jar`, `junit-platform-console-standalone-1.11.4.jar` y las APIs de Tomcat 11) se encuentran ya versionadas dentro del repositorio en `WebContent/WEB-INF/lib/` y `lib/tomcat-11/`, por lo que **no se requiere Maven ni Gradle** para compilar el proyecto.

---

## Puesta en Marcha Local

### 1. Configuración de Base de Datos

El repositorio ofrece dos alternativas según el objetivo:

#### Opción A: Entorno de Pruebas Automatizadas (Recomendado para testing y CI)
Crea una base de datos limpia `libreria_brenda_test` con el esquema oficial y un juego mínimo de datos controlados:

```bash
mysql -u root -p < database/schema_test.sql
mysql -u root -p < database/fixtures_test.sql
```

#### Opción B: Entorno de Demostración Local
Crea una base de datos `libreria_brenda_demo` con un catálogo ampliado y clientes con historial de pedidos ficticios:

```bash
mysql -u root -p < database/demo/libreria_brenda_demo.sql
```

---

### 2. Configuración de la Conexión

La clase `ConexionBD` resuelve las credenciales de conexión de forma desacoplada y sin necesidad de modificar el código fuente, respetando la siguiente jerarquía de precedencia:

1. **Parámetro del Sistema JVM** (ej. `-DDB_NAME=libreria_brenda_test`)
2. **Variables de Entorno del Sistema** (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`)
3. **Archivo de Propiedades:** `WebContent/WEB-INF/db.properties`
4. **Valores por defecto:** `localhost:3306`, base `libreria_brenda`, usuario `root`, contraseña vacía.

#### Configuración recomendada mediante `db.properties`:
Copie la plantilla de ejemplo y configure sus credenciales locales:

```bash
cp WebContent/WEB-INF/db.properties.example WebContent/WEB-INF/db.properties
```

Edite `WebContent/WEB-INF/db.properties`:
```properties
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=libreria_brenda_test
DB_USER=root
DB_PASSWORD=su_contraseña
```

*(El archivo `db.properties` se encuentra en `.gitignore` para garantizar que sus credenciales locales nunca se publiquen en el repositorio).*

---

### 3. Compilación y Despliegue en Tomcat

#### A. Desde un Entorno de Desarrollo (VS Code / Eclipse)
1. Importe el proyecto en el IDE como un **Dynamic Web Project**.
2. Asegúrese de que el entorno de ejecución apunte a **Tomcat 11** con **JDK 21**.
3. Añada el proyecto al servidor Tomcat y pulse **Start / Deploy**.
4. Ingrese desde el navegador a: `http://localhost:8080/LibreriaBrend/` (o al puerto configurado en su servidor).

#### B. Compilación y Despliegue Manual por Consola
En entornos Unix o Git Bash (en Windows el separador de classpath es `;`, en Linux/macOS es `:`):

```bash
# 1. Compilar clases Java a build/classes
mkdir -p build/classes
javac -encoding UTF-8 -cp "WebContent/WEB-INF/lib/*;lib/tomcat-11/*" \
  -d build/classes $(find src -name '*.java')

# 2. Desplegar contexto en Tomcat
cp -r WebContent/. <RUTA_TOMCAT>/webapps/LibreriaBrend/
cp -r build/classes/. <RUTA_TOMCAT>/webapps/LibreriaBrend/WEB-INF/classes/

# 3. Iniciar Tomcat
<RUTA_TOMCAT>/bin/startup.sh    # En Windows: startup.bat
```

---

### 4. Credenciales de Demostración y Prueba

| Entorno | Rol | Correo Electrónico | Contraseña | Código Empleado |
|---|---|---|---|---|
| **Pruebas (`fixtures_test.sql`)** | Administrador | `admin@test.local` | `Admin#2026` | `EMP-TEST` |
| **Pruebas (`fixtures_test.sql`)** | Cliente | `cliente.a@test.local` | `Cliente#2026` | — |
| **Demo (`libreria_brenda_demo.sql`)** | Administrador | `admin@example.com` | `Admin#2026` | `EMP-DEMO` |
| **Demo (`libreria_brenda_demo.sql`)** | Cliente | `cliente01@example.com` | `Cliente#2026` | — |

---

## Estrategia de Calidad y Pruebas (QA)

El proyecto cuenta con un ecosistema exhaustivo de pruebas automatizadas y aseguramiento de la calidad:

### Pruebas Unitarias y de Persistencia (JUnit 5)

El script `test/run-junit-tests.sh` compila y ejecuta la suite automatizada:

```bash
# 1. Suite Rápida (Pruebas unitarias sin motor de base de datos)
# Valida lógica de dominio, validadores de email/producto, utilidades BCrypt y reglas de negocio:
JUNIT_EXCLUDE='libreria\.dao\..*' bash test/run-junit-tests.sh

# 2. Suite Completa (Pruebas unitarias + Pruebas de integración DAO con base de datos)
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=libreria_brenda_test \
DB_USER=root DB_PASSWORD=tu_clave bash test/run-junit-tests.sh
```

- **Cobertura de Casos de Negocio:**
  - `CalculadoraMorosidadTest`: Cálculo de intereses y penalidades financieras.
  - `EvaluadorPrestamoTest`: Cobertura de caminos (caja blanca) y clases de equivalencia (caja negra).
  - `ControlIntentosLoginTest`: Validación de bloqueo con reloj inyectado sin retardos reales de tiempo de espera.
  - `ValidadorEmailTest` / `ValidadorProductoTest`: Reglas de entrada y validaciones de límites.
  - `ClienteDAOLoginTest` / `AdministradorDAOLoginTest`: Verificación de autenticación contra persistencia real.

---

### Pruebas de Integración HTTP de Extremo a Extremo

Ejecutan comprobaciones automatizadas reales sobre el servidor Tomcat en ejecución y validan códigos de estado HTTP, cabeceras de sesión, redirecciones y respuestas JSON:

```bash
# Validación de Autenticación, Roles y Rotación de Sesión (RF02)
BASE=http://localhost:8080/LibreriaBrend DB_NAME=libreria_brenda_test bash test/integration/rf02-login-tests.sh

# Validación de Bloqueo por Fuerza Bruta y Expiración (RF03)
BASE=http://localhost:8080/LibreriaBrend DB_NAME=libreria_brenda_test bash test/integration/rf03-bloqueo-tests.sh

# Suite de Regresión Comercial (Catálogo, Carrito, Cupones, Despacho y Stock)
BASE=http://localhost:8080/LibreriaBrend DB_NAME=libreria_brenda_test bash test/integration/http-tests.sh
```

---

### Pipeline de CI en GitHub Actions

El archivo [`.github/workflows/junit.yml`](.github/workflows/junit.yml) define dos trabajos paralelos que se ejecutan automáticamente ante cada `push` o `pull_request`:

1. **Unit Tests (Sin BD):** Compila el código bajo JDK 21 y ejecuta la batería unitaria de forma inmediata.
2. **Integration DAO Tests (Con MariaDB):** Levanta un contenedor de servicio con MariaDB 11.8, inicializa el esquema y datos de prueba (`schema_test.sql` y `fixtures_test.sql`) y valida la persistencia de datos.

---

### Pruebas No Funcionales y Cobertura

- **Pruebas de Rendimiento (JMeter):** Escenarios de concurrencia y carga sobre navegación de catálogo y autenticación simultánea. Ver detalle en [docs/QA/SPRINT4_PRUEBAS_NO_FUNCIONALES.md](docs/QA/SPRINT4_PRUEBAS_NO_FUNCIONALES.md).
- **Cobertura de Código (JaCoCo):** Análisis de cobertura de ramas e instrucciones en componentes críticos del sistema.
- **Auditoría y Saneamiento de Datos:** El repositorio fue saneado para eliminar cualquier credencial sensible o dato personal, empleando datos sintéticos auditados en todo el historial público. Ver [docs/QA/SEGURIDAD_REPOSITORIO.md](docs/QA/SEGURIDAD_REPOSITORIO.md).

---

## Navegación de la Documentación

La carpeta [`docs/`](docs/) contiene la documentación técnica y analítica detallada del proyecto:

| Sección | Descripción |
|---|---|
| [docs/producto/](docs/producto/) | Casos de uso de negocio y reporte técnico del panel administrativo. |
| [docs/QA/](docs/QA/) | Índice central de aseguramiento de calidad, matrices RF02/RF03, reporte no funcional e informe del caso combinado. |
| [docs/auditoria/](docs/auditoria/) | Informes de auditoría de datos, integridad referencial y verificaciones HTTP. |
| [docs/historial/](docs/historial/) | Registro cronológico de cambios de la aplicación ([REGISTRO_CAMBIOS.md](docs/historial/REGISTRO_CAMBIOS.md)). |
| [docs/academico/](docs/academico/) | Laboratorios de desarrollo guiado por pruebas (TDD) y plantillas metodológicas. |

---

## Equipo y Contexto Académico

El proyecto fue desarrollado y mantenido en el marco del curso **Calidad y Pruebas de Software** en la **Universidad Privada del Norte (UPN)**, sirviendo como caso integral de desarrollo de software web y banco de pruebas de automatización de QA.

### Integrantes y Roles

| Rol | Integrante | Responsabilidades Principales |
|---|---|---|
| **Product Owner** | Brenda Erika Bolo Vergara | Definición de requerimientos de negocio, historias de usuario y criterios de aceptación. |
| **Scrum Master** | Nicolás Favio Quiroz Salvador | Facilitación de sprints, gestión de backlog y coordinación del equipo. |
| **QA / Analista de Calidad** | Kevin David Urbe Bolo | Arquitectura de pruebas (JUnit 5, HTTP), automatización CI/CD, ciclos TDD, seguridad y auditoría de repositorio. |
| **Equipo de Desarrollo** | Harold Alexis Córdova Ascarza<br>José Luis Rodríguez Navarro<br>Jeeicson Youfre Vise Soto | Implementación de módulos web (MVC, Servlets, DAO, JSP), lógica de negocio e integración de interfaz de usuario. |
