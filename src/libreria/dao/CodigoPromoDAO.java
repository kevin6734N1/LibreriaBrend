package libreria.dao;

import libreria.models.CodigoPromo;
import libreria.util.ConexionBD;

import java.sql.*;
import java.time.LocalDate;
import java.time.ZoneId;

/** CodigoPromoDAO - Libreria Brenda. Acceso a "codigos_promo" y "codigos_promo_usos". */
public class CodigoPromoDAO {

    // Misma zona que usa ConexionBD (serverTimezone=America/Lima), sin depender de la del servidor.
    private static final ZoneId ZONA_LIMA = ZoneId.of("America/Lima");

    /** Resultado de validar un codigo: ok + descuento, o el motivo del rechazo. */
    public static class Resultado {
        public final boolean ok;
        public final String error;
        public final CodigoPromo promo;
        public final double descuento;

        private Resultado(boolean ok, String error, CodigoPromo promo, double descuento) {
            this.ok = ok; this.error = error; this.promo = promo; this.descuento = descuento;
        }
        static Resultado fallo(String mensaje)              { return new Resultado(false, mensaje, null, 0); }
        static Resultado exito(CodigoPromo p, double desc)  { return new Resultado(true, null, p, desc); }
    }

    public static String normalizar(String codigo) {
        return codigo == null ? "" : codigo.trim().toUpperCase();
    }

    /** Valida existencia, estado, vencimiento y uso previo del cliente; calcula el descuento. */
    public Resultado validar(String codigoIngresado, int clienteId, double subtotal) {
        String codigo = normalizar(codigoIngresado);
        if (codigo.isEmpty()) return Resultado.fallo("Escribe un código promocional.");
        if (!(subtotal > 0))  return Resultado.fallo("Tu carrito está vacío.");

        String sqlCodigo = "SELECT tipo, valor, activo, fecha_expiracion FROM codigos_promo WHERE codigo = ?";
        String sqlUso    = "SELECT 1 FROM codigos_promo_usos WHERE codigo = ? AND cliente_id = ?";

        try (Connection con = ConexionBD.getConexion()) {

            CodigoPromo promo = new CodigoPromo();
            promo.setCodigo(codigo);

            try (PreparedStatement ps = con.prepareStatement(sqlCodigo)) {
                ps.setString(1, codigo);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next() || !rs.getBoolean("activo")) {
                        return Resultado.fallo("El código no existe o no está activo.");
                    }
                    promo.setTipo(rs.getString("tipo"));
                    promo.setValor(rs.getDouble("valor"));

                    Date exp = rs.getDate("fecha_expiracion");
                    // Vigente hasta el propio dia de expiracion (inclusive).
                    if (exp != null && exp.toLocalDate().isBefore(LocalDate.now(ZONA_LIMA))) {
                        return Resultado.fallo("Este código ya venció.");
                    }
                }
            }

            try (PreparedStatement ps = con.prepareStatement(sqlUso)) {
                ps.setString(1, codigo);
                ps.setInt(2, clienteId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) return Resultado.fallo("Ya usaste este código en un pedido anterior.");
                }
            }

            double descuento = promo.calcularDescuento(subtotal);
            if (descuento <= 0) return Resultado.fallo("El código no aplica a este pedido.");
            return Resultado.exito(promo, descuento);

        } catch (SQLException e) {
            e.printStackTrace();
            return Resultado.fallo("No se pudo validar el código. Intenta de nuevo.");
        }
    }

    /**
     * Registra el uso dentro de la transaccion del pedido (usa la Connection de
     * PedidoDAO.crear). La PK (codigo, cliente_id) hace que un segundo uso falle.
     */
    public void registrarUso(Connection con, String codigo, int clienteId, String pedidoId) throws SQLException {
        String sql = "INSERT INTO codigos_promo_usos (codigo, cliente_id, pedido_id) VALUES (?, ?, ?)";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, codigo);
            ps.setInt(2, clienteId);
            ps.setString(3, pedidoId);
            ps.executeUpdate();
        }
    }
}
