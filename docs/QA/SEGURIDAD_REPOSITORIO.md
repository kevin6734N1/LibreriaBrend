# Saneamiento de datos del repositorio

**Fecha:** 2026-10-21
**Estado:** árbol de trabajo saneado. **El historial de Git no se reescribió.**
**Alcance:** `libreria_brenda_backup.sql` y credenciales locales de la documentación.

## 1. Confirmación del propietario

El propietario revisó visualmente los clientes y confirmó:

- Los datos del respaldo son **ficticios**, salvo su nombre y su correo personal,
  usados para registrar una cuenta de prueba.
- Su DNI y teléfono mostrados también son ficticios.
- El propietario advirtió que no podía garantizar que todos los DNI fueran
  ficticios, por eso se pidió reemplazar todos los DNI.
- Se autorizó un saneamiento mínimo: sin borrar el backup, sin reescribir el
  historial y conservando los tres commits de `qa/rf02-login`.

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

## 4. Riesgo residual: el historial anterior

Este saneamiento **no elimina** los valores anteriores del historial de Git.
Los commits ya publicados en `main` siguen conteniendo el nombre y correo
personal, los DNI originales (incluidos los que pudieron ser reales) y los
hashes antiguos. Cualquiera puede consultarlos en el historial público.

Además, si el cambio del backup se incluye en el PR, el diff mostrará las
líneas antiguas eliminadas. No es una exposición nueva —ya estaban en `main`—
pero sí queda visible en la revisión.

Para eliminar esos valores del historial haría falta una reescritura coordinada
(`git filter-repo` o BFG) y un push forzado, o poner el repositorio en privado.
**No se ejecutó ninguna de las dos acciones**, por indicación expresa de no
reescribir el historial.

## 5. Qué revisar antes de publicar

1. Confirmar que los DNI originales que pudieron ser reales ya no importan en el
   historial público. Si importan, la reescritura del historial es la única
   solución efectiva.
2. Revisar si el correo personal debe seguir apareciendo en commits antiguos.
3. Decidir si las evidencias de auditoría con direcciones e IDs de pedido se
   conservan. El propietario confirmó que esos datos son ficticios y no
   contienen nombre, correo ni DNI; se dejaron para no romper la trazabilidad.
4. Autorizar el push y el PR solo después de aceptar el riesgo residual del
   historial.

## 6. Comandos de verificación (sin imprimir datos)

```bash
# Importar en una base aislada y comprobar integridad
mysql -h 127.0.0.1 -P 3307 -u root < libreria_brenda_backup.sql
mysql -h 127.0.0.1 -P 3307 -u root -N -B <<'SQL'
USE libreria_brenda;
SELECT COUNT(*), COUNT(DISTINCT dni), SUM(dni LIKE '999%') FROM clientes;
SELECT COUNT(*), COUNT(DISTINCT email), SUM(email LIKE '%@example.com') FROM clientes;
SELECT SUM(password_hash LIKE '$2a$10$%' AND CHAR_LENGTH(password_hash) = 60) FROM clientes;
SQL

# Buscar restos del nombre/correo personal solo en el árbol actual.
# Ejecuta git grep con tus propios tokens y no pegues el resultado.
git grep -n "<token-personal>" -- libreria_brenda_backup.sql || true
```

No pegues resultados con datos en issues, PRs o capturas.
