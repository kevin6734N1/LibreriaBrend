package libreria.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * ConexionBD - Libreria Brenda
 * Clase utilitaria centralizada para obtener conexiones JDBC a MySQL (XAMPP).
 *
 * REQUISITOS:
 *  1. XAMPP corriendo con Apache + MySQL activos.
 *  2. Haber ejecutado el script database/libreria_brenda.sql en phpMyAdmin.
 *  3. Descargar el conector MySQL JDBC (mysql-connector-j-8.x.x.jar) y
 *     colocarlo en WebContent/WEB-INF/lib/  (o en el Build Path del proyecto).
 *     Descarga: https://dev.mysql.com/downloads/connector/j/
 *
 * USO en un servlet o DAO:
 *     Connection con = ConexionBD.getConexion();
 *     ... hacer queries ...
 *     ConexionBD.cerrar(con);
 */
public class ConexionBD {

    // ---- Datos de conexion (ajustar si tu XAMPP usa otro puerto o clave) ----
    private static final String HOST     = "localhost";
    private static final String PUERTO   = "3306";
    private static final String BD       = "libreria_brenda";
    private static final String USUARIO  = "root";
    private static final String PASSWORD = "root";   // XAMPP por defecto no tiene clave

    private static final String URL =
        "jdbc:mysql://" + HOST + ":" + PUERTO + "/" + BD +
        "?useSSL=false&serverTimezone=America/Lima&allowPublicKeyRetrieval=true";

    private static final String DRIVER = "com.mysql.cj.jdbc.Driver";

    // Bloque estatico: carga el driver una sola vez al iniciar la aplicacion
    static {
        try {
            Class.forName(DRIVER);
        } catch (ClassNotFoundException e) {
            System.err.println("ERROR: No se encontro el driver JDBC de MySQL.");
            System.err.println("Verifica que mysql-connector-j-x.x.x.jar este en WEB-INF/lib");
            e.printStackTrace();
        }
    }

    private ConexionBD() {
        // Clase utilitaria, no se instancia
    }

    /**
     * Obtiene una nueva conexion activa a la base de datos.
     * @return Connection lista para usar
     * @throws SQLException si XAMPP/MySQL no esta corriendo o las
     *         credenciales son incorrectas
     */
    public static Connection getConexion() throws SQLException {
        return DriverManager.getConnection(URL, USUARIO, PASSWORD);
    }

    /**
     * Cierra la conexion de forma segura, ignorando errores si ya estaba cerrada.
     */
    public static void cerrar(Connection con) {
        if (con != null) {
            try {
                con.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * Metodo de prueba rapida: ejecutar este main para verificar que la
     * conexion a MySQL funciona antes de integrar con los servlets.
     */
    public static void main(String[] args) {
        try (Connection con = getConexion()) {
            System.out.println("Conexion exitosa a la base de datos: " + BD);
        } catch (SQLException e) {
            System.out.println("ERROR al conectar con la base de datos:");
            e.printStackTrace();
        }
    }
}