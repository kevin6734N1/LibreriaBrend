<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Clientes | Libreria Brenda Admin</title>
  <link rel="stylesheet" href="css/style.css">
  <style>
    .icon-img { width: 24px; height: 24px; vertical-align: middle; margin-right: 6px; }

    .admin-layout { display: flex; min-height: 100vh; }

    .sidebar {
      width: 220px; min-width: 220px; background: #1259C3;
      display: flex; flex-direction: column; padding: 20px 0;
      position: sticky; top: 0; height: 100vh; overflow-y: auto;
    }
    .sb-logo {
      padding: 0 20px 24px; font-family: 'Nunito', sans-serif;
      font-weight: 900; font-size: 1.05rem; color: white;
      border-bottom: 1px solid rgba(255,255,255,0.15); margin-bottom: 10px;
    }
    .sidebar nav a {
      display: flex; align-items: center; padding: 11px 20px;
      color: rgba(255,255,255,0.75); text-decoration: none;
      font-size: 0.9rem; font-weight: 700; transition: all 0.18s;
    }
    .sidebar nav a:hover, .sidebar nav a.active {
      background: rgba(255,255,255,0.15); color: white;
    }
    .sidebar nav a img { filter: brightness(5); opacity: 0.8; }
    .sidebar nav a.active img, .sidebar nav a:hover img { opacity: 1; }
    .sidebar-sep { border: none; border-top: 1px solid rgba(255,255,255,0.12); margin: 10px 20px; }

    .admin-main { flex: 1; background: #EDEDED; padding: 28px; overflow: auto; }

    .topbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
    .topbar h2 { font-family: 'Nunito', sans-serif; font-weight: 900; font-size: 1.4rem; }
    .topbar-right { display: flex; align-items: center; gap: 10px; font-size: 0.88rem; color: #555; }
    .badge-admin { background: #1259C3; color: white; padding: 4px 10px; border-radius: 20px; font-size: 0.75rem; font-weight: 700; }

    .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px,1fr)); gap: 14px; margin-bottom: 24px; }
    .stat-card  { background: white; border-radius: 8px; padding: 18px 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.10); }
    .stat-card img { width: 40px; height: 40px; margin-bottom: 8px; }
    .stat-num   { font-family: 'Nunito', sans-serif; font-size: 1.9rem; font-weight: 900; color: #1259C3; }
    .stat-label { font-size: 0.80rem; color: #666; margin-top: 2px; }

    .toolbar {
      display: flex; gap: 10px; align-items: center; flex-wrap: wrap;
      background: white; border-radius: 8px; padding: 14px 18px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 18px;
    }
    .toolbar input[type=text] {
      flex: 1; min-width: 180px; padding: 9px 14px; border: 1.5px solid #e0e0e0;
      border-radius: 8px; font-family: 'Lato', sans-serif; font-size: 0.9rem; outline: none;
    }
    .toolbar input[type=text]:focus { border-color: #1259C3; }
    .toolbar select {
      padding: 9px 14px; border: 1.5px solid #e0e0e0; border-radius: 8px;
      font-family: 'Lato', sans-serif; font-size: 0.88rem; outline: none; background: white;
    }
    .contador-tabla { font-size: 0.82rem; color: #666; margin-left: auto; }
    .btn-exportar {
      background: none; border: 1.5px solid #1259C3; color: #1259C3;
      padding: 9px 18px; border-radius: 8px; font-weight: 700; cursor: pointer;
      font-family: 'Lato', sans-serif; font-size: 0.88rem; white-space: nowrap;
      transition: all 0.18s; display: flex; align-items: center; gap: 6px;
    }
    .btn-exportar:hover { background: #1259C3; color: white; }

    .admin-table-wrap { background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); overflow: hidden; }
    .admin-table-wrap table { width: 100%; border-collapse: collapse; }
    .admin-table-wrap th {
      background: #F5F5F5; padding: 12px 16px; text-align: left;
      font-size: 0.78rem; font-weight: 700; text-transform: uppercase;
      letter-spacing: 0.5px; color: #666; white-space: nowrap; cursor: pointer;
      user-select: none;
    }
    .admin-table-wrap th:hover { color: #1259C3; }
    .admin-table-wrap th .sort-arrow { font-size: 0.7rem; opacity: 0.5; margin-left: 3px; }
    .admin-table-wrap td { padding: 12px 16px; font-size: 0.88rem; border-bottom: 1px solid #F0F0F0; vertical-align: middle; }
    .admin-table-wrap tr:last-child td { border-bottom: none; }
    .admin-table-wrap tr:hover td { background: rgba(18,89,195,0.03); }

    .cliente-avatar {
      width: 38px; height: 38px; border-radius: 50%;
      background: #1259C3; color: white; display: flex; align-items: center; justify-content: center;
      font-weight: 700; font-size: 0.9rem; font-family: 'Nunito', sans-serif;
    }
    .cliente-nombre-wrap { display: flex; align-items: center; gap: 10px; }
    .cliente-nombre { font-weight: 700; font-size: 0.9rem; }
    .cliente-dni { font-size: 0.78rem; color: #888; }

    .badge-pedidos {
      background: #EEF2FF; color: #1259C3; padding: 3px 12px;
      border-radius: 12px; font-size: 0.82rem; font-weight: 700;
    }
    .badge-vip { background: #FFF3CD; color: #856404; padding: 2px 8px; border-radius: 10px; font-size: 0.68rem; font-weight: 700; margin-left: 6px; }
    .badge-activo   { background: #D4EDDA; color: #155724; padding: 3px 10px; border-radius: 12px; font-size: 0.75rem; font-weight: 700; }
    .badge-inactivo { background: #F8D7DA; color: #721c24; padding: 3px 10px; border-radius: 12px; font-size: 0.75rem; font-weight: 700; }

    .btn-accion {
      border: none; padding: 5px 12px; border-radius: 6px; cursor: pointer;
      font-size: 0.78rem; font-weight: 700; font-family: 'Lato', sans-serif; transition: all 0.15s;
    }
    .btn-ver     { background: #EEF2FF; color: #1259C3; border: 1px solid #1259C3; }
    .btn-ver:hover { background: #1259C3; color: white; }

    .sin-resultados { text-align: center; padding: 50px 20px; color: #999; font-size: 0.9rem; }
    .sin-resultados img { width: 60px; opacity: 0.4; margin-bottom: 10px; display: block; margin-left: auto; margin-right: auto; }

    /* Modal detalle cliente */
    .modal-overlay {
      display: none; position: fixed; inset: 0;
      background: rgba(0,0,0,0.5); z-index: 999; align-items: center; justify-content: center;
    }
    .modal-overlay.open { display: flex; }
    .modal-box {
      background: white; border-radius: 12px; padding: 28px;
      width: 90%; max-width: 540px; max-height: 85vh; overflow-y: auto;
      box-shadow: 0 10px 40px rgba(0,0,0,0.25); animation: fadeUp 0.2s ease;
    }
    @keyframes fadeUp { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    .modal-header h3 { font-family: 'Nunito', sans-serif; font-weight: 900; font-size: 1.2rem; }
    .btn-cerrar { background: none; border: none; font-size: 1.4rem; cursor: pointer; color: #666; line-height: 1; }

    .cliente-detalle-header { display: flex; align-items: center; gap: 14px; margin-bottom: 20px; padding-bottom: 16px; border-bottom: 1px solid #f0f0f0; }
    .cliente-avatar-lg {
      width: 60px; height: 60px; border-radius: 50%;
      background: #1259C3; color: white; display: flex; align-items: center; justify-content: center;
      font-weight: 700; font-size: 1.4rem; font-family: 'Nunito', sans-serif; flex-shrink: 0;
    }

    .modal-row { display: flex; justify-content: space-between; padding: 9px 0; font-size: 0.88rem; border-bottom: 1px solid #f5f5f5; }
    .modal-row:last-child { border-bottom: none; }
    .modal-label { color: #666; }
    .modal-value { font-weight: 700; text-align: right; }

    .seccion-subtitulo { font-size: 0.78rem; font-weight: 700; color: #555; text-transform: uppercase; letter-spacing: .5px; margin: 18px 0 8px; }

    .mini-pedido-row {
      display: flex; justify-content: space-between; align-items: center;
      padding: 9px 0; font-size: 0.84rem; border-bottom: 1px solid #f5f5f5;
    }
    .mini-pedido-row:last-child { border-bottom: none; }

    @media (max-width: 768px) {
      .admin-layout { flex-direction: column; }
      .sidebar { width: 100%; height: auto; position: static; flex-direction: row; flex-wrap: wrap; padding: 10px; }
    }
  </style>
</head>
<body>
<div class="admin-layout">

  <!-- ===== SIDEBAR ===== -->
  <aside class="sidebar">
    <div class="sb-logo">
      <img src="images/libro-logo.png" style="width:26px;height:26px;vertical-align:middle;filter:brightness(10);margin-right:8px;" alt="">
      Libreria Brenda
      <div style="font-size:0.7rem;opacity:0.6;font-weight:400;margin-top:2px;">Panel de Administracion</div>
    </div>
    <nav>
      <a href="admin.jsp">
        <img src="images/dashboard.png" class="icon-img"> Dashboard
      </a>
      <a href="pedidos.jsp">
        <img src="images/pedidos.png" class="icon-img"> Pedidos
      </a>
      <a href="productos.jsp">
        <img src="images/productos.png" class="icon-img"> Productos
      </a>
      <a href="clientes.jsp" class="active">
        <img src="images/clientes.png" class="icon-img"> Clientes
      </a>
      <a href="reportes.jsp">
        <img src="images/reportes.png" class="icon-img"> Reportes
      </a>
      <hr class="sidebar-sep">
      <a href="index.jsp">
        <img src="images/tienda.png" class="icon-img"> Ver tienda
      </a>
      <a href="LogoutServlet">
        <img src="images/logout.png" class="icon-img"> Cerrar sesion
      </a>
    </nav>
  </aside>

  <!-- ===== MAIN ===== -->
  <main class="admin-main">

    <div class="topbar">
      <h2>
        <img src="images/clientes.png" style="width:28px;height:28px;vertical-align:middle;margin-right:8px;" alt="">
        Clientes Registrados
      </h2>
      <div class="topbar-right">
        <img src="images/usuario.png" style="width:28px;height:28px;" alt="">
        <span><%= session.getAttribute("adminNombre") != null ? session.getAttribute("adminNombre") : "Admin" %></span>
        <span class="badge-admin">ADMIN</span>
      </div>
    </div>

    <!-- Stats -->
    <div class="stats-grid">
      <div class="stat-card">
        <img src="images/clientes.png" alt="">
        <div class="stat-num" id="stat-total">0</div>
        <div class="stat-label">Total clientes</div>
      </div>
      <div class="stat-card">
        <img src="images/check.png" alt="">
        <div class="stat-num" id="stat-activos" style="color:#00A650;">0</div>
        <div class="stat-label">Clientes activos</div>
      </div>
      <div class="stat-card">
        <img src="images/pedidos.png" alt="">
        <div class="stat-num" id="stat-con-pedidos" style="color:#1259C3;">0</div>
        <div class="stat-label">Con pedidos realizados</div>
      </div>
      <div class="stat-card">
        <img src="images/ventas.png" alt="">
        <div class="stat-num" id="stat-nuevos-mes" style="color:#856404;">0</div>
        <div class="stat-label">Nuevos este mes</div>
      </div>
    </div>

    <!-- Toolbar -->
    <div class="toolbar">
      <input type="text" id="buscador" placeholder="Buscar por nombre, DNI o correo..." oninput="renderTabla()">
      <select id="filtro-estado" onchange="renderTabla()">
        <option value="">Todos los estados</option>
        <option value="activo">Activo</option>
        <option value="inactivo">Inactivo</option>
      </select>
      <select id="orden-campo" onchange="renderTabla()">
        <option value="nombre">Ordenar: Nombre</option>
        <option value="fecha">Ordenar: Fecha registro</option>
        <option value="pedidos">Ordenar: N de pedidos</option>
        <option value="gastado">Ordenar: Total gastado</option>
      </select>
      <span class="contador-tabla" id="contador-tabla"></span>
      <button class="btn-exportar" onclick="exportarCSV()">
        &#128190; Exportar CSV
      </button>
    </div>

    <!-- Tabla -->
    <div class="admin-table-wrap">
      <table>
        <thead>
          <tr>
            <th>Cliente</th>
            <th>Correo</th>
            <th>Telefono</th>
            <th>Pedidos</th>
            <th>Total gastado</th>
            <th>Registro</th>
            <th>Estado</th>
            <th style="width:90px;">Accion</th>
          </tr>
        </thead>
        <tbody id="tbody-clientes">
          <tr><td colspan="8" style="text-align:center;padding:30px;color:#999;">Cargando...</td></tr>
        </tbody>
      </table>
    </div>

  </main>
</div>

<!-- ===== MODAL DETALLE CLIENTE ===== -->
<div class="modal-overlay" id="modal-cliente" onclick="cerrarModalClick(event)">
  <div class="modal-box">
    <div class="modal-header">
      <h3>Detalle del Cliente</h3>
      <button class="btn-cerrar" onclick="cerrarModal()">&#10005;</button>
    </div>

    <div class="cliente-detalle-header">
      <div class="cliente-avatar-lg" id="det-avatar">--</div>
      <div>
        <div style="font-weight:800;font-size:1.05rem;" id="det-nombre">--</div>
        <div style="color:#888;font-size:0.85rem;" id="det-dni">--</div>
      </div>
    </div>

    <div class="seccion-subtitulo">Informacion de contacto</div>
    <div id="det-info"></div>

    <div class="seccion-subtitulo">Resumen de compras</div>
    <div id="det-resumen"></div>

    <div class="seccion-subtitulo">Ultimos pedidos</div>
    <div id="det-pedidos"></div>

  </div>
</div>

<script>
  // ================================================================
  //  DATOS DEMO — reemplazar por fetch a ClienteServlet cuando
  //  este conectado a MySQL. Campos alineados con registro.jsp:
  //  nombres, apellidos, dni, email, telefono, direccion
  // ================================================================
  var clientes = [
    { id:1, nombres:'Maria',   apellidos:'Garcia Lopez',   dni:'45678901', email:'maria.garcia@email.com',   telefono:'945123456', direccion:'Av. Arequipa 1234, Miraflores',  fechaRegistro:'2026-01-05', pedidos:5, totalGastado:412.30, activo:true },
    { id:2, nombres:'Carlos',  apellidos:'Mendoza Ruiz',   dni:'41234567', email:'carlos.mendoza@email.com', telefono:'987654321', direccion:'Jr. Huancayo 567, Brena',        fechaRegistro:'2026-02-12', pedidos:3, totalGastado:198.50, activo:true },
    { id:3, nombres:'Ana',     apellidos:'Torres Vega',    dni:'47891234', email:'ana.torres@email.com',     telefono:'912345678', direccion:'Calle Los Pinos 890, Surco',     fechaRegistro:'2026-03-01', pedidos:1, totalGastado:72.50,  activo:true },
    { id:4, nombres:'Luis',    apellidos:'Rojas Fernandez',dni:'44567890', email:'luis.rojas@email.com',     telefono:'998877665', direccion:'Av. La Marina 345, San Miguel',  fechaRegistro:'2026-03-18', pedidos:2, totalGastado:108.90, activo:true },
    { id:5, nombres:'Rosa',    apellidos:'Paredes Quispe', dni:'43210987', email:'rosa.paredes@email.com',   telefono:'934567890', direccion:'Jr. Tacna 201, Cercado de Lima', fechaRegistro:'2026-04-02', pedidos:1, totalGastado:120.00, activo:false },
    { id:6, nombres:'Jorge',   apellidos:'Salazar Vidal',  dni:'48765432', email:'jorge.salazar@email.com',  telefono:'956789012', direccion:'Av. Brasil 880, Pueblo Libre',   fechaRegistro:'2026-04-20', pedidos:7, totalGastado:589.40, activo:true },
    { id:7, nombres:'Patricia',apellidos:'Nunez Castro',   dni:'42345678', email:'patricia.nunez@email.com', telefono:'923456789', direccion:'Calle Las Flores 45, San Borja', fechaRegistro:'2026-05-10', pedidos:0, totalGastado:0.00,   activo:true },
    { id:8, nombres:'Diego',   apellidos:'Ramos Herrera',  dni:'46789012', email:'diego.ramos@email.com',    telefono:'967890123', direccion:'Av. Angamos 1200, Surquillo',    fechaRegistro:'2026-05-28', pedidos:2, totalGastado:145.80, activo:true },
    { id:9, nombres:'Valeria', apellidos:'Chavez Morales', dni:'49012345', email:'valeria.chavez@email.com', telefono:'978901234', direccion:'Jr. Cusco 310, La Victoria',     fechaRegistro:'2026-06-03', pedidos:1, totalGastado:65.00,  activo:true },
    { id:10,nombres:'Fernando',apellidos:'Vargas Soto',    dni:'40123456', email:'fernando.vargas@email.com',telefono:'945678901', direccion:'Av. Colonial 500, Callao',      fechaRegistro:'2026-06-10', pedidos:0, totalGastado:0.00,   activo:false }
  ];

  // Mini historial de pedidos por cliente (demo) usado en el modal
  var pedidosPorCliente = {
    1: [ { id:'PED-1001', fecha:'10/05/2026', total:115.40, estado:'Entregado' }, { id:'PED-0892', fecha:'02/03/2026', total:89.90,  estado:'Entregado' } ],
    2: [ { id:'PED-1002', fecha:'15/05/2026', total:65.00,  estado:'Enviado' } ],
    3: [ { id:'PED-1003', fecha:'17/05/2026', total:72.50,  estado:'Pendiente' } ],
    4: [ { id:'PED-1004', fecha:'18/05/2026', total:70.90,  estado:'Confirmado' } ],
    5: [ { id:'PED-1005', fecha:'18/05/2026', total:120.00, estado:'Cancelado' } ],
    6: [ { id:'PED-0950', fecha:'25/05/2026', total:230.00, estado:'Entregado' }, { id:'PED-0810', fecha:'14/04/2026', total:180.40, estado:'Entregado' } ],
    8: [ { id:'PED-0930', fecha:'30/05/2026', total:145.80, estado:'Enviado' } ],
    9: [ { id:'PED-1010', fecha:'12/06/2026', total:65.00,  estado:'Pendiente' } ]
  };

  // ================================================================
  //  HELPERS
  // ================================================================
  function nombreCompleto(c) { return c.nombres + ' ' + c.apellidos; }

  function iniciales(c) {
    var n = c.nombres ? c.nombres.charAt(0) : '';
    var a = c.apellidos ? c.apellidos.charAt(0) : '';
    return (n + a).toUpperCase();
  }

  function formatearFecha(f) {
    var partes = f.split('-');
    return partes[2] + '/' + partes[1] + '/' + partes[0];
  }

  function toggleEstado(id, nuevoActivo) {
    var accion = nuevoActivo ? 'activar' : 'inactivar';
    if (!confirm('¿Seguro que quieres ' + accion + ' a este cliente?')) return;

    var datos = new URLSearchParams();
    datos.append('accion', 'cambiarEstado');
    datos.append('id', id);
    datos.append('activo', nuevoActivo);

    fetch('ClienteServlet', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: datos.toString()
    })
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (data.ok) {
        var c = buscarPorId(id);
        if (c) c.activo = nuevoActivo;
        renderTabla();
        actualizarStats();
      } else {
        alert(data.error || 'No se pudo actualizar el estado.');
      }
    })
    .catch(function(err) {
      console.error(err);
      alert('Error de conexión con el servidor.');
    });
  }

  function buscarPorId(id) {
    for (var i = 0; i < clientes.length; i++) {
      if (clientes[i].id === id) return clientes[i];
    }
    return null;
  }

  // ================================================================
  //  STATS
  // ================================================================
  function actualizarStats() {
    var total = clientes.length;
    var activos = 0;
    var conPedidos = 0;
    var nuevosMes = 0;
    var hoy = new Date();
    var mesActual = hoy.getMonth();
    var anioActual = hoy.getFullYear();

    for (var i = 0; i < clientes.length; i++) {
      var c = clientes[i];
      if (c.activo) activos++;
      if (c.pedidos > 0) conPedidos++;
      var fr = new Date(c.fechaRegistro);
      if (fr.getMonth() === mesActual && fr.getFullYear() === anioActual) nuevosMes++;
    }

    document.getElementById('stat-total').textContent = total;
    document.getElementById('stat-activos').textContent = activos;
    document.getElementById('stat-con-pedidos').textContent = conPedidos;
    document.getElementById('stat-nuevos-mes').textContent = nuevosMes;
  }

  // ================================================================
  //  RENDER TABLA
  // ================================================================
  function renderTabla() {
    var busq   = (document.getElementById('buscador').value || '').toLowerCase();
    var estado = document.getElementById('filtro-estado').value;
    var orden  = document.getElementById('orden-campo').value;
    var tbody  = document.getElementById('tbody-clientes');
    var contador = document.getElementById('contador-tabla');

    var lista = clientes.slice();

    if (busq) {
      lista = lista.filter(function(c) {
        return nombreCompleto(c).toLowerCase().indexOf(busq) >= 0 ||
               c.dni.indexOf(busq) >= 0 ||
               c.email.toLowerCase().indexOf(busq) >= 0;
      });
    }
    if (estado === 'activo')   lista = lista.filter(function(c){ return c.activo; });
    if (estado === 'inactivo') lista = lista.filter(function(c){ return !c.activo; });

    lista.sort(function(a, b) {
      if (orden === 'nombre')  return nombreCompleto(a).localeCompare(nombreCompleto(b));
      if (orden === 'fecha')   return new Date(b.fechaRegistro) - new Date(a.fechaRegistro);
      if (orden === 'pedidos') return b.pedidos - a.pedidos;
      if (orden === 'gastado') return b.totalGastado - a.totalGastado;
      return 0;
    });

    contador.textContent = lista.length + ' cliente' + (lista.length !== 1 ? 's' : '');

    if (lista.length === 0) {
      tbody.innerHTML = '<tr><td colspan="8"><div class="sin-resultados">' +
        '<img src="images/empty.png" alt=""><br>No se encontraron clientes</div></td></tr>';
      return;
    }

    var html = '';
    for (var i = 0; i < lista.length; i++) {
      var c = lista[i];

      var vipTag = c.totalGastado >= 400 ? '<span class="badge-vip">VIP</span>' : '';
      var estadoHtml = c.activo
        ? '<span class="badge-activo">Activo</span>'
        : '<span class="badge-inactivo">Inactivo</span>';

      html +=
        '<tr>' +
          '<td>' +
            '<div class="cliente-nombre-wrap">' +
              '<div class="cliente-avatar">' + iniciales(c) + '</div>' +
              '<div>' +
                '<div class="cliente-nombre">' + nombreCompleto(c) + vipTag + '</div>' +
                '<div class="cliente-dni">DNI: ' + c.dni + '</div>' +
              '</div>' +
            '</div>' +
          '</td>' +
          '<td>' + c.email + '</td>' +
          '<td>' + c.telefono + '</td>' +
          '<td><span class="badge-pedidos">' + c.pedidos + '</span></td>' +
          '<td><strong style="font-family:Nunito,sans-serif;">S/ ' + c.totalGastado.toFixed(2) + '</strong></td>' +
          '<td>' + formatearFecha(c.fechaRegistro) + '</td>' +
          '<td>' + estadoHtml + '</td>' +
          '<td><button class="btn-accion btn-ver" onclick="abrirDetalle(' + c.id + ')">Ver</button> ' +
          '<button class="btn-accion" onclick="toggleEstado(' + c.id + ',' + !c.activo + ')" style="border-color:' + (c.activo ? '#DC3545' : '#00A650') + ';color:' + (c.activo ? '#DC3545' : '#00A650') + ';">' +
          (c.activo ? 'Inactivar' : 'Activar') + '</button></td>' +
        '</tr>';
    }
    tbody.innerHTML = html;
  }

  // ================================================================
  //  MODAL DETALLE
  // ================================================================
  function abrirDetalle(id) {
    var c = buscarPorId(id);
    if (!c) return;

    document.getElementById('det-avatar').textContent = iniciales(c);
    document.getElementById('det-nombre').textContent = nombreCompleto(c);
    document.getElementById('det-dni').textContent = 'DNI: ' + c.dni;

    document.getElementById('det-info').innerHTML =
      '<div class="modal-row"><span class="modal-label">Correo</span><span class="modal-value">' + c.email + '</span></div>' +
      '<div class="modal-row"><span class="modal-label">Telefono</span><span class="modal-value">' + c.telefono + '</span></div>' +
      '<div class="modal-row"><span class="modal-label">Direccion</span><span class="modal-value">' + c.direccion + '</span></div>' +
      '<div class="modal-row"><span class="modal-label">Fecha de registro</span><span class="modal-value">' + formatearFecha(c.fechaRegistro) + '</span></div>' +
      '<div class="modal-row"><span class="modal-label">Estado</span><span class="modal-value">' + (c.activo ? '<span class="badge-activo">Activo</span>' : '<span class="badge-inactivo">Inactivo</span>') + '</span></div>';

    document.getElementById('det-resumen').innerHTML =
      '<div class="modal-row"><span class="modal-label">Total de pedidos</span><span class="modal-value">' + c.pedidos + '</span></div>' +
      '<div class="modal-row"><span class="modal-label">Total gastado</span><span class="modal-value">S/ ' + c.totalGastado.toFixed(2) + '</span></div>';

    var hist = pedidosPorCliente[id];
    var pedidosHtml = '';
    if (hist && hist.length > 0) {
      for (var i = 0; i < hist.length; i++) {
        var h = hist[i];
        pedidosHtml +=
          '<div class="mini-pedido-row">' +
            '<span><strong>' + h.id + '</strong> &middot; ' + h.fecha + '</span>' +
            '<span>S/ ' + h.total.toFixed(2) + ' &middot; ' + h.estado + '</span>' +
          '</div>';
      }
    } else {
      pedidosHtml = '<div style="color:#999;font-size:0.85rem;padding:10px 0;">Este cliente aun no tiene pedidos.</div>';
    }
    document.getElementById('det-pedidos').innerHTML = pedidosHtml;

    document.getElementById('modal-cliente').classList.add('open');
  }

  function cerrarModal() {
    document.getElementById('modal-cliente').classList.remove('open');
  }
  function cerrarModalClick(e) {
    if (e.target.id === 'modal-cliente') cerrarModal();
  }

  // ================================================================
  //  EXPORTAR CSV
  // ================================================================
  function exportarCSV() {
    var filas = ['Nombres,Apellidos,DNI,Correo,Telefono,Direccion,Fecha Registro,Pedidos,Total Gastado,Estado'];
    for (var i = 0; i < clientes.length; i++) {
      var c = clientes[i];
      filas.push([
        c.nombres, c.apellidos, c.dni, c.email, c.telefono,
        '"' + c.direccion + '"', formatearFecha(c.fechaRegistro),
        c.pedidos, c.totalGastado.toFixed(2), c.activo ? 'Activo' : 'Inactivo'
      ].join(','));
    }
    var csv = filas.join('\n');
    var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = 'clientes_libreria_brenda.csv';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

//================================================================
//INIT
//================================================================

fetch('ClienteServlet')
   .then(function(response) {
       return response.json();
   })
   .then(function(data) {

       clientes = data;

       for (var i = 0; i < clientes.length; i++) {

           clientes[i].pedidos =
               clientes[i].totalPedidos || 0;

           clientes[i].fechaRegistro =
               clientes[i].fechaRegistro
               ? new Date(clientes[i].fechaRegistro)
                   .toISOString()
                   .substring(0,10)
               : '2026-01-01';
       }

       renderTabla();
       actualizarStats();
   })
   .catch(function(error) {

       console.error('Error cargando clientes:', error);

       renderTabla();
       actualizarStats();
   });
</script>
</body>
</html>
