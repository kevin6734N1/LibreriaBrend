package libreria.dao;

import libreria.util.ConexionBD;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * Guarda de seguridad para las pruebas que necesitan MySQL/MariaDB.
 *
 * - Si DB_NAME no apunta a `libreria_brenda_test`, los tests se omiten.
 * - Si la base no responde, tambien se omiten (no se simula un resultado).
 * - Si la conexion llega a otra base, se aborta antes de ejecutar consultas.
 *
 * Esto permite que la suite unitaria corra sin motor de base de datos y que
 * las pruebas de integracion solo se ejecuten contra la base ficticia.
 */
final class BaseDatosPruebas {

    static final String NOMBRE_ESPERADO = "libreria_brenda_test";

    private BaseDatosPruebas() {
    }

    static void asumirDisponible() {
        String configurado = System.getProperty("DB_NAME");
        if (configurado == null || configurado.isBlank()) {
            configurado = System.getenv("DB_NAME");
        }

        assumeTrue(NOMBRE_ESPERADO.equals(configurado),
                "DB_NAME debe ser " + NOMBRE_ESPERADO + "; se omite la prueba de DAO");

        String baseActual;
        try (Connection con = ConexionBD.getConexion();
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT DATABASE()")) {
            rs.next();
            baseActual = rs.getString(1);
        } catch (SQLException e) {
            assumeTrue(false, "Base de pruebas no disponible: " + e.getMessage());
            return;
        }

        assumeTrue(NOMBRE_ESPERADO.equals(baseActual),
                "La conexion apunta a " + baseActual + ", no a " + NOMBRE_ESPERADO);
    }
}
