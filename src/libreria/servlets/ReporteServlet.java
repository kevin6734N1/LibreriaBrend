package libreria.servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import libreria.dao.PedidoDAO;

import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * ReporteServlet - Libreria Brenda
 * Expone en JSON los datos que reportes.jsp necesita para pintar los
 * graficos con Chart.js: stats, ventas por dia, pedidos por estado,
 * ventas por categoria, top productos, top clientes y clientes nuevos.
 *
 * Se serializa el JSON a mano (sin Gson/Jackson) para no depender de
 * librerias externas adicionales en el proyecto.
 *
 * Endpoint: GET /ReporteServlet?periodo=semana|mes|trimestre|anio
 */
@WebServlet("/ReporteServlet")
public class ReporteServlet extends HttpServlet {

    private final PedidoDAO pedidoDAO = new PedidoDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");

        String periodo = request.getParameter("periodo");
        if (periodo == null) periodo = "mes";

        String fechaInicio = calcularFechaInicio(periodo);

        Map<String, Object> stats        = pedidoDAO.obtenerStats(fechaInicio);
        List<Map<String,Object>> ventas  = pedidoDAO.ventasPorDia(fechaInicio);
        List<Map<String,Object>> estados = pedidoDAO.pedidosPorEstado();
        List<Map<String,Object>> cats    = pedidoDAO.ventasPorCategoria();
        List<Map<String,Object>> topProd = pedidoDAO.topProductos(5);
        List<Map<String,Object>> topCli  = pedidoDAO.topClientes(5);
        List<Map<String,Object>> clisMes = pedidoDAO.clientesNuevosPorMes();

        StringBuilder json = new StringBuilder();
        json.append("{");
        json.append("\"stats\":").append(mapAJson(stats)).append(",");
        json.append("\"ventasPorDia\":").append(listaAJsonArray(ventas, "dia", "total")).append(",");
        json.append("\"pedidosPorEstado\":").append(listaAJsonArray(estados, "estado", "cantidad")).append(",");
        json.append("\"ventasPorCategoria\":").append(listaAJsonArray(cats, "categoria", "ingresos")).append(",");
        json.append("\"topProductos\":").append(topProductosAJson(topProd)).append(",");
        json.append("\"topClientes\":").append(topClientesAJson(topCli)).append(",");
        json.append("\"clientesNuevosPorMes\":").append(listaAJsonArray(clisMes, "mes", "cantidad"));
        json.append("}");

        try (PrintWriter out = response.getWriter()) {
            out.print(json.toString());
        }
    }

    /** Calcula la fecha de inicio segun el periodo seleccionado (formato yyyy-MM-dd). */
    private String calcularFechaInicio(String periodo) {
        Calendar cal = Calendar.getInstance();
        switch (periodo) {
            case "semana":     cal.add(Calendar.DAY_OF_MONTH, -7); break;
            case "trimestre":  cal.add(Calendar.MONTH, -3);        break;
            case "anio":       cal.add(Calendar.YEAR, -1);         break;
            case "mes":
            default:           cal.add(Calendar.MONTH, -1);        break;
        }
        SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd");
        return fmt.format(cal.getTime());
    }

    // =================================================================
    //  HELPERS DE SERIALIZACION JSON (manual, sin librerias externas)
    // =================================================================

    private String mapAJson(Map<String, Object> m) {
        StringBuilder sb = new StringBuilder("{");
        int i = 0;
        for (Map.Entry<String, Object> e : m.entrySet()) {
            if (i++ > 0) sb.append(",");
            sb.append("\"").append(e.getKey()).append("\":").append(valorAJson(e.getValue()));
        }
        sb.append("}");
        return sb.toString();
    }

    /** Convierte una lista de mapas de 2 campos (label,valor) en un array JSON simple. */
    private String listaAJsonArray(List<Map<String, Object>> lista, String campoLabel, String campoValor) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < lista.size(); i++) {
            if (i > 0) sb.append(",");
            Map<String, Object> m = lista.get(i);
            sb.append("{\"label\":\"").append(escapar(String.valueOf(m.get(campoLabel)))).append("\",")
              .append("\"valor\":").append(valorAJson(m.get(campoValor))).append("}");
        }
        sb.append("]");
        return sb.toString();
    }

    private String topProductosAJson(List<Map<String, Object>> lista) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < lista.size(); i++) {
            if (i > 0) sb.append(",");
            Map<String, Object> m = lista.get(i);
            sb.append("{\"nombre\":\"").append(escapar(String.valueOf(m.get("nombre")))).append("\",")
              .append("\"unidades\":").append(valorAJson(m.get("unidades"))).append(",")
              .append("\"ingresos\":").append(valorAJson(m.get("ingresos"))).append("}");
        }
        sb.append("]");
        return sb.toString();
    }

    private String topClientesAJson(List<Map<String, Object>> lista) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < lista.size(); i++) {
            if (i > 0) sb.append(",");
            Map<String, Object> m = lista.get(i);
            sb.append("{\"nombre\":\"").append(escapar(String.valueOf(m.get("nombre")))).append("\",")
              .append("\"pedidos\":").append(valorAJson(m.get("pedidos"))).append(",")
              .append("\"gastado\":").append(valorAJson(m.get("gastado"))).append("}");
        }
        sb.append("]");
        return sb.toString();
    }

    private String valorAJson(Object v) {
        if (v == null) return "0";
        if (v instanceof Number) return String.valueOf(v);
        return "\"" + escapar(String.valueOf(v)) + "\"";
    }

    private String escapar(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
