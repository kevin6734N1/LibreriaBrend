# RF02 — Inicio de sesión de cliente y administrador

**Estado:** implementado y verificado localmente el **2026-10-21**.
**Rama:** `qa/rf02-login`.
**Alcance:** autenticación, validación de correo, BCrypt, cuentas inactivas,
separación de roles y sesión. No incluye recuperación de contraseña ni CSRF.

## Definición usada

> El sistema debe autenticar al cliente mediante correo y contraseña; al
> administrador mediante correo, contraseña y código de empleado. Debe validar
> correo, verificar BCrypt y rechazar cuentas inactivas.

## 1. Qué se probó

| Área | Qué cubre |
|---|---|
| Cliente | credenciales válidas, contraseña incorrecta, cuenta inactiva, correo inexistente, formatos inválidos, límite de 120 caracteres, espacios, mayúsculas, hash truncado y hash en texto plano |
| Administrador | correo + contraseña + código, código incorrecto/ausente/vacío, contraseña incorrecta, cruce de roles cliente/admin |
| Autorización | `admin.jsp`, `ClienteServlet`, `ProductoServlet` y `PedidoServlet` con sesión anónima, de cliente y de admin; logout |
| Sesión | rotación de `JSESSIONID` al iniciar sesión y al registrarse; acceso posterior a recursos autenticados |
| Fuerza bruta | bloqueo en el 6.º intento, aislamiento por correo, reinicio tras login exitoso |

## 2. Matriz resumida

La evidencia cruda tiene **62 comprobaciones** (55 de casos y 7 de
preparación/limpieza). Todas en verde.

| Grupo | Casos | Tipo | Resultado |
|---|---|---|---|
| `RF02-CL-01..05` | login válido, contraseña mala, inactivo, inexistente, mensaje uniforme | Integración / regresión | 10/10 |
| `RF02-CL-06..10` | formatos inválidos, 121 caracteres, campos vacíos, rol inválido | Integración / borde | 10/10 |
| `RF02-CL-11..12` | espacios externos y mayúsculas en el correo | Caracterización | 2/2 |
| `RF02-CL-13..14` | hash BCrypt truncado y hash en texto plano | Integración / defecto corregido | 3/3 |
| `RF02-AD-01..09` | triplete válido, código malo/ausente/vacío, contraseña mala, cruce de roles | Integración / regresión | 14/14 |
| `RF02-AZ-01..06` | acceso anónimo/cliente/admin a recursos protegidos y logout | Integración / autorización | 6/6 |
| `RF02-SES-01..04` | rotación de sesión en login y registro | TDD / seguridad | 5/5 |
| `RF02-BR-01..05` | 5.º y 6.º intento, aislamiento por correo, reset tras éxito | Integración / regresión | 5/5 |
| `libreria.dao.*` (JUnit) | 18 pruebas de `ClienteDAO` y `AdministradorDAO` | Caracterización / regresión | 18/18 |
| `ValidadorEmailTest` (JUnit) | 16 pruebas de formato y longitud | TDD / unitaria | 16/16 |
| `PasswordUtilTest` (JUnit) | 12 pruebas, incluidas 2 nuevas de hash malformado | Regresión / defecto corregido | 12/12 |
| `ControlIntentosLoginTest` (JUnit) | 12 pruebas, incluida concurrencia de 5 fallos | Regresión / concurrencia | 12/12 |

## 3. TDD: qué fue RED real y qué fue caracterización

No se inventó una fase RED para comportamiento que ya funcionaba.

### 3.1 Validador de correo (nuevo)

- Se escribieron primero 16 pruebas en
  [`ValidadorEmailTest.java`](../../test/libreria/util/ValidadorEmailTest.java).
- **RED:** la compilación falló con `cannot find symbol: ValidadorEmail`
  ([evidencia](evidencias/tdd-validador-email-red-2026-10-21.txt)).
- **GREEN:** se implementó [`ValidadorEmail.java`](../../src/libreria/util/ValidadorEmail.java)
  con el límite de 120 caracteres de la columna y se reutilizó en `LoginServlet`
  y `RegistroServlet` (antes había dos regex duplicadas).
- **Resultado:** 16/16.

### 3.2 Hash BCrypt truncado (defecto real)

- La prueba `verificar_hashBCryptTruncado_noLanzaExcepcionYDevuelveFalse`
  falló con `StringIndexOutOfBoundsException` dentro de jBCrypt.
- **Causa:** `PasswordUtil` solo capturaba `IllegalArgumentException`; un hash
  incompleto que empieza con `$2a$` llegaba hasta `BCrypt.checkpw`.
- **RED reproducido con el código de `HEAD`:**
  [evidencia](evidencias/tdd-passwordutil-red-2026-10-21.txt).
- **GREEN:** se valida el formato completo (`$2a$` + costo + 53 caracteres)
  antes de llamar a jBCrypt. Un dato legado ya no puede tumbar el login con
  un 500; se rechaza como credencial inválida.
- **Resultado:** 90/90 JUnit con base de datos.

### 3.3 Session fixation (defecto real)

- **RED:** `RF02-SES-02` falló con `esperado=[distinto] actual=[igual]` al
  comparar el `JSESSIONID` antes y después del login
  ([primera corrida](evidencias/rf02-http-primera-corrida-2026-10-21.txt)).
- **GREEN:** se creó [`SesionAutenticada.java`](../../src/libreria/servlets/SesionAutenticada.java),
  que crea la sesión, ejecuta `request.changeSessionId()` y limpia atributos de
  autenticación previos. Se usa en login y registro.
- `RF02-SES-04` reprodujo el mismo defecto en el registro y quedó en verde con
  el mismo cambio.
- **Resultado:** 62/62 HTTP.

### 3.4 Corrección de la primera corrida

La primera corrida tuvo 4 fallos; no todos eran defectos de producción:

- `CL-07` (correo de 121 caracteres) era el RED esperado del validador.
- `SES-02` era el defecto real de session fixation.
- `AD-09` falló porque las pruebas negativas anteriores ya habían bloqueado
  ese correo; se reordenó el caso. Eso expuso la limitación del contador
  compartido entre roles (ver §6).
- `BR-02` tenía un desfase de una petición en el propio test (el 5.º intento
  se estaba comparando como 6.º); se corrigió la secuencia.

## 4. Resultados verificables

| Suite | Comando | Resultado |
|---|---|---|
| JUnit sin BD (DAO excluidos) | `JUNIT_EXCLUDE='libreria\.dao\..*' bash test/run-junit-tests.sh` | **72/72** |
| JUnit con `libreria_brenda_test` | `DB_HOST=127.0.0.1 DB_PORT=3307 DB_NAME=libreria_brenda_test DB_USER=root DB_PASSWORD= bash test/run-junit-tests.sh` | **90/90** |
| HTTP RF02 | `BASE=... DB_... bash test/integration/rf02-login-tests.sh` | **62/62** |
| HTTP general (regresión) | `BASE=... DB_... bash test/integration/http-tests.sh` | **80/80** |

Evidencias crudas:

- [JUnit sin BD](evidencias/junit-unit-2026-10-21.txt)
- [JUnit con BD](evidencias/junit-db-2026-10-21.txt)
- [HTTP RF02](evidencias/rf02-http-2026-10-21.txt)
- [HTTP general](evidencias/http-general-2026-10-21.txt)

No se midió cobertura con JaCoCo ni se afirma ningún porcentaje.

**Entorno de la corrida:** OpenJDK 21.0.12, Tomcat 11.0.26, MariaDB 11.8.9
sobre WSL2 Fedora 44, base `libreria_brenda_test` en el puerto 3307. Es un
entorno aislado; los scripts aceptan otro puerto/usuario por variables.

## 5. Reproducción

```bash
# 1. Base de prueba (nunca la comercial)
mysql -u root -p < database/schema_test.sql
mysql -u root -p < database/fixtures_test.sql

# 2. JUnit sin motor de base de datos
bash test/run-junit-tests.sh

# 3. JUnit con los DAO de login
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=libreria_brenda_test \
DB_USER=root DB_PASSWORD=tu_clave bash test/run-junit-tests.sh

# 4. HTTP (Tomcat con el contexto /LibreriaBrend)
BASE=http://localhost:8080/LibreriaBrend \
DB_HOST=127.0.0.1 DB_PORT=3306 DB_NAME=libreria_brenda_test \
DB_USER=root DB_PASSWORD=tu_clave \
bash test/integration/rf02-login-tests.sh
```

El script HTTP crea sus propios clientes y administrador ficticios con correos
`rf02.*@test.local`, los elimina al terminar y se niega a ejecutarse si
`DB_NAME` no es `libreria_brenda_test`.

## 6. Limitaciones y riesgos abiertos

1. **Bloqueo de cuenta como DoS:** el contador es por correo y se comparte
   entre los roles cliente y admin. Cinco intentos fallidos contra el correo de
   un administrador lo bloquean 2 minutos aunque el atacante no conozca la
   contraseña. No hay límite por IP.
2. **Estado en memoria:** el contador vive en un `ConcurrentHashMap` estático.
   Se reinicia con Tomcat y no se comparte entre nodos. Un atacante puede
   crear muchas claves con correos únicos; no hay cota ni TTL de entradas.
3. **Sin prueba de expiración:** no se prueba que el bloqueo se levante a los
   2 minutos porque no hay reloj inyectable; solo se prueba el bloqueo.
4. **Respuesta HTTP 200 en fallo:** el contrato actual del frontend es
   `200` + `{"ok":false}`; no se cambió a `401`. Un cliente que solo mire el
   status no distingue éxito de fallo.
5. **Administrador sin `activo`:** la tabla no modela administradores
   inactivos. El requisito de cuentas inactivas se cumple para clientes.
6. **Hashes legados:** solo se aceptan hashes `$2a$` completos. Cuentas con
   texto plano no pueden entrar hasta migrarlas o resetear la contraseña.
7. **Sin CSRF/SameSite:** no se añadieron tokens CSRF ni atributos de cookie;
   el login CSRF queda fuera de este incremento.
8. **Sin auditoría de accesos:** no se registra quién intentó entrar, desde
   qué IP ni el resultado.
9. **CI no ejecutado en GitHub:** el workflow existe, pero solo se validaron
   localmente los comandos y el YAML. No se afirma que GitHub Actions esté en
   verde.
10. **Suite HTTP fuera de CI:** requiere Tomcat y MariaDB; no se automatizó en
    el workflow para no prometer una ejecución no verificada.
11. **Sin pruebas de carga:** no se evaluó concurrencia HTTP real ni latencia
    de BCrypt bajo carga.

## 7. Archivos principales

- [`src/libreria/util/ValidadorEmail.java`](../../src/libreria/util/ValidadorEmail.java)
- [`src/libreria/util/PasswordUtil.java`](../../src/libreria/util/PasswordUtil.java)
- [`src/libreria/servlets/SesionAutenticada.java`](../../src/libreria/servlets/SesionAutenticada.java)
- [`src/libreria/servlets/LoginServlet.java`](../../src/libreria/servlets/LoginServlet.java)
- [`src/libreria/servlets/RegistroServlet.java`](../../src/libreria/servlets/RegistroServlet.java)
- [`test/integration/rf02-login-tests.sh`](../../test/integration/rf02-login-tests.sh)
- [`test/run-junit-tests.sh`](../../test/run-junit-tests.sh)
- [`test/libreria/dao/ClienteDAOLoginTest.java`](../../test/libreria/dao/ClienteDAOLoginTest.java)
- [`test/libreria/dao/AdministradorDAOLoginTest.java`](../../test/libreria/dao/AdministradorDAOLoginTest.java)
- [`.github/workflows/junit.yml`](../../.github/workflows/junit.yml)
