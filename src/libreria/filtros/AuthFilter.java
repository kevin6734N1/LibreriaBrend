package libreria.filtros;

import java.io.IOException;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * AuthFilter - Libreria Brenda
 *
 * Antes NINGUNA pagina ni servlet del panel admin verificaba sesion: se
 * podia entrar a admin.jsp, clientes.jsp (con DNI/telefono/direccion de
 * todos los clientes), reportes.jsp, etc. escribiendo la URL directo,
 * logueado o no. Este filtro es el unico punto de control de acceso para
 * todo lo administrativo, en vez de repetir el chequeo en cada JSP/servlet.
 *
 * Regla: sin sesion con rol "admin" -> no pasa.
 *  - Paginas .jsp completas         -> redirige a login.jsp
 *  - Servlets/JSON (llamados via fetch) -> responde 401 en JSON
 *
 * ProductoServlet y PedidoServlet se protegen solo parcialmente: el
 * catalogo (GET de productos) sigue siendo publico; crear/editar/eliminar
 * producto y cambiar el estado de un pedido exigen sesion admin. Las
 * operaciones de cliente (listar/crear/cancelar pedido propio) exigen una
 * sesion de cliente valida y se validan dentro de PedidoServlet, que
 * responde 401 si no la hay.
 */
@WebFilter(urlPatterns = {
        "/admin.jsp",
        "/admin-pedidos.jsp",
        "/clientes.jsp",
        "/reportes.jsp",
        "/productos.jsp",
        "/ClienteServlet",
        "/ReporteServlet",
        "/ProductoServlet",
        "/ImagenProductoServlet",
        "/PedidoServlet"
})
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest request   = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;

        String path = request.getRequestURI().substring(request.getContextPath().length());

        if (!requiereAdmin(path, request)) {
            chain.doFilter(req, res);
            return;
        }

        HttpSession session = request.getSession(false);
        boolean esAdmin = session != null && "admin".equals(session.getAttribute("rol"));

        if (esAdmin) {
            chain.doFilter(req, res);
            return;
        }

        if (path.endsWith(".jsp")) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=sesion");
        } else {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().print("{\"ok\":false,\"error\":\"No autorizado. Inicia sesion como administrador.\"}");
        }
    }

    /** Decide si la ruta (y, para algunos servlets, la accion/metodo pedido) exige sesion admin. */
    private boolean requiereAdmin(String path, HttpServletRequest request) {

        // Paginas completas del panel admin: siempre protegidas.
        if (path.equals("/admin.jsp") || path.equals("/admin-pedidos.jsp")
                || path.equals("/clientes.jsp") || path.equals("/reportes.jsp")
                || path.equals("/productos.jsp")) {
            return true;
        }

        // Datos sensibles: listado de clientes (con DNI/telefono/direccion) y
        // reportes de negocio. No tienen ninguna razon para ser publicos.
        if (path.equals("/ClienteServlet") || path.equals("/ReporteServlet")) {
            return true;
        }

        // Subir imagenes de producto escribe archivos en el proyecto: solo admin.
        if (path.equals("/ImagenProductoServlet")) {
            return true;
        }

        // Alta/edicion/borrado de productos requiere admin; el catalogo
        // publico (GET, usado por index.jsp) sigue abierto.
        if (path.equals("/ProductoServlet")) {
            return "POST".equalsIgnoreCase(request.getMethod());
        }

        // Cambiar el estado de un pedido emite el comprobante de venta: solo
        // admin. Crear/listar/cancelar el propio pedido sigue siendo publico.
        if (path.equals("/PedidoServlet")) {
            return "cambiarEstado".equals(request.getParameter("accion"));
        }

        return false;
    }
}
