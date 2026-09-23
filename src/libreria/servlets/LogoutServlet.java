package libreria.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;

/**
 * LogoutServlet - Libreria Brenda
 *
 * Antes el boton "Cerrar sesion" del panel admin apuntaba directo a
 * login.jsp (no invalidaba nada, porque tampoco existia una sesion real).
 * Ahora que el login si crea sesion, hace falta invalidarla de verdad.
 */
@WebServlet("/LogoutServlet")
public class LogoutServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        response.sendRedirect("login.jsp");
    }
}
