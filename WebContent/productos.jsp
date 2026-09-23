<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Productos | Libreria Brenda Admin</title>
  <link rel="stylesheet" href="css/style.css">
  <style>
    .icon-img { width: 24px; height: 24px; vertical-align: middle; margin-right: 6px; }

    /* ===== LAYOUT ADMIN ===== */
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

    /* ===== TOPBAR ===== */
    .topbar {
      display: flex; justify-content: space-between; align-items: center;
      margin-bottom: 24px;
    }
    .topbar h2 { font-family: 'Nunito', sans-serif; font-weight: 900; font-size: 1.4rem; }
    .topbar-right { display: flex; align-items: center; gap: 10px; font-size: 0.88rem; color: #555; }
    .badge-admin {
      background: #1259C3; color: white; padding: 4px 10px;
      border-radius: 20px; font-size: 0.75rem; font-weight: 700;
    }

    /* ===== STATS ===== */
    .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px,1fr)); gap: 14px; margin-bottom: 24px; }
    .stat-card  { background: white; border-radius: 8px; padding: 18px 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.10); }
    .stat-card img { width: 40px; height: 40px; margin-bottom: 8px; }
    .stat-num   { font-family: 'Nunito', sans-serif; font-size: 1.9rem; font-weight: 900; color: #1259C3; }
    .stat-label { font-size: 0.80rem; color: #666; margin-top: 2px; }

    /* ===== BARRA DE HERRAMIENTAS ===== */
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
    .btn-nuevo {
      background: #1259C3; color: white; border: none; padding: 10px 20px;
      border-radius: 8px; font-weight: 700; cursor: pointer;
      font-family: 'Lato', sans-serif; font-size: 0.9rem; white-space: nowrap;
      transition: background 0.18s; display: flex; align-items: center; gap: 6px;
    }
    .btn-nuevo:hover { background: #0a3e8f; }

    /* ===== TABLA ===== */
    .admin-table-wrap { background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); overflow: hidden; }
    .admin-table-wrap table { width: 100%; border-collapse: collapse; }
    .admin-table-wrap th {
      background: #F5F5F5; padding: 12px 16px; text-align: left;
      font-size: 0.78rem; font-weight: 700; text-transform: uppercase;
      letter-spacing: 0.5px; color: #666; white-space: nowrap;
    }
    .admin-table-wrap td { padding: 12px 16px; font-size: 0.88rem; border-bottom: 1px solid #F0F0F0; vertical-align: middle; }
    .admin-table-wrap tr:last-child td { border-bottom: none; }
    .admin-table-wrap tr:hover td { background: rgba(18,89,195,0.03); }

    .prod-thumb { width: 48px; height: 48px; object-fit: contain; border-radius: 6px; background: #F5F5F5; padding: 3px; }
    .prod-nombre { font-weight: 700; font-size: 0.9rem; }
    .prod-desc   { font-size: 0.78rem; color: #888; margin-top: 2px; }

    .badge-cat {
      padding: 3px 10px; border-radius: 12px; font-size: 0.75rem; font-weight: 700;
      background: #EEF2FF; color: #1259C3;
    }
    .badge-activo    { background: #D4EDDA; color: #155724; padding: 3px 10px; border-radius: 12px; font-size: 0.75rem; font-weight: 700; }
    .badge-inactivo  { background: #F8D7DA; color: #721c24; padding: 3px 10px; border-radius: 12px; font-size: 0.75rem; font-weight: 700; }
    .badge-stock-ok  { color: #00A650; font-weight: 700; }
    .badge-stock-low { color: #FFC107; font-weight: 700; }
    .badge-stock-out { color: #dc3545; font-weight: 700; }

    .btn-accion {
      border: none; padding: 5px 12px; border-radius: 6px; cursor: pointer;
      font-size: 0.78rem; font-weight: 700; font-family: 'Lato', sans-serif; transition: all 0.15s;
    }
    .btn-editar  { background: #EEF2FF; color: #1259C3; border: 1px solid #1259C3; }
    .btn-editar:hover  { background: #1259C3; color: white; }
    .btn-toggle  { background: #FFF3CD; color: #856404; border: 1px solid #FFC107; }
    .btn-toggle:hover  { background: #FFC107; color: white; }
    .btn-eliminar-tbl { background: #F8D7DA; color: #721c24; border: 1px solid #dc3545; }
    .btn-eliminar-tbl:hover { background: #dc3545; color: white; }

    .sin-resultados {
      text-align: center; padding: 50px 20px; color: #999;
      font-size: 0.9rem;
    }
    .sin-resultados img { width: 60px; opacity: 0.4; margin-bottom: 10px; display: block; margin-left: auto; margin-right: auto; }

    /* ===== MODAL ===== */
    .modal-overlay {
      display: none; position: fixed; inset: 0;
      background: rgba(0,0,0,0.5); z-index: 999;
      align-items: center; justify-content: center;
    }
    .modal-overlay.open { display: flex; }
    .modal-box {
      background: white; border-radius: 12px; padding: 28px;
      width: 90%; max-width: 560px; max-height: 90vh; overflow-y: auto;
      box-shadow: 0 10px 40px rgba(0,0,0,0.25); animation: fadeUp 0.2s ease;
    }
    @keyframes fadeUp {
      from { opacity:0; transform:translateY(20px); }
      to   { opacity:1; transform:translateY(0); }
    }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 22px; }
    .modal-header h3 { font-family: 'Nunito', sans-serif; font-weight: 900; font-size: 1.2rem; }
    .btn-cerrar { background: none; border: none; font-size: 1.4rem; cursor: pointer; color: #666; line-height: 1; }

    .form-group { margin-bottom: 16px; }
    .form-group label { display: block; font-size: 0.83rem; font-weight: 700; margin-bottom: 6px; color: #444; }
    .form-group input, .form-group select, .form-group textarea {
      width: 100%; padding: 10px 14px; border: 1.5px solid #e0e0e0; border-radius: 8px;
      font-family: 'Lato', sans-serif; font-size: 0.9rem; outline: none;
      transition: border-color 0.18s; box-sizing: border-box;
    }
    .form-group input:focus, .form-group select:focus, .form-group textarea:focus { border-color: #1259C3; }
    .form-group textarea { resize: vertical; min-height: 70px; }
    .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }

    .preview-img {
      width: 80px; height: 80px; object-fit: contain;
      border-radius: 8px; background: #F5F5F5; padding: 6px;
      border: 1.5px dashed #e0e0e0; display: block; margin-bottom: 8px;
    }

    .modal-footer { display: flex; justify-content: flex-end; gap: 10px; margin-top: 24px; padding-top: 18px; border-top: 1px solid #e0e0e0; }
    .btn-guardar {
      background: #1259C3; color: white; border: none; padding: 11px 26px;
      border-radius: 8px; font-weight: 700; cursor: pointer; font-family: 'Lato', sans-serif; font-size: 0.9rem;
    }
    .btn-guardar:hover { background: #0a3e8f; }
    .btn-cancelar-modal {
      background: none; border: 1.5px solid #e0e0e0; color: #555; padding: 11px 20px;
      border-radius: 8px; font-weight: 700; cursor: pointer; font-family: 'Lato', sans-serif; font-size: 0.9rem;
    }
    .btn-cancelar-modal:hover { border-color: #999; }

    .alert-toast {
      position: fixed; bottom: 24px; right: 24px; padding: 14px 22px;
      border-radius: 10px; font-weight: 700; font-size: 0.9rem; z-index: 9999;
      box-shadow: 0 4px 16px rgba(0,0,0,0.2); opacity: 0; transition: opacity 0.3s;
      pointer-events: none;
    }
    .alert-toast.show { opacity: 1; }
    .toast-ok  { background: #D4EDDA; color: #155724; }
    .toast-err { background: #F8D7DA; color: #721c24; }

    .contador-tabla { font-size: 0.82rem; color: #666; margin-left: auto; }

    @media (max-width: 768px) {
      .admin-layout { flex-direction: column; }
      .sidebar { width: 100%; height: auto; position: static; flex-direction: row; flex-wrap: wrap; padding: 10px; }
      .form-row { grid-template-columns: 1fr; }
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
      <a href="admin.jsp">
        <img src="images/pedidos.png" class="icon-img"> Pedidos
      </a>
      <a href="productos.jsp" class="active">
        <img src="images/productos.png" class="icon-img"> Productos
      </a>
      <a href="clientes.jsp">
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

    <!-- Topbar -->
    <div class="topbar">
      <h2>
        <img src="images/productos.png" style="width:28px;height:28px;vertical-align:middle;margin-right:8px;" alt="">
        Catalogo de Productos
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
        <img src="images/productos.png" alt="">
        <div class="stat-num" id="stat-total">10</div>
        <div class="stat-label">Total productos</div>
      </div>
      <div class="stat-card">
        <img src="images/check.png" alt="">
        <div class="stat-num" id="stat-activos" style="color:#00A650;">9</div>
        <div class="stat-label">Productos activos</div>
      </div>
      <div class="stat-card">
        <img src="images/pendiente.png" alt="">
        <div class="stat-num" id="stat-stock-bajo" style="color:#FFC107;">2</div>
        <div class="stat-label">Stock bajo (menos de 5)</div>
      </div>
      <div class="stat-card">
        <img src="images/ventas.png" alt="">
        <div class="stat-num" id="stat-categorias" style="color:#1259C3;">6</div>
        <div class="stat-label">Categorias</div>
      </div>
    </div>

    <!-- Toolbar -->
    <div class="toolbar">
      <input type="text" id="buscador" placeholder="Buscar producto por nombre..." oninput="renderTabla()">
      <select id="filtro-cat" onchange="renderTabla()">
        <option value="">Todas las categorias</option>
        <option value="Libros">Libros</option>
        <option value="Cuadernos">Cuadernos</option>
        <option value="Lapiceros">Lapiceros</option>
        <option value="Mochilas">Mochilas</option>
        <option value="Arte">Arte</option>
        <option value="Oficina">Oficina</option>
      </select>
      <select id="filtro-estado" onchange="renderTabla()">
        <option value="">Todos los estados</option>
        <option value="activo">Activo</option>
        <option value="inactivo">Inactivo</option>
      </select>
      <span class="contador-tabla" id="contador-tabla"></span>
      <button class="btn-nuevo" onclick="abrirModalNuevo()">
        &#43; Nuevo producto
      </button>
    </div>

    <!-- Tabla -->
    <div class="admin-table-wrap">
      <table>
        <thead>
          <tr>
            <th style="width:56px;">Imagen</th>
            <th>Producto</th>
            <th>Categoria</th>
            <th>Precio</th>
            <th>Stock</th>
            <th>Estado</th>
            <th style="width:180px;">Acciones</th>
          </tr>
        </thead>
        <tbody id="tbody-productos">
          <tr><td colspan="7" style="text-align:center;padding:30px;color:#999;">Cargando...</td></tr>
        </tbody>
      </table>
    </div>

  </main>
</div>

<!-- ===== MODAL AGREGAR / EDITAR ===== -->
<div class="modal-overlay" id="modal-prod" onclick="cerrarModalClick(event)">
  <div class="modal-box">
    <div class="modal-header">
      <h3 id="modal-titulo">Nuevo Producto</h3>
      <button class="btn-cerrar" onclick="cerrarModal()">&#10005;</button>
    </div>

    <!-- Preview imagen -->
    <div style="text-align:center;margin-bottom:16px;">
      <img id="preview-img" class="preview-img" src="images/productos.png" alt="Preview">
      <div style="font-size:0.78rem;color:#888;">Vista previa de imagen</div>
    </div>

    <!-- Formulario -->
    <div class="form-group">
      <label>Nombre del producto *</label>
      <input type="text" id="f-nombre" placeholder="Ej: Pack Libros Escolares 2026" oninput="validarCampo('f-nombre')">
    </div>
    <div class="form-group">
      <label>Descripcion</label>
      <textarea id="f-descripcion" placeholder="Descripcion breve del producto..."></textarea>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label>Categoria *</label>
        <select id="f-categoria" onchange="validarCampo('f-categoria')">
          <option value="">-- Seleccionar --</option>
          <option value="Libros">Libros</option>
          <option value="Cuadernos">Cuadernos</option>
          <option value="Lapiceros">Lapiceros</option>
          <option value="Mochilas">Mochilas</option>
          <option value="Arte">Arte</option>
          <option value="Oficina">Oficina</option>
        </select>
      </div>
      <div class="form-group">
        <label>Precio (S/) *</label>
        <input type="number" id="f-precio" placeholder="0.00" min="0" step="0.10" oninput="validarCampo('f-precio')">
      </div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label>Stock inicial *</label>
        <input type="number" id="f-stock" placeholder="0" min="0" oninput="validarCampo('f-stock')">
      </div>
      <div class="form-group">
        <label>Ruta de imagen</label>
        <input type="text" id="f-imagen" placeholder="images/productos/nombre.png" oninput="actualizarPreview()">
      </div>
    </div>
    <div class="form-group">
      <label>Etiqueta especial</label>
      <select id="f-etiqueta">
        <option value="">Sin etiqueta</option>
        <option value="NUEVO">NUEVO</option>
        <option value="OFERTA">OFERTA</option>
        <option value="HOT">HOT</option>
        <option value="30% OFF">30% OFF</option>
        <option value="15% OFF">15% OFF</option>
      </select>
    </div>

    <div id="msg-modal" style="display:none;padding:10px 14px;border-radius:8px;font-size:0.85rem;font-weight:600;margin-bottom:8px;"></div>

    <div class="modal-footer">
      <button class="btn-cancelar-modal" onclick="cerrarModal()">Cancelar</button>
      <button class="btn-guardar" onclick="guardarProducto()">
        <img src="images/check.png" style="width:16px;height:16px;vertical-align:middle;filter:brightness(10);margin-right:4px;" alt="">
        Guardar producto
      </button>
    </div>
  </div>
</div>

<!-- Toast notificacion -->
<div class="alert-toast" id="toast"></div>

<script>
  // ================================================================
  //  DATOS DEMO — reemplazar por fetch a ProductoServlet cuando
  //  este conectado a MySQL
  //  Estructura compatible con Producto.java:
  //  { id, nombre, descripcion, precio, stock, categoria, imagen, activo, etiqueta }
  // ================================================================
  var productos = [
    { id:1, nombre:'Pack Libros Escolares Primaria Completo 2026', descripcion:'Coleccion completa de libros para primaria.',        precio:89.90, stock:15, categoria:'Libros',    imagen:'images/productos/pack-libros.png',        activo:true,  etiqueta:'30% OFF' },
    { id:2, nombre:'Cuaderno Universitario 100 hojas Cuadriculado', descripcion:'Cuaderno de 100 hojas cuadriculado.',              precio:8.50,  stock:80, categoria:'Cuadernos', imagen:'images/productos/agenda-escolar.png',      activo:true,  etiqueta:'' },
    { id:3, nombre:'Set Lapiceros Faber-Castell x 24 colores',      descripcion:'Set de 24 lapiceros de colores Faber-Castell.',   precio:25.00, stock:40, categoria:'Lapiceros', imagen:'images/productos/lapiceros-faber.png',     activo:true,  etiqueta:'NUEVO' },
    { id:4, nombre:'Mochila Escolar Resistente con Bolsillos',      descripcion:'Mochila resistente con bolsillos laterales.',     precio:65.00, stock:12, categoria:'Mochilas',  imagen:'images/productos/mochila-escolar.png',    activo:true,  etiqueta:'15% OFF' },
    { id:5, nombre:'Caja de Acuarelas Profesional 48 colores',      descripcion:'Acuarelas profesionales de 48 colores.',          precio:38.90, stock:20, categoria:'Arte',      imagen:'images/productos/acuarelas.png',           activo:true,  etiqueta:'' },
    { id:6, nombre:'Pizarra Acrilica 60x80cm con Marco Aluminio',   descripcion:'Pizarra acrilica de alta calidad.',               precio:120.00,stock:6,  categoria:'Oficina',   imagen:'images/productos/pizarra-acrilica.png',   activo:true,  etiqueta:'OFERTA' },
    { id:7, nombre:'Diccionario de Matematicas Escolar Ilustrado',  descripcion:'Diccionario matematico para escolares.',          precio:45.00, stock:18, categoria:'Libros',    imagen:'images/productos/diccionario-matematicas.png', activo:true, etiqueta:'' },
    { id:8, nombre:'Agenda Escolar 2026 Diseno Moderno',            descripcion:'Agenda escolar con diseno moderno.',              precio:18.00, stock:35, categoria:'Cuadernos', imagen:'images/productos/agenda-escolar.png',      activo:true,  etiqueta:'' },
    { id:9, nombre:'Resma Papel Bond A4 75gr x 500 hojas',          descripcion:'Resma de papel bond A4.',                        precio:22.50, stock:4,  categoria:'Oficina',   imagen:'images/productos/resma-papel.png',         activo:true,  etiqueta:'HOT' },
    { id:10,nombre:'Set Pinceles Artisticos x 12 unidades',         descripcion:'Set de 12 pinceles artisticos mixtos.',           precio:32.00, stock:3,  categoria:'Arte',      imagen:'images/productos/pinceles.png',            activo:false, etiqueta:'' }
  ];

  var nextId = 11;
  var editandoId = null;

  // ================================================================
  //  STATS
  // ================================================================
  function actualizarStats() {
    var total    = productos.length;
    var activos  = 0;
    var stockBajo = 0;
    var cats     = {};
    for (var i = 0; i < productos.length; i++) {
      var p = productos[i];
      if (p.activo) activos++;
      if (p.stock < 5) stockBajo++;
      cats[p.categoria] = true;
    }
    document.getElementById('stat-total').textContent     = total;
    document.getElementById('stat-activos').textContent   = activos;
    document.getElementById('stat-stock-bajo').textContent = stockBajo;
    document.getElementById('stat-categorias').textContent = Object.keys(cats).length;
  }

  // ================================================================
  //  RENDER TABLA
  // ================================================================
  function renderTabla() {
    var busq   = (document.getElementById('buscador').value || '').toLowerCase();
    var cat    = document.getElementById('filtro-cat').value;
    var estado = document.getElementById('filtro-estado').value;
    var tbody  = document.getElementById('tbody-productos');
    var contador = document.getElementById('contador-tabla');

    var lista = productos.slice();
    if (busq)   lista = lista.filter(function(p){ return p.nombre.toLowerCase().indexOf(busq) >= 0; });
    if (cat)    lista = lista.filter(function(p){ return p.categoria === cat; });
    if (estado === 'activo')   lista = lista.filter(function(p){ return p.activo; });
    if (estado === 'inactivo') lista = lista.filter(function(p){ return !p.activo; });

    contador.textContent = lista.length + ' producto' + (lista.length !== 1 ? 's' : '');

    if (lista.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7"><div class="sin-resultados">' +
        '<img src="images/empty.png" alt=""><br>No se encontraron productos</div></td></tr>';
      return;
    }

    var html = '';
    for (var i = 0; i < lista.length; i++) {
      var p = lista[i];

      var stockHtml = '';
      if (p.stock === 0)    stockHtml = '<span class="badge-stock-out">Sin stock</span>';
      else if (p.stock < 5) stockHtml = '<span class="badge-stock-low">&#9888; ' + p.stock + ' unid.</span>';
      else                  stockHtml = '<span class="badge-stock-ok">&#10003; ' + p.stock + ' unid.</span>';

      var estadoHtml = p.activo
        ? '<span class="badge-activo">Activo</span>'
        : '<span class="badge-inactivo">Inactivo</span>';

      var toggleTxt = p.activo ? 'Desactivar' : 'Activar';

      html +=
        '<tr>' +
          '<td><img src="' + p.imagen + '" class="prod-thumb" alt="' + p.nombre + '" onerror="this.src=\'images/productos.png\'"></td>' +
          '<td>' +
            '<div class="prod-nombre">' + p.nombre + '</div>' +
            '<div class="prod-desc">' + (p.descripcion || '') + '</div>' +
            (p.etiqueta ? '<span style="background:#FFE600;color:#333;padding:2px 8px;border-radius:10px;font-size:0.7rem;font-weight:700;margin-top:4px;display:inline-block;">' + p.etiqueta + '</span>' : '') +
          '</td>' +
          '<td><span class="badge-cat">' + p.categoria + '</span></td>' +
          '<td><strong style="font-family:Nunito,sans-serif;font-size:1rem;">S/ ' + p.precio.toFixed(2) + '</strong></td>' +
          '<td>' + stockHtml + '</td>' +
          '<td>' + estadoHtml + '</td>' +
          '<td>' +
            '<div style="display:flex;gap:5px;flex-wrap:wrap;">' +
              '<button class="btn-accion btn-editar" onclick="abrirModalEditar(' + p.id + ')">&#9998; Editar</button>' +
              '<button class="btn-accion btn-toggle" onclick="toggleActivo(' + p.id + ')">' + toggleTxt + '</button>' +
              '<button class="btn-accion btn-eliminar-tbl" onclick="eliminarProducto(' + p.id + ')">&#128465;</button>' +
            '</div>' +
          '</td>' +
        '</tr>';
    }
    tbody.innerHTML = html;
  }

  // ================================================================
  //  MODAL — NUEVO
  // ================================================================
  function abrirModalNuevo() {
    editandoId = null;
    document.getElementById('modal-titulo').textContent = 'Nuevo Producto';
    limpiarFormulario();
    document.getElementById('modal-prod').classList.add('open');
  }

  // ================================================================
  //  MODAL — EDITAR
  // ================================================================
  function abrirModalEditar(id) {
    var p = buscarPorId(id);
    if (!p) return;
    editandoId = id;
    document.getElementById('modal-titulo').textContent = 'Editar Producto';
    document.getElementById('f-nombre').value      = p.nombre;
    document.getElementById('f-descripcion').value = p.descripcion || '';
    document.getElementById('f-categoria').value   = p.categoria;
    document.getElementById('f-precio').value      = p.precio;
    document.getElementById('f-stock').value       = p.stock;
    document.getElementById('f-imagen').value      = p.imagen;
    document.getElementById('f-etiqueta').value    = p.etiqueta || '';
    document.getElementById('preview-img').src     = p.imagen || 'images/productos.png';
    document.getElementById('msg-modal').style.display = 'none';
    document.getElementById('modal-prod').classList.add('open');
  }

  // ================================================================
  //  GUARDAR (nuevo o editar)
  // ================================================================
  function guardarProducto() {
    var nombre    = document.getElementById('f-nombre').value.trim();
    var desc      = document.getElementById('f-descripcion').value.trim();
    var categoria = document.getElementById('f-categoria').value;
    var precio    = parseFloat(document.getElementById('f-precio').value);
    var stock     = parseInt(document.getElementById('f-stock').value);
    var imagen    = document.getElementById('f-imagen').value.trim() || 'images/productos.png';
    var etiqueta  = document.getElementById('f-etiqueta').value;

    if (!nombre)                      { mostrarMsgModal('El nombre es obligatorio.', 'error'); return; }
    if (!categoria)                   { mostrarMsgModal('Selecciona una categoria.', 'error'); return; }
    if (isNaN(precio) || precio < 0)  { mostrarMsgModal('Precio invalido.', 'error'); return; }
    if (isNaN(stock)  || stock < 0)   { mostrarMsgModal('Stock invalido.', 'error'); return; }

    var accion = (editandoId !== null) ? 'editar' : 'crear';
    var cuerpo = 'accion=' + accion
               + '&nombre='      + encodeURIComponent(nombre)
               + '&descripcion=' + encodeURIComponent(desc)
               + '&categoria='   + encodeURIComponent(categoria)
               + '&precio='      + precio
               + '&stock='       + stock
               + '&imagen='      + encodeURIComponent(imagen)
               + '&etiqueta='    + encodeURIComponent(etiqueta);

    if (editandoId !== null) {
      cuerpo += '&id=' + editandoId;
    }

    fetch('ProductoServlet', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: cuerpo
    })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (!data.ok) {
          mostrarMsgModal(data.error || 'No se pudo guardar el producto.', 'error');
          return;
        }
        cerrarModal();
        mostrarToast(accion === 'crear' ? 'Producto agregado correctamente' : 'Producto actualizado correctamente', 'ok');
        recargarProductos();
      })
      .catch(function() {
        mostrarMsgModal('Error de conexion con el servidor.', 'error');
      });
  }

  // ================================================================
  //  TOGGLE ACTIVO / INACTIVO
  // ================================================================
  function toggleActivo(id) {
    fetch('ProductoServlet', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'accion=toggleActivo&id=' + id
    })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (data.ok) {
          recargarProductos();
        } else {
          mostrarToast('No se pudo cambiar el estado.', 'err');
        }
      })
      .catch(function() { mostrarToast('Error de conexion.', 'err'); });
  }

  // ================================================================
  //  ELIMINAR
  // ================================================================
  function eliminarProducto(id) {
    var p = buscarPorId(id);
    if (!p) return;
    if (!confirm('Eliminar "' + p.nombre + '"? Esta accion no se puede deshacer.')) return;

    fetch('ProductoServlet', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'accion=eliminar&id=' + id
    })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (data.ok) {
          mostrarToast('Producto eliminado', 'ok');
          recargarProductos();
        } else {
          mostrarToast('No se pudo eliminar el producto.', 'err');
        }
      })
      .catch(function() { mostrarToast('Error de conexion.', 'err'); });
  }

  // ================================================================
  //  RECARGAR DESDE BD
  // ================================================================
  function recargarProductos() {
    fetch('ProductoServlet')
      .then(function(r) { return r.json(); })
      .then(function(data) {
        productos = data;
        for (var i = 0; i < productos.length; i++) {
          if (!productos[i].etiqueta)    productos[i].etiqueta    = '';
          if (!productos[i].descripcion) productos[i].descripcion = '';
          if (!productos[i].imagen)      productos[i].imagen      = 'images/productos.png';
        }
        renderTabla();
        actualizarStats();
      })
      .catch(function(e) { console.error('Error recargando productos:', e); });
  }

  // ================================================================
  //  HELPERS
  // ================================================================
  function buscarPorId(id) {
    for (var i = 0; i < productos.length; i++) {
      if (productos[i].id === id) return productos[i];
    }
    return null;
  }

  function limpiarFormulario() {
    document.getElementById('f-nombre').value      = '';
    document.getElementById('f-descripcion').value = '';
    document.getElementById('f-categoria').value   = '';
    document.getElementById('f-precio').value      = '';
    document.getElementById('f-stock').value       = '';
    document.getElementById('f-imagen').value      = '';
    document.getElementById('f-etiqueta').value    = '';
    document.getElementById('preview-img').src     = 'images/productos.png';
    document.getElementById('msg-modal').style.display = 'none';
  }

  function actualizarPreview() {
    var ruta = document.getElementById('f-imagen').value.trim();
    document.getElementById('preview-img').src = ruta || 'images/productos.png';
  }

  function validarCampo(id) {
    var el = document.getElementById(id);
    el.style.borderColor = el.value.trim() ? '#00A650' : '#dc3545';
  }

  function mostrarMsgModal(txt, tipo) {
    var m = document.getElementById('msg-modal');
    m.textContent = txt;
    m.style.display = '';
    m.style.background = tipo === 'error' ? '#F8D7DA' : '#D4EDDA';
    m.style.color      = tipo === 'error' ? '#721c24' : '#155724';
  }

  function cerrarModal() {
    document.getElementById('modal-prod').classList.remove('open');
  }
  function cerrarModalClick(e) {
    if (e.target.id === 'modal-prod') cerrarModal();
  }

  function mostrarToast(txt, tipo) {
    var t = document.getElementById('toast');
    t.textContent = txt;
    t.className = 'alert-toast show ' + (tipo === 'ok' ? 'toast-ok' : 'toast-err');
    clearTimeout(window._toastTimer);
    window._toastTimer = setTimeout(function(){ t.className = 'alert-toast'; }, 3000);
  }

//================================================================
//INIT - CARGAR DESDE MYSQL
//================================================================

fetch('ProductoServlet')
   .then(function(response) {
       return response.json();
   })
   .then(function(data) {

       productos = data;

       for (var i = 0; i < productos.length; i++) {

           if (productos[i].etiqueta == null) {
               productos[i].etiqueta = '';
           }

           if (productos[i].descripcion == null) {
               productos[i].descripcion = '';
           }

           if (productos[i].imagen == null || productos[i].imagen === '') {
               productos[i].imagen = 'images/productos.png';
           }
       }

       renderTabla();
       actualizarStats();
   })
   .catch(function(error) {

       console.error('Error cargando productos:', error);

       renderTabla();
       actualizarStats();
   });
</script>
</body>
</html>
