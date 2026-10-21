package libreria.util;

import org.mindrot.jbcrypt.BCrypt;

import java.util.regex.Pattern;

/**
 * PasswordUtil - Libreria Brenda
 *
 * Punto unico para todo lo relacionado a contraseñas. Antes se guardaban y
 * comparaban en texto plano directamente contra la columna password_hash
 * (a pesar del nombre). Ahora esa columna sí contiene un hash real de
 * BCrypt (via jBCrypt, jbcrypt-0.4.jar en WEB-INF/lib).
 *
 * BCrypt ya incluye el salt dentro del propio hash generado, por eso no
 * hace falta guardar una columna de salt aparte.
 */
public class PasswordUtil {

    private static final int COSTO = 10; // factor de trabajo de BCrypt (10-12 es razonable para un proyecto academico)

    /** Formato completo que produce jBCrypt 0.4: $2a$ + costo + 53 caracteres. */
    private static final Pattern HASH_BCRYPT = Pattern.compile("^\\$2a\\$\\d{2}\\$[./A-Za-z0-9]{53}$");

    private PasswordUtil() {
        // clase utilitaria, no se instancia
    }

    /** Genera el hash BCrypt de una contraseña en texto plano, listo para guardar en la BD. */
    public static String hash(String passwordPlano) {
        return BCrypt.hashpw(passwordPlano, BCrypt.gensalt(COSTO));
    }

    /**
     * Verifica que una contraseña en texto plano corresponda al hash guardado.
     * Si el hash guardado no tiene formato BCrypt valido (ej. datos viejos en
     * texto plano que no se migraron) devuelve false en vez de lanzar excepcion.
     */
    public static boolean verificar(String passwordPlano, String hashGuardado) {
        if (passwordPlano == null || hashGuardado == null || hashGuardado.isEmpty()) {
            return false;
        }
        if (!HASH_BCRYPT.matcher(hashGuardado).matches()) {
            // Texto plano antiguo o hash truncado: se rechaza sin llamar a jBCrypt,
            // que con un hash incompleto lanza StringIndexOutOfBoundsException.
            return false;
        }
        try {
            return BCrypt.checkpw(passwordPlano, hashGuardado);
        } catch (IllegalArgumentException formatoInvalido) {
            return false;
        }
    }
}
