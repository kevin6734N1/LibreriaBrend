<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Productos | Libreria Brenda Admin</title>
  <link rel="stylesheet" href="css/style.css">
  <link rel="stylesheet" href="css/admin.css">
  <style>
    /* ===== Estilos propios de Productos ===== */
    .prod-thumb { width: 48px; height: 48px; object-fit: contain; border-radius: 6px; background: var(--gris-card); padding: 3px; }
    .prod-nombre { font-weight: 700; font-size: 0.9rem; }
    .prod-desc { font-size: 0.78rem; color: #888; margin-top: 2px; }
  </style>
</head>
<body>
<div class="admin-layout">

  <!-- ===== SIDEBAR ===== -->
  <%@ include file="/WEB-INF/jspf/admin-sidebar.jspf" %>

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
    <div class="admin-table-wrap tabla-cards">
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

    <!-- Imagen: arrastrar y soltar o elegir desde el equipo -->
    <div class="form-group">
      <label for="f-archivo">Imagen del producto</label>
      <div class="dropzone" id="dropzone" role="button" tabindex="0"
           aria-label="Arrastra una imagen o pulsa para elegirla"
           aria-describedby="dropzone-ayuda">
        <img id="preview-img" class="preview-img" src="images/productos.png" alt="Vista previa de la imagen">
        <div class="dropzone-texto">
          <strong>Arrastra una imagen aquí</strong>
          <span>o haz clic para elegirla desde tu equipo</span>
          <span class="dropzone-hint" id="dropzone-ayuda">JPG, PNG, GIF o WEBP &middot; máximo 3 MB</span>
        </div>
      </div>
      <input type="file" id="f-archivo" accept="image/jpeg,image/png,image/gif,image/webp" hidden>
      <p class="dropzone-estado" id="estado-imagen" role="status" aria-live="polite"></p>
      <label class="label-ruta" for="f-imagen">Ruta guardada en el proyecto</label>
      <input type="text" id="f-imagen" class="input-ruta" placeholder="images/productos/mi-imagen.png" oninput="actualizarPreview()">
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
    </div>

    <div id="msg-modal" style="display:none;padding:10px 14px;border-radius:8px;font-size:0.85rem;font-weight:600;margin-bottom:8px;"></div>

    <div class="modal-footer">
      <button class="btn-cancelar-modal" onclick="cerrarModal()">Cancelar</button>
      <button class="btn-guardar" onclick="guardarProducto()">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M20 6L9 17l-5-5"></path>
        </svg>
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
      tbody.innerHTML = '<tr><td colspan="7" class="celda-vacia"><div class="sin-resultados">' +
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
          '<td data-label="Imagen"><img src="' + p.imagen + '" class="prod-thumb" alt="' + p.nombre + '" onerror="this.src=\'images/productos.png\'"></td>' +
          '<td data-label="Producto">' +
            '<div class="prod-nombre">' + p.nombre + '</div>' +
            '<div class="prod-desc">' + (p.descripcion || '') + '</div>' +
            (p.etiqueta ? '<span style="background:#FFE600;color:#333;padding:2px 8px;border-radius:10px;font-size:0.7rem;font-weight:700;margin-top:4px;display:inline-block;">' + p.etiqueta + '</span>' : '') +
          '</td>' +
          '<td data-label="Categoría"><span class="badge-cat">' + p.categoria + '</span></td>' +
          '<td data-label="Precio"><strong style="font-family:Nunito,sans-serif;font-size:1rem;">S/ ' + p.precio.toFixed(2) + '</strong></td>' +
          '<td data-label="Stock">' + stockHtml + '</td>' +
          '<td data-label="Estado">' + estadoHtml + '</td>' +
          '<td data-label="Acciones" class="celda-acciones">' +
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
    document.getElementById('estado-imagen').textContent = '';
    document.getElementById('msg-modal').style.display = 'none';
    document.getElementById('modal-prod').classList.add('open');
  }

  // ================================================================
  //  SUBIDA DE IMAGEN (arrastrar y soltar / elegir archivo)
  //  El archivo NO se manda junto al producto: se sube primero a
  //  ImagenProductoServlet, que lo guarda en images/productos y devuelve
  //  la ruta. El formulario solo envia esa ruta, igual que antes.
  // ================================================================
  var subiendoImagen = false;
  var TIPOS_IMAGEN  = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
  var MAX_IMAGEN_MB = 3;

  function iniciarDropzone() {
    var zona  = document.getElementById('dropzone');
    var input = document.getElementById('f-archivo');
    if (!zona || !input) return;

    zona.addEventListener('click', function() { input.click(); });
    zona.addEventListener('keydown', function(e) {
      if (e.key === 'Enter' || e.key === ' ' || e.key === 'Spacebar') {
        e.preventDefault();
        input.click();
      }
    });
    input.addEventListener('change', function() {
      if (input.files && input.files[0]) subirImagen(input.files[0]);
    });

    // Evita que el navegador abra la imagen si se suelta FUERA de la zona,
    // sin romper otros elementos que acepten archivos.
    ['dragover', 'drop'].forEach(function(ev) {
      document.addEventListener(ev, function(e) {
        if (!zona.contains(e.target)) e.preventDefault();
      });
    });

    ['dragenter', 'dragover'].forEach(function(ev) {
      zona.addEventListener(ev, function(e) {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'copy';
        zona.classList.add('dragover');
      });
    });
    ['dragleave', 'dragend'].forEach(function(ev) {
      zona.addEventListener(ev, function(e) {
        if (e.target === zona) zona.classList.remove('dragover');
      });
    });
    zona.addEventListener('drop', function(e) {
      e.preventDefault();
      zona.classList.remove('dragover');
      if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) {
        subirImagen(e.dataTransfer.files[0]);
      }
    });
  }

  function subirImagen(file) {
    var preview = document.getElementById('preview-img');
    var ruta    = document.getElementById('f-imagen');
    var input   = document.getElementById('f-archivo');
    var anterior = ruta.value;

    if (TIPOS_IMAGEN.indexOf(file.type) < 0) {
      mostrarEstadoImagen('Formato no permitido. Usa JPG, PNG, GIF o WEBP.', 'error');
      input.value = '';
      return;
    }
    if (file.size > MAX_IMAGEN_MB * 1024 * 1024) {
      mostrarEstadoImagen('La imagen pesa demasiado (máximo ' + MAX_IMAGEN_MB + ' MB).', 'error');
      input.value = '';
      return;
    }

    // Vista previa inmediata mientras sube
    preview.src = URL.createObjectURL(file);
    subiendoImagen = true;
    actualizarBotonGuardar();
    mostrarEstadoImagen('Subiendo ' + file.name + '…', 'subiendo');

    var datos = new FormData();
    datos.append('archivo', file);

    fetch('ImagenProductoServlet', { method: 'POST', body: datos })
      .then(function(r) {
        if (r.status === 401) {
          window.location.href = 'login.jsp?error=sesion';
          return null;
        }
        return r.json();
      })
      .then(function(data) {
        if (!data) return;
        if (!data.ok) {
          ruta.value = anterior;
          preview.src = anterior || 'images/productos.png';
          mostrarEstadoImagen(data.error || 'No se pudo subir la imagen.', 'error');
          return;
        }
        ruta.value = data.imagen;
        preview.src = data.imagen;
        mostrarEstadoImagen('Guardada en ' + data.imagen, 'ok');
        mostrarToast('Imagen subida correctamente', 'ok');
      })
      .catch(function() {
        ruta.value = anterior;
        preview.src = anterior || 'images/productos.png';
        mostrarEstadoImagen('Error de conexión al subir la imagen.', 'error');
      })
      .then(function() {
        subiendoImagen = false;
        actualizarBotonGuardar();
        input.value = '';
      });
  }

  function mostrarEstadoImagen(txt, tipo) {
    var el = document.getElementById('estado-imagen');
    el.textContent = txt || '';
    el.className = 'dropzone-estado' + (tipo ? ' ' + tipo : '');
  }

  function actualizarBotonGuardar() {
    var btn = document.querySelector('.modal-footer .btn-guardar');
    if (btn) btn.disabled = subiendoImagen;
  }

  // ================================================================
  //  GUARDAR (nuevo o editar)
  // ================================================================
  function guardarProducto() {
    if (subiendoImagen) {
      mostrarMsgModal('Espera a que termine la subida de la imagen.', 'error');
      return;
    }

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
    document.getElementById('estado-imagen').textContent = '';
    document.getElementById('f-archivo').value     = '';
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
//INIT - DROPZONE + CARGAR DESDE MYSQL
//================================================================
iniciarDropzone();

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
<script src="js/accesibilidad.js"></script>
</body>
</html>
