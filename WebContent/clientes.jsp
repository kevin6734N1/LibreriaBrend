<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Clientes | Libreria Brenda Admin</title>
  <link rel="stylesheet" href="css/style.css">
  <link rel="stylesheet" href="css/admin.css">
  <style>
    /* ===== Estilos propios de Clientes ===== */
    .admin-table-wrap th { cursor: pointer; user-select: none; }
    .admin-table-wrap th:hover { color: var(--azul); }
    .admin-table-wrap th .sort-arrow { font-size: 0.7rem; opacity: 0.5; margin-left: 3px; }

    .cliente-avatar {
      width: 38px; height: 38px; border-radius: 50%;
      background: var(--azul); color: #fff; display: flex; align-items: center; justify-content: center;
      font-weight: 700; font-size: 0.9rem; font-family: 'Nunito', sans-serif;
    }
    .cliente-nombre-wrap { display: flex; align-items: center; gap: 10px; }
    .cliente-nombre { font-weight: 700; font-size: 0.9rem; }
    .cliente-dni { font-size: 0.78rem; color: #888; }

    .cliente-detalle-header { display: flex; align-items: center; gap: 14px; margin-bottom: 20px; padding-bottom: 16px; border-bottom: 1px solid #f0f0f0; }
    .cliente-avatar-lg {
      width: 60px; height: 60px; border-radius: 50%;
      background: var(--azul); color: #fff; display: flex; align-items: center; justify-content: center;
      font-weight: 700; font-size: 1.4rem; font-family: 'Nunito', sans-serif; flex-shrink: 0;
    }

    .modal-row { display: flex; justify-content: space-between; gap: 12px; padding: 9px 0; font-size: 0.88rem; border-bottom: 1px solid #f5f5f5; }
    .modal-row:last-child { border-bottom: none; }
    .modal-label { color: #666; }
    .modal-value { font-weight: 700; text-align: right; }
    .seccion-subtitulo { font-size: 0.78rem; font-weight: 700; color: #555; text-transform: uppercase; letter-spacing: .5px; margin: 18px 0 8px; }

    .mini-pedido-row { display: flex; justify-content: space-between; align-items: center; gap: 10px; padding: 9px 0; font-size: 0.84rem; border-bottom: 1px solid #f5f5f5; }
    .mini-pedido-row:last-child { border-bottom: none; }
  </style>
</head>
<body>
<div class="admin-layout">

  <!-- ===== SIDEBAR ===== -->
  <%@ include file="/WEB-INF/jspf/admin-sidebar.jspf" %>

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
    <div class="admin-table-wrap tabla-cards">
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
  //  Los clientes se cargan SIEMPRE desde ClienteServlet (MySQL).
  //  No se dejan datos de ejemplo embebidos: si la consulta falla,
  //  la tabla queda vacia en vez de mostrar registros viejos.
  // ================================================================
  var clientes = [];
  var solicitudPedidos = 0;

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
    if (!f) return '';
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
      tbody.innerHTML = '<tr><td colspan="8" class="celda-vacia"><div class="sin-resultados">' +
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
          '<td data-label="Cliente">' +
            '<div class="cliente-nombre-wrap">' +
              '<div class="cliente-avatar">' + iniciales(c) + '</div>' +
              '<div>' +
                '<div class="cliente-nombre">' + nombreCompleto(c) + vipTag + '</div>' +
                '<div class="cliente-dni">DNI: ' + c.dni + '</div>' +
              '</div>' +
            '</div>' +
          '</td>' +
          '<td data-label="Correo">' + c.email + '</td>' +
          '<td data-label="Teléfono">' + c.telefono + '</td>' +
          '<td data-label="Pedidos"><span class="badge-pedidos">' + c.pedidos + '</span></td>' +
          '<td data-label="Total gastado"><strong style="font-family:Nunito,sans-serif;">S/ ' + c.totalGastado.toFixed(2) + '</strong></td>' +
          '<td data-label="Registro">' + formatearFecha(c.fechaRegistro) + '</td>' +
          '<td data-label="Estado">' + estadoHtml + '</td>' +
          '<td data-label="Acciones" class="celda-acciones"><button class="btn-accion btn-ver" onclick="abrirDetalle(' + c.id + ')">Ver</button> ' +
          '<button class="btn-accion" onclick="toggleEstado(' + c.id + ',' + !c.activo + ')" style="border-color:' + (c.activo ? '#DC3545' : '#00A650') + ';color:' + (c.activo ? '#DC3545' : '#00A650') + ';">' +
          (c.activo ? 'Inactivar' : 'Activar') + '</button></td>' +
        '</tr>';
    }
    tbody.innerHTML = html;
  }

  // ================================================================
  //  MODAL DETALLE
  // ================================================================
  function escaparHtml(valor) {
    return String(valor == null ? '' : valor).replace(/[&<>"']/g, function(c) {
      return { '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' }[c];
    });
  }

  function capitalizar(texto) {
    if (!texto) return '';
    return texto.charAt(0).toUpperCase() + texto.substring(1).toLowerCase();
  }

  function renderHistorial(hist) {
    if (!hist || hist.length === 0) {
      return '<div style="color:#999;font-size:0.85rem;padding:10px 0;">Este cliente aun no tiene pedidos.</div>';
    }

    var html = '';
    for (var i = 0; i < hist.length; i++) {
      var h = hist[i];
      html +=
        '<div class="mini-pedido-row">' +
          '<span><strong>' + escaparHtml(h.id) + '</strong> &middot; ' +
            escaparHtml(h.fecha ? formatearFecha(h.fecha) : '') + '</span>' +
          '<span>S/ ' + Number(h.total || 0).toFixed(2) + ' &middot; ' +
            escaparHtml(capitalizar(h.estado)) + '</span>' +
        '</div>';
    }
    return html;
  }

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

    var contenedor = document.getElementById('det-pedidos');
    contenedor.innerHTML = '<div style="color:#999;font-size:0.85rem;padding:10px 0;">Cargando pedidos...</div>';
    var solicitud = ++solicitudPedidos;

    fetch('ClienteServlet?accion=pedidos&id=' + encodeURIComponent(id))
      .then(function(response) {
        if (!response.ok) throw new Error('HTTP ' + response.status);
        return response.json();
      })
      .then(function(hist) {
        if (solicitud !== solicitudPedidos) return;
        contenedor.innerHTML = renderHistorial(hist);
      })
      .catch(function(error) {
        if (solicitud !== solicitudPedidos) return;
        console.error('Error cargando pedidos:', error);
        contenedor.innerHTML = '<div style="color:#b00020;font-size:0.85rem;padding:10px 0;">No se pudo cargar el historial de pedidos.</div>';
      });

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
