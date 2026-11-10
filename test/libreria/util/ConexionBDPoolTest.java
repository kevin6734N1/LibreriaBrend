package libreria.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * QA-S4-02: el pool de conexiones debe reutilizar las conexiones fisicas y
 * mantener acotado el numero de conexiones abiertas al motor.
 *
 * Antes, cada consulta abria y cerraba una conexion fisica; bajo carga
 * sostenida eso agotaba el rango de puertos efimeros del sistema y producia
 * CommunicationsException.
 */
class ConexionBDPoolTest {

    @Test
    @DisplayName("QA-S4-02: el pool no abre mas conexiones fisicas que su maximo")
    void poolAcotado() throws Exception {
        int antes = ConexionBD.conexionesAbiertas();

        ExecutorService pool = Executors.newFixedThreadPool(16);
        CountDownLatch listo = new CountDownLatch(16);
        CountDownLatch arranque = new CountDownLatch(1);
        AtomicInteger errores = new AtomicInteger();
        AtomicInteger consultas = new AtomicInteger();

        for (int i = 0; i < 16; i++) {
            pool.submit(() -> {
                listo.countDown();
                try {
                    arranque.await();
                    for (int j = 0; j < 10; j++) {
                        try (Connection con = ConexionBD.getConexion()) {
                            con.createStatement().execute("SELECT 1");
                            consultas.incrementAndGet();
                        }
                    }
                } catch (Exception e) {
                    errores.incrementAndGet();
                }
            });
        }

        assertTrue(listo.await(10, TimeUnit.SECONDS), "Los hilos no arrancaron");
        arranque.countDown();
        pool.shutdown();
        assertTrue(pool.awaitTermination(60, TimeUnit.SECONDS), "El pool de hilos no termino");

        assertEquals(0, errores.get(), "Hubo errores al usar el pool de conexiones");
        assertEquals(160, consultas.get(), "No se ejecutaron todas las consultas");

        int abiertas = ConexionBD.conexionesAbiertas();
        assertTrue(abiertas <= 60,
                "El pool abrio mas conexiones fisicas que su maximo: " + abiertas);
        assertTrue(abiertas >= antes, "El contador de conexiones del pool se decremento");
    }

    @Test
    @DisplayName("QA-S4-02: cerrar() devuelve la conexion al pool en vez de destruirla")
    void cerrarDevuelveAlPool() throws Exception {
        Connection primera = ConexionBD.getConexion();
        int abiertasTrasObtener = ConexionBD.conexionesAbiertas();

        ConexionBD.cerrar(primera);

        assertEquals(abiertasTrasObtener, ConexionBD.conexionesAbiertas(),
                "cerrar() no debe decrementar el contador: la conexion vuelve al pool");
        assertTrue(ConexionBD.conexionesDisponibles() > 0,
                "La conexion devuelta no quedo disponible en el pool");
    }

    @Test
    @DisplayName("QA-S4-02: la conexion devuelta al pool es utilizable de nuevo")
    void conexionDevueltaSirve() throws Exception {
        Connection con = ConexionBD.getConexion();
        con.createStatement().execute("SELECT 1");
        ConexionBD.cerrar(con);

        Connection reutilizada = ConexionBD.getConexion();
        try {
            reutilizada.createStatement().execute("SELECT 1");
        } finally {
            ConexionBD.cerrar(reutilizada);
        }
    }

    @Test
    @DisplayName("QA-S4-02: el autoCommit queda activo al devolver la conexion al pool")
    void autoCommitRestablecido() throws Exception {
        Connection con = ConexionBD.getConexion();
        con.setAutoCommit(false);
        ConexionBD.cerrar(con);

        Connection siguiente = ConexionBD.getConexion();
        try {
            assertTrue(siguiente.getAutoCommit(),
                    "La conexion devuelta al pool debe quedar con autoCommit activo");
        } finally {
            ConexionBD.cerrar(siguiente);
        }
    }
}
