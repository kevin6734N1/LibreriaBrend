<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC" crossorigin="anonymous">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Librería Brenda | Tienda Online</title>
  <link rel="stylesheet" href="css/style.css">
  <style>
    .icon-img {
      width: 24px;
      height: 24px;
      vertical-align: middle;
    }
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
  </style>
</head>
<body>

  <a href="#contenido-principal" class="skip-link">Saltar al contenido principal</a>

  <!-- ===== NAVBAR ===== -->
  <nav class="navbar" aria-label="Navegación principal">
    <a href="index.jsp" class="logo">
      <img src="images/libro-logo.png" class="icon-img" style="width:32px; height:32px;" alt=""> 
      Librería Brenda
    </a>

    <div class="search-bar">
      <input type="text" id="busqueda" aria-label="Buscar productos" placeholder="Buscar libros, cuadernos, útiles...">
      <button onclick="buscarProductos()" aria-label="Buscar">🔍</button>
    </div>

    <div class="navbar-links">
      <%
        String rolSesion = (String) session.getAttribute("rol");
        String nombreCliente = (String) session.getAttribute("clienteNombre");
      %>
      <% if ("cliente".equals(rolSesion) && nombreCliente != null) { %>
        <div class="cuenta-dropdown">
          <button class="cuenta-dropdown-btn" onclick="toggleCuentaMenu(event)" aria-haspopup="true" aria-expanded="false">
            <img src="images/usuario.png" class="icon-img" alt=""> Hola, <%= nombreCliente.split(" ")[0] %> ▾
          </button>
          <div class="cuenta-dropdown-menu" id="cuenta-dropdown-menu">
            <a href="pedidos.jsp">Mis Pedidos</a>
            <a href="LogoutServlet">Cerrar sesión</a>
          </div>
        </div>
      <% } else { %>
        <a href="login.jsp">
          <img src="images/usuario.png" class="icon-img" alt="Cuenta"> Ingresar
        </a>
        <a href="registro.jsp">Registrarse</a>
      <% } %>
      <a href="carrito.jsp" class="btn-carrito" style="position:relative">
        <img src="images/carrito.png" class="icon-img" alt=""> 
        Carrito
        <span class="badge" id="carrito-badge" role="status" aria-live="polite" aria-label="Productos en el carrito">0</span>
      </a>
    </div>
  </nav>

  <main id="contenido-principal">

  <!-- ===== CATEGORÍAS ===== -->
  <div class="categorias-bar">
    <a href="#" role="button" class="active" onclick="filtrar('todos')">
      <img src="images/todos.png" class="icon-img" alt=""> Todos
    </a>
    <a href="#" role="button" onclick="filtrar('libros')">
      <img src="images/libro-logo.png" class="icon-img" alt=""> Libros
    </a>
    <a href="#" role="button" onclick="filtrar('cuadernos')">
      <img src="images/productos.png" class="icon-img" alt=""> Cuadernos
    </a>
    <a href="#" role="button" onclick="filtrar('lapiceros')">
      <img src="images/tienda.png" class="icon-img" alt=""> Lapiceros
    </a>
    <a href="#" role="button" onclick="filtrar('mochilas')">
      <img src="images/mochila-silueta.png" class="icon-img" alt=""> Mochilas
    </a>
    <a href="#" role="button" onclick="filtrar('arte')">
      <img src="images/acuarelas.png" class="icon-img" alt=""> Arte
    </a>
    <a href="#" role="button" onclick="filtrar('oficina')">
      <img src="images/dashboard.png" class="icon-img" alt=""> Oficina
    </a>
  </div>

  <!-- ===== BANNER ===== -->
  <div class="banner">
    <div>
      <h1>¡Bienvenido a Librería Brenda!</h1>
      <p>Encuentra todo para tus estudios y oficina con los mejores precios</p>
      <a href="#productos" class="btn-banner">Ver catálogo</a>
    </div>
  </div>

  <!-- ===== OFERTAS ===== -->
  <h2 class="seccion-titulo">🔥 Ofertas del día</h2>
  <div class="productos-grid" id="productos" aria-live="polite" aria-busy="true">
    <p id="productos-cargando" style="padding:40px;text-align:center;color:#666;grid-column:1/-1">
      Cargando productos...
    </p>
  </div>

  </main>

  <!-- ===== FOOTER ===== -->
  <footer class="footer">
    <p><strong>Librería Brenda</strong> | Lima, Perú &nbsp;|&nbsp; © 2026 Todos los derechos reservados</p>
    <p style="margin-top:6px; font-size:0.8rem;">Proyecto académico - IHC G2 | ISC</p>
  </footer>

  <script src="js/carrito.js"></script>
  <script>
    // ================================================================
    //  MENÚ DE CUENTA (dropdown "Hola, {nombre}")
    // ================================================================
    function toggleCuentaMenu(e) {
      e.stopPropagation();
      var menu = document.getElementById('cuenta-dropdown-menu');
      var abierto = menu ? menu.classList.toggle('show') : false;
      e.currentTarget.setAttribute('aria-expanded', abierto ? 'true' : 'false');
    }
    document.addEventListener('click', function() {
      var menu = document.getElementById('cuenta-dropdown-menu');
      if (menu) menu.classList.remove('show');
      var btn = document.querySelector('.cuenta-dropdown-btn');
      if (btn) btn.setAttribute('aria-expanded', 'false');
    });

    // ================================================================
    //  PRODUCTOS — cargados desde MySQL vía ProductoServlet
    //  (antes eran 10 tarjetas fijas escritas a mano en el HTML)
    // ================================================================
    function crearTarjetaProducto(p) {
      var imagen = (p.imagen && p.imagen.trim() !== '') ? p.imagen : 'images/productos.png';
      var categoria = (p.categoria || '').toLowerCase();

      var badge = (p.etiqueta && p.etiqueta.trim() !== '')
        ? '<span class="badge-oferta">' + p.etiqueta + '</span>'
        : '';

      // Misma regla de envío gratis que usa el carrito (>= S/30)
      var envio = (p.precio >= 30)
        ? '<p class="envio">✅ Envío gratis</p>'
        : '<p class="envio">✅ Envío gratis desde S/30</p>';

      var nombreEscapado = p.nombre.replace(/'/g, "\\'");

      var card = document.createElement('div');
      card.className = 'producto-card';
      card.dataset.categoria = categoria;
      card.innerHTML =
        '<div class="img-wrap">' +
          '<img src="' + imagen + '" alt="' + p.nombre.replace(/"/g, '&quot;') + '">' +
        '</div>' +
        '<div class="info">' +
          badge +
          '<p class="nombre">' + p.nombre + '</p>' +
          '<p class="precio"><span>S/</span>' + p.precio.toFixed(2) + '</p>' +
          envio +
          '<button type="button" class="btn-leer-voz" aria-pressed="false" aria-label="Leer en voz alta: ' + p.nombre.replace(/"/g, '&quot;') + '">🔊 Escuchar</button>' +
          '<button class="btn-agregar" aria-label="Agregar ' + p.nombre.replace(/"/g, '&quot;') + ' al carrito" onclick="agregarCarrito(' + p.id + ", '" + nombreEscapado + "', " + p.precio + ')">' +
            '+ Agregar al carrito' +
          '</button>' +
        '</div>';

      // Texto que lee el boton 🔊 (pieza 3). Va como dataset y no en un
      // atributo onclick para no pelear con comillas ni apostrofes.
      // "12.50" se lee "12 con 50 soles": suena natural en la sintesis.
      var precioTxt = p.precio.toFixed(2).replace('.', ' con ');
      card.dataset.textoVoz = p.nombre + '. ' +
        (p.descripcion ? p.descripcion + '. ' : '') +
        'Categoría: ' + (p.categoria || 'sin categoría') + '. ' +
        'Precio: ' + precioTxt + ' soles.' +
        (p.precio >= 30 ? ' Envío gratis.' : '');

      return card;
    }

    function cargarProductos() {
      var grid = document.getElementById('productos');

      fetch('ProductoServlet')
        .then(function(r) { return r.json(); })
        .then(function(data) {
          var activos = data.filter(function(p) { return p.activo; });

          grid.innerHTML = '';

          if (activos.length === 0) {
            grid.innerHTML = '<p style="padding:40px;text-align:center;color:#666;grid-column:1/-1">No hay productos disponibles por el momento.</p>';
            return;
          }

          activos.forEach(function(p) {
            grid.appendChild(crearTarjetaProducto(p));
          });
          grid.setAttribute('aria-busy', 'false');
        })
        .catch(function(e) {
          console.error('Error cargando productos:', e);
          grid.innerHTML = '<p style="padding:40px;text-align:center;color:#c0392b;grid-column:1/-1">No se pudieron cargar los productos. Intenta recargar la página.</p>';
          grid.setAttribute('aria-busy', 'false');
        });
    }

    document.addEventListener('DOMContentLoaded', cargarProductos);

    function filtrar(cat) {
      const cards = document.querySelectorAll('.producto-card');
      cards.forEach(c => {
        c.style.display = (cat === 'todos' || c.dataset.categoria === cat) ? '' : 'none';
      });
      document.querySelectorAll('.categorias-bar a').forEach(a => {
        a.classList.remove('active');
        a.removeAttribute('aria-current');
      });
      var link = event.target.closest('a');
      if (link) {
        link.classList.add('active');
        link.setAttribute('aria-current', 'true');
      }
    }

    function buscarProductos() {
      const q = document.getElementById('busqueda').value.toLowerCase();
      document.querySelectorAll('.producto-card').forEach(c => {
        const nombre = c.querySelector('.nombre').textContent.toLowerCase();
        c.style.display = nombre.includes(q) ? '' : 'none';
      });
    }

    document.getElementById('busqueda').addEventListener('keydown', e => {
      if (e.key === 'Enter') buscarProductos();
    });
  </script>
<script src="js/accesibilidad.js"></script>
</body>
</html>
