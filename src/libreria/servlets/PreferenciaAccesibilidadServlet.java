package libreria.servlets;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Arrays;
import java.util.List;

import libreria.dao.ClienteDAO;
import libreria.dao.PreferenciaAccesibilidadDAO;
import libreria.models.Cliente;
import libreria.models.PreferenciaAccesibilidad;

/**
 * PreferenciaAccesibilidadServlet - Libreria Brenda
 * Lee/guarda el perfil de accesibilidad (ODS10 / Ley 29973) del cliente logueado.
 */
@WebServlet("/PreferenciaAccesibilidadServlet")
public class PreferenciaAccesibilidadServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final List<String> TIPOS_VALIDOS =
            Arrays.asList("ninguno", "protanopia", "deuteranopia", "tritanopia");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        Integer clienteId = obtenerClienteIdAutenticado(req);
        if (clienteId == null) {
            // Sin sesion: el navegador usa su propia preferencia local (ver accesibilidad.js).
            out.print("{\"autenticado\":false,\"tipoDaltonismo\":\"ninguno\",\"lecturaVozActiva\":false}");
            return;
        }

        PreferenciaAccesibilidad p = new PreferenciaAccesibilidadDAO().obtenerPorCliente(clienteId);
        out.print("{\"autenticado\":true,"
                + "\"tipoDaltonismo\":\"" + p.getTipoDaltonismo() + "\","
                + "\"lecturaVozActiva\":" + p.isLecturaVozActiva() + "}");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException {
        req.setCharacterEncoding("UTF-8");
        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        Integer clienteId = obtenerClienteIdAutenticado(req);
        if (clienteId == null) {
            out.print("{\"ok\":false,\"error\":\"Debes iniciar sesion para guardar tu preferencia de accesibilidad.\"}");
            return;
        }

        String  tipo       = req.getParameter("tipoDaltonismo");
        boolean lecturaVoz = "true".equals(req.getParameter("lecturaVozActiva"));

        if (tipo == null || !TIPOS_VALIDOS.contains(tipo)) {
            out.print("{\"ok\":false,\"error\":\"Tipo de daltonismo no valido.\"}");
            return;
        }

        PreferenciaAccesibilidad p = new PreferenciaAccesibilidad();
        p.setClienteId(clienteId);
        p.setTipoDaltonismo(tipo);
        p.setLecturaVozActiva(lecturaVoz);

        boolean ok = new PreferenciaAccesibilidadDAO().guardar(p);
        out.print("{\"ok\":" + ok + "}");
    }

    /**
     * A diferencia de PedidoServlet, aqui NO se cae a un "cliente demo" (id=1)
     * cuando no hay sesion. Un pedido necesita quedar ligado a algun cliente
     * en BD, pero una preferencia de accesibilidad es personal: si cualquier
     * visitante anonimo escribiera sobre la fila del cliente demo, todos los
     * visitantes sin sesion terminarian pisandose la misma preferencia. Por
     * eso "sin sesion" = null = sin perfil en BD; el filtro para visitantes
     * anonimos se maneja solo en el navegador (localStorage).
     */
    private Integer obtenerClienteIdAutenticado(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session != null) {
            String email = (String) session.getAttribute("clienteEmail");
            if (email != null) {
                Cliente c = new ClienteDAO().buscarPorEmail(email);
                if (c != null) return c.getId();
            }
        }
        return null;
    }
}
