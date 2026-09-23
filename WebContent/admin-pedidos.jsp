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
  <style>
    .icon-img { width: 24px; height: 24px; vertical-align: middle; margin-right: 8px; }
    .form-estado { display: flex; gap: 6px; align-items: center; }
    .form-estado select {
      padding: 5px 8px; border-radius: 6px; border: 1.5px solid #ddd;
      font-family: 'Lato', sans-serif; font-size: 0.82rem;
    }
    .form-estado button {
      background: #1259C3; color: white; border: none; padding: 6px 12px;
      border-radius: 6px; font-size: 0.8rem; font-weight: 700; cursor: pointer;
      font-family: 'Lato', sans-serif;
    }
    .form-estado button:hover { background: #0d47a1; }
  </style>
</head>
<body>

<div class="admin-layout">

  <!-- ===== SIDEBAR ===== -->
  <aside class="sidebar">
    <div class="sb-logo">
      <img src="images/libro-logo.png" class="icon-img" style="width:28px;height:28px;" alt="Logo">
      Librería Brenda<br>
      <span style="font-size:0.7rem;opacity:0.6;font-weight:400;">Panel de Administración</span>
    </div>
    <nav>
      <a href="admin.jsp">
        <img src="images/dashboard.png" class="icon-img" alt="Dashboard"> Dashboard
      </a>
      <a href="admin-pedidos.jsp" class="active">
        <img src="images/pedidos.png" class="icon-img" alt="Pedidos"> Pedidos
      </a>
      <a href="productos.jsp">
        <img src="images/productos.png" class="icon-img" alt="Productos"> Productos
      </a>
      <a href="clientes.jsp">
        <img src="images/clientes.png" class="icon-img" alt="Clientes"> Clientes
      </a>
      <a href="reportes.jsp">
        <img src="images/reportes.png" class="icon-img" alt="Reportes"> Reportes
      </a>
      <a href="index.jsp" style="margin-top:auto;border-top:1px solid rgba(255,255,255,0.1);margin-top:30px;">
        <img src="images/tienda.png" class="icon-img" alt="Tienda"> Ver tienda
      </a>
      <a href="LogoutServlet">
        <img src="images/logout.png" class="icon-img" alt="Cerrar sesion"> Cerrar sesion
      </a>
    </nav>
  </aside>

  <!-- ===== MAIN ===== -->
  <main class="admin-main">

    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;">
      <h2 style="font-family:'Nunito',sans-serif;font-weight:900;font-size:1.4rem;">
        Pedidos (<%= pedidos.size() %>)
      </h2>
      <div style="display:flex;align-items:center;gap:10px;font-size:0.88rem;color:#555;">
        <span><img src="images/usuario.png" style="width:18px;height:18px;vertical-align:middle;margin-right:4px;" alt=""> <%= session.getAttribute("adminNombre") != null ? session.getAttribute("adminNombre") : "Admin" %></span>
        <span style="background:#1259C3;color:white;padding:4px 10px;border-radius:20px;font-size:0.75rem;font-weight:700;">ADMIN</span>
      </div>
    </div>

    <div class="admin-table-wrap">
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
            <tr><td colspan="9" style="text-align:center;color:#888;padding:30px;">Todavía no hay pedidos registrados.</td></tr>
          <% } %>
          <% for (Map<String, Object> p : pedidos) {
               String estadoActual = String.valueOf(p.get("estado")); // PENDIENTE, CONFIRMADO, etc (mayusculas, como en la DB)
               String claseCss = estadoActual.toLowerCase();
               Comprobante comp = comprobanteDAO.buscarPorPedido(String.valueOf(p.get("id")));
          %>
          <tr>
            <td><strong><%= p.get("id") %></strong></td>
            <td><%= p.get("cliente") %></td>
            <td><%= p.get("fecha") %></td>
            <td><%= p.get("direccion") %></td>
            <td><%= p.get("pago") != null ? p.get("pago") : "-" %></td>
            <td>S/ <%= String.format("%.2f", (Double) p.get("total")) %></td>
            <td><span class="badge-estado estado-<%= claseCss %>"><%= estadoActual %></span></td>
            <td>
              <% if (comp != null) { %>
                <span style="font-size:0.78rem;color:#1259C3;font-weight:700;" title="Emitido por <%= comp.getAdministradorNombre() != null ? comp.getAdministradorNombre() : "—" %>">
                  <%= comp.getNumeroCompleto() %>
                </span>
              <% } else { %>
                <span style="font-size:0.78rem;color:#aaa;">— sin emitir —</span>
              <% } %>
            </td>
            <td>
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
