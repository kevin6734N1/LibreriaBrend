package libreria.dao;

import libreria.models.Cliente;
import libreria.util.ConexionBD;
import libreria.util.PasswordUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ClienteDAO - Libreria Brenda
 * Acceso a datos para la tabla "clientes".
 * Usado por RegistroServlet (insertar), LoginServlet (validar) y
 * ClienteServlet (listar para clientes.jsp).
 */
public class ClienteDAO {

    /** Inserta un nuevo cliente. Retorna true si se registro correctamente. */
    public boolean registrar(Cliente c) {
        String sql = "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, c.getNombres());
            ps.setString(2, c.getApellidos());
            ps.setString(3, c.getDni());
            ps.setString(4, c.getEmail());
            ps.setString(5, c.getTelefono());
            ps.setString(6, c.getDireccion());
            // c.getPasswordHash() en este punto todavia trae la contraseña en texto
            // plano que puso RegistroServlet; se hashea aqui, justo antes de guardar.
            ps.setString(7, PasswordUtil.hash(c.getPasswordHash()));

            return ps.executeUpdate() == 1;

        } catch (SQLIntegrityConstraintViolationException dupe) {
            // DNI o email ya existen (columnas UNIQUE)
            System.err.println("Cliente duplicado: " + dupe.getMessage());
            return false;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Busca un cliente por email (sin validar password). Usado por PedidoServlet para asociar pedidos al cliente en sesion. */
    public Cliente buscarPorEmail(String email) {
        String sql = "SELECT * FROM clientes WHERE email = ?";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, email);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapearCliente(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /** Busca un cliente por email y password (para LoginServlet). La comparacion de password ya no es en SQL: se trae el hash y se verifica con BCrypt en Java. */
    public Cliente validarLogin(String email, String password) {
        String sql = "SELECT * FROM clientes WHERE email = ? AND activo = TRUE";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, email);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && PasswordUtil.verificar(password, rs.getString("password_hash"))) {
                    return mapearCliente(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /** Lista todos los clientes junto con su cantidad de pedidos y total gastado. */
    public List<Cliente> listarTodos() {
        List<Cliente> lista = new ArrayList<>();
        String sql = "SELECT * FROM vista_clientes_resumen ORDER BY fecha_registro DESC";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Cliente c = mapearCliente(rs);
                c.setTotalPedidos(rs.getInt("total_pedidos"));
                c.setTotalGastado(rs.getDouble("total_gastado"));
                lista.add(c);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return lista;
    }

    /** Cambia el estado activo/inactivo de un cliente. */
    public boolean cambiarEstado(int id, boolean activo) {
        String sql = "UPDATE clientes SET activo = ? WHERE id = ?";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setBoolean(1, activo);
            ps.setInt(2, id);
            return ps.executeUpdate() == 1;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Mapea una fila de ResultSet a un objeto Cliente. */
    private Cliente mapearCliente(ResultSet rs) throws SQLException {
        Cliente c = new Cliente();
        c.setId(rs.getInt("id"));
        c.setNombres(rs.getString("nombres"));
        c.setApellidos(rs.getString("apellidos"));
        c.setDni(rs.getString("dni"));
        c.setEmail(rs.getString("email"));
        c.setTelefono(rs.getString("telefono"));
        c.setDireccion(rs.getString("direccion"));
        c.setActivo(rs.getBoolean("activo"));
        c.setFechaRegistro(rs.getTimestamp("fecha_registro"));
        return c;
    }
}