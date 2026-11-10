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
 *
 * POOL DE CONEXIONES (QA-S4-02)
 * ------------------------------
 * Antes, cada llamada a getConexion() abria una conexion fisica nueva al
 * motor y cerrar(con) la destruia. Bajo carga sostenida eso agotaba el rango
 * de puertos efimeros del sistema operativo (decenas de miles de sockets en
 * TIME_WAIT) y producia CommunicationsException, dejando el sistema sin
 * capacidad de atender solicitudes.
 *
 * Ahora las conexiones fisicas se prestan de un pool con un maximo acotado
 * (DB_POOL_MAX, por defecto 20). La API publica NO cambia: getConexion()
 * sigue devolviendo una Connection utilizable y cerrar(con) la devuelve al
 * pool en lugar de cerrarla. El uso con try-with-resources ya presente en los
 * DAOs tambien funciona: el proxy devuelve la conexion al pool al cerrarse.
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

    /**
     * Tamano maximo del pool de conexiones fisicas (DB_POOL_MAX).
     *
     * QA-S4-02: 20 conexiones resultaban insuficientes para la carga mixta de
     * 45 usuarios concurrentes (30 clientes + 15 administradores): las peticiones
     * aguardaban hasta 10 s por una conexion y la latencia maxima llegaba a
     * 49 s. Con 60 conexiones, por debajo del max_connections del motor (151),
     * la latencia se mantiene estable y se reserva margen para las conexiones
     * de administracion y de la propia suite de pruebas.
     */
    private static final int POOL_MAX = Integer.parseInt(config("DB_POOL_MAX", "60"));

    /**
     * Tiempo maximo de espera para obtener una conexion del pool, en ms.
     *
     * QA-S4-02: se amplia a 20 s para que una rafaga de concurrencia no se
     * traduzca en errores de negocio, sino en una espera acotada y medible.
     */
    private static final long POOL_ESPERA_MS = Long.parseLong(config("DB_POOL_TIMEOUT_MS", "20000"));

    /** Conexiones fisicas disponibles para reutilizacion. */
    private static final java.util.concurrent.ConcurrentLinkedQueue<Connection> POOL =
            new java.util.concurrent.ConcurrentLinkedQueue<>();

    /** Numero de conexiones fisicas abiertas actualmente por el pool. */
    private static final java.util.concurrent.atomic.AtomicInteger POOL_ABIERTAS =
            new java.util.concurrent.atomic.AtomicInteger(0);

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
     * Obtiene una conexion lista para usar.
     *
     * QA-S4-02: la conexion fisica se toma del pool si hay alguna disponible;
     * si no, se abre una nueva mientras el pool no haya alcanzado su maximo.
     * Si se alcanza el maximo, se espera hasta DB_POOL_TIMEOUT_MS a que se
     * devuelva alguna conexion.
     *
     * @return Connection lista para usar
     * @throws SQLException si el motor no esta corriendo o las
     *         credenciales configuradas son incorrectas
     */
    public static Connection getConexion() throws SQLException {
        long limite = System.currentTimeMillis() + POOL_ESPERA_MS;

        while (true) {
            Connection prestada = POOL.poll();
            if (prestada != null) {
                if (prestada.isClosed()) {
                    POOL_ABIERTAS.decrementAndGet();
                    continue;
                }
                try {
                    if (!prestada.getAutoCommit()) {
                        prestada.rollback();
                        prestada.setAutoCommit(true);
                    }
                    return envolver(prestada);
                } catch (SQLException invalida) {
                    POOL_ABIERTAS.decrementAndGet();
                    try { prestada.close(); } catch (SQLException ignorada) { }
                    continue;
                }
            }

            if (POOL_ABIERTAS.get() < POOL_MAX) {
                POOL_ABIERTAS.incrementAndGet();
                try {
                    Connection nueva = DriverManager.getConnection(URL, USUARIO, PASSWORD);
                    nueva.setAutoCommit(true);
                    return envolver(nueva);
                } catch (SQLException fallo) {
                    POOL_ABIERTAS.decrementAndGet();
                    throw fallo;
                }
            }

            if (System.currentTimeMillis() >= limite) {
                throw new SQLException(
                    "No se obtuvo una conexion del pool en " + POOL_ESPERA_MS
                    + " ms (maximo " + POOL_MAX + " conexiones abiertas).");
            }
            try {
                Thread.sleep(25);
            } catch (InterruptedException interrumpido) {
                Thread.currentThread().interrupt();
                throw new SQLException("Espera interrumpida al pedir una conexion del pool.", interrumpido);
            }
        }
    }

    /**
     * Envuelve la conexion fisica en un proxy cuyo close() la devuelve al pool.
     *
     * QA-S4-02: los DAO usan try-with-resources, que invoca close() sobre la
     * conexion. Sin este proxy, close() cerraria la conexion fisica y el pool
     * no serviria de nada. Con el proxy, close() devuelve la conexion al pool
     * y el uso con try-with-resources y el uso con ConexionBD.cerrar() se
     * comportan igual.
     */
    private static Connection envolver(Connection fisica) {
        return (Connection) java.lang.reflect.Proxy.newProxyInstance(
                ConexionBD.class.getClassLoader(),
                new Class<?>[]{Connection.class},
                new ManejadorPool(fisica));
    }

    /** Intercepta close() para devolver la conexion fisica al pool. */
    private static final class ManejadorPool implements java.lang.reflect.InvocationHandler {
        private final Connection fisica;
        /** Evita devolver la misma conexion al pool dos veces. */
        private boolean devuelta;

        ManejadorPool(Connection fisica) {
            this.fisica = fisica;
        }

        @Override
        public Object invoke(Object proxy, java.lang.reflect.Method metodo, Object[] args) throws Throwable {
            String nombre = metodo.getName();
            if ("close".equals(nombre)) {
                synchronized (this) {
                    if (!devuelta) {
                        devuelta = true;
                        devolverAlPool(fisica);
                    }
                }
                return null;
            }
            if ("isWrapperFor".equals(nombre) && args != null && args.length == 1) {
                return Boolean.valueOf(args[0] == Connection.class);
            }
            if ("unwrap".equals(nombre) && args != null && args.length == 1) {
                if (args[0] == Connection.class) return fisica;
                if (args[0] == proxy.getClass()) return proxy;
            }
            if ("hashCode".equals(nombre)) return Integer.valueOf(System.identityHashCode(proxy));
            if ("equals".equals(nombre)) return Boolean.valueOf(proxy == args[0]);
            if ("toString".equals(nombre)) return "ConexionPool[" + fisica + "]";
            try {
                return metodo.invoke(fisica, args);
            } catch (java.lang.reflect.InvocationTargetException e) {
                throw e.getCause();
            }
        }
    }

    /** Devuelve una conexion fisica al pool; la destruye si el pool esta lleno. */
    private static void devolverAlPool(Connection fisica) {
        try {
            if (fisica.isClosed()) {
                POOL_ABIERTAS.decrementAndGet();
                return;
            }
            if (!fisica.getAutoCommit()) {
                fisica.rollback();
                fisica.setAutoCommit(true);
            }
            if (POOL_ABIERTAS.get() <= POOL_MAX && POOL.offer(fisica)) {
                return;
            }
            fisica.close();
            POOL_ABIERTAS.decrementAndGet();
        } catch (SQLException e) {
            POOL_ABIERTAS.decrementAndGet();
            try { fisica.close(); } catch (SQLException ex) { ex.printStackTrace(); }
        }
    }

    /**
     * Devuelve la conexion al pool en lugar de cerrar la conexion fisica.
     *
     * QA-S4-02: nombre y firma intactos para no romper los DAO existentes.
     */
    public static void cerrar(Connection con) {
        if (con == null) return;
        if (con instanceof java.lang.reflect.Proxy) {
            // El proxy ya sabe devolver la conexion fisica al pool.
            try {
                con.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return;
        }
        devolverAlPool(con);
    }

    /** Numero de conexiones fisicas abiertas actualmente por el pool (diagnostico). */
    public static int conexionesAbiertas() {
        return POOL_ABIERTAS.get();
    }

    /** Numero de conexiones disponibles en el pool (diagnostico). */
    public static int conexionesDisponibles() {
        return POOL.size();
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
