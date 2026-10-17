package libreria.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * ConexionBD - Libreria Brenda
 * Clase utilitaria centralizada para obtener conexiones JDBC.
 *
 * La configuracion NO vive en el codigo: se lee de variables de entorno o de
 * propiedades del sistema, en este orden de prioridad:
 *
 *   DB_URL       URL JDBC completa (si se define, ignora HOST/PORT/BD)
 *   DB_HOST      host del motor (por defecto localhost)
 *   DB_PORT      puerto (por defecto 3306)
 *   DB_NAME      nombre de la base de datos (por defecto libreria_brenda)
 *   DB_USER      usuario (por defecto root)
 *   DB_PASSWORD  contrasena (por defecto vacia)
 *
 * Ejemplo para una base de pruebas en Linux/macOS:
 *   export DB_NAME=libreria_brenda_test DB_PASSWORD=mi_clave
 *   catalina.sh run
 *
 * En Windows (PowerShell):
 *   $env:DB_NAME="libreria_brenda_test"; $env:DB_PASSWORD="mi_clave"
 *
 * USO en un servlet o DAO:
 *     Connection con = ConexionBD.getConexion();
 *     ... hacer queries ...
 *     ConexionBD.cerrar(con);
 */
public class ConexionBD {

    private static final String HOST     = config("DB_HOST", "localhost");
    private static final String PUERTO   = config("DB_PORT", "3306");
    private static final String BD       = config("DB_NAME", "libreria_brenda");
    private static final String USUARIO  = config("DB_USER", "root");
    private static final String PASSWORD = config("DB_PASSWORD", "");

    private static final String URL = config("DB_URL",
        "jdbc:mysql://" + HOST + ":" + PUERTO + "/" + BD +
        "?useSSL=false&serverTimezone=America/Lima&allowPublicKeyRetrieval=true");

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

    /** Lee una propiedad del sistema y, si no existe, una variable de entorno. */
    private static String config(String clave, String porDefecto) {
        String valor = System.getProperty(clave);
        if (valor == null || valor.isEmpty()) valor = System.getenv(clave);
        return (valor == null || valor.isEmpty()) ? porDefecto : valor;
    }

    /**
     * Obtiene una nueva conexion activa a la base de datos.
     * @return Connection lista para usar
     * @throws SQLException si el motor no esta corriendo o las
     *         credenciales configuradas son incorrectas
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
     * conexion funciona antes de integrar con los servlets. No imprime la
     * contrasena.
     */
    public static void main(String[] args) {
        System.out.println("Conectando a " + URL + " como " + USUARIO);
        try (Connection con = getConexion()) {
            System.out.println("Conexion exitosa a la base de datos: " + BD);
        } catch (SQLException e) {
            System.out.println("ERROR al conectar con la base de datos:");
            e.printStackTrace();
        }
    }
}
