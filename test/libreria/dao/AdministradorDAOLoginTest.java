package libreria.dao;

import libreria.models.Administrador;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * RF02 en la capa de datos: el administrador exige correo, contrasena y
 * codigo de empleado. Pruebas de CARACTERIZACION: el comportamiento ya
 * existia; se fija para detectar regresiones.
 *
 * Fixture: admin@test.local / Admin#2026 / EMP-TEST.
 */
class AdministradorDAOLoginTest {

    private static final String EMAIL = "admin@test.local";
    private static final String PASSWORD = "Admin#2026";
    private static final String CODIGO = "EMP-TEST";

    private final AdministradorDAO dao = new AdministradorDAO();

    @BeforeAll
    static void verificarBaseDePruebas() {
        BaseDatosPruebas.asumirDisponible();
    }

    @Test
    void validarLogin_losTresDatosCorrectos_devuelveElAdministrador() {
        Administrador admin = dao.validarLogin(EMAIL, PASSWORD, CODIGO);

        assertEquals(1, admin.getId());
        assertEquals(EMAIL, admin.getEmail());
        assertEquals(CODIGO, admin.getCodigoEmpleado());
    }

    @Test
    void validarLogin_codigoIncorrecto_devuelveNull() {
        assertNull(dao.validarLogin(EMAIL, PASSWORD, "EMP-OTRO"));
    }

    @Test
    void validarLogin_codigoNulo_devuelveNull() {
        assertNull(dao.validarLogin(EMAIL, PASSWORD, null));
    }

    @Test
    void validarLogin_codigoVacio_devuelveNull() {
        assertNull(dao.validarLogin(EMAIL, PASSWORD, ""));
    }

    @Test
    void validarLogin_contrasenaIncorrecta_devuelveNull() {
        assertNull(dao.validarLogin(EMAIL, "Admin#2027", CODIGO));
    }

    @Test
    void validarLogin_contrasenaNula_devuelveNull() {
        assertNull(dao.validarLogin(EMAIL, null, CODIGO));
    }

    @Test
    void validarLogin_correoDeCliente_noDevuelveAdministrador() {
        assertNull(dao.validarLogin("cliente.a@test.local", "Cliente#2026", CODIGO));
    }

    /** Caracterizacion de la collation: el correo no distingue mayusculas. */
    @Test
    void validarLogin_emailEnMayusculas_encuentraLaCuenta() {
        Administrador admin = dao.validarLogin("ADMIN@TEST.LOCAL", PASSWORD, CODIGO);

        assertEquals(1, admin.getId());
    }

    /** Un administrador no puede autenticarse por la puerta de clientes. */
    @Test
    void clienteDAO_noAceptaCredencialesDeAdministrador() {
        assertNull(new ClienteDAO().validarLogin(EMAIL, PASSWORD));
    }
}
