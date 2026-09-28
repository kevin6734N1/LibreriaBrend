package libreria.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.*;

import libreria.dao.AdministradorDAO;
import libreria.dao.ClienteDAO;
import libreria.dao.CodigoPromoDAO;
import libreria.dao.CodigoPromoInvalidoException;
import libreria.dao.PedidoDAO;
import libreria.dao.StockInsuficienteException;
import libreria.models.Administrador;
import libreria.models.Cliente;
import libreria.models.Pedido;
import libreria.models.Producto;

/**
 * PedidoServlet - Librería Brenda
 * Gestiona la creación y actualización de pedidos.
 */
@WebServlet("/PedidoServlet")
public class PedidoServlet extends HttpServlet {

    // Cliente de respaldo cuando nadie inicio sesion (id=1, "Cliente Demo" del seed SQL)
    private static final int CLIENTE_DEMO_ID = 1;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String accion = request.getParameter("accion");

        if ("cambiarEstado".equals(accion)) {
            cambiarEstado(request, response);
        } else if ("guardarDB".equals(accion)) {
            guardarPedidoEnDB(request, response);
        } else if ("validarPromo".equals(accion)) {
            validarPromo(request, response);
        } else if ("cancelarPedido".equals(accion)) {
            cancelarPedidoCliente(request, response);
        } else {
            response.sendRedirect("pedidos.jsp");
        }
    }

    /** Determina el id de cliente a partir de la sesion (o el cliente demo si nadie inicio sesion). */
    private int obtenerClienteIdDeSesion(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session != null) {
            String email = (String) session.getAttribute("clienteEmail");
            if (email != null) {
                Cliente c = new ClienteDAO().buscarPorEmail(email);
                if (c != null) return c.getId();
            }
        }
        return CLIENTE_DEMO_ID;
    }

    /** Id del cliente con sesion real, o null. Los codigos promocionales no se pueden usar como "demo". */
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

    /** Valida un codigo promocional para mostrar el descuento en el carrito (no consume el codigo). */
    private void validarPromo(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        Integer clienteId = obtenerClienteIdAutenticado(req);
        if (clienteId == null) {
            out.print("{\"ok\":false,\"error\":\"Inicia sesión para usar un código promocional.\"}");
            return;
        }

        double subtotal;
        try {
            subtotal = Double.parseDouble(req.getParameter("subtotal"));
        } catch (Exception e) {
            subtotal = 0;
        }

        CodigoPromoDAO.Resultado r = new CodigoPromoDAO().validar(req.getParameter("codigo"), clienteId, subtotal);
        if (!r.ok) {
            out.print("{\"ok\":false,\"error\":\"" + esc(r.error) + "\"}");
            return;
        }

        out.print("{\"ok\":true,"
                + "\"codigo\":\"" + esc(r.promo.getCodigo()) + "\","
                + "\"tipo\":\"" + r.promo.getTipo() + "\","
                + "\"valor\":" + r.promo.getValor() + ","
                + "\"descuento\":" + r.descuento + "}");
    }

    /** Cancela un pedido propio del cliente (usado por el boton "Cancelar" en pedidos.jsp). */
    private void cancelarPedidoCliente(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        String idPedido = req.getParameter("idPedido");
        if (idPedido == null || idPedido.isEmpty()) {
            out.print("{\"ok\":false,\"error\":\"idPedido requerido\"}");
            return;
        }

        // Defecto corregido: antes se cancelaba con un UPDATE ciego, sin
        // validar que el pedido fuera del cliente logueado ni que siguiera
        // en PENDIENTE. Ahora ambas condiciones van dentro del propio UPDATE
        // (ver PedidoDAO.cancelarPedidoCliente).
        int clienteId = obtenerClienteIdDeSesion(req);
        boolean ok = new PedidoDAO().cancelarPedidoCliente(idPedido, clienteId);

        if (ok) {
            out.print("{\"ok\":true}");
        } else {
            out.print("{\"ok\":false,\"error\":\"No se pudo cancelar: el pedido no existe, no te pertenece, o ya no esta pendiente\"}");
        }
    }

    /**
     * Recibe el carrito (enviado por fetch() desde carrito.jsp al hacer clic en
     * "Realizar pedido") y lo guarda en las tablas "pedidos" / "pedido_items".
     * Este es el UNICO lugar donde un pedido queda registrado (antes tambien
     * se duplicaba en localStorage, ver limpieza en carrito.jsp). Si no hay
     * stock suficiente de algun producto, no se crea nada y se devuelve el
     * motivo para que el carrito se lo muestre al cliente.
     */
    private void guardarPedidoEnDB(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        try {
            String[] ids     = req.getParameterValues("item_id");
            String[] qtys    = req.getParameterValues("item_qty");
            String[] precios = req.getParameterValues("item_precio");
            String direccion = req.getParameter("direccion");
            String pago      = req.getParameter("pago");
            String codigoPromo = CodigoPromoDAO.normalizar(req.getParameter("codigoPromo"));

            if (ids == null || ids.length == 0) {
                out.print("{\"ok\":false,\"error\":\"carrito vacio\"}");
                return;
            }

            if (ids.length > 10) {
                out.print("{\"ok\":false,\"error\":\"El carrito supera el maximo de 10 productos distintos permitido.\"}");
                return;
            }

            // Determinar cliente: si hay sesion de cliente, usar ese id; si no, el demo.
            int clienteId = obtenerClienteIdDeSesion(req);

            List<Pedido.ItemPedido> items = new ArrayList<>();
            for (int i = 0; i < ids.length; i++) {
                Producto p = new Producto();
                p.setId(Integer.parseInt(ids[i]));
                p.setPrecio(Double.parseDouble(precios[i]));

                int cantidad = Integer.parseInt(qtys[i]);
                items.add(new Pedido.ItemPedido(p, cantidad));
            }

            Pedido pedido = new Pedido();
            pedido.setItems(items);
            pedido.calcularSubtotal();

            // Codigo promocional: se vuelve a validar en el servidor (el navegador solo previsualiza).
            if (!codigoPromo.isEmpty()) {
                Integer clienteAuth = obtenerClienteIdAutenticado(req);
                if (clienteAuth == null) {
                    out.print("{\"ok\":false,\"error\":\"Inicia sesión para usar un código promocional.\"}");
                    return;
                }
                CodigoPromoDAO.Resultado r = new CodigoPromoDAO().validar(codigoPromo, clienteAuth, pedido.getSubtotal());
                if (!r.ok) {
                    out.print("{\"ok\":false,\"error\":\"" + esc(r.error) + "\"}");
                    return;
                }
                pedido.setDescuento(r.descuento);
            }

            // Recalculado en el servidor: envio gratis si (subtotal - descuento) >= 30.
            pedido.calcularTotal();
            pedido.setDireccionEntrega(direccion != null && !direccion.isEmpty() ? direccion : "Por confirmar");
            pedido.setMetodoPago(pago != null && !pago.isEmpty() ? pago : "Por confirmar");

            boolean ok = new PedidoDAO().crear(pedido, clienteId, codigoPromo.isEmpty() ? null : codigoPromo);

            if (ok) {
                out.print("{\"ok\":true,\"id\":\"" + pedido.getId() + "\"}");
            } else {
                out.print("{\"ok\":false,\"error\":\"no se pudo guardar en la base de datos\"}");
            }

        } catch (StockInsuficienteException stockEx) {
            // No es un bug: el carrito pidio mas unidades de las que hay en stock.
            out.print("{\"ok\":false,\"error\":\"" + esc(stockEx.getMessage()) + "\"}");
        } catch (CodigoPromoInvalidoException promoEx) {
            out.print("{\"ok\":false,\"error\":\"" + esc(promoEx.getMessage()) + "\"}");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"error\":\"" + esc(e.getMessage()) + "\"}");
        }
    }

    /**
     * Cambia el estado de un pedido desde el panel admin. Esta accion queda
     * restringida a rol admin por AuthFilter; aqui solo falta averiguar
     * cual admin es, para que quede registrado como quien emitio el
     * comprobante (si el nuevo estado genera uno).
     */
    private void cambiarEstado(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        String idPedido = req.getParameter("idPedido");
        String nuevoEst = req.getParameter("estado");

        new PedidoDAO().cambiarEstado(idPedido, nuevoEst, obtenerAdminIdDeSesion(req));

        res.sendRedirect("admin-pedidos.jsp");
    }

    /** Busca el id del administrador logueado en la sesion actual, o null si no hay uno. */
    private Integer obtenerAdminIdDeSesion(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session != null && "admin".equals(session.getAttribute("rol"))) {
            String email = (String) session.getAttribute("usuario");
            if (email != null) {
                Administrador admin = new AdministradorDAO().buscarPorEmail(email);
                if (admin != null) return admin.getId();
            }
        }
        return null;
    }

    // ================================================================
    //  GET — pedidos del cliente logueado (JSON, para pedidos.jsp)
    // ================================================================
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");

        int clienteId = obtenerClienteIdDeSesion(request);
        List<Map<String, Object>> pedidosCliente = new PedidoDAO().listarPorCliente(clienteId);

        response.getWriter().print(construirJsonPedidos(pedidosCliente));
    }

    @SuppressWarnings("unchecked")
    private String construirJsonPedidos(List<Map<String, Object>> pedidos) {
        SimpleDateFormat fmtFecha = new SimpleDateFormat("dd/MM/yyyy");
        SimpleDateFormat fmtHora  = new SimpleDateFormat("hh:mm a", Locale.US);

        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < pedidos.size(); i++) {
            Map<String, Object> p = pedidos.get(i);
            if (i > 0) json.append(",");

            Object fechaObj = p.get("fecha");
            String fechaStr = "";
            String horaStr  = "";
            if (fechaObj instanceof Date) {
                fechaStr = fmtFecha.format((Date) fechaObj);
                horaStr  = fmtHora.format((Date) fechaObj);
            }

            json.append("{")
                .append("\"id\":\"").append(esc((String) p.get("id"))).append("\",")
                .append("\"fecha\":\"").append(esc(fechaStr)).append("\",")
                .append("\"hora\":\"").append(esc(horaStr)).append("\",")
                .append("\"estado\":\"").append(esc(capitalizar((String) p.get("estado")))).append("\",")
                .append("\"direccion\":\"").append(esc((String) p.get("direccion"))).append("\",")
                .append("\"pago\":\"").append(esc((String) p.get("pago"))).append("\",")
                .append("\"subtotal\":").append(p.get("subtotal")).append(",")
                .append("\"descuento\":").append(p.get("descuento")).append(",")
                .append("\"envio\":").append(p.get("envio")).append(",")
                .append("\"total\":").append(p.get("total")).append(",")
                .append("\"items\":").append(construirJsonItems((List<Map<String, Object>>) p.get("items")))
                .append("}");
        }
        json.append("]");
        return json.toString();
    }

    private String construirJsonItems(List<Map<String, Object>> items) {
        if (items == null) return "[]";
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < items.size(); i++) {
            Map<String, Object> it = items.get(i);
            if (i > 0) json.append(",");
            json.append("{")
                .append("\"nombre\":\"").append(esc((String) it.get("nombre"))).append("\",")
                .append("\"img\":\"").append(esc((String) it.get("img"))).append("\",")
                .append("\"qty\":").append(it.get("qty")).append(",")
                .append("\"precio\":").append(it.get("precio"))
                .append("}");
        }
        json.append("]");
        return json.toString();
    }

    /** PENDIENTE -> Pendiente (la BD guarda mayusculas, el frontend de pedidos.jsp espera Capitalizado). */
    private String capitalizar(String estado) {
        if (estado == null || estado.isEmpty()) return "Pendiente";
        return estado.substring(0, 1).toUpperCase() + estado.substring(1).toLowerCase();
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}