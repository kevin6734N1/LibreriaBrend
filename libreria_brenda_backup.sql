/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.20-11.8.9-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: libreria_brenda
-- ------------------------------------------------------
-- Server version	11.8.8-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `administradores`
--

DROP TABLE IF EXISTS `administradores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `administradores` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(80) NOT NULL,
  `email` varchar(120) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `codigo_empleado` varchar(20) NOT NULL,
  `fecha_registro` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `codigo_empleado` (`codigo_empleado`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `administradores`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `administradores` WRITE;
/*!40000 ALTER TABLE `administradores` DISABLE KEYS */;
INSERT INTO `administradores` VALUES
(1,'Admin Brenda','admin@example.com','$2a$10$6JsbyV9YprzX4WDrRRsfrOA53nQHfS0KxYNZ1NeAjK0rals87T0Wq','EMP-0001','2026-06-16 08:04:44');
/*!40000 ALTER TABLE `administradores` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `categorias`
--

DROP TABLE IF EXISTS `categorias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `categorias` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(40) NOT NULL,
  `icono` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categorias`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `categorias` WRITE;
/*!40000 ALTER TABLE `categorias` DISABLE KEYS */;
INSERT INTO `categorias` VALUES
(1,'Libros','images/libro-logo.png'),
(2,'Cuadernos','images/productos.png'),
(3,'Lapiceros','images/tienda.png'),
(4,'Mochilas','images/mochila-silueta.png'),
(5,'Arte','images/acuarelas.png'),
(6,'Oficina','images/dashboard.png');
/*!40000 ALTER TABLE `categorias` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `clientes`
--

DROP TABLE IF EXISTS `clientes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `clientes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombres` varchar(80) NOT NULL,
  `apellidos` varchar(80) NOT NULL,
  `dni` varchar(8) NOT NULL,
  `email` varchar(120) NOT NULL,
  `telefono` varchar(15) NOT NULL,
  `direccion` varchar(200) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `fecha_registro` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `dni` (`dni`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_email` (`email`),
  KEY `idx_dni` (`dni`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clientes`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `clientes` WRITE;
/*!40000 ALTER TABLE `clientes` DISABLE KEYS */;
INSERT INTO `clientes` VALUES
(1,'Cliente','Demo','99900001','cliente1@example.com','900000000','Direccion Demo, Lima','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-01-01 10:00:00'),
(2,'Maria','Garcia Lopez','99900002','cliente2@example.com','945123456','Av. Arequipa 1234, Miraflores','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-01-05 09:15:00'),
(3,'Carlos','Mendoza Ruiz','99900003','cliente3@example.com','987654321','Jr. Huancayo 567, Brena','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-02-12 14:20:00'),
(4,'Ana','Torres Vega','99900004','cliente4@example.com','912345678','Calle Los Pinos 890, Surco','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-03-01 11:05:00'),
(5,'Luis','Rojas Fernandez','99900005','cliente5@example.com','998877665','Av. La Marina 345, San Miguel','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-03-18 16:40:00'),
(6,'Rosa','Paredes Quispe','99900006','cliente6@example.com','934567890','Jr. Tacna 201, Cercado de Lima','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',0,'2026-04-02 08:30:00'),
(7,'Jorge','Salazar Vidal','99900007','cliente7@example.com','956789012','Av. Brasil 880, Pueblo Libre','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-04-20 13:10:00'),
(8,'Patricia','Nunez Castro','99900008','cliente8@example.com','923456789','Calle Las Flores 45, San Borja','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-05-10 10:50:00'),
(9,'Diego','Ramos Herrera','99900009','cliente9@example.com','967890123','Av. Angamos 1200, Surquillo','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-05-28 17:25:00'),
(10,'Valeria','Chavez Morales','99900010','cliente10@example.com','978901234','Jr. Cusco 310, La Victoria','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-06-03 09:00:00'),
(11,'Fernando','Vargas Soto','99900011','cliente11@example.com','945678901','Av. Colonial 500, Callao','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',0,'2026-06-10 12:15:00'),
(12,'Fabio','Quiroz','99900012','cliente12@example.com','991919716','jiron manco inca 262','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-06-16 09:41:06'),
(18,'juanita','juarez','99900013','cliente18@example.com','991919717','jiron manco inca 262','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-06-16 10:10:54'),
(19,'Alexis','Cordova','99900014','cliente19@example.com','934722351','los malditos cerros','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-07-02 21:19:53'),
(21,'Carol','Bolo','99900015','cliente21@example.com','999-888-777','Callao','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-09-05 16:12:05'),
(22,'Cliente','Sintetico 22','99900016','cliente22@example.com','991919718','Castilla','$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S',1,'2026-09-18 19:24:53');
/*!40000 ALTER TABLE `clientes` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `codigos_promo`
--

DROP TABLE IF EXISTS `codigos_promo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `codigos_promo` (
  `codigo` varchar(30) NOT NULL,
  `tipo` enum('PORCENTAJE','MONTO_FIJO') NOT NULL,
  `valor` decimal(10,2) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `fecha_expiracion` date DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`codigo`),
  CONSTRAINT `chk_promo_valor` CHECK (`valor` > 0 and (`tipo` <> 'PORCENTAJE' or `valor` <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `codigos_promo`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `codigos_promo` WRITE;
/*!40000 ALTER TABLE `codigos_promo` DISABLE KEYS */;
INSERT INTO `codigos_promo` VALUES
('BIENVENIDA10','PORCENTAJE',10.00,1,NULL,'2026-09-28 00:33:34'),
('LIBRO5','MONTO_FIJO',5.00,1,'2026-12-31','2026-09-28 00:33:34'),
('VERANO20','PORCENTAJE',20.00,1,'2026-01-31','2026-09-28 00:33:34');
/*!40000 ALTER TABLE `codigos_promo` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `codigos_promo_usos`
--

DROP TABLE IF EXISTS `codigos_promo_usos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `codigos_promo_usos` (
  `codigo` varchar(30) NOT NULL,
  `cliente_id` int(11) NOT NULL,
  `pedido_id` varchar(30) NOT NULL,
  `fecha_uso` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`codigo`,`cliente_id`),
  KEY `fk_promo_uso_cliente` (`cliente_id`),
  CONSTRAINT `fk_promo_uso_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_promo_uso_codigo` FOREIGN KEY (`codigo`) REFERENCES `codigos_promo` (`codigo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `codigos_promo_usos`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `codigos_promo_usos` WRITE;
/*!40000 ALTER TABLE `codigos_promo_usos` DISABLE KEYS */;
/*!40000 ALTER TABLE `codigos_promo_usos` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `comprobantes`
--

DROP TABLE IF EXISTS `comprobantes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `comprobantes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pedido_id` varchar(30) NOT NULL,
  `tipo_comprobante` enum('BOLETA','FACTURA') NOT NULL DEFAULT 'BOLETA',
  `serie` varchar(4) NOT NULL DEFAULT 'B001',
  `monto` decimal(10,2) NOT NULL,
  `administrador_id` int(11) DEFAULT NULL,
  `fecha_emision` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_comprobante_pedido` (`pedido_id`),
  KEY `fk_comprobante_admin` (`administrador_id`),
  CONSTRAINT `fk_comprobante_admin` FOREIGN KEY (`administrador_id`) REFERENCES `administradores` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_comprobante_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedidos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comprobantes`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `comprobantes` WRITE;
/*!40000 ALTER TABLE `comprobantes` DISABLE KEYS */;
INSERT INTO `comprobantes` VALUES
(1,'PED-1001','BOLETA','B001',115.40,1,'2026-05-10 10:32:00'),
(2,'PED-1002','BOLETA','B001',65.00,1,'2026-05-15 15:15:00'),
(3,'PED-1004','BOLETA','B001',70.90,1,'2026-05-18 11:48:00'),
(4,'PED-1783021834713','BOLETA','B001',248.80,1,'2026-07-02 14:50:34'),
(5,'PED-1783026074772','BOLETA','B001',85.50,1,'2026-07-02 16:01:14'),
(6,'PED-1783046974349','BOLETA','B001',9.00,1,'2026-07-02 21:49:34'),
(8,'PED-1788638730511','BOLETA','B001',102.00,1,'2026-09-05 15:07:48'),
(9,'PED-1788642782184','BOLETA','B001',42.50,1,'2026-09-05 16:13:49');
/*!40000 ALTER TABLE `comprobantes` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `pedido_items`
--

DROP TABLE IF EXISTS `pedido_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedido_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pedido_id` varchar(30) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL DEFAULT 1,
  `precio_unitario` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_item_producto` (`producto_id`),
  KEY `idx_pedido` (`pedido_id`),
  CONSTRAINT `fk_item_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedidos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_item_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedido_items`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `pedido_items` WRITE;
/*!40000 ALTER TABLE `pedido_items` DISABLE KEYS */;
INSERT INTO `pedido_items` VALUES
(1,'PED-1001',1,1,89.90),
(2,'PED-1001',2,3,8.50),
(3,'PED-1002',4,1,65.00),
(4,'PED-1003',3,2,25.00),
(5,'PED-1003',9,1,22.50),
(6,'PED-1004',5,1,38.90),
(7,'PED-1004',10,1,32.00),
(8,'PED-1005',6,1,120.00),
(9,'PED-1783021834713',6,1,120.00),
(10,'PED-1783021834713',5,1,38.90),
(11,'PED-1783021834713',1,1,89.90),
(12,'PED-1783026074772',8,1,18.00),
(13,'PED-1783026074772',7,1,45.00),
(14,'PED-1783026074772',9,1,22.50),
(15,'PED-1783046974349',11,3,3.00),
(16,'PED-1783047700759',2,1,8.50),
(17,'PED-1783104538829',11,1,3.00),
(18,'PED-1783106072691',8,1,18.00),
(19,'PED-1783106072691',2,1,8.50),
(20,'PED-1783106072691',3,1,25.00),
(21,'PED-1783390538284',11,1,3.00),
(22,'PED-1783390538284',2,1,8.50),
(23,'PED-1783390538284',5,1,38.90),
(24,'PED-1788638730511',6,1,120.00),
(25,'PED-1788640391751',1,1,89.90),
(26,'PED-1788640391751',10,1,32.00),
(27,'PED-1788642782184',3,2,25.00),
(28,'PED-1789777523824',2,1,8.50),
(29,'PED-1789777523824',8,1,18.00),
(30,'PED-1789777523824',11,1,3.00),
(31,'PED-1789777523824',3,1,25.00);
/*!40000 ALTER TABLE `pedido_items` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `pedidos`
--

DROP TABLE IF EXISTS `pedidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedidos` (
  `id` varchar(30) NOT NULL,
  `cliente_id` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` enum('PENDIENTE','CONFIRMADO','ENVIADO','ENTREGADO','CANCELADO') NOT NULL DEFAULT 'PENDIENTE',
  `subtotal` decimal(10,2) NOT NULL DEFAULT 0.00,
  `descuento` decimal(10,2) NOT NULL DEFAULT 0.00,
  `envio` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total` decimal(10,2) NOT NULL DEFAULT 0.00,
  `direccion_entrega` varchar(200) DEFAULT NULL,
  `metodo_pago` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cliente` (`cliente_id`),
  KEY `idx_estado` (`estado`),
  KEY `idx_fecha` (`fecha`),
  CONSTRAINT `fk_pedido_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedidos`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `pedidos` WRITE;
/*!40000 ALTER TABLE `pedidos` DISABLE KEYS */;
INSERT INTO `pedidos` VALUES
('PED-1001',2,'2026-05-10 10:32:00','ENTREGADO',115.40,0.00,0.00,115.40,'Av. Arequipa 1234, Miraflores','Tarjeta Visa'),
('PED-1002',3,'2026-05-15 15:15:00','ENVIADO',65.00,0.00,0.00,65.00,'Jr. Huancayo 567, Brena','Yape'),
('PED-1003',4,'2026-05-17 09:05:00','PENDIENTE',72.50,0.00,0.00,72.50,'Calle Los Pinos 890, Surco','Transferencia BCP'),
('PED-1004',5,'2026-05-18 11:48:00','CONFIRMADO',70.90,0.00,0.00,70.90,'Av. La Marina 345, San Miguel','Efectivo contra entrega'),
('PED-1005',6,'2026-05-20 16:22:00','CANCELADO',120.00,0.00,0.00,120.00,'Jr. Tacna 201, Cercado de Lima','Tarjeta Mastercard'),
('PED-1783021834713',1,'2026-07-02 14:50:34','ENVIADO',248.80,0.00,0.00,248.80,'jiron manco inca 262','Yape'),
('PED-1783026074772',1,'2026-07-02 16:01:14','CONFIRMADO',85.50,0.00,0.00,85.50,'jiron manco inca 267','Transferencia BCP'),
('PED-1783046974349',1,'2026-07-02 21:49:34','ENVIADO',9.00,0.00,0.00,9.00,'jiron manco inca 269','Tarjeta Visa'),
('PED-1783047700759',1,'2026-07-02 22:01:40','PENDIENTE',8.50,0.00,0.00,8.50,'jiron manco inca 276','Tarjeta Visa'),
('PED-1783104538829',1,'2026-07-03 13:48:58','PENDIENTE',3.00,0.00,0.00,3.00,'jiron manco inca 281','Efectivo contra entrega'),
('PED-1783106072691',1,'2026-07-03 14:14:32','PENDIENTE',51.50,7.73,0.00,43.78,'jiron manco inca 283','Transferencia BCP'),
('PED-1783390538284',1,'2026-07-06 21:15:38','PENDIENTE',50.40,7.56,0.00,42.84,'Av Cezar Rojas','Yape'),
('PED-1788638730511',1,'2026-09-05 15:05:30','CONFIRMADO',120.00,18.00,0.00,102.00,'jiron manco inca 6767','Yape'),
('PED-1788640391751',2,'2026-09-05 15:33:11','CANCELADO',121.90,18.29,0.00,103.62,'arequipa 6767','Tarjeta Mastercard'),
('PED-1788642782184',21,'2026-09-05 16:13:02','ENTREGADO',50.00,7.50,0.00,42.50,'parque callao','Plin'),
('PED-1789777523824',22,'2026-09-18 19:25:23','PENDIENTE',54.50,0.00,0.00,54.50,'Jr manco inca 262','Yape');
/*!40000 ALTER TABLE `pedidos` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `preferencias_accesibilidad`
--

DROP TABLE IF EXISTS `preferencias_accesibilidad`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `preferencias_accesibilidad` (
  `cliente_id` int(11) NOT NULL,
  `tipo_daltonismo` enum('ninguno','protanopia','deuteranopia','tritanopia') NOT NULL DEFAULT 'ninguno',
  `lectura_voz_activa` tinyint(1) NOT NULL DEFAULT 0,
  `fecha_actualizacion` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`cliente_id`),
  CONSTRAINT `fk_pref_accesibilidad_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `clientes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `preferencias_accesibilidad`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `preferencias_accesibilidad` WRITE;
/*!40000 ALTER TABLE `preferencias_accesibilidad` DISABLE KEYS */;
/*!40000 ALTER TABLE `preferencias_accesibilidad` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Table structure for table `productos`
--

DROP TABLE IF EXISTS `productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `precio` decimal(10,2) NOT NULL DEFAULT 0.00,
  `stock` int(11) NOT NULL DEFAULT 0,
  `categoria_id` int(11) NOT NULL,
  `imagen` varchar(200) NOT NULL DEFAULT 'images/productos.png',
  `etiqueta` varchar(20) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_categoria` (`categoria_id`),
  KEY `idx_activo` (`activo`),
  CONSTRAINT `fk_producto_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categorias` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `productos` WRITE;
/*!40000 ALTER TABLE `productos` DISABLE KEYS */;
INSERT INTO `productos` VALUES
(1,'Pack Libros Escolares Primaria Completo 2026','Coleccion completa de libros para primaria.',89.90,15,1,'images/productos/pack-libros.png','30% OFF',1,'2026-06-16 08:04:44'),
(2,'Cuaderno Universitario 100 hojas Cuadriculado','Cuaderno de 100 hojas cuadriculado.',8.50,79,2,'images/productos/agenda-escolar.png',NULL,1,'2026-06-16 08:04:44'),
(3,'Set Lapiceros Faber-Castell x 24 colores','Set de 24 lapiceros de colores Faber-Castell.',25.00,37,3,'images/productos/lapiceros-faber.png','NUEVO',1,'2026-06-16 08:04:44'),
(4,'Mochila Escolar Resistente con Bolsillos','Mochila resistente con bolsillos laterales.',65.00,12,4,'images/productos/mochila-escolar.png','15% OFF',1,'2026-06-16 08:04:44'),
(5,'Caja de Acuarelas Profesional 48 colores','Acuarelas profesionales de 48 colores.',38.90,20,5,'images/productos/acuarelas.png',NULL,1,'2026-06-16 08:04:44'),
(6,'Pizarra Acrilica 60x80cm con Marco Aluminio','Pizarra acrilica de alta calidad.',120.00,6,6,'images/productos/pizarra-acrilica.png','OFERTA',1,'2026-06-16 08:04:44'),
(7,'Diccionario de Matematicas Escolar Ilustrado','Diccionario matematico para escolares.',45.00,18,1,'images/productos/diccionario-matematicas.png',NULL,1,'2026-06-16 08:04:44'),
(8,'Agenda Escolar 2026 Diseno Moderno','Agenda escolar con diseno moderno.',18.00,34,2,'images/productos/agenda-escolar.png',NULL,1,'2026-06-16 08:04:44'),
(9,'Resma Papel Bond A4 75gr x 500 hojas','Resma de papel bond A4.',22.50,4,6,'images/productos/resma-papel.png','HOT',1,'2026-06-16 08:04:44'),
(10,'Set Pinceles Artisticos x 12 unidades','Set de 12 pinceles artisticos mixtos.',32.00,7,5,'images/productos/pinceles.png',NULL,1,'2026-06-16 08:04:44'),
(11,'Reglas','Escuadra de Reglas',3.00,5,6,'images/productos/Escuadras.png','HOT',1,'2026-07-02 16:22:51');
/*!40000 ALTER TABLE `productos` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;

--
-- Temporary table structure for view `vista_clientes_resumen`
--

DROP TABLE IF EXISTS `vista_clientes_resumen`;
/*!50001 DROP VIEW IF EXISTS `vista_clientes_resumen`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vista_clientes_resumen` AS SELECT
 NULL AS `id`,
 NULL AS `nombres`,
 NULL AS `apellidos`,
 NULL AS `dni`,
 NULL AS `email`,
 NULL AS `telefono`,
 NULL AS `direccion`,
 NULL AS `activo`,
 NULL AS `fecha_registro`,
 NULL AS `total_pedidos`,
 NULL AS `total_gastado` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vista_top_productos`
--

DROP TABLE IF EXISTS `vista_top_productos`;
/*!50001 DROP VIEW IF EXISTS `vista_top_productos`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vista_top_productos` AS SELECT
 NULL AS `id`,
 NULL AS `nombre`,
 NULL AS `unidades_vendidas`,
 NULL AS `ingresos_generados` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vista_ventas_categoria`
--

DROP TABLE IF EXISTS `vista_ventas_categoria`;
/*!50001 DROP VIEW IF EXISTS `vista_ventas_categoria`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vista_ventas_categoria` AS SELECT
 NULL AS `id`,
 NULL AS `categoria`,
 NULL AS `ingresos` */;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'libreria_brenda'
--

--
-- Dumping routines for database 'libreria_brenda'
--

--
-- Final view structure for view `vista_clientes_resumen`
--

/*!50001 DROP VIEW IF EXISTS `vista_clientes_resumen`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vista_clientes_resumen` AS select `c`.`id` AS `id`,`c`.`nombres` AS `nombres`,`c`.`apellidos` AS `apellidos`,`c`.`dni` AS `dni`,`c`.`email` AS `email`,`c`.`telefono` AS `telefono`,`c`.`direccion` AS `direccion`,`c`.`activo` AS `activo`,`c`.`fecha_registro` AS `fecha_registro`,count(distinct `p`.`id`) AS `total_pedidos`,coalesce(sum(case when `co`.`pedido_id` is not null then `p`.`total` else 0 end),0) AS `total_gastado` from ((`clientes` `c` left join `pedidos` `p` on(`p`.`cliente_id` = `c`.`id`)) left join `comprobantes` `co` on(`co`.`pedido_id` = `p`.`id`)) group by `c`.`id` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vista_top_productos`
--

/*!50001 DROP VIEW IF EXISTS `vista_top_productos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vista_top_productos` AS select `pr`.`id` AS `id`,`pr`.`nombre` AS `nombre`,sum(`pi`.`cantidad`) AS `unidades_vendidas`,sum(`pi`.`cantidad` * `pi`.`precio_unitario`) AS `ingresos_generados` from ((`pedido_items` `pi` join `productos` `pr` on(`pr`.`id` = `pi`.`producto_id`)) join `comprobantes` `co` on(`co`.`pedido_id` = `pi`.`pedido_id`)) group by `pr`.`id` order by sum(`pi`.`cantidad`) desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vista_ventas_categoria`
--

/*!50001 DROP VIEW IF EXISTS `vista_ventas_categoria`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vista_ventas_categoria` AS select `cat`.`id` AS `id`,`cat`.`nombre` AS `categoria`,sum(`pi`.`cantidad` * `pi`.`precio_unitario`) AS `ingresos` from (((`pedido_items` `pi` join `productos` `pr` on(`pr`.`id` = `pi`.`producto_id`)) join `categorias` `cat` on(`cat`.`id` = `pr`.`categoria_id`)) join `comprobantes` `co` on(`co`.`pedido_id` = `pi`.`pedido_id`)) group by `cat`.`id` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-10-01 16:58:43
