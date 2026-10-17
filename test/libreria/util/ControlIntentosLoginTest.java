package libreria.util;

import org.junit.jupiter.api.Test;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;

class ControlIntentosLoginTest {

    /** Email único por test: el contador es estático y compartido entre tests. */
    private String emailUnico() {
        return "user-" + UUID.randomUUID() + "@mail.com";
    }

    private void fallar(String email, int veces) {
        for (int i = 0; i < veces; i++) ControlIntentosLogin.registrarFallo(email);
    }

    @Test
    void emailSinHistorial_noEstaBloqueado() {
        assertFalse(ControlIntentosLogin.estaBloqueado(emailUnico()));
    }

    @Test
    void cuatroFallos_noBloquea() {
        String e = emailUnico();
        fallar(e, 4);
        assertFalse(ControlIntentosLogin.estaBloqueado(e));
    }

    @Test
    void cincoFallos_bloquea() {
        String e = emailUnico();
        fallar(e, 5);
        assertTrue(ControlIntentosLogin.estaBloqueado(e));
    }

    @Test
    void masDeCincoFallos_sigueBloqueado() {
        String e = emailUnico();
        fallar(e, 8);
        assertTrue(ControlIntentosLogin.estaBloqueado(e));
    }

    @Test
    void bloqueo_esPorEmail_noAfectaAOtrosUsuarios() {
        String atacado = emailUnico();
        String otro = emailUnico();
        fallar(atacado, 5);
        assertFalse(ControlIntentosLogin.estaBloqueado(otro));
    }

    @Test
    void email_ignoraMayusculasYEspacios() {
        String base = "Usuario-" + UUID.randomUUID() + "@Mail.com";
        fallar("  " + base.toUpperCase() + "  ", 5);
        assertTrue(ControlIntentosLogin.estaBloqueado(base.toLowerCase()));
    }

    @Test
    void loginExitoso_reiniciaElContador() {
        String e = emailUnico();
        fallar(e, 4);
        ControlIntentosLogin.registrarExito(e);
        fallar(e, 4); // si no se hubiera reiniciado, ya estaría bloqueado (8 fallos)
        assertFalse(ControlIntentosLogin.estaBloqueado(e));
    }

    @Test
    void loginExitoso_levantaUnBloqueoActivo() {
        String e = emailUnico();
        fallar(e, 5);
        ControlIntentosLogin.registrarExito(e);
        assertFalse(ControlIntentosLogin.estaBloqueado(e));
    }

    @Test
    void minutosRestantes_sinBloqueo_esCero() {
        assertEquals(0, ControlIntentosLogin.minutosRestantes(emailUnico()));
    }

    @Test
    void minutosRestantes_recienBloqueado_sonDos() {
        String e = emailUnico();
        fallar(e, 5);
        assertEquals(2, ControlIntentosLogin.minutosRestantes(e));
    }

    @Test
    void emailNulo_noLanzaExcepcion() {
        assertDoesNotThrow(() -> ControlIntentosLogin.registrarFallo(null));
        assertDoesNotThrow(() -> ControlIntentosLogin.estaBloqueado(null));
        assertDoesNotThrow(() -> ControlIntentosLogin.registrarExito(null));
    }
}
