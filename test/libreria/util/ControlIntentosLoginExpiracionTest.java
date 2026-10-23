package libreria.util;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

import static org.junit.jupiter.api.Assertions.*;

/**
 * RF03 - Fronteras de expiracion del bloqueo de 2 minutos.
 *
 * Usa un reloj falso inyectado (fijarRelojParaPruebas) para no esperar los
 * 120 s reales y poder observar los tres instantes que exige la mision:
 * anterior al vencimiento, exacto del vencimiento y posterior al vencimiento.
 *
 * El reloj se restaura en @AfterEach para no contaminar otras pruebas
 * (el estado de ControlIntentosLogin es estatico y compartido).
 */
class ControlIntentosLoginExpiracionTest {

    private static final long BLOQUEO_MS = 2 * 60 * 1000L;

    private AtomicLong ahora;
    private String email;

    @BeforeEach
    void fijarRelojYEmail() {
        ahora = new AtomicLong(System.currentTimeMillis());
        ControlIntentosLogin.fijarRelojParaPruebas(ahora::get);
        email = "exp-" + UUID.randomUUID() + "@mail.com";
    }

    @AfterEach
    void restaurarReloj() {
        ControlIntentosLogin.restaurarRelojReal();
    }

    private void fallar(int veces) {
        for (int i = 0; i < veces; i++) ControlIntentosLogin.registrarFallo(email);
    }

    @Test
    void anteDelVencimiento_sigueBloqueado_eInformaUnMinuto() {
        fallar(5);
        ahora.addAndGet(BLOQUEO_MS - 1); // 1 ms antes del vencimiento
        assertEquals(1, ControlIntentosLogin.minutosRestantes(email));
        assertTrue(ControlIntentosLogin.estaBloqueado(email));
    }

    @Test
    void minutos_seGunElRangoDelRestante() {
        fallar(5);
        ahora.addAndGet(BLOQUEO_MS - 60_001); // restante 60_001 ms -> techo = 2
        assertEquals(2, ControlIntentosLogin.minutosRestantes(email));
        ahora.addAndGet(1); // restante exacto 60_000 ms -> 1
        assertEquals(1, ControlIntentosLogin.minutosRestantes(email));
    }

    @Test
    void enElVencimiento_estaBloqueado_seLevanta() {
        fallar(5);
        ahora.addAndGet(BLOQUEO_MS); // instante exacto del vencimiento
        assertFalse(ControlIntentosLogin.estaBloqueado(email));
    }

    /** BRECHA RF03-G1: con el bloqueo vencido, minutosRestantes debe informar 0. */
    @Test
    void enElVencimiento_minutosRestantes_esCero() {
        fallar(5);
        ahora.addAndGet(BLOQUEO_MS);
        assertEquals(0, ControlIntentosLogin.minutosRestantes(email),
                "bloqueo vencido: los minutos restantes deben ser 0");
    }

    /** BRECHA RF03-G1: consulta directa al vencido, sin pasar antes por estaBloqueado(). */
    @Test
    void trasElVencimiento_minutosRestantes_esCero_sinConsultaPrevia() {
        fallar(5);
        ahora.addAndGet(BLOQUEO_MS + 1);
        assertEquals(0, ControlIntentosLogin.minutosRestantes(email),
                "bloqueo vencido: minutosRestantes no debe informar minutos de un bloqueo ya levantado");
    }

    @Test
    void trasElVencimiento_laConsultaLimpiaYArrancaUnNuevoCiclo() {
        fallar(5);
        ahora.addAndGet(BLOQUEO_MS + 1);
        assertFalse(ControlIntentosLogin.estaBloqueado(email), "vencido => no bloqueado");
        ControlIntentosLogin.registrarFallo(email);
        assertFalse(ControlIntentosLogin.estaBloqueado(email),
                "tras limpiar, un fallo es el primer intento del nuevo ciclo (no re-bloquea)");
        fallar(4); // 5 fallos acumulados en el nuevo ciclo
        assertTrue(ControlIntentosLogin.estaBloqueado(email),
                "cinco fallos del nuevo ciclo vuelven a bloquear 2 minutos");
    }
}
