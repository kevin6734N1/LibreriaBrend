package libreria.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;

import libreria.dao.AdministradorDAO;
import libreria.dao.ClienteDAO;
import libreria.models.Administrador;
import libreria.models.Cliente;
import libreria.util.ControlIntentosLogin;
import libreria.util.ValidadorEmail;

/**
 * LoginServlet - Libreria Brenda
 *
 * Antes login.jsp nunca llamaba a este servlet: el "login" era una
 * simulacion 100% en JavaScript contra dos credenciales fijas escritas en
 * el HTML, por eso ningun cliente registrado de verdad podia entrar y la
 * sesion nunca se creaba. Ahora login.jsp hace un fetch real hacia aqui.
 *
 * Responde en JSON (en vez de sendRedirect) porque login.jsp lo consume
 * con fetch(), igual que el resto de servlets del proyecto.
 */
@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();

        String email    = request.getParameter("email");
        String password = request.getParameter("password");
        String rol      = request.getParameter("rol");
        String codigo   = request.getParameter("codigo");

        if (email == null || email.isEmpty() || password == null || password.isEmpty() || rol == null) {
            out.print("{\"ok\":false,\"error\":\"Completa todos los campos.\"}");
            return;
        }

        email = email.trim();

        if (!ValidadorEmail.esValido(email)) {
            out.print("{\"ok\":false,\"error\":\"Ingresa un correo con formato válido.\"}");
            return;
        }

        // Proteccion contra fuerza bruta: si este email ya acumulo demasiados
        // intentos fallidos, se corta aqui, antes de tocar la BD.
        if (ControlIntentosLogin.estaBloqueado(email)) {
            long min = ControlIntentosLogin.minutosRestantes(email);
            out.print("{\"ok\":false,\"error\":\"Demasiados intentos fallidos. Intenta de nuevo en " + min + " minuto(s).\"}");
            return;
        }

        if ("cliente".equals(rol)) {

            Cliente cliente = new ClienteDAO().validarLogin(email, password);

            if (cliente != null) {
                ControlIntentosLogin.registrarExito(email);
                HttpSession session = SesionAutenticada.iniciar(request, "cliente", email);
                session.setAttribute("clienteEmail", email);
                session.setAttribute("clienteNombre", cliente.getNombreCompleto());
                out.print("{\"ok\":true,\"redirect\":\"index.jsp\"}");
            } else {
                ControlIntentosLogin.registrarFallo(email);
                out.print("{\"ok\":false,\"error\":\"Correo o contraseña incorrectos.\"}");
            }

        } else if ("admin".equals(rol)) {

            Administrador admin = new AdministradorDAO().validarLogin(email, password, codigo);

            if (admin != null) {
                ControlIntentosLogin.registrarExito(email);
                HttpSession session = SesionAutenticada.iniciar(request, "admin", email);
                session.setAttribute("adminNombre", admin.getNombre());
                out.print("{\"ok\":true,\"redirect\":\"admin.jsp\"}");
            } else {
                ControlIntentosLogin.registrarFallo(email);
                out.print("{\"ok\":false,\"error\":\"Credenciales de empleado incorrectas.\"}");
            }

        } else {
            out.print("{\"ok\":false,\"error\":\"Rol no reconocido.\"}");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("login.jsp");
    }
}
