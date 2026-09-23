package libreria.dao;

import libreria.models.Administrador;
import libreria.util.ConexionBD;
import libreria.util.PasswordUtil;

import java.sql.*;

/**
 * AdministradorDAO - Libreria Brenda
 * Antes el login de admin comparaba contra credenciales fijas en
 * LoginServlet ("admin@brenda.pe" / "admin123" / "EMP-0001") y la tabla
 * "administradores" no la usaba nadie. Ahora el login valida contra esta
 * tabla de verdad, con la contraseña hasheada con BCrypt.
 */
public class AdministradorDAO {

    /** Valida email + password + codigo de empleado. Devuelve el Administrador si todo coincide, o null. */
    public Administrador validarLogin(String email, String password, String codigoEmpleado) {
        String sql = "SELECT * FROM administradores WHERE email = ? AND codigo_empleado = ?";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, email);
            ps.setString(2, codigoEmpleado);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && PasswordUtil.verificar(password, rs.getString("password_hash"))) {
                    return mapear(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /** Busca un administrador por email (usado para saber quien esta en sesion, ej. al emitir un comprobante). */
    public Administrador buscarPorEmail(String email) {
        String sql = "SELECT * FROM administradores WHERE email = ?";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, email);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapear(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    private Administrador mapear(ResultSet rs) throws SQLException {
        Administrador a = new Administrador();
        a.setId(rs.getInt("id"));
        a.setNombre(rs.getString("nombre"));
        a.setEmail(rs.getString("email"));
        a.setCodigoEmpleado(rs.getString("codigo_empleado"));
        a.setFechaRegistro(rs.getTimestamp("fecha_registro"));
        return a;
    }
}
