package libreria.util;

import java.util.concurrent.ConcurrentHashMap;

/**
 * ControlIntentosLogin - Libreria Brenda
 *
 * Protección básica contra fuerza bruta en el login. Antes el sistema no
 * limitaba en absoluto los intentos fallidos de inicio de sesión (se podía
 * probar contraseñas indefinidamente sin ninguna penalización).
 *
 * Guarda el conteo de intentos fallidos por email en memoria (no en BD):
 * es suficiente para un solo servidor Tomcat como el de este proyecto, y
 * evita una tabla nueva para algo que es, por naturaleza, temporal. Se
 * resetea si el servidor se reinicia — aceptable para este alcance.
 *
 * Se bloquea por EMAIL, no de forma global: así un atacante probando
 * contraseñas contra una cuenta no termina bloqueando también a todos los
 * demás usuarios (eso sería un problema de disponibilidad en sí mismo).
 */
public class ControlIntentosLogin {

    private static final int MAX_INTENTOS = 5;
    private static final long BLOQUEO_MS = 2 * 60 * 1000L; // 2 minutos

    private static class Registro {
        int intentosFallidos = 0;
        long bloqueadoHasta = 0L;
    }

    private static final ConcurrentHashMap<String, Registro> intentos = new ConcurrentHashMap<>();

    private ControlIntentosLogin() {
        // clase utilitaria, no se instancia
    }

    private static String normalizar(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }

    /** true si este email está temporalmente bloqueado por demasiados intentos fallidos. */
    public static boolean estaBloqueado(String email) {
        Registro r = intentos.get(normalizar(email));
        if (r == null) return false;
        if (r.bloqueadoHasta == 0L) return false;
        if (System.currentTimeMillis() >= r.bloqueadoHasta) {
            // el bloqueo ya expiró: se limpia para no arrastrar estado viejo
            intentos.remove(normalizar(email));
            return false;
        }
        return true;
    }

    /** Minutos (redondeados hacia arriba) que faltan para que se levante el bloqueo. */
    public static long minutosRestantes(String email) {
        Registro r = intentos.get(normalizar(email));
        if (r == null || r.bloqueadoHasta == 0L) return 0;
        long restanteMs = r.bloqueadoHasta - System.currentTimeMillis();
        return Math.max(1, (restanteMs + 59_999) / 60_000);
    }

    /** Registra un intento fallido; si llega al máximo, activa el bloqueo temporal. */
    public static void registrarFallo(String email) {
        String key = normalizar(email);
        Registro r = intentos.computeIfAbsent(key, k -> new Registro());
        synchronized (r) {
            r.intentosFallidos++;
            if (r.intentosFallidos >= MAX_INTENTOS) {
                r.bloqueadoHasta = System.currentTimeMillis() + BLOQUEO_MS;
            }
        }
    }

    /** Login exitoso: se limpia cualquier historial de intentos fallidos previos. */
    public static void registrarExito(String email) {
        intentos.remove(normalizar(email));
    }
}
