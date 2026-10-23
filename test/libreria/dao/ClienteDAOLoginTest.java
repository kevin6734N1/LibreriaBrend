package libreria.dao;

import libreria.models.Cliente;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * RF02 en la capa de datos: autenticacion de clientes contra una base aislada.
 *
 * Estas pruebas son de CARACTERIZACION/REGRESION: el comportamiento ya existia
 * y se fija aqui para que un cambio futuro no lo rompa en silencio. No se
 * invento una fase RED para codigo que ya funcionaba.
 *
 * Requieren DB_NAME=libreria_brenda_test y los fixtures cargados:
 *   cliente.a@test.local / Cliente#2026 (activo)
 *   inactivo@test.local  / Cliente#2026 (activo = 0)
 */
class ClienteDAOLoginTest {

    private static final String EMAIL_ACTIVO = "cliente.a@test.local";
    private static final String PASSWORD = "Cliente#2026";

    private final ClienteDAO dao = new ClienteDAO();

    @BeforeAll
    static void verificarBaseDePruebas() {
        BaseDatosPruebas.asumirDisponible();
    }

    @Test
    void validarLogin_credencialesCorrectas_devuelveElCliente() {
        Cliente cliente = dao.validarLogin(EMAIL_ACTIVO, PASSWORD);

        assertEquals(1, cliente.getId());
        assertEquals(EMAIL_ACTIVO, cliente.getEmail());
        assertEquals("Cliente Alfa", cliente.getNombreCompleto());
    }

    @Test
    void validarLogin_contrasenaIncorrecta_devuelveNull() {
        assertNull(dao.validarLogin(EMAIL_ACTIVO, "Cliente#2027"));
    }

    @Test
    void validarLogin_contrasenaVacia_devuelveNull() {
        assertNull(dao.validarLogin(EMAIL_ACTIVO, ""));
    }

    @Test
    void validarLogin_contrasenaNula_devuelveNull() {
        assertNull(dao.validarLogin(EMAIL_ACTIVO, null));
    }

    @Test
    void validarLogin_cuentaInactivaConContrasenaCorrecta_devuelveNull() {
        assertNull(dao.validarLogin("inactivo@test.local", PASSWORD));
    }

    @Test
    void validarLogin_emailInexistente_devuelveNull() {
        assertNull(dao.validarLogin("nadie@test.local", PASSWORD));
    }

    @Test
    void validarLogin_emailNulo_devuelveNull() {
        assertNull(dao.validarLogin(null, PASSWORD));
    }

    /**
     * Caracterizacion: la collation utf8mb4_unicode_ci de la columna hace que
     * el correo no distinga mayusculas. El servlet conserva el texto original
     * en la sesion, por eso no se normaliza a minusculas en el DAO.
     */
    @Test
    void validarLogin_emailEnMayusculas_encuentraLaCuenta() {
        Cliente cliente = dao.validarLogin("CLIENTE.A@TEST.LOCAL", PASSWORD);

        assertEquals(1, cliente.getId());
    }

    /**
     * El recorte de espacios es responsabilidad del servlet, no del DAO.
     * Se documenta para que nadie asuma un trim inexistente en esta capa.
     */
    @Test
    void validarLogin_emailConEspacios_noCoincide() {
        assertNull(dao.validarLogin("  " + EMAIL_ACTIVO + "  ", PASSWORD));
    }
}
