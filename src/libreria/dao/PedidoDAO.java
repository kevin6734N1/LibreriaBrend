package libreria.dao;

import libreria.models.Pedido;
import libreria.util.ConexionBD;

import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * PedidoDAO - Libreria Brenda
 * Acceso a datos para las tablas "pedidos" y "pedido_items".
 * Usado por PedidoServlet (crear/listar/cambiar estado) y por
 * ReporteServlet (queries agregadas para los graficos de reportes.jsp).
 */
public class PedidoDAO {

    // =================================================================
    //  CRUD BASICO
    // =================================================================

    /**
     * Crea un pedido nuevo junto con sus items, dentro de una transaccion.
     * Antes de insertar los items, descuenta el stock de cada producto
     * (ProductoDAO.descontarStock, que ya trae su propia validacion
     * "stock >= cantidad" en el UPDATE). Si algun producto no tiene stock
     * suficiente, se hace rollback de todo el pedido y se lanza
     * StockInsuficienteException con el nombre del producto que fallo.
     *
     * @throws StockInsuficienteException si algun item pide mas stock del disponible
     */
    public boolean crear(Pedido pedido, int clienteId) {
        String sqlPedido = "INSERT INTO pedidos (id, cliente_id, fecha, estado, subtotal, descuento, envio, total, direccion_entrega, metodo_pago) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        String sqlItem = "INSERT INTO pedido_items (pedido_id, producto_id, cantidad, precio_unitario) " +
                          "VALUES (?, ?, ?, ?)";

        Connection con = null;
        try {
            con = ConexionBD.getConexion();
            con.setAutoCommit(false); // inicia transaccion

            try (PreparedStatement ps = con.prepareStatement(sqlPedido)) {
                ps.setString(1, pedido.getId());
                ps.setInt(2, clienteId);
                ps.setTimestamp(3, new Timestamp(pedido.getFecha().getTime()));
                ps.setString(4, pedido.getEstado().name());
                ps.setDouble(5, pedido.getSubtotal());
                ps.setDouble(6, pedido.getDescuento());
                ps.setDouble(7, pedido.getEnvio());
                // El total ya viene calculado (subtotal - descuento + envio) desde
                // Pedido.calcularTotal(); no se recalcula aquí para no perder el descuento.
                ps.setDouble(8, pedido.getTotal());
                ps.setString(9, pedido.getDireccionEntrega());
                ps.setString(10, pedido.getMetodoPago());
                ps.executeUpdate();
            }

            // Descontar stock ANTES de registrar los items: si algo no alcanza,
            // se aborta todo el pedido (ver catch de StockInsuficienteException).
            ProductoDAO productoDAO = new ProductoDAO();
            for (Pedido.ItemPedido item : pedido.getItems()) {
                int productoId = item.getProducto().getId();
                boolean hayStock = productoDAO.descontarStock(con, productoId, item.getCantidad());
                if (!hayStock) {
                    String nombre = productoDAO.obtenerNombre(con, productoId);
                    con.rollback();
                    throw new StockInsuficienteException(nombre, productoId, item.getCantidad());
                }
            }

            try (PreparedStatement ps = con.prepareStatement(sqlItem)) {
                for (Pedido.ItemPedido item : pedido.getItems()) {
                    ps.setString(1, pedido.getId());
                    ps.setInt(2, item.getProducto().getId());
                    ps.setInt(3, item.getCantidad());
                    ps.setDouble(4, item.getPrecioUnitario());
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            con.commit();
            return true;

        } catch (SQLException e) {
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            return false;
        } finally {
            if (con != null) {
                try { con.setAutoCommit(true); } catch (SQLException ignored) {}
                ConexionBD.cerrar(con);
            }
        }
    }

    /** Lista todos los pedidos de un cliente especifico (para pedidos.jsp del cliente). */
    public List<Map<String, Object>> listarPorCliente(int clienteId) {
        String sql = "SELECT p.id, p.fecha, p.estado, p.subtotal, p.descuento, p.envio, p.total, p.direccion_entrega, p.metodo_pago " +
                     "FROM pedidos p WHERE p.cliente_id = ? ORDER BY p.fecha DESC";
        return ejecutarListaPedidos(sql, clienteId, true);
    }

    /** Lista TODOS los pedidos (para el panel admin). */
    public List<Map<String, Object>> listarTodos() {
        String sql = "SELECT p.id, c.nombres, c.apellidos, p.fecha, p.estado, p.subtotal, p.descuento, p.envio, p.total, " +
                     "p.direccion_entrega, p.metodo_pago " +
                     "FROM pedidos p JOIN clientes c ON c.id = p.cliente_id " +
                     "ORDER BY p.fecha DESC";

        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> p = new LinkedHashMap<>();
                p.put("id", rs.getString("id"));
                p.put("cliente", rs.getString("nombres") + " " + rs.getString("apellidos"));
                p.put("fecha", rs.getTimestamp("fecha"));
                p.put("estado", rs.getString("estado"));
                p.put("subtotal", rs.getDouble("subtotal"));
                p.put("descuento", rs.getDouble("descuento"));
                p.put("envio", rs.getDouble("envio"));
                p.put("total", rs.getDouble("total"));
                p.put("direccion", rs.getString("direccion_entrega"));
                p.put("pago", rs.getString("metodo_pago"));
                p.put("items", obtenerItems(con, rs.getString("id")));
                lista.add(p);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return lista;
    }

    private List<Map<String, Object>> ejecutarListaPedidos(String sql, int clienteId, boolean incluirItems) {
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, clienteId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> p = new LinkedHashMap<>();
                    p.put("id", rs.getString("id"));
                    p.put("fecha", rs.getTimestamp("fecha"));
                    p.put("estado", rs.getString("estado"));
                    p.put("subtotal", rs.getDouble("subtotal"));
                    p.put("descuento", rs.getDouble("descuento"));
                    p.put("envio", rs.getDouble("envio"));
                    p.put("total", rs.getDouble("total"));
                    p.put("direccion", rs.getString("direccion_entrega"));
                    p.put("pago", rs.getString("metodo_pago"));
                    if (incluirItems) p.put("items", obtenerItems(con, rs.getString("id")));
                    lista.add(p);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return lista;
    }

    /** Obtiene los items (productos) de un pedido especifico. */
    private List<Map<String, Object>> obtenerItems(Connection con, String pedidoId) throws SQLException {
        String sql = "SELECT pr.nombre, pr.imagen, pi.cantidad, pi.precio_unitario " +
                     "FROM pedido_items pi JOIN productos pr ON pr.id = pi.producto_id " +
                     "WHERE pi.pedido_id = ?";

        List<Map<String, Object>> items = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, pedidoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> it = new LinkedHashMap<>();
                    it.put("nombre", rs.getString("nombre"));
                    it.put("img", rs.getString("imagen"));
                    it.put("qty", rs.getInt("cantidad"));
                    it.put("precio", rs.getDouble("precio_unitario"));
                    items.add(it);
                }
            }
        }
        return items;
    }

    // Estados en los que un pedido ya se considera una venta real y por lo
    // tanto debe tener su comprobante emitido (si todavia no lo tiene).
    private static final List<String> ESTADOS_VENTA_CONFIRMADA =
        List.of("CONFIRMADO", "ENVIADO", "ENTREGADO");

    /**
     * Cambia el estado de un pedido (PENDIENTE, CONFIRMADO, ENVIADO, ENTREGADO, CANCELADO).
     * Sobrecarga de compatibilidad sin administrador (usada cuando el propio
     * cliente cancela su pedido: ahi no hace falta emitir comprobante).
     */
    public boolean cambiarEstado(String pedidoId, String nuevoEstado) {
        return cambiarEstado(pedidoId, nuevoEstado, null);
    }

    /**
     * Cancela un pedido SOLO si pertenece al cliente indicado Y su estado
     * actual es PENDIENTE. Ambas condiciones van en el propio UPDATE (no en
     * un SELECT previo) para que la verificacion y el cambio sean atomicos:
     * asi no hay ventana entre "leer estado" y "escribir estado" en la que
     * otra peticion pueda colarse (ej. el admin confirmandolo justo en ese
     * instante).
     *
     * @return true si se cancelo (existia, era del cliente y estaba
     *         PENDIENTE); false si no existe, no es del cliente, o ya no
     *         esta en PENDIENTE (ya fue confirmado/enviado/entregado/
     *         cancelado antes).
     */
    public boolean cancelarPedidoCliente(String pedidoId, int clienteId) {
        String sql = "UPDATE pedidos SET estado = 'CANCELADO' " +
                     "WHERE id = ? AND cliente_id = ? AND estado = 'PENDIENTE'";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, pedidoId);
            ps.setInt(2, clienteId);
            int filas = ps.executeUpdate();
            return filas > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Cambia el estado de un pedido. Si el nuevo estado es CONFIRMADO, ENVIADO
     * o ENTREGADO y el pedido todavia no tiene comprobante, se emite uno
     * dentro de la misma transaccion (ver ComprobanteDAO). Este es el punto
     * exacto donde un pedido deja de ser una simple intencion de compra y
     * pasa a contar como venta real para los reportes.
     *
     * @param administradorId id del admin logueado que hizo el cambio (para
     *                        dejar registro de quien confirmo la venta). Null
     *                        si no aplica (ej. cancelacion hecha por el cliente).
     */
    public boolean cambiarEstado(String pedidoId, String nuevoEstado, Integer administradorId) {
        String sqlUpdate = "UPDATE pedidos SET estado = ? WHERE id = ?";
        String sqlTotal  = "SELECT total FROM pedidos WHERE id = ?";
        String estado    = nuevoEstado.toUpperCase();

        Connection con = null;
        try {
            con = ConexionBD.getConexion();
            con.setAutoCommit(false);

            try (PreparedStatement ps = con.prepareStatement(sqlUpdate)) {
                ps.setString(1, estado);
                ps.setString(2, pedidoId);
                ps.executeUpdate();
            }

            if (ESTADOS_VENTA_CONFIRMADA.contains(estado)) {
                ComprobanteDAO comprobanteDAO = new ComprobanteDAO();
                if (!comprobanteDAO.existeParaPedido(con, pedidoId)) {
                    double total = 0;
                    try (PreparedStatement ps = con.prepareStatement(sqlTotal)) {
                        ps.setString(1, pedidoId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) total = rs.getDouble("total");
                        }
                    }
                    comprobanteDAO.emitir(con, pedidoId, total, administradorId);
                }
            }

            con.commit();
            return true;

        } catch (SQLException e) {
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            return false;
        } finally {
            if (con != null) {
                try { con.setAutoCommit(true); } catch (SQLException ignored) {}
                ConexionBD.cerrar(con);
            }
        }
    }

    // =================================================================
    //  QUERIES PARA REPORTES (usadas por ReporteServlet)
    // =================================================================

    /**
     * Stats generales del periodo: pedidos, ingresos, clientes nuevos, ticket promedio.
     * Los ingresos/ticket se calculan solo sobre pedidos con comprobante emitido
     * (ventas realmente confirmadas), no sobre todo lo que no este CANCELADO -
     * un pedido en PENDIENTE todavia no es una venta real.
     */
    public Map<String, Object> obtenerStats(String fechaInicio) {
        Map<String, Object> stats = new LinkedHashMap<>();
        String sqlPedidos =
            "SELECT COUNT(*) AS total_pedidos, COALESCE(SUM(p.total),0) AS ingresos, " +
            "COALESCE(AVG(p.total),0) AS ticket " +
            "FROM pedidos p INNER JOIN comprobantes c ON c.pedido_id = p.id " +
            "WHERE p.fecha >= ?";
        String sqlClientes =
            "SELECT COUNT(*) AS nuevos FROM clientes WHERE fecha_registro >= ?";

        try (Connection con = ConexionBD.getConexion()) {

            try (PreparedStatement ps = con.prepareStatement(sqlPedidos)) {
                ps.setString(1, fechaInicio);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        stats.put("pedidos", rs.getInt("total_pedidos"));
                        stats.put("ingresos", rs.getDouble("ingresos"));
                        stats.put("ticket", rs.getDouble("ticket"));
                    }
                }
            }

            try (PreparedStatement ps = con.prepareStatement(sqlClientes)) {
                ps.setString(1, fechaInicio);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) stats.put("clientesNuevos", rs.getInt("nuevos"));
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return stats;
    }

    /** Ventas agrupadas por dia (solo con comprobante emitido), para el grafico de linea "Ventas en el tiempo". */
    public List<Map<String, Object>> ventasPorDia(String fechaInicio) {
        String sql = "SELECT DATE(p.fecha) AS dia, SUM(p.total) AS total " +
                     "FROM pedidos p INNER JOIN comprobantes c ON c.pedido_id = p.id " +
                     "WHERE p.fecha >= ? " +
                     "GROUP BY DATE(p.fecha) ORDER BY dia ASC";
        return ejecutarQueryGenerica(sql, fechaInicio, "dia", "total");
    }

    /** Cantidad de pedidos agrupados por estado, para el grafico de dona. */
    public List<Map<String, Object>> pedidosPorEstado() {
        String sql = "SELECT estado, COUNT(*) AS cantidad FROM pedidos GROUP BY estado";

        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("estado", rs.getString("estado"));
                m.put("cantidad", rs.getInt("cantidad"));
                lista.add(m);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return lista;
    }

    /** Ingresos agrupados por categoria, usa la vista_ventas_categoria. */
    public List<Map<String, Object>> ventasPorCategoria() {
        String sql = "SELECT categoria, ingresos FROM vista_ventas_categoria ORDER BY ingresos DESC";

        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("categoria", rs.getString("categoria"));
                m.put("ingresos", rs.getDouble("ingresos"));
                lista.add(m);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return lista;
    }

    /** Top 5 productos mas vendidos, usa la vista_top_productos. */
    public List<Map<String, Object>> topProductos(int limite) {
        String sql = "SELECT nombre, unidades_vendidas, ingresos_generados " +
                     "FROM vista_top_productos LIMIT ?";

        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, limite);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("nombre", rs.getString("nombre"));
                    m.put("unidades", rs.getInt("unidades_vendidas"));
                    m.put("ingresos", rs.getDouble("ingresos_generados"));
                    lista.add(m);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return lista;
    }

    /** Top 5 clientes por total gastado, usa la vista_clientes_resumen. */
    public List<Map<String, Object>> topClientes(int limite) {
        String sql = "SELECT nombres, apellidos, total_pedidos, total_gastado " +
                     "FROM vista_clientes_resumen ORDER BY total_gastado DESC LIMIT ?";

        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, limite);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("nombre", rs.getString("nombres") + " " + rs.getString("apellidos"));
                    m.put("pedidos", rs.getInt("total_pedidos"));
                    m.put("gastado", rs.getDouble("total_gastado"));
                    lista.add(m);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return lista;
    }

    /** Clientes nuevos agrupados por mes (para el grafico de barras de clientes). */
    public List<Map<String, Object>> clientesNuevosPorMes() {
        String sql = "SELECT DATE_FORMAT(fecha_registro, '%Y-%m') AS mes, COUNT(*) AS cantidad " +
                     "FROM clientes GROUP BY mes ORDER BY mes ASC";
        return ejecutarQueryGenerica(sql, null, "mes", "cantidad");
    }

    /** Helper generico para queries de 2 columnas (label, valor) con o sin parametro. */
    private List<Map<String, Object>> ejecutarQueryGenerica(String sql, String param, String campoLabel, String campoValor) {
        List<Map<String, Object>> lista = new ArrayList<>();
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            if (param != null) ps.setString(1, param);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put(campoLabel, rs.getString(campoLabel));
                    m.put(campoValor, rs.getDouble(campoValor));
                    lista.add(m);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return lista;
    }
}