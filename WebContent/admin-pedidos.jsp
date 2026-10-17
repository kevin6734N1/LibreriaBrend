<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, libreria.dao.PedidoDAO, libreria.dao.ComprobanteDAO, libreria.models.Comprobante" %>
<%
  List<Map<String, Object>> pedidos = new PedidoDAO().listarTodos();
  ComprobanteDAO comprobanteDAO = new ComprobanteDAO();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pedidos | Panel Admin | Librería Brenda</title>
  <link rel="stylesheet" href="css/style.css">
  <link rel="stylesheet" href="css/admin.css">
</head>
<body>

<div class="admin-layout">

  <!-- ===== SIDEBAR ===== -->
  <%@ include file="/WEB-INF/jspf/admin-sidebar.jspf" %>

  <!-- ===== MAIN ===== -->
  <main class="admin-main">

    <div class="topbar">
      <h2>
        <img src="images/pedidos.png" alt="">
        Pedidos (<%= pedidos.size() %>)
      </h2>
      <div class="topbar-right">
        <img src="images/usuario.png" style="width:28px;height:28px;" alt="">
        <span><%= session.getAttribute("adminNombre") != null ? session.getAttribute("adminNombre") : "Admin" %></span>
        <span class="badge-admin">ADMIN</span>
      </div>
    </div>

    <div class="admin-table-wrap admin-table-wide tabla-cards">
      <table>
        <thead>
          <tr>
            <th>N° Pedido</th>
            <th>Cliente</th>
            <th>Fecha</th>
            <th>Dirección</th>
            <th>Pago</th>
            <th>Total</th>
            <th>Estado</th>
            <th>Comprobante</th>
            <th>Cambiar estado</th>
          </tr>
        </thead>
        <tbody>
          <% if (pedidos.isEmpty()) { %>
            <tr><td colspan="9" class="celda-vacia" style="text-align:center;color:#888;padding:30px;">Todavía no hay pedidos registrados.</td></tr>
          <% } %>
          <% for (Map<String, Object> p : pedidos) {
               String estadoActual = String.valueOf(p.get("estado")); // PENDIENTE, CONFIRMADO, etc (mayusculas, como en la DB)
               String claseCss = estadoActual.toLowerCase();
               Comprobante comp = comprobanteDAO.buscarPorPedido(String.valueOf(p.get("id")));
          %>
          <tr>
            <td data-label="N° pedido"><strong><%= p.get("id") %></strong></td>
            <td data-label="Cliente"><%= p.get("cliente") %></td>
            <td data-label="Fecha"><%= p.get("fecha") %></td>
            <td data-label="Dirección"><%= p.get("direccion") %></td>
            <td data-label="Pago"><%= p.get("pago") != null ? p.get("pago") : "-" %></td>
            <td class="celda-nowrap" data-label="Total">S/ <%= String.format("%.2f", (Double) p.get("total")) %></td>
            <td data-label="Estado"><span class="badge-estado estado-<%= claseCss %>"><%= estadoActual %></span></td>
            <td data-label="Comprobante">
              <% if (comp != null) { %>
                <span class="celda-nowrap" style="font-size:0.78rem;color:var(--azul);font-weight:700;" title="Emitido por <%= comp.getAdministradorNombre() != null ? comp.getAdministradorNombre() : "—" %>">
                  <%= comp.getNumeroCompleto() %>
                </span>
              <% } else { %>
                <span class="celda-nowrap" style="font-size:0.78rem;color:#aaa;">— sin emitir —</span>
              <% } %>
            </td>
            <td class="celda-acciones" data-label="Cambiar estado">
              <form class="form-estado" method="post" action="PedidoServlet">
                <input type="hidden" name="accion" value="cambiarEstado">
                <input type="hidden" name="idPedido" value="<%= p.get("id") %>">
                <select name="estado">
                  <option value="PENDIENTE"  <%= estadoActual.equals("PENDIENTE")  ? "selected" : "" %>>Pendiente</option>
                  <option value="CONFIRMADO" <%= estadoActual.equals("CONFIRMADO") ? "selected" : "" %>>Confirmado</option>
                  <option value="ENVIADO"    <%= estadoActual.equals("ENVIADO")    ? "selected" : "" %>>Enviado</option>
                  <option value="ENTREGADO"  <%= estadoActual.equals("ENTREGADO")  ? "selected" : "" %>>Entregado</option>
                  <option value="CANCELADO"  <%= estadoActual.equals("CANCELADO")  ? "selected" : "" %>>Cancelado</option>
                </select>
                <button type="submit">Guardar</button>
              </form>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>

  </main>
</div>

</body>
</html>
