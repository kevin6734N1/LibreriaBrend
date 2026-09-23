package libreria.util;

import org.mindrot.jbcrypt.BCrypt;

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
        try {
            return BCrypt.checkpw(passwordPlano, hashGuardado);
        } catch (IllegalArgumentException formatoInvalido) {
            // El valor guardado no es un hash BCrypt (ej. cuenta antigua no migrada)
            return false;
        }
    }
}
