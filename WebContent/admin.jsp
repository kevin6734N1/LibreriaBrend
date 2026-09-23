<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, libreria.dao.PedidoDAO, libreria.dao.ClienteDAO" %>
<%
    PedidoDAO pedidoDAO = new PedidoDAO();
    ClienteDAO clienteDAO = new ClienteDAO();

    // Stats: pedidos de hoy y del mes, ventas del dia, clientes totales
    String hoy = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    String inicioMes = hoy.substring(0, 8) + "01";

    Map<String, Object> statsHoy  = pedidoDAO.obtenerStats(hoy);
    Map<String, Object> statsMes  = pedidoDAO.obtenerStats(inicioMes);

    int pedidosHoy      = statsHoy.get("pedidos")  != null ? ((Number) statsHoy.get("pedidos")).intValue()   : 0;
    double ventasHoy    = statsHoy.get("ingresos") != null ? ((Number) statsHoy.get("ingresos")).doubleValue() : 0;
    int totalClientes   = clienteDAO.listarTodos().size();

    // Contar pedidos pendientes de todos los tiempos
    List<Map<String, Object>> estadosPedido = pedidoDAO.pedidosPorEstado();
    int pedidosPendientes = 0;
    for (Map<String, Object> ep : estadosPedido) {
        if ("PENDIENTE".equals(ep.get("estado"))) {
            pedidosPendientes = ((Number) ep.get("cantidad")).intValue();
            break;
        }
    }

    // Ultimos 5 pedidos
    List<Map<String, Object>> todosPedidos = pedidoDAO.listarTodos();
    List<Map<String, Object>> recientes = todosPedidos.subList(0, Math.min(5, todosPedidos.size()));
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Panel Admin | Libreria Brenda</title>
  <link rel="stylesheet" href="css/style.css">
  <style>
    .icon-img      { width: 24px; height: 24px; vertical-align: middle; margin-right: 8px; }
    .stat-icon-img { width: 48px; height: 48px; margin-bottom: 8px; }
  </style>
</head>
<body>

<div class="admin-layout">

  <!-- SIDEBAR -->
  <aside class="sidebar">
    <div class="sb-logo">
      <img src="images/libro-logo.png" class="icon-img" style="width:28px;height:28px;" alt="Logo">
      Libreria Brenda<br>
      <span style="font-size:0.7rem;opacity:0.6;font-weight:400;">Panel de Administracion</span>
    </div>
    <nav>
      <a href="admin.jsp" class="active">
        <img src="images/dashboard.png" class="icon-img" alt="Dashboard"> Dashboard
      </a>
      <a href="admin-pedidos.jsp">
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
      <a href="index.jsp" style="margin-top:30px;border-top:1px solid rgba(255,255,255,0.1);">
        <img src="images/tienda.png" class="icon-img" alt="Tienda"> Ver tienda
      </a>
      <a href="LogoutServlet">
        <img src="images/logout.png" class="icon-img" alt="Cerrar sesion"> Cerrar sesion
      </a>
    </nav>
  </aside>

  <!-- MAIN -->
  <main class="admin-main">

    <!-- TOP BAR -->
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;">
      <h2 style="font-family:'Nunito',sans-serif;font-weight:900;font-size:1.4rem;">Dashboard</h2>
      <div style="display:flex;align-items:center;gap:10px;font-size:0.88rem;color:#555;">
        <img src="images/usuario.png" style="width:28px;height:28px;" alt="">
        <span><%= session.getAttribute("adminNombre") != null ? session.getAttribute("adminNombre") : "Admin" %></span>
        <span style="background:#1259C3;color:white;padding:4px 10px;border-radius:20px;font-size:0.75rem;font-weight:700;">ADMIN</span>
      </div>
    </div>

    <!-- STATS desde la BD -->
    <div class="stats-grid">
      <div class="stat-card">
        <img src="images/pedidos.png" class="stat-icon-img" alt="Pedidos">
        <div class="stat-num"><%= pedidosHoy %></div>
        <div class="stat-label">Pedidos hoy</div>
      </div>
      <div class="stat-card">
        <img src="images/pendiente.png" class="stat-icon-img" alt="Pendientes">
        <div class="stat-num" style="color:#856404;"><%= pedidosPendientes %></div>
        <div class="stat-label">Pedidos pendientes</div>
      </div>
      <div class="stat-card">
        <img src="images/ventas.png" class="stat-icon-img" alt="Ventas">
        <div class="stat-num" style="color:#00A650;">S/<%= String.format("%,.2f", ventasHoy) %></div>
        <div class="stat-label">Ventas del dia</div>
      </div>
      <div class="stat-card">
        <img src="images/clientes.png" class="stat-icon-img" alt="Clientes">
        <div class="stat-num"><%= totalClientes %></div>
        <div class="stat-label">Clientes registrados</div>
      </div>
    </div>

    <!-- PEDIDOS RECIENTES desde la BD -->
    <h3 style="font-family:'Nunito',sans-serif;font-weight:800;margin-bottom:12px;">Pedidos recientes</h3>
    <div class="admin-table-wrap">
      <table>
        <thead>
          <tr>
            <th>N Pedido</th>
            <th>Cliente</th>
            <th>Fecha</th>
            <th>Total</th>
            <th>Estado</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <% if (recientes.isEmpty()) { %>
            <tr>
              <td colspan="6" style="text-align:center;padding:30px;color:#999;">
                No hay pedidos registrados aun.
              </td>
            </tr>
          <% } else {
              for (Map<String, Object> p : recientes) {
                String estado    = String.valueOf(p.get("estado"));
                String estadoCss = estado.toLowerCase();
                String cliente   = p.get("cliente") != null ? String.valueOf(p.get("cliente")) : "-";
                String fecha     = p.get("fecha")   != null ? String.valueOf(p.get("fecha")).substring(0, 10) : "-";
                String idPed     = String.valueOf(p.get("id"));
                double total     = p.get("total") != null ? ((Number) p.get("total")).doubleValue() : 0;

                // Capitalizar estado para mostrar (PENDIENTE -> Pendiente)
                String estadoDisplay = estado.length() > 0
                    ? estado.charAt(0) + estado.substring(1).toLowerCase()
                    : estado;
          %>
            <tr>
              <td><strong><%= idPed %></strong></td>
              <td><%= cliente %></td>
              <td><%= fecha %></td>
              <td>S/ <%= String.format("%.2f", total) %></td>
              <td>
                <span class="badge-estado estado-<%= estadoCss %>">
                  <%= estadoDisplay %>
                </span>
              </td>
              <td>
                <a href="admin-pedidos.jsp"
                   style="background:none;border:1px solid #1259C3;color:#1259C3;padding:4px 10px;
                          border-radius:6px;font-size:0.8rem;font-family:Lato,sans-serif;
                          font-weight:700;text-decoration:none;">
                  Ver pedidos
                </a>
              </td>
            </tr>
          <% } } %>
        </tbody>
      </table>
    </div>

  </main>
</div>

</body>
</html>
