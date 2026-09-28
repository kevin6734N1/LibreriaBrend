package libreria.dao;

import libreria.models.Producto;
import libreria.util.ConexionBD;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProductoDAO {

    public List<Producto> listarTodos() {

        List<Producto> lista = new ArrayList<>();

        String sql =
            "SELECT p.*, c.nombre AS categoria " +
            "FROM productos p " +
            "INNER JOIN categorias c ON p.categoria_id = c.id " +
            "ORDER BY p.id DESC";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Producto p = new Producto();

                p.setId(rs.getInt("id"));
                p.setNombre(rs.getString("nombre"));
                p.setDescripcion(rs.getString("descripcion"));
                p.setPrecio(rs.getDouble("precio"));
                p.setStock(rs.getInt("stock"));
                p.setCategoria(rs.getString("categoria"));
                p.setImagen(rs.getString("imagen"));
                p.setActivo(rs.getBoolean("activo"));

                lista.add(p);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return lista;
    }

    /** Busca el id de una categoria por nombre para los INSERT/UPDATE. */
    private int obtenerCategoriaId(Connection con, String nombreCategoria) throws SQLException {
        String sql = "SELECT id FROM categorias WHERE nombre = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, nombreCategoria);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("id");
            }
        }
        return 1; // fallback a primera categoria si no encuentra
    }

    /** Inserta un producto nuevo. Devuelve el id generado o -1 si falla. */
    public int crear(Producto p) {
        String sql = "INSERT INTO productos (nombre, descripcion, precio, stock, categoria_id, imagen, etiqueta, activo) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)";
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, p.getNombre());
            ps.setString(2, p.getDescripcion());
            ps.setDouble(3, p.getPrecio());
            ps.setInt(4, p.getStock());
            ps.setInt(5, obtenerCategoriaId(con, p.getCategoria()));
            ps.setString(6, p.getImagen());
            ps.setString(7, p.getEtiqueta() != null && !p.getEtiqueta().isEmpty() ? p.getEtiqueta() : null);

            ps.executeUpdate();

            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return -1;
    }

    /** Actualiza un producto existente. Devuelve true si se modifico. */
    public boolean editar(Producto p) {
        String sql = "UPDATE productos SET nombre=?, descripcion=?, precio=?, stock=?, " +
                     "categoria_id=?, imagen=?, etiqueta=? WHERE id=?";
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, p.getNombre());
            ps.setString(2, p.getDescripcion());
            ps.setDouble(3, p.getPrecio());
            ps.setInt(4, p.getStock());
            ps.setInt(5, obtenerCategoriaId(con, p.getCategoria()));
            ps.setString(6, p.getImagen());
            ps.setString(7, p.getEtiqueta() != null && !p.getEtiqueta().isEmpty() ? p.getEtiqueta() : null);
            ps.setInt(8, p.getId());

            return ps.executeUpdate() == 1;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Cambia el campo activo de un producto. Devuelve true si se modifico. */
    public boolean toggleActivo(int id) {
        String sql = "UPDATE productos SET activo = NOT activo WHERE id = ?";
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);
            return ps.executeUpdate() == 1;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Elimina un producto por id. Devuelve true si se elimino. */
    public boolean eliminar(int id) {
        String sql = "DELETE FROM productos WHERE id = ?";
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);
            return ps.executeUpdate() == 1;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public Producto buscarPorId(int id) {
        String sql = "SELECT p.*, c.nombre AS categoria FROM productos p " +
                     "INNER JOIN categorias c ON p.categoria_id = c.id WHERE p.id = ?";
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Producto p = new Producto();
                    p.setId(rs.getInt("id"));
                    p.setNombre(rs.getString("nombre"));
                    p.setDescripcion(rs.getString("descripcion"));
                    p.setPrecio(rs.getDouble("precio"));
                    p.setStock(rs.getInt("stock"));
                    p.setCategoria(rs.getString("categoria"));
                    p.setImagen(rs.getString("imagen"));
                    p.setActivo(rs.getBoolean("activo"));
                    return p;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean descontarStock(int productoId, int cantidad) {
        String sql = "UPDATE productos SET stock = stock - ? WHERE id = ? AND stock >= ?";
        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, cantidad);
            ps.setInt(2, productoId);
            ps.setInt(3, cantidad);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Igual que descontarStock(productoId, cantidad), pero participa de una
     * transaccion externa ya abierta (no abre ni cierra la conexion). La usa
     * PedidoDAO.crear() para que "crear pedido" y "descontar stock" sean una
     * sola operacion atomica: si no hay stock, no se crea el pedido.
     */
    public boolean descontarStock(Connection con, int productoId, int cantidad) throws SQLException {
        String sql = "UPDATE productos SET stock = stock - ? WHERE id = ? AND stock >= ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, cantidad);
            ps.setInt(2, productoId);
            ps.setInt(3, cantidad);
            return ps.executeUpdate() == 1;
        }
    }

    /** Precio real del producto en la BD (null si el producto no existe). Usado por PedidoServlet para no confiar en los precios que mande el navegador. */
    public Double obtenerPrecio(Connection con, int productoId) throws SQLException {
        String sql = "SELECT precio FROM productos WHERE id = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, productoId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? (Double) rs.getDouble("precio") : null;
            }
        }
    }

    /** Nombre del producto, usado para armar un mensaje de error legible cuando falta stock. */
    public String obtenerNombre(Connection con, int productoId) throws SQLException {
        String sql = "SELECT nombre FROM productos WHERE id = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, productoId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString("nombre") : ("producto #" + productoId);
            }
        }
    }
}