package libreria.util;

import java.util.regex.Pattern;

/**
 * Valida el correo electronico que llega en el inicio de sesion y el registro.
 *
 * La regla no pretende cubrir todo el RFC 5322: filtra entradas que no pueden
 * existir en la columna `email` (varchar(120)) y formatos claramente invalidos
 * antes de consultar la base de datos. El limite de longitud es el de la
 * columna, para no enviar a MySQL valores que nunca podrian coincidir.
 */
public final class ValidadorEmail {

    /** Longitud maxima de `clientes.email` y `administradores.email`. */
    public static final int LONGITUD_MAXIMA = 120;

    private static final Pattern FORMATO = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

    private ValidadorEmail() {
        // clase utilitaria, no se instancia
    }

    /** true si el correo tiene formato valido y cabe en la columna de la BD. */
    public static boolean esValido(String email) {
        if (email == null) return false;

        String normalizado = email.trim();
        return !normalizado.isEmpty()
                && normalizado.length() <= LONGITUD_MAXIMA
                && FORMATO.matcher(normalizado).matches();
    }
}
