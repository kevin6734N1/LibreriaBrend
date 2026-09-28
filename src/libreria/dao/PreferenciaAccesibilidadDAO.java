package libreria.dao;

import libreria.models.PreferenciaAccesibilidad;
import libreria.util.ConexionBD;

import java.sql.*;

/**
 * PreferenciaAccesibilidadDAO - Libreria Brenda
 * Acceso a datos para "preferencias_accesibilidad" (ODS10 / Ley 29973).
 */
public class PreferenciaAccesibilidadDAO {

    /** Si el cliente todavia no tiene fila guardada, devuelve los valores por defecto (sin tocar la BD). */
    public PreferenciaAccesibilidad obtenerPorCliente(int clienteId) {
        String sql = "SELECT tipo_daltonismo, lectura_voz_activa FROM preferencias_accesibilidad WHERE cliente_id = ?";

        PreferenciaAccesibilidad p = new PreferenciaAccesibilidad();
        p.setClienteId(clienteId);
        p.setTipoDaltonismo("ninguno");
        p.setLecturaVozActiva(false);

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, clienteId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    p.setTipoDaltonismo(rs.getString("tipo_daltonismo"));
                    p.setLecturaVozActiva(rs.getBoolean("lectura_voz_activa"));
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return p;
    }

    /** Inserta o actualiza (upsert) la preferencia del cliente. */
    public boolean guardar(PreferenciaAccesibilidad p) {
        String sql = "INSERT INTO preferencias_accesibilidad (cliente_id, tipo_daltonismo, lectura_voz_activa) " +
                     "VALUES (?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE tipo_daltonismo = VALUES(tipo_daltonismo), " +
                     "lectura_voz_activa = VALUES(lectura_voz_activa)";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, p.getClienteId());
            ps.setString(2, p.getTipoDaltonismo());
            ps.setBoolean(3, p.isLecturaVozActiva());
            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
