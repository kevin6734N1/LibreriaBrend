package libreria.servlets;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import libreria.dao.ClienteDAO;
import libreria.models.Cliente;

@WebServlet("/ClienteServlet")
public class ClienteServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // El JSON viaja como yyyy-MM-dd porque asi es como clientes.jsp
    // (formatearFecha) espera partir el string con split('-').
    private static final SimpleDateFormat FORMATO_FECHA = new SimpleDateFormat("yyyy-MM-dd");

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        ClienteDAO dao = new ClienteDAO();
        List<Cliente> clientes = dao.listarTodos();

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        StringBuilder json = new StringBuilder();
        json.append("[");

        for (int i = 0; i < clientes.size(); i++) {

            Cliente c = clientes.get(i);
            String fechaRegistro = c.getFechaRegistro() != null
                ? FORMATO_FECHA.format(c.getFechaRegistro())
                : null;

            json.append("{")
                .append("\"id\":").append(c.getId()).append(",")
                .append("\"nombres\":\"").append(escapar(c.getNombres())).append("\",")
                .append("\"apellidos\":\"").append(escapar(c.getApellidos())).append("\",")
                .append("\"dni\":\"").append(escapar(c.getDni())).append("\",")
                .append("\"email\":\"").append(escapar(c.getEmail())).append("\",")
                .append("\"telefono\":\"").append(escapar(c.getTelefono())).append("\",")
                .append("\"direccion\":\"").append(escapar(c.getDireccion())).append("\",")
                .append("\"fechaRegistro\":").append(fechaRegistro != null ? "\"" + fechaRegistro + "\"" : "null").append(",")
                .append("\"activo\":").append(c.isActivo()).append(",")
                .append("\"totalPedidos\":").append(c.getTotalPedidos()).append(",")
                .append("\"totalGastado\":").append(c.getTotalGastado())
                .append("}");

            if (i < clientes.size() - 1) {
                json.append(",");
            }
        }

        json.append("]");

        response.getWriter().write(json.toString());
    }

    /**
     * Activa/inactiva un cliente. Antes no existia forma de hacer esto desde
     * la interfaz: ClienteDAO.cambiarEstado() ya existia en el DAO, pero
     * nadie lo llamaba. AuthFilter ya exige sesion admin para cualquier
     * peticion a este servlet (GET o POST).
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        String accion = request.getParameter("accion");

        if ("cambiarEstado".equals(accion)) {
            try {
                int id = Integer.parseInt(request.getParameter("id"));
                boolean activo = Boolean.parseBoolean(request.getParameter("activo"));

                boolean ok = new ClienteDAO().cambiarEstado(id, activo);
                response.getWriter().write(ok
                    ? "{\"ok\":true}"
                    : "{\"ok\":false,\"error\":\"No se pudo actualizar el estado.\"}");
            } catch (NumberFormatException e) {
                response.getWriter().write("{\"ok\":false,\"error\":\"Parámetros inválidos.\"}");
            }
        } else {
            response.getWriter().write("{\"ok\":false,\"error\":\"Acción no reconocida.\"}");
        }
    }

    private String escapar(String texto) {
        if (texto == null) {
            return "";
        }
        return texto.replace("\"", "\\\"");
    }
}