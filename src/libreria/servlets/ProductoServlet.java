package libreria.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import libreria.dao.CategoriaInvalidaException;
import libreria.dao.ProductoDAO;
import libreria.models.Producto;
import libreria.util.ValidadorProducto;

/**
 * ProductoServlet - Libreria Brenda
 *
 * GET  /ProductoServlet           -> JSON con todos los productos (para cargar la tabla)
 * POST /ProductoServlet accion=crear        -> valida e inserta producto nuevo
 * POST /ProductoServlet accion=editar       -> valida y actualiza producto existente
 * POST /ProductoServlet accion=toggleActivo -> invierte activo/inactivo
 * POST /ProductoServlet accion=eliminar     -> elimina producto
 *
 * Las reglas de validación (H0007 / tarea 5 del Sprint 2) viven en
 * ValidadorProducto y se aplican EN EL SERVIDOR para crear y editar:
 * si hay errores se responde HTTP 400 con {"ok":false,"error":...}
 * y el producto no llega a tocar la base de datos.
 */
@WebServlet("/ProductoServlet")
public class ProductoServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private final ProductoDAO dao = new ProductoDAO();

    // ================================================================
    //  GET — listar todos los productos como JSON
    // ================================================================
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");

        List<Producto> productos = dao.listarTodos();
        StringBuilder json = new StringBuilder("[");

        for (int i = 0; i < productos.size(); i++) {
            Producto p = productos.get(i);
            if (i > 0) json.append(",");
            json.append("{")
                .append("\"id\":").append(p.getId()).append(",")
                .append("\"nombre\":\"").append(esc(p.getNombre())).append("\",")
                .append("\"descripcion\":\"").append(esc(p.getDescripcion())).append("\",")
                .append("\"precio\":").append(p.getPrecio()).append(",")
                .append("\"stock\":").append(p.getStock()).append(",")
                .append("\"categoria\":\"").append(esc(p.getCategoria())).append("\",")
                .append("\"imagen\":\"").append(esc(p.getImagen())).append("\",")
                .append("\"etiqueta\":\"").append(esc(p.getEtiqueta())).append("\",")
                .append("\"activo\":").append(p.isActivo())
                .append("}");
        }

        json.append("]");
        response.getWriter().write(json.toString());
    }

    // ================================================================
    //  POST — crear / editar / toggleActivo / eliminar
    // ================================================================
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        String accion = request.getParameter("accion");
        PrintWriter out = response.getWriter();

        if ("crear".equals(accion)) {
            Producto p;
            try {
                p = leerProductoDeRequest(request);
            } catch (IllegalArgumentException formato) {
                response.setStatus(400);
                out.print("{\"ok\":false,\"error\":\"" + esc(formato.getMessage()) + "\"}");
                return;
            }
            List<String> errores = ValidadorProducto.validar(p);
            if (!errores.isEmpty()) {
                response.setStatus(400);
                out.print("{\"ok\":false,\"error\":\"" + esc(String.join(" | ", errores)) + "\"}");
                return;
            }
            try {
                int nuevoId = dao.crear(p);
                if (nuevoId > 0) {
                    out.print("{\"ok\":true,\"id\":" + nuevoId + "}");
                } else {
                    response.setStatus(500);
                    out.print("{\"ok\":false,\"error\":\"No se pudo crear el producto.\"}");
                }
            } catch (CategoriaInvalidaException categoria) {
                // No se asigna ninguna categoria "de respaldo" ni se escribe nada.
                response.setStatus(400);
                out.print("{\"ok\":false,\"error\":\"" + esc(categoria.getMessage()) + "\"}");
            }

        } else if ("editar".equals(accion)) {
            Producto p;
            try {
                p = leerProductoDeRequest(request);
            } catch (IllegalArgumentException formato) {
                response.setStatus(400);
                out.print("{\"ok\":false,\"error\":\"" + esc(formato.getMessage()) + "\"}");
                return;
            }
            List<String> errores = ValidadorProducto.validar(p);
            if (!errores.isEmpty()) {
                response.setStatus(400);
                out.print("{\"ok\":false,\"error\":\"" + esc(String.join(" | ", errores)) + "\"}");
                return;
            }
            try {
                p.setId(Integer.parseInt(request.getParameter("id")));
                boolean ok = dao.editar(p);
                if (ok) {
                    out.print("{\"ok\":true}");
                } else {
                    response.setStatus(404);
                    out.print("{\"ok\":false,\"error\":\"El producto no existe o no se pudo actualizar.\"}");
                }
            } catch (NumberFormatException idInvalido) {
                response.setStatus(400);
                out.print("{\"ok\":false,\"error\":\"El id del producto es inválido.\"}");
            } catch (CategoriaInvalidaException categoria) {
                response.setStatus(400);
                out.print("{\"ok\":false,\"error\":\"" + esc(categoria.getMessage()) + "\"}");
            }

        } else if ("toggleActivo".equals(accion) || "eliminar".equals(accion)) {
            int id;
            try {
                id = Integer.parseInt(request.getParameter("id"));
            } catch (NumberFormatException idInvalido) {
                response.setStatus(400);
                out.print("{\"ok\":false,\"error\":\"El id del producto es inválido.\"}");
                return;
            }
            boolean ok = "toggleActivo".equals(accion) ? dao.toggleActivo(id) : dao.eliminar(id);
            out.print("{\"ok\":" + ok + "}");

        } else {
            response.setStatus(400);
            out.print("{\"ok\":false,\"error\":\"Accion desconocida.\"}");
        }
    }

    // ================================================================
    //  HELPERS
    // ================================================================
    /**
     * Lee el formulario. Un valor no numerico se rechaza con
     * IllegalArgumentException (HTTP 400) en vez de convertirse a 0: para el
     * stock, 0 es un valor VALIDO, asi que "stock=abc" no puede terminar
     * guardado como stock 0 (QA-10 / IT-05).
     */
    private Producto leerProductoDeRequest(HttpServletRequest req) {
        Producto p = new Producto();
        p.setNombre(req.getParameter("nombre"));
        p.setDescripcion(req.getParameter("descripcion"));
        p.setCategoria(req.getParameter("categoria"));
        p.setImagen(req.getParameter("imagen") != null && !req.getParameter("imagen").isEmpty()
                    ? req.getParameter("imagen") : "images/productos.png");
        p.setEtiqueta(req.getParameter("etiqueta"));

        String precioStr = req.getParameter("precio");
        if (precioStr == null || precioStr.trim().isEmpty()) {
            throw new IllegalArgumentException("El precio es obligatorio.");
        }
        try {
            p.setPrecio(Double.parseDouble(precioStr.trim()));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("El precio debe ser un número válido.");
        }

        String stockStr = req.getParameter("stock");
        if (stockStr == null || stockStr.trim().isEmpty()) {
            throw new IllegalArgumentException("El stock es obligatorio.");
        }
        try {
            p.setStock(Integer.parseInt(stockStr.trim()));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("El stock debe ser un número entero válido.");
        }

        return p;
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
