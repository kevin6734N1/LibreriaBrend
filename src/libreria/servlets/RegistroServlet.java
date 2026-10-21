package libreria.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;

import libreria.dao.ClienteDAO;
import libreria.models.Cliente;
import libreria.util.ValidadorEmail;

/**
 * RegistroServlet - Libreria Brenda
 *
 * Antes registraba en la BD y devolvia "OK"/"ERROR" en texto plano, y
 * registro.jsp mandaba al usuario de vuelta a login.jsp a escribir sus
 * datos otra vez. Ahora, si el registro sale bien, se crea la sesion de
 * una vez (igual que hace LoginServlet) para no pedirle que se loguee dos
 * veces seguidas.
 */
@WebServlet("/RegistroServlet")
public class RegistroServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final int PASSWORD_MIN_LENGTH = 8;

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();

        String nombres   = request.getParameter("nombres");
        String apellidos = request.getParameter("apellidos");
        String dni       = request.getParameter("dni");
        String email     = request.getParameter("email");
        String telefono  = request.getParameter("telefono");
        String direccion = request.getParameter("direccion");
        String password  = request.getParameter("password");

        if (nombres == null || apellidos == null || dni == null || email == null || password == null
                || nombres.isEmpty() || apellidos.isEmpty() || dni.isEmpty() || email.isEmpty() || password.isEmpty()) {
            out.print("{\"ok\":false,\"error\":\"Completa los campos requeridos.\"}");
            return;
        }

        email = email.trim();

        if (!ValidadorEmail.esValido(email)) {
            out.print("{\"ok\":false,\"error\":\"Ingresa un correo con formato válido.\"}");
            return;
        }

        if (password.length() < PASSWORD_MIN_LENGTH) {
            out.print("{\"ok\":false,\"error\":\"La contraseña debe tener al menos " + PASSWORD_MIN_LENGTH + " caracteres.\"}");
            return;
        }

        Cliente cliente = new Cliente();
        cliente.setNombres(nombres);
        cliente.setApellidos(apellidos);
        cliente.setDni(dni);
        cliente.setEmail(email);
        cliente.setTelefono(telefono);
        cliente.setDireccion(direccion);
        cliente.setPasswordHash(password); // ClienteDAO.registrar() se encarga de hashearla antes de guardar

        ClienteDAO dao = new ClienteDAO();
        boolean registrado = dao.registrar(cliente);

        if (registrado) {
            HttpSession session = SesionAutenticada.iniciar(request, "cliente", email);
            session.setAttribute("clienteEmail", email);
            session.setAttribute("clienteNombre", nombres + " " + apellidos);
            out.print("{\"ok\":true,\"redirect\":\"index.jsp\"}");
        } else {
            out.print("{\"ok\":false,\"error\":\"El correo o DNI ya estan registrados.\"}");
        }
    }
}
