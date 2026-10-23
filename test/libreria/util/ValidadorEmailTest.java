package libreria.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * RF02: el inicio de sesion debe validar el formato del correo antes de
 * consultar la base de datos. Estos casos se escribieron antes de existir
 * {@link ValidadorEmail} (fase RED del ciclo TDD).
 */
class ValidadorEmailTest {

    @Test
    void esValido_correoNormal_devuelveTrue() {
        assertTrue(ValidadorEmail.esValido("cliente@test.local"));
    }

    @Test
    void esValido_correoConEtiqueta_devuelveTrue() {
        assertTrue(ValidadorEmail.esValido("cliente+ofertas@test.local"));
    }

    @Test
    void esValido_correoConMayusculas_devuelveTrue() {
        assertTrue(ValidadorEmail.esValido("Cliente.A@Test.Local"));
    }

    @Test
    void esValido_espaciosExternos_seIgnoran() {
        assertTrue(ValidadorEmail.esValido("  cliente@test.local  "));
    }

    @Test
    void esValido_longitudExactaDe120Caracteres_devuelveTrue() {
        String correo = "a".repeat(109) + "@test.local"; // 109 + 11 = 120

        assertTrue(ValidadorEmail.esValido(correo));
    }

    @Test
    void esValido_longitudDe121Caracteres_devuelveFalse() {
        String correo = "a".repeat(110) + "@test.local"; // 110 + 11 = 121

        assertFalse(ValidadorEmail.esValido(correo));
    }

    @Test
    void esValido_nulo_devuelveFalse() {
        assertFalse(ValidadorEmail.esValido(null));
    }

    @Test
    void esValido_vacio_devuelveFalse() {
        assertFalse(ValidadorEmail.esValido(""));
    }

    @Test
    void esValido_soloEspacios_devuelveFalse() {
        assertFalse(ValidadorEmail.esValido("   "));
    }

    @Test
    void esValido_sinArroba_devuelveFalse() {
        assertFalse(ValidadorEmail.esValido("cliente.test.local"));
    }

    @Test
    void esValido_sinPuntoEnElDominio_devuelveFalse() {
        assertFalse(ValidadorEmail.esValido("cliente@test"));
    }

    @Test
    void esValido_conEspacioInterno_devuelveFalse() {
        assertFalse(ValidadorEmail.esValido("cliente @test.local"));
    }

    @Test
    void esValido_conDobleArroba_devuelveFalse() {
        assertFalse(ValidadorEmail.esValido("cliente@@test.local"));
    }

    @Test
    void esValido_sinParteLocal_devuelveFalse() {
        assertFalse(ValidadorEmail.esValido("@test.local"));
    }

    @Test
    void esValido_sinDominio_devuelveFalse() {
        assertFalse(ValidadorEmail.esValido("cliente@"));
    }

    @Test
    void esValido_conSaltoDeLinea_devuelveFalse() {
        assertFalse(ValidadorEmail.esValido("cliente@test.local\nBcc: otro@test.local"));
    }
}
