<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page isELIgnored="false" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mis Pedidos | Librería Brenda</title>
  <link rel="stylesheet" href="css/style.css">
  <style>
    .icon-img    { width: 24px; height: 24px; vertical-align: middle; }
    .cuenta-dropdown { position: relative; display: inline-block; }
    .cuenta-dropdown-btn {
      background: none;
      border: none;
      cursor: pointer;
      font-family: inherit;
      color: var(--azul-dark);
      font-weight: 700;
      font-size: 0.88rem;
      padding: 7px 14px;
      border-radius: 6px;
      transition: background 0.2s;
      display: inline-flex;
      align-items: center;
      gap: 4px;
    }
    .cuenta-dropdown-btn:hover { background: rgba(0,0,0,0.1); }
    .cuenta-dropdown-menu {
      display: none;
      position: absolute;
      right: 0;
      top: 100%;
      margin-top: 4px;
      background: #fff;
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      box-shadow: 0 6px 16px rgba(0,0,0,0.12);
      min-width: 170px;
      z-index: 200;
      overflow: hidden;
    }
    .cuenta-dropdown-menu.show { display: block; }
    .cuenta-dropdown-menu a {
      display: block;
      padding: 10px 16px;
      color: #333;
      text-decoration: none;
      font-size: 0.88rem;
      font-weight: 600;
    }
    .cuenta-dropdown-menu a:hover { background: #f2f5fb; }
    .estado-icon { width: 18px; height: 18px; vertical-align: middle; margin-right: 5px; }

    .filtros-wrap { display:flex; gap:8px; flex-wrap:wrap; margin-bottom:22px; }
    .filtro-btn {
      display:flex; align-items:center; gap:6px;
      padding:7px 16px; border-radius:20px; border:1.5px solid #e0e0e0;
      background:white; cursor:pointer; font-family:'Lato',sans-serif;
      font-weight:700; font-size:0.83rem; color:#333; transition:all 0.18s;
    }
    .filtro-btn:hover { border-color:#1259C3; color:#1259C3; }
    .filtro-btn.active { background:#1259C3; color:white; border-color:#1259C3; }
    .filtro-btn.active img { filter:brightness(10); }

    .pedido-card {
      background:white; border-radius:10px;
      box-shadow:0 2px 8px rgba(0,0,0,0.10);
      margin-bottom:16px; overflow:hidden; transition:box-shadow 0.2s;
    }
    .pedido-card:hover { box-shadow:0 6px 20px rgba(0,0,0,0.14); }

    .pedido-header {
      display:flex; justify-content:space-between; align-items:center;
      padding:14px 20px; background:#F8F9FA; border-bottom:1px solid #e0e0e0;
    }
    .pedido-num   { font-weight:700; font-size:0.92rem; color:#1259C3; }
    .pedido-fecha { font-size:0.80rem; color:#666; margin-top:2px; }
    .pedido-body  { padding:16px 20px; }

    .pedido-item-row {
      display:flex; align-items:center; gap:14px;
      padding:10px 0; border-bottom:1px solid #f0f0f0;
    }
    .pedido-item-row:last-child { border-bottom:none; }
    .prod-img {
      width:52px; height:52px; object-fit:contain;
      border-radius:6px; background:#f5f5f5; padding:3px;
    }
    .ped-info        { flex:1; font-size:0.88rem; }
    .ped-info strong { display:block; margin-bottom:3px; }
    .ped-info span   { color:#666; font-size:0.80rem; }
    .ped-precio      { font-family:'Nunito',sans-serif; font-weight:900; font-size:1rem; white-space:nowrap; }

    .pedido-footer {
      display:flex; justify-content:space-between; align-items:center;
      padding:12px 20px; border-top:1px solid #e0e0e0; background:#FAFAFA;
    }
    .pedido-total       { font-family:'Nunito',sans-serif; font-weight:900; font-size:1.15rem; color:#1259C3; }
    .pedido-total-label { font-size:0.78rem; color:#666; margin-bottom:2px; }

    .btn-cancelar {
      background:none; border:1.5px solid #dc3545; color:#dc3545;
      padding:7px 14px; border-radius:6px; font-weight:700;
      cursor:pointer; font-size:0.82rem; font-family:'Lato',sans-serif; transition:all 0.18s;
    }
    .btn-cancelar:hover { background:#dc3545; color:white; }

    .btn-ver-detalle {
      border:1.5px solid #1259C3; color:#1259C3; padding:7px 16px;
      border-radius:6px; font-weight:700; cursor:pointer; font-size:0.82rem;
      font-family:'Lato',sans-serif; background:none; transition:all 0.18s;
    }
    .btn-ver-detalle:hover { background:#1259C3; color:white; }

    .empty-state { text-align:center; padding:60px 20px; background:white; border-radius:10px; box-shadow:0 2px 8px rgba(0,0,0,0.08); }
    .empty-state img { width:80px; height:80px; margin-bottom:14px; opacity:0.7; }
    .empty-state h3  { font-family:'Nunito',sans-serif; font-size:1.15rem; margin-bottom:8px; }
    .empty-state p   { color:#666; font-size:0.88rem; margin-bottom:20px; }
    .btn-ir-tienda {
      background:#1259C3; color:white; padding:12px 28px;
      border-radius:8px; font-weight:700; text-decoration:none; display:inline-block;
    }
    .btn-ir-tienda:hover { background:#0a3e8f; }

    /* Modal */
    .modal-overlay {
      display:none; position:fixed; inset:0;
      background:rgba(0,0,0,0.5); z-index:999; align-items:center; justify-content:center;
    }
    .modal-overlay.open { display:flex; }
    .modal-box {
      background:white; border-radius:12px; padding:28px;
      width:90%; max-width:520px; max-height:80vh; overflow-y:auto;
      box-shadow:0 10px 40px rgba(0,0,0,0.25); animation:fadeUp 0.2s ease;
    }
    @keyframes fadeUp {
      from { opacity:0; transform:translateY(20px); }
      to   { opacity:1; transform:translateY(0); }
    }
    .modal-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:18px; }
    .modal-header h3 { font-family:'Nunito',sans-serif; font-weight:900; font-size:1.15rem; }
    .btn-cerrar-modal { background:none; border:none; font-size:1.4rem; cursor:pointer; color:#666; }
    .modal-row {
      display:flex; justify-content:space-between;
      padding:8px 0; font-size:0.88rem; border-bottom:1px solid #f0f0f0;
    }
    .modal-row:last-child { border-bottom:none; }
    .modal-label { color:#666; }
    .modal-value { font-weight:700; }
    .modal-total-row {
      display:flex; justify-content:space-between; align-items:center;
      margin-top:14px; padding-top:14px; border-top:2px solid #e0e0e0;
    }
    .modal-total-label { font-size:0.92rem; font-weight:700; }
    .modal-total-val   { font-family:'Nunito',sans-serif; font-weight:900; font-size:1.3rem; color:#1259C3; }

    /* Timeline */
    .timeline { display:flex; align-items:flex-start; margin:18px 0 6px; }
    .tl-step  { display:flex; flex-direction:column; align-items:center; flex:1; position:relative; }
    .tl-step:not(:last-child)::after {
      content:''; position:absolute; top:13px; left:50%;
      width:100%; height:3px; background:#e0e0e0; z-index:0;
    }
    .tl-step.done:not(:last-child)::after { background:#1259C3; }
    .tl-dot {
      width:26px; height:26px; border-radius:50%;
      background:#e0e0e0; border:3px solid #e0e0e0; z-index:1; margin-bottom:5px;
    }
    .tl-step.done    .tl-dot { background:#1259C3; border-color:#1259C3; }
    .tl-step.current .tl-dot { background:white; border-color:#1259C3; box-shadow:0 0 0 3px rgba(18,89,195,0.2); }
    .tl-label { font-size:0.68rem; color:#999; text-align:center; line-height:1.2; }
    .tl-step.done    .tl-label,
    .tl-step.current .tl-label { color:#1259C3; font-weight:700; }

    .seccion-subtitulo {
      font-size:0.78rem; font-weight:700; color:#555;
      text-transform:uppercase; letter-spacing:.5px; margin:16px 0 8px;
    }
  </style>
</head>
<body>

  <!-- NAVBAR -->
  <nav class="navbar">
    <a href="index.jsp" class="logo">
      <img src="images/libro-logo.png" class="icon-img" style="width:30px;height:30px;" alt="Logo">
      Librería Brenda
    </a>
    <div class="search-bar">
      <input type="text" placeholder="Buscar productos...">
      <button>&#128269;</button>
    </div>
    <div class="navbar-links">
      <a href="index.jsp"><img src="images/tienda.png" class="icon-img" alt=""> Inicio</a>
      <%
        String rolSesion = (String) session.getAttribute("rol");
        String nombreCliente = (String) session.getAttribute("clienteNombre");
      %>
      <% if ("cliente".equals(rolSesion) && nombreCliente != null) { %>
        <div class="cuenta-dropdown">
          <button class="cuenta-dropdown-btn" onclick="toggleCuentaMenu(event)">
            <img src="images/usuario.png" class="icon-img" alt=""> Hola, <%= nombreCliente.split(" ")[0] %> ▾
          </button>
          <div class="cuenta-dropdown-menu" id="cuenta-dropdown-menu">
            <a href="pedidos.jsp">Mis Pedidos</a>
            <a href="LogoutServlet">Cerrar sesión</a>
          </div>
        </div>
      <% } else { %>
        <a href="login.jsp"><img src="images/usuario.png" class="icon-img" alt=""> Mi cuenta</a>
      <% } %>
      <a href="carrito.jsp" class="btn-carrito" style="position:relative">
        <img src="images/carrito.png" class="icon-img" alt="Carrito"> Carrito
        <span class="badge" id="carrito-badge">0</span>
      </a>
    </div>
  </nav>

  <!-- BREADCRUMB -->
  <div style="padding:10px 24px;font-size:0.83rem;color:#666;background:white;border-bottom:1px solid #e0e0e0;">
    <a href="index.jsp" style="color:#1259C3;text-decoration:none;font-weight:700;">Inicio</a>
    &nbsp;&#187;&nbsp; Mis Pedidos
  </div>

  <!-- CONTENIDO -->
  <div style="max-width:900px;margin:28px auto;padding:0 20px;">

    <div class="page-header" style="margin-bottom:20px;">
      <h2>
        <img src="images/pedidos.png" class="icon-img" style="width:30px;height:30px;" alt="">
        Mis Pedidos
      </h2>
      <a href="index.jsp" class="btn-ver-detalle">+ Nuevo pedido</a>
    </div>

    <!-- Buscador -->
    <div style="background:white;border-radius:10px;padding:14px 18px;box-shadow:0 2px 8px rgba(0,0,0,0.08);margin-bottom:18px;display:flex;gap:10px;align-items:center;">
      <img src="images/pedidos.png" style="width:20px;height:20px;" alt="">
      <input type="text" id="buscar-pedido"
        placeholder="Buscar por N de pedido o producto..."
        style="flex:1;border:none;outline:none;font-family:'Lato',sans-serif;font-size:0.9rem;"
        oninput="renderPedidos()">
      <span id="contador-pedidos" style="font-size:0.8rem;color:#666;white-space:nowrap;"></span>
    </div>

    <!-- Filtros -->
    <div class="filtros-wrap">
      <button class="filtro-btn active" onclick="setFiltro('', this)">
        <img src="images/todos.png" style="width:16px;height:16px;" alt=""> Todos
      </button>
      <button class="filtro-btn" onclick="setFiltro('Pendiente', this)" style="border-color:#FFC107;color:#856404;">
        <img src="images/pendiente.png" class="estado-icon" alt=""> Pendiente
      </button>
      <button class="filtro-btn" onclick="setFiltro('Confirmado', this)" style="border-color:#17a2b8;color:#0c5460;">
        <img src="images/confirmado.png" class="estado-icon" alt=""> Confirmado
      </button>
      <button class="filtro-btn" onclick="setFiltro('Enviado', this)" style="border-color:#007bff;color:#004085;">
        <img src="images/enviado.png" class="estado-icon" alt=""> Enviado
      </button>
      <button class="filtro-btn" onclick="setFiltro('Entregado', this)" style="border-color:#28a745;color:#155724;">
        <img src="images/entregado.png" class="estado-icon" alt=""> Entregado
      </button>
      <button class="filtro-btn" onclick="setFiltro('Cancelado', this)" style="border-color:#dc3545;color:#721c24;">
        <img src="images/cancelar.png" class="estado-icon" alt=""> Cancelado
      </button>
    </div>

    <!-- Lista -->
    <div id="lista-pedidos"></div>

  </div>

  <!-- MODAL DETALLE -->
  <div class="modal-overlay" id="modal-detalle" onclick="cerrarModalClick(event)">
    <div class="modal-box">
      <div class="modal-header">
        <h3 id="modal-titulo">Detalle del Pedido</h3>
        <button class="btn-cerrar-modal" onclick="cerrarModal()">&#10005;</button>
      </div>
      <div class="timeline" id="modal-timeline"></div>
      <div class="seccion-subtitulo">Productos</div>
      <div id="modal-items"></div>
      <div class="seccion-subtitulo" style="margin-top:16px;">Informacion del pedido</div>
      <div id="modal-info"></div>
      <div class="modal-total-row">
        <span class="modal-total-label">Total pagado</span>
        <span class="modal-total-val" id="modal-total"></span>
      </div>
    </div>
  </div>

  <!-- FOOTER -->
  <footer class="footer">
    <p><strong>Libreria Brenda</strong> | Lima, Peru &nbsp;|&nbsp; &copy; 2026 Todos los derechos reservados</p>
  </footer>

  <script src="js/carrito.js"></script>
  <script>
    // ================================================================
    //  MENÚ DE CUENTA (dropdown "Hola, {nombre}")
    // ================================================================
    function toggleCuentaMenu(e) {
      e.stopPropagation();
      var menu = document.getElementById('cuenta-dropdown-menu');
      if (menu) menu.classList.toggle('show');
    }
    document.addEventListener('click', function() {
      var menu = document.getElementById('cuenta-dropdown-menu');
      if (menu) menu.classList.remove('show');
    });

    // ===== PEDIDOS — cargados desde MySQL vía PedidoServlet =====
    var todosPedidos = [];

    function cargarPedidos() {
      var lista = document.getElementById('lista-pedidos');
      lista.innerHTML = '<p style="padding:40px;text-align:center;color:#666;">Cargando tus pedidos...</p>';

      fetch('PedidoServlet')
        .then(function(r) { return r.json(); })
        .then(function(data) {
          todosPedidos = data;
          renderPedidos();
        })
        .catch(function(e) {
          console.error('Error cargando pedidos:', e);
          lista.innerHTML =
            '<div class="empty-state">' +
              '<h3>No se pudieron cargar tus pedidos</h3>' +
              '<p>Intenta recargar la pagina.</p>' +
            '</div>';
        });
    }

    // Devuelve el HTML de la miniatura de un producto: usa imagen real si existe
    // (pedidos demo) o el icono emoji guardado por el carrito (pedidos nuevos).
    function prodThumbHtml(it) {
      if (it.img) {
        return '<img src="' + it.img + '" class="prod-img" alt="' + it.nombre + '" onerror="this.src=\'images/productos.png\'">';
      }
      return '<div class="prod-img" style="display:flex;align-items:center;justify-content:center;font-size:1.7rem;">' + (it.icon || '\uD83D\uDCE6') + '</div>';
    }

    var filtroActual = '';

    function badgeClass(estado) {
      var m = { 'Pendiente':'pendiente','Confirmado':'confirmado','Enviado':'enviado','Entregado':'entregado','Cancelado':'cancelado' };
      return 'badge-estado estado-' + (m[estado] || 'pendiente');
    }

    function estadoIconImg(estado) {
      var m = { 'Pendiente':'pendiente','Confirmado':'confirmado','Enviado':'enviado','Entregado':'entregado','Cancelado':'cancelar' };
      return 'images/' + (m[estado] || 'pendiente') + '.png';
    }

    function setFiltro(estado, btn) {
      filtroActual = estado;
      var btns = document.querySelectorAll('.filtro-btn');
      for (var i = 0; i < btns.length; i++) btns[i].classList.remove('active');
      btn.classList.add('active');
      renderPedidos();
    }

    function renderPedidos() {
      var busq = (document.getElementById('buscar-pedido').value || '').toLowerCase();
      var lista = document.getElementById('lista-pedidos');
      var contador = document.getElementById('contador-pedidos');

      var pedidos = todosPedidos.slice();
      if (filtroActual) {
        pedidos = pedidos.filter(function(p) { return p.estado === filtroActual; });
      }
      if (busq) {
        pedidos = pedidos.filter(function(p) {
          if (p.id.toLowerCase().indexOf(busq) >= 0) return true;
          for (var i = 0; i < p.items.length; i++) {
            if (p.items[i].nombre.toLowerCase().indexOf(busq) >= 0) return true;
          }
          return false;
        });
      }

      contador.textContent = pedidos.length + ' pedido' + (pedidos.length !== 1 ? 's' : '');

      if (pedidos.length === 0) {
        lista.innerHTML =
          '<div class="empty-state">' +
            '<img src="images/empty.png" alt="Sin pedidos">' +
            '<h3>No tienes pedidos' + (filtroActual ? ' con estado "' + filtroActual + '"' : '') + '</h3>' +
            '<p>Explora nuestra tienda y realiza tu primer pedido</p>' +
            '<a href="index.jsp" class="btn-ir-tienda">Ir a la tienda</a>' +
          '</div>';
        return;
      }

      var html = '';
      for (var i = 0; i < pedidos.length; i++) {
        var p = pedidos[i];

        // Items HTML (max 2 visibles)
        var itemsHtml = '';
        var maxItems = Math.min(p.items.length, 2);
        for (var j = 0; j < maxItems; j++) {
          var it = p.items[j];
          itemsHtml +=
            '<div class="pedido-item-row">' +
              prodThumbHtml(it) +
              '<div class="ped-info">' +
                '<strong>' + it.nombre + '</strong>' +
                '<span>Cantidad: ' + it.qty + '</span>' +
              '</div>' +
              '<div class="ped-precio">S/ ' + (it.precio * it.qty).toFixed(2) + '</div>' +
            '</div>';
        }
        if (p.items.length > 2) {
          itemsHtml += '<div style="font-size:0.8rem;color:#1259C3;font-weight:700;padding:8px 0 0;">+' + (p.items.length - 2) + ' producto(s) mas - ver detalle</div>';
        }

        // Boton cancelar solo si Pendiente
        var btnCancelar = '';
        if (p.estado === 'Pendiente') {
          btnCancelar = '<button class="btn-cancelar" onclick="cancelarPedido(\'' + p.id + '\')">' +
            '<img src="images/cancelar.png" class="estado-icon" alt=""> Cancelar' +
          '</button>';
        }

        html +=
          '<div class="pedido-card">' +
            '<div class="pedido-header">' +
              '<div>' +
                '<div class="pedido-num">Pedido ' + p.id + '</div>' +
                '<div class="pedido-fecha">' + p.fecha + (p.hora ? ' &middot; ' + p.hora : '') + '</div>' +
              '</div>' +
              '<span class="' + badgeClass(p.estado) + '">' +
                '<img src="' + estadoIconImg(p.estado) + '" class="estado-icon" alt="' + p.estado + '">' +
                p.estado +
              '</span>' +
            '</div>' +
            '<div class="pedido-body">' + itemsHtml + '</div>' +
            '<div class="pedido-footer">' +
              '<div>' +
                '<div class="pedido-total-label">Total del pedido</div>' +
                '<div class="pedido-total">S/ ' + p.total.toFixed(2) + '</div>' +
              '</div>' +
              '<div style="display:flex;gap:8px;align-items:center;">' +
                btnCancelar +
                '<button class="btn-ver-detalle" onclick="abrirDetalle(\'' + p.id + '\')">Ver detalle</button>' +
              '</div>' +
            '</div>' +
          '</div>';
      }

      lista.innerHTML = html;
    }

    function cancelarPedido(id) {
      if (!confirm('Seguro que deseas cancelar el pedido ' + id + '?')) return;

      var cuerpo = 'accion=cancelarPedido&idPedido=' + encodeURIComponent(id);

      fetch('PedidoServlet', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: cuerpo
      })
        .then(function(r) { return r.json(); })
        .then(function(data) {
          if (!data.ok) {
            alert('No se pudo cancelar el pedido.');
            return;
          }
          for (var i = 0; i < todosPedidos.length; i++) {
            if (todosPedidos[i].id === id) todosPedidos[i].estado = 'Cancelado';
          }
          renderPedidos();
        })
        .catch(function() { alert('Error de conexion con el servidor.'); });
    }

    function abrirDetalle(id) {
      var p = null;
      for (var i = 0; i < todosPedidos.length; i++) {
        if (todosPedidos[i].id === id) { p = todosPedidos[i]; break; }
      }
      if (!p) return;

      document.getElementById('modal-titulo').textContent = 'Pedido ' + p.id;

      // Timeline
      var pasos = ['Pendiente', 'Confirmado', 'Enviado', 'Entregado'];
      var tlHtml = '';
      if (p.estado === 'Cancelado') {
        tlHtml = '<div style="width:100%;text-align:center;padding:10px;background:#F8D7DA;border-radius:8px;color:#721c24;font-weight:700;font-size:0.88rem;">' +
          '<img src="images/cancelar.png" style="width:18px;height:18px;vertical-align:middle;margin-right:6px;" alt="">Pedido Cancelado</div>';
      } else {
        var idx = pasos.indexOf(p.estado);
        for (var i = 0; i < pasos.length; i++) {
          var cls = i < idx ? 'tl-step done' : (i === idx ? 'tl-step current' : 'tl-step');
          tlHtml += '<div class="' + cls + '"><div class="tl-dot"></div><div class="tl-label">' + pasos[i] + '</div></div>';
        }
      }
      document.getElementById('modal-timeline').innerHTML = tlHtml;

      // Items
      var itemsHtml = '';
      for (var i = 0; i < p.items.length; i++) {
        var it = p.items[i];
        itemsHtml +=
          '<div class="pedido-item-row" style="padding:8px 0;">' +
            prodThumbHtml(it) +
            '<div class="ped-info">' +
              '<strong>' + it.nombre + '</strong>' +
              '<span>Cantidad: ' + it.qty + ' &middot; S/ ' + it.precio.toFixed(2) + ' c/u</span>' +
            '</div>' +
            '<div class="ped-precio">S/ ' + (it.precio * it.qty).toFixed(2) + '</div>' +
          '</div>';
      }
      document.getElementById('modal-items').innerHTML = itemsHtml;

      // Info
      var envio = p.total >= 30 ? 'Gratis' : 'S/ 10.00';
      document.getElementById('modal-info').innerHTML =
        '<div class="modal-row"><span class="modal-label">N Pedido</span><span class="modal-value">' + p.id + '</span></div>' +
        '<div class="modal-row"><span class="modal-label">Fecha</span><span class="modal-value">' + p.fecha + (p.hora ? ' &middot; ' + p.hora : '') + '</span></div>' +
        '<div class="modal-row"><span class="modal-label">Estado</span><span class="modal-value"><span class="' + badgeClass(p.estado) + '">' + p.estado + '</span></span></div>' +
        '<div class="modal-row"><span class="modal-label">Direccion</span><span class="modal-value">' + (p.direccion || '-') + '</span></div>' +
        '<div class="modal-row"><span class="modal-label">Pago</span><span class="modal-value">' + (p.pago || '-') + '</span></div>' +
        '<div class="modal-row"><span class="modal-label">Envio</span><span class="modal-value">' + envio + '</span></div>';

      document.getElementById('modal-total').textContent = 'S/ ' + p.total.toFixed(2);
      document.getElementById('modal-detalle').classList.add('open');
    }

    function cerrarModal() {
      document.getElementById('modal-detalle').classList.remove('open');
    }
    function cerrarModalClick(e) {
      if (e.target.id === 'modal-detalle') cerrarModal();
    }

    // Init
    cargarPedidos();
  </script>
</body>
</html>
