-- FASE 2 - Auditoría LibreriaBrend
-- Captura de estado de la base de datos (SOLO SELECT).
-- Se ejecuta al inicio (baseline) y al final (verificación de que no hubo escrituras).

SELECT NOW() AS momento_captura, DATABASE() AS db_actual;

SELECT '--- Conteos por tabla ---' AS seccion;
SELECT 'clientes'                 AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL SELECT 'administradores',        COUNT(*) FROM administradores
UNION ALL SELECT 'productos',              COUNT(*) FROM productos
UNION ALL SELECT 'pedidos',                COUNT(*) FROM pedidos
UNION ALL SELECT 'pedido_items',           COUNT(*) FROM pedido_items
UNION ALL SELECT 'comprobantes',           COUNT(*) FROM comprobantes
UNION ALL SELECT 'codigos_promo',          COUNT(*) FROM codigos_promo
UNION ALL SELECT 'codigos_promo_usos',     COUNT(*) FROM codigos_promo_usos
UNION ALL SELECT 'preferencias_accesibilidad', COUNT(*) FROM preferencias_accesibilidad
UNION ALL SELECT 'categorias',             COUNT(*) FROM categorias;

SELECT '--- Huella de contenido (para detectar cualquier mutación) ---' AS seccion;
SELECT 'clientes' AS tabla,
       COUNT(*) AS filas,
       COALESCE(SUM(id),0) AS suma_ids,
       COALESCE(SUM(CHAR_LENGTH(CONCAT_WS('|',nombres,apellidos,COALESCE(email,''),COALESCE(dni,'')))),0) AS suma_longitudes
FROM clientes
UNION ALL
SELECT 'pedidos', COUNT(*), COALESCE(SUM(CRC32(id)),0),
       COALESCE(SUM(ROUND(total*100)),0) + COALESCE(SUM(ROUND(descuento*100)),0)
FROM pedidos
UNION ALL
SELECT 'productos', COUNT(*), COALESCE(SUM(CRC32(nombre)),0),
       COALESCE(SUM(ROUND(precio*100)),0) + COALESCE(SUM(stock),0)
FROM productos
UNION ALL
SELECT 'comprobantes', COUNT(*), COALESCE(SUM(id),0), COALESCE(SUM(ROUND(monto*100)),0) FROM comprobantes
UNION ALL
SELECT 'codigos_promo_usos', COUNT(*), COALESCE(SUM(CRC32(CONCAT(codigo,pedido_id))),0), 0 FROM codigos_promo_usos;

SELECT '--- Pedidos del Cliente Demo (id=1) ---' AS seccion;
SELECT id, estado, subtotal, descuento, envio, total, LEFT(COALESCE(direccion_entrega,''),28) AS direccion, metodo_pago
FROM pedidos WHERE cliente_id = 1 ORDER BY fecha DESC;

SELECT '--- Último pedido registrado en toda la tabla (para detectar inserciones) ---' AS seccion;
SELECT id, cliente_id, fecha, estado, total FROM pedidos ORDER BY fecha DESC LIMIT 3;

SELECT '--- Consumos de códigos promocionales (debe estar vacío) ---' AS seccion;
SELECT * FROM codigos_promo_usos;
