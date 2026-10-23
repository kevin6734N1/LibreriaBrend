package libreria.dao;

import libreria.models.PedidoResumen;
import libreria.util.ConexionBD;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Historial que consume el modal de clientes.jsp.
 *
 * Requiere DB_NAME=libreria_brenda_test y los fixtures cargados. Crea dos
 * clientes y tres pedidos temporales, verifica el filtro por cliente y el
 * orden descendente, y elimina todo al terminar.
 */
class ClienteDAOPedidosTest {

    private final ClienteDAO dao = new ClienteDAO();

    @BeforeAll
    static void verificarBaseDePruebas() {
        BaseDatosPruebas.asumirDisponible();
    }

    @Test
    void listarPedidosRecientes_filtraPorClienteYOrdenaPorFechaDescendente() throws SQLException {
        String sufijo = String.valueOf(System.currentTimeMillis());
        String idAntiguo = "PED-MODAL-" + sufijo + "-1";
        String idReciente = "PED-MODAL-" + sufijo + "-2";
        String idOtroCliente = "PED-MODAL-" + sufijo + "-3";
        int clienteA = -1;
        int clienteB = -1;

        try (Connection con = ConexionBD.getConexion()) {
            clienteA = insertarCliente(con, "7" + ultimosSiete(sufijo), "modal." + sufijo + ".a@test.local");
            clienteB = insertarCliente(con, "6" + ultimosSiete(sufijo), "modal." + sufijo + ".b@test.local");

            insertarPedido(con, idAntiguo, clienteA, "2026-01-10 10:00:00", 10.00, "PENDIENTE");
            insertarPedido(con, idReciente, clienteA, "2026-02-10 10:00:00", 25.50, "ENTREGADO");
            insertarPedido(con, idOtroCliente, clienteB, "2026-03-10 10:00:00", 99.00, "CANCELADO");

            List<PedidoResumen> unPedido = dao.listarPedidosRecientes(clienteA, 1);
            assertEquals(1, unPedido.size());
            assertEquals(idReciente, unPedido.get(0).getId());
            assertEquals(25.50, unPedido.get(0).getTotal(), 0.001);
            assertEquals("ENTREGADO", unPedido.get(0).getEstado());

            List<PedidoResumen> historial = dao.listarPedidosRecientes(clienteA, 10);
            assertEquals(2, historial.size());
            assertEquals(idReciente, historial.get(0).getId());
            assertEquals(idAntiguo, historial.get(1).getId());
        } finally {
            limpiar(clienteA, clienteB);
        }
    }

    private int insertarCliente(Connection con, String dni, String email) throws SQLException {
        String sql = "INSERT INTO clientes (nombres, apellidos, dni, email, telefono, direccion, password_hash, activo) " +
                     "VALUES ('Cliente', 'Modal Temporal', ?, ?, '900000999', 'Av. Prueba 1, Lima', " +
                     "'$2a$10$Svoeojut3iUXPxxUHN2Dm.YojMY7P6mYd.QaCGHrcpppsFSopIc9S', 1)";
        try (PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, dni);
            ps.setString(2, email);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private void insertarPedido(Connection con, String id, int clienteId, String fecha,
                                double total, String estado) throws SQLException {
        String sql = "INSERT INTO pedidos (id, cliente_id, fecha, estado, subtotal, descuento, envio, total, " +
                     "direccion_entrega, metodo_pago) VALUES (?, ?, ?, ?, ?, 0, 0, ?, 'Av. Prueba 1, Lima', 'Yape')";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.setInt(2, clienteId);
            ps.setTimestamp(3, Timestamp.valueOf(fecha));
            ps.setString(4, estado);
            ps.setDouble(5, total);
            ps.setDouble(6, total);
            ps.executeUpdate();
        }
    }

    private void limpiar(int... ids) {
        try (Connection con = ConexionBD.getConexion()) {
            try (PreparedStatement pedidos = con.prepareStatement(
                    "DELETE FROM pedidos WHERE cliente_id = ?")) {
                for (int id : ids) {
                    if (id <= 0) continue;
                    pedidos.setInt(1, id);
                    pedidos.executeUpdate();
                }
            }
            try (PreparedStatement clientes = con.prepareStatement(
                    "DELETE FROM clientes WHERE id = ?")) {
                for (int id : ids) {
                    if (id <= 0) continue;
                    clientes.setInt(1, id);
                    clientes.executeUpdate();
                }
            }
        } catch (SQLException ignored) {
            // La limpieza no debe ocultar el resultado del test.
        }
    }

    private String ultimosSiete(String valor) {
        return valor.substring(Math.max(0, valor.length() - 7));
    }
}
