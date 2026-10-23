# Saneamiento de datos del repositorio

**Fecha de saneamiento del árbol:** 2026-10-21. **Actualización del historial:** 2026-10-23.
**Estado:** el árbol y los historiales de `main` y `qa/rf02-login` fueron saneados y publicados en un repositorio **privado**. **Persisten referencias y objetos históricos accesibles mediante GitHub**, por lo que todavía no debe hacerse público.
**Alcance:** respaldo SQL, datos antiguos en `WebContent/clientes.jsp`, documentación de credenciales locales e historial de las ramas publicables.

## 1. Confirmación del propietario

El propietario revisó visualmente los clientes y confirmó:

- Los datos del respaldo son **ficticios**, salvo su nombre y su correo personal,
  usados para registrar una cuenta de prueba.
- Su DNI y teléfono mostrados también son ficticios.
- El propietario advirtió que no podía garantizar que todos los DNI fueran
  ficticios, por eso se pidió reemplazar todos los DNI.
- El **21 de octubre** se autorizó inicialmente un saneamiento mínimo sin reescribir
  el historial. **El 23 de octubre**, una autorización posterior permitió la
  reescritura controlada de las ramas publicables y su publicación privada.

## 2. Cambios aplicados en el árbol actual

| Dato | Tratamiento | Resultado |
|---|---|---|
| DNI de clientes | reemplazados por el rango de demostración `99900001`–`99900016` | 16 DNI únicos, ninguno aportado por usuarios |
| Correos de clientes | reemplazados por `cliente<id>@example.com` | 16 correos únicos |
| Correo de administrador | reemplazado por `admin@example.com` | 1 correo |
| Nombre personal | reemplazado por `Cliente Sintetico 22` | sin nombre personal en el árbol |
| Hashes de clientes | los 16 reemplazados por el hash sintético de los fixtures | sin contraseñas originales |
| Hash del administrador | reemplazado por el hash sintético de los fixtures | sin contraseña original |
| IDs, fechas, montos, teléfonos, direcciones y claves foráneas | **sin cambios** | relaciones y demo intactos |
| Backup completo | **conservado** | 587 líneas, mismo formato y CRLF |

También se retiraron las menciones literales de usuario y clave por defecto de la documentación
(`docs/EVIDENCIAS_PRUEBAS.md`, `docs/REGISTRO_CAMBIOS.md` y
`docs/auditoria/FASE2_CIERRE_LIMITACIONES.md`). Ahora se describen como
credenciales locales por defecto.

## 3. Verificación ejecutada

El backup saneado se importó en una instancia MariaDB 11.8 aislada. Resultado:

| Comprobación | Resultado |
|---|---|
| Importación SQL | exit 0 |
| Clientes / administradores / pedidos / ítems / comprobantes / productos / cupones | 16 / 1 / 16 / 31 / 8 / 11 / 3 |
| DNI únicos / DNI en rango `999` | 16 / 16 |
| Correos de clientes únicos / `@example.com` | 16 / 16 |
| Correo de administrador `@example.com` | 1 |
| Hashes BCrypt válidos (clientes / admin) | 16 / 1 |
| Hashes de clientes distintos | 1 (todos sintéticos) |
| Pedidos, ítems y comprobantes huérfanos | 0 |
| Nombres o correos personales en el backup actual | 0 |
| Credenciales en texto plano en el backup | 0 |

Evidencia agregada (sin datos personales):
[`evidencias/saneamiento-2026-10-21.txt`](evidencias/saneamiento-2026-10-21.txt).

Las suites de regresión se volvieron a ejecutar después del cambio:
**72/72 JUnit sin BD, 91/91 JUnit con BD, 62/62 HTTP RF02 y 80/80 HTTP general**.

## 4. Reescritura histórica ejecutada el 2026-10-23 y riesgo residual

Con autorización expresa, se creó un espejo privado de respaldo y se reescribió
el historial de las ramas publicables. El saneamiento histórico sustituyó **41
valores identificados** en `libreria_brenda_backup.sql` y
`WebContent/clientes.jsp`, preservando las pruebas, el código y las evidencias.

El 2026-10-23 se publicaron **en una única transacción atómica** las ramas:

- `main` → `965b34bc5a435c938a70620fdb4e859608a7beb8`.
- `qa/rf02-login` → `7cec57b145cfc32050ec9a76d9789e5b65eebd47`.

Se utilizó `git push --atomic` con candados `--force-with-lease` explícitos,
sin `--force` simple. El repositorio **permaneció privado**.
El PR #3 recalculó su comparación: **cero coincidencias de los 41 valores
buscados** y ninguna ruta de archivos de LibaaS; conservó el código y las
evidencias de RF02. Las ejecuciones nuevas de GitHub Actions #9, #10 y #11
terminaron correctamente, con sus dos jobs cada una.

**Importante: esto no equivale a una purga completa de GitHub.** Aunque las
puntas actuales están saneadas, el commit original de `main` seguía siendo
consultable con autenticación después de la reescritura. Las referencias
internas de los PR #1 y #2 todavía apuntaban a commits antiguos. También
pueden subsistir diffs cacheados, ejecuciones anteriores de Actions, clones y
copias externas. El escaneo de 41 valores conocidos tampoco demuestra la
ausencia de cualquier otro dato personal.

Los respaldos que conservan el historial anterior y los mapas de sustitución
están **fuera del repositorio rastreado** y deben permanecer privados.

## 5. Pendientes antes de volver a hacer público el repositorio

1. Comprobar y tratar los **objetos antiguos todavía accesibles en GitHub**,
   especialmente por SHA y referencias internas de PR. Evaluar una solicitud a
   GitHub Support; no asumir que la reescritura o el cierre de un PR los elimina.
2. Coordinar con los colaboradores la sustitución de clones antiguos después
   de respaldar su trabajo propio. No republicar ramas `backup/*` o `recovery/*`.
3. Revisar `screenshots/` antes de versionarla. Al cierre de este saneamiento
   seguía fuera de Git.
4. Mantener la decisión consciente sobre metadatos de autor y datos sintéticos
   de demostración (nombres, teléfonos y direcciones). Los metadatos de autor
   se conservaron; las credenciales demo no deben reutilizarse.
5. Conservar las evidencias históricas tal como fueron capturadas. Algunos SHA
   originales allí mencionados ya no resuelven mediante las ramas nuevas;
   el mapeo de equivalencias se mantiene **privado**.

La privacidad actual del repositorio es una protección temporal, no una garantía
de que desaparezcan clones o cachés ya existentes.

## 6. Comandos de verificación no destructivos

```bash
# Confirmar las dos puntas remotas sin alterar el repositorio
git ls-remote --heads origin

# Comprobar la rama local y los cambios pendientes
git status -sb

# Verificar integridad del repositorio local
git fsck --full
```

Las pruebas SQL de importación se realizaron previamente **en instancias
aisladas**, no en la base comercial ni en la demo. No ejecutar importaciones
sobre un puerto o servidor preexistente sin verificar expresamente que sea un
entorno de pruebas desechable.

No pegar datos personales ni resultados sensibles en issues, PR o capturas.
