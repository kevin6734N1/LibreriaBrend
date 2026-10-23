package libreria.servlets;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

/**
 * Unico punto donde se crea una sesion autenticada.
 *
 * Rota el JSESSIONID para evitar session fixation: una cookie fijada antes
 * del login o del registro deja de servir despues de autenticarse.
 *
 * Tambien limpia los atributos de autenticacion previos. Asi un cambio de rol
 * en el mismo navegador no arrastra el nombre o el correo del usuario anterior.
 */
final class SesionAutenticada {

    private static final String[] ATRIBUTOS_DE_AUTENTICACION = {
            "usuario",
            "rol",
            "clienteEmail",
            "clienteNombre",
            "adminNombre"
    };

    private SesionAutenticada() {
        // clase utilitaria, no se instancia
    }

    static HttpSession iniciar(HttpServletRequest request, String rol, String email) {
        HttpSession session = request.getSession();
        request.changeSessionId();

        for (String atributo : ATRIBUTOS_DE_AUTENTICACION) {
            session.removeAttribute(atributo);
        }

        session.setAttribute("usuario", email);
        session.setAttribute("rol", rol);
        return session;
    }
}
