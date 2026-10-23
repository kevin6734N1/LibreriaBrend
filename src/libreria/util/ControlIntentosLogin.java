package libreria.util;

import java.util.concurrent.ConcurrentHashMap;
import java.util.function.LongSupplier;

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

    /**
     * Reloj del sistema, inyectable SOLO desde las pruebas del mismo paquete
     * para poder comprobar la expiracion (120 s) sin esperar 2 minutos reales.
     * En produccion siempre es System::currentTimeMillis: conducta publica
     * identica a la anterior.
     */
    private static volatile LongSupplier reloj = System::currentTimeMillis;

    /** Solo para pruebas: fija un reloj controlable. Ver ControlIntentosLoginExpiracionTest. */
    static void fijarRelojParaPruebas(LongSupplier relojPruebas) {
        reloj = relojPruebas;
    }

    /** Solo para pruebas: restaura el reloj real del sistema. */
    static void restaurarRelojReal() {
        reloj = System::currentTimeMillis;
    }

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
        if (reloj.getAsLong() >= r.bloqueadoHasta) {
            // el bloqueo ya expiró: se limpia para no arrastrar estado viejo
            intentos.remove(normalizar(email));
            return false;
        }
        return true;
    }

    /**
     * Minutos (redondeados hacia arriba) que faltan para que se levante el bloqueo.
     * Si el bloqueo ya vencio informa 0, consistente con estaBloqueado().
     */
    public static long minutosRestantes(String email) {
        Registro r = intentos.get(normalizar(email));
        if (r == null || r.bloqueadoHasta == 0L) return 0;
        long restanteMs = r.bloqueadoHasta - reloj.getAsLong();
        if (restanteMs <= 0L) return 0; // vencido: 0 minutos restantes
        return (restanteMs + 59_999) / 60_000;
    }

    /** Registra un intento fallido; si llega al máximo, activa el bloqueo temporal. */
    public static void registrarFallo(String email) {
        String key = normalizar(email);
        Registro r = intentos.computeIfAbsent(key, k -> new Registro());
        synchronized (r) {
            r.intentosFallidos++;
            if (r.intentosFallidos >= MAX_INTENTOS) {
                r.bloqueadoHasta = reloj.getAsLong() + BLOQUEO_MS;
            }
        }
    }

    /** Login exitoso: se limpia cualquier historial de intentos fallidos previos. */
    public static void registrarExito(String email) {
        intentos.remove(normalizar(email));
    }
}
