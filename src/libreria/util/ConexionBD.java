package libreria.util;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.net.URL;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * ConexionBD - Libreria Brenda
 * Clase utilitaria centralizada para obtener conexiones JDBC.
 *
 * La configuracion NO vive en el codigo. Se resuelve, por orden de prioridad:
 *
 *   1. Propiedad del sistema de la JVM (-DDB_NAME=...).
 *   2. Variable de entorno (export DB_NAME=...).
 *   3. Archivo WEB-INF/db.properties (o el indicado en DB_CONFIG).
 *   4. Valor por defecto.
 *
 * Claves: DB_URL, DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD.
 *   DB_URL       URL JDBC completa (si se define, ignora HOST/PORT/BD)
 *   DB_HOST      host del motor (por defecto localhost)
 *   DB_PORT      puerto (por defecto 3306)
 *   DB_NAME      nombre de la base de datos (por defecto libreria_brenda)
 *   DB_USER      usuario (por defecto root)
 *   DB_PASSWORD  contrasena (por defecto vacia)
 *
 * El archivo permite arrancar desde el IDE (VS Code, Eclipse) sin configurar
 * variables de entorno en el servidor. NO se versiona: copia
 * db.properties.example a db.properties y ajusta tus credenciales locales.
 * DB_CONFIG puede apuntar a otra ruta absoluta si prefieres tenerlo fuera
 * del proyecto.
 *
 * USO en un servlet o DAO:
 *     Connection con = ConexionBD.getConexion();
 *     ... hacer queries ...
 *     ConexionBD.cerrar(con);
 */
public class ConexionBD {

    /** Nombre del archivo de configuracion local dentro del classpath. */
    private static final String ARCHIVO_POR_DEFECTO = "db.properties";

    /** Configuracion leida del archivo local (vacia si no existe). */
    private static final Properties ARCHIVO = cargarArchivo();

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

    /**
     * Lee db.properties del classpath (WEB-INF/classes) o la ruta indicada en
     * DB_CONFIG. Si no existe, devuelve una configuracion vacia: la aplicacion
     * sigue funcionando con variables de entorno o con los valores por defecto.
     */
    private static Properties cargarArchivo() {
        Properties props = new Properties();
        String ruta = System.getProperty("DB_CONFIG");
        if (ruta == null || ruta.isBlank()) ruta = System.getenv("DB_CONFIG");

        try {
            InputStream entrada;
            if (ruta != null && !ruta.isBlank()) {
                Path archivo = Paths.get(ruta);
                if (!Files.isReadable(archivo)) {
                    System.err.println("AVISO: DB_CONFIG no es legible: " + ruta);
                    return props;
                }
                entrada = Files.newInputStream(archivo);
            } else {
                entrada = abrirArchivoPorDefecto();
            }

            if (entrada != null) {
                try (Reader lector = new InputStreamReader(entrada, StandardCharsets.UTF_8)) {
                    props.load(lector);
                }
            }
        } catch (IOException e) {
            System.err.println("AVISO: no se pudo leer la configuracion de base de datos: " + e.getMessage());
        }
        return props;
    }

    /**
     * Busca db.properties primero en el classpath (WEB-INF/classes) y luego
     * junto a las clases desplegadas (WEB-INF/db.properties), que es donde
     * queda al copiarse WebContent en un contexto explotado.
     */
    private static InputStream abrirArchivoPorDefecto() throws IOException {
        InputStream enClasspath = ConexionBD.class.getClassLoader()
                .getResourceAsStream(ARCHIVO_POR_DEFECTO);
        if (enClasspath != null) return enClasspath;

        try {
            URL ubicacion = ConexionBD.class.getProtectionDomain().getCodeSource().getLocation();
            if (ubicacion != null && "file".equals(ubicacion.getProtocol())) {
                Path clases = Paths.get(ubicacion.toURI());            // .../WEB-INF/classes/
                Path webInf = clases.getParent();                       // .../WEB-INF/
                if (webInf != null) {
                    Path archivo = webInf.resolve(ARCHIVO_POR_DEFECTO);
                    if (Files.isReadable(archivo)) return Files.newInputStream(archivo);
                }
            }
        } catch (Exception sinArchivo) {
            // Contexto empaquetado en WAR o classpath sin carpeta: se usan
            // variables de entorno o los valores por defecto.
        }
        return null;
    }

    /** Propiedad del sistema > variable de entorno > db.properties > valor por defecto. */
    private static String config(String clave, String porDefecto) {
        String valor = System.getProperty(clave);
        if (valor == null || valor.isEmpty()) valor = System.getenv(clave);
        if (valor == null || valor.isEmpty()) valor = ARCHIVO.getProperty(clave);
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
