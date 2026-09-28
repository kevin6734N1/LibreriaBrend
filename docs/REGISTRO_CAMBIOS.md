# REGISTRO DE CAMBIOS — Librería Brenda

> **Convención del proyecto:** cada cambio funcional se documenta en este
> registro junto con sus pruebas, y se cierra con un commit de Git que queda
> anotado aquí como "estado actual del proyecto". Las evidencias de
> funcionamiento de cada pieza viven en [`EVIDENCIAS_PRUEBAS.md`](EVIDENCIAS_PRUEBAS.md).

## Estado actual del proyecto

| Fecha | Commit | Cambio |
|---|---|---|
| 2026-09-23 | `1a8c8af` | Primer commit — Librería Brenda (app web Java + MySQL) |
| 2026-09-27 | `65dce9f` | CU-03: validar máximo de 10 productos distintos en el carrito + informe de validación |
| 2026-09-27 | `84f4288` | **Pieza 1 accesibilidad:** perfil de accesibilidad en BD + filtro de corrección de color (Daltonize) + docs/ con registro y evidencias |

**Entorno vigente:** Java 21 · Tomcat 11.0.0-M24 · MariaDB 11.8.8 sobre Fedora
WSL2 · BD `libreria_brenda` (root/root, puerto 3306) · driver
`mysql-connector-j-9.7.0.jar` · Jakarta Servlet 6.

---

## [Pieza 1] Perfil de accesibilidad en BD + filtro de corrección de color

**Fecha:** 2026-09-27
**Motivación:** ODS 10 (reducción de desigualdades) / Ley 29973 — accesibilidad
visual para usuarios con daltonismo dentro del flujo de compra.

### Qué se implementó

1. **Base de datos** — nueva tabla `preferencias_accesibilidad` (una fila por
   cliente, creada con FK `ON DELETE CASCADE` hacia `clientes`):
   el ENUM garantiza a nivel de BD que solo se guarden los 4 valores válidos.

2. **Modelo / DAO** — `PreferenciaAccesibilidad` +
   `PreferenciaAccesibilidadDAO` con `obtenerPorCliente()` (devuelve valores
   por defecto si el cliente aún no tiene fila, sin tocar la BD) y `guardar()`
   (upsert con `ON DUPLICATE KEY UPDATE`).

3. **Servlet** — `PreferenciaAccesibilidadServlet` (`GET`/`POST` JSON):
   - Autenticado por sesión (`clienteEmail` → `ClienteDAO.buscarPorEmail`).
   - Valida el tipo contra la lista blanca antes de tocar la BD.

4. **Frontend** — `WebContent/js/accesibilidad.js`: botón flotante ♿ con
   panel de radios; aplica el filtro al `<body>` vía matrices SVG
   (`feColorMatrix`). Persistencia: en BD si hay sesión, en `localStorage`
   si es visitante anónimo. Filtros de **corrección** (algoritmo Daltonize
   publicado en daltonize.org, matrices RGB→LMS→RGB calculadas, no simulación).

5. **Enganche** — `<script src="js/accesibilidad.js"></script>` agregado antes
   de `</body>` en los 6 JSPs de cliente: `index`, `productos`, `carrito`,
   `pedidos`, `login`, `registro`. Los JSPs del panel admin no se tocan.

### Decisiones de diseño

- **Corrección, no simulación:** un filtro que "simula" daltonismo sirve para
  diseñadores pero no ayuda al usuario real; se implementó Daltonize real para
  correr los colores que el usuario no distingue hacia canales que sí percibe.
- **Sin fallback a cliente demo:** a diferencia de `PedidoServlet`, un
  visitante anónimo NO escribe sobre el cliente id=1; su preferencia es local
  (localStorage). Evita que todos los anónimos se pisen la misma fila.
- **`lectura_voz_activa` reservada:** la columna existe desde ya (piezas
  futuras de lectura en voz alta) pero no se expone en la UI hasta que active
  algo real — nada de controles decorativos.
- **Validación en dos capas:** lista blanca en el servlet + ENUM en la BD.

### DDL aplicado a `libreria_brenda`

```sql
CREATE TABLE preferencias_accesibilidad (
  cliente_id INT NOT NULL,
  tipo_daltonismo ENUM('ninguno','protanopia','deuteranopia','tritanopia') NOT NULL DEFAULT 'ninguno',
  lectura_voz_activa TINYINT(1) NOT NULL DEFAULT 0,
  fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (cliente_id),
  CONSTRAINT fk_pref_accesibilidad_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Pruebas

Compilación completa del proyecto sin errores + **7/7 pruebas funcionales
contra la BD real** (defaults, insert, upsert, rechazo ENUM, cascade) con
cliente temporal de QA eliminado al terminar. Evidencias completas en
[`EVIDENCIAS_PRUEBAS.md`](EVIDENCIAS_PRUEBAS.md).

---

## Pendiente (roadmap de accesibilidad)

- **[Pieza 2]** Marcado ARIA / compatibilidad con lector de pantalla.
- **[Pieza 3]** Botón de lectura en voz alta (activará `lectura_voz_activa`).
- Guardar el DDL en un script versionado `database/` para reproducir el schema.
