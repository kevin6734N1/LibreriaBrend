package libreria.util;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class PasswordUtilTest {

    @Test
    void hash_noGuardaLaContrasenaEnTextoPlano() {
        String h = PasswordUtil.hash("MiClave123");
        assertNotEquals("MiClave123", h);
    }

    @Test
    void hash_tieneFormatoBCrypt() {
        assertTrue(PasswordUtil.hash("MiClave123").startsWith("$2a$10$"));
    }

    @Test
    void hash_mismaContrasenaDosVeces_generaHashesDistintos() {
        // BCrypt usa salt aleatorio
        assertNotEquals(PasswordUtil.hash("MiClave123"), PasswordUtil.hash("MiClave123"));
    }

    @Test
    void verificar_contrasenaCorrecta_devuelveTrue() {
        String h = PasswordUtil.hash("MiClave123");
        assertTrue(PasswordUtil.verificar("MiClave123", h));
    }

    @Test
    void verificar_contrasenaIncorrecta_devuelveFalse() {
        String h = PasswordUtil.hash("MiClave123");
        assertFalse(PasswordUtil.verificar("otraClave", h));
    }

    @Test
    void verificar_distingueMayusculasYMinusculas() {
        String h = PasswordUtil.hash("MiClave123");
        assertFalse(PasswordUtil.verificar("miclave123", h));
    }

    @Test
    void verificar_passwordNula_devuelveFalse() {
        assertFalse(PasswordUtil.verificar(null, PasswordUtil.hash("x")));
    }

    @Test
    void verificar_hashNulo_devuelveFalse() {
        assertFalse(PasswordUtil.verificar("MiClave123", null));
    }

    @Test
    void verificar_hashVacio_devuelveFalse() {
        assertFalse(PasswordUtil.verificar("MiClave123", ""));
    }

    @Test
    void verificar_hashEnTextoPlano_noLanzaExcepcionYDevuelveFalse() {
        assertFalse(PasswordUtil.verificar("MiClave123", "MiClave123"));
    }
}
