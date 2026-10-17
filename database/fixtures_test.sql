-- Datos FICTICIOS para libreria_brenda_test.
-- Ningun registro corresponde a clientes, pedidos o ventas reales.
-- Usuarios de prueba:
--   admin@test.local      / Admin#2026
--   cliente.a@test.local  / Cliente#2026
--   cliente.b@test.local  / Cliente#2026

USE libreria_brenda_test;
SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM comprobantes;
DELETE FROM codigos_promo_usos;
DELETE FROM pedido_items;
DELETE FROM pedidos;
DELETE FROM preferencias_accesibilidad;
DELETE FROM productos;
DELETE FROM categorias;
DELETE FROM codigos_promo;
DELETE FROM clientes;
DELETE FROM administradores;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------
-- Administrador de pruebas (contrasena: Admin#2026)
-- ---------------------------------------------------------------
INSERT INTO administradores (id, nombre, email, password_hash, codigo_empleado) VALUES
(1, 'Admin de Pruebas', 'admin@test.local',
 '$2a$10$6JsbyV9YprzX4WDrRRsfrOA53nQHfS0KxYNZ1NeAjK0rals87T0Wq', 'EMP-TEST');

-- ---------------------------------------------------------------
-- Clientes de prueba (contrasena: Cliente#2026)
-- ---------------------------------------------------------------
INSERT INTO clientes (id, nombres, apellidos, dni, email, telefono, direccion, password_hash, activo) VALUES
(1, 'Cliente', 'Alfa', '90000001', 'cliente.a@test.local', '900000001', 'Av. Pruebas 100, Lima',
 '$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S', 1),
(2, 'Cliente', 'Beta', '90000002', 'cliente.b@test.local', '900000002', 'Av. Pruebas 200, Lima',
 '$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S', 1),
(3, 'Cliente', 'Inactivo', '90000003', 'inactivo@test.local', '900000003', 'Av. Pruebas 300, Lima',
 '$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S', 0);

-- ---------------------------------------------------------------
-- Categorias
-- ---------------------------------------------------------------
INSERT INTO categorias (id, nombre, icono) VALUES
(1, 'Libros', 'images/libro-logo.png'),
(2, 'Cuadernos', 'images/productos.png'),
(3, 'Lapiceros', 'images/tienda.png'),
(4, 'Mochilas', 'images/mochila-silueta.png'),
(5, 'Arte', 'images/acuarelas.png'),
(6, 'Oficina', 'images/dashboard.png');

-- ---------------------------------------------------------------
-- Productos: 1..11 permiten probar el limite de 10 distintos.
-- El 13 tiene stock 2 y el 14 stock 0 para probar rechazos.
-- ---------------------------------------------------------------
INSERT INTO productos (id, nombre, descripcion, precio, stock, categoria_id, imagen, etiqueta, activo) VALUES
(1,  'Producto de prueba 01', 'Fixture ficticio', 5.00, 100, 2, 'images/productos.png', NULL, 1),
(2,  'Producto de prueba 02', 'Fixture ficticio', 5.00, 100, 2, 'images/productos.png', NULL, 1),
(3,  'Producto de prueba 03', 'Fixture ficticio', 5.00, 100, 3, 'images/productos.png', NULL, 1),
(4,  'Producto de prueba 04', 'Fixture ficticio', 5.00, 100, 3, 'images/productos.png', NULL, 1),
(5,  'Producto de prueba 05', 'Fixture ficticio', 5.00, 100, 1, 'images/productos.png', NULL, 1),
(6,  'Producto de prueba 06', 'Fixture ficticio', 5.00, 100, 1, 'images/productos.png', NULL, 1),
(7,  'Producto de prueba 07', 'Fixture ficticio', 5.00, 100, 4, 'images/productos.png', NULL, 1),
(8,  'Producto de prueba 08', 'Fixture ficticio', 5.00, 100, 4, 'images/productos.png', NULL, 1),
(9,  'Producto de prueba 09', 'Fixture ficticio', 5.00, 100, 5, 'images/productos.png', NULL, 1),
(10, 'Producto de prueba 10', 'Fixture ficticio', 5.00, 100, 5, 'images/productos.png', NULL, 1),
(11, 'Producto de prueba 11', 'Fixture ficticio', 5.00, 100, 6, 'images/productos.png', NULL, 1),
(12, 'Producto de prueba 12', 'Fixture ficticio', 6.00, 100, 6, 'images/productos.png', NULL, 1),
(13, 'Producto con stock limitado', 'Fixture ficticio', 20.00, 2, 6, 'images/productos.png', NULL, 1),
(14, 'Producto sin stock', 'Fixture ficticio', 15.00, 0, 6, 'images/productos.png', NULL, 1);

-- ---------------------------------------------------------------
-- Codigos promocionales
-- ---------------------------------------------------------------
INSERT INTO codigos_promo (codigo, tipo, valor, activo, fecha_expiracion) VALUES
('BIENVENIDA10', 'PORCENTAJE', 10.00, 1, NULL),
('LIBRO5', 'MONTO_FIJO', 5.00, 1, '2030-12-31'),
('VENCIDO20', 'PORCENTAJE', 20.00, 1, '2020-01-01');
