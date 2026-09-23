package libreria.dao;

import libreria.models.Comprobante;
import libreria.util.ConexionBD;

import java.sql.*;

/**
 * ComprobanteDAO - Libreria Brenda
 *
 * Un comprobante certifica que un pedido se convirtio en una venta real.
 * Se emite una sola vez por pedido (columna pedido_id es UNIQUE), en el
 * momento en que un administrador confirma el pedido (ver
 * PedidoDAO.cambiarEstado, que es quien orquesta la transaccion). Por eso
 * los metodos que reciben una Connection no abren ni cierran nada: son
 * parte de una transaccion mas grande que maneja quien los llama.
 */
public class ComprobanteDAO {

    private static final String SERIE_DEFECTO = "B001";

    /** true si el pedido ya tiene un comprobante emitido (para no duplicar). */
    public boolean existeParaPedido(Connection con, String pedidoId) throws SQLException {
        String sql = "SELECT 1 FROM comprobantes WHERE pedido_id = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, pedidoId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Emite el comprobante de un pedido, dentro de la conexion/transaccion
     * que ya tiene abierta PedidoDAO.cambiarEstado. administradorId puede
     * ser null solo para datos historicos migrados; en el flujo normal
     * siempre viene del admin logueado que confirmo el pedido.
     */
    public Comprobante emitir(Connection con, String pedidoId, double monto, Integer administradorId)
            throws SQLException {

        String sql = "INSERT INTO comprobantes (pedido_id, tipo_comprobante, serie, monto, administrador_id) " +
                     "VALUES (?, 'BOLETA', ?, ?, ?)";

        try (PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, pedidoId);
            ps.setString(2, SERIE_DEFECTO);
            ps.setDouble(3, monto);
            if (administradorId != null) {
                ps.setInt(4, administradorId);
            } else {
                ps.setNull(4, Types.INTEGER);
            }
            ps.executeUpdate();

            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    Comprobante c = new Comprobante();
                    c.setId(keys.getInt(1));
                    c.setPedidoId(pedidoId);
                    c.setTipoComprobante("BOLETA");
                    c.setSerie(SERIE_DEFECTO);
                    c.setMonto(monto);
                    c.setAdministradorId(administradorId);
                    return c;
                }
            }
        }
        return null;
    }

    /** Busca el comprobante de un pedido especifico, para mostrarlo en admin-pedidos.jsp. Usa su propia conexion. */
    public Comprobante buscarPorPedido(String pedidoId) {
        String sql = "SELECT c.*, a.nombre AS admin_nombre FROM comprobantes c " +
                     "LEFT JOIN administradores a ON a.id = c.administrador_id " +
                     "WHERE c.pedido_id = ?";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, pedidoId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    private Comprobante mapear(ResultSet rs) throws SQLException {
        Comprobante c = new Comprobante();
        c.setId(rs.getInt("id"));
        c.setPedidoId(rs.getString("pedido_id"));
        c.setTipoComprobante(rs.getString("tipo_comprobante"));
        c.setSerie(rs.getString("serie"));
        c.setMonto(rs.getDouble("monto"));
        c.setFechaEmision(rs.getTimestamp("fecha_emision"));
        int adminId = rs.getInt("administrador_id");
        c.setAdministradorId(rs.wasNull() ? null : adminId);
        c.setAdministradorNombre(rs.getString("admin_nombre"));
        return c;
    }
}
