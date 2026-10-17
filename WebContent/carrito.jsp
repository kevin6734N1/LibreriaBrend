<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%-- El carrito y el checkout son del comprador: la sesion de administrador
     no puede cerrar pedidos, asi que se le devuelve a su panel. --%>
<% if ("admin".equals(session.getAttribute("rol"))) {
     response.sendRedirect(request.getContextPath() + "/admin.jsp");
     return;
   } %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mi Carrito | Librería Brenda</title>
  <link rel="stylesheet" href="css/style.css">
  <style>
    .icon-img { width: 24px; height: 24px; vertical-align: middle; }
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
    .pago-metodos {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 8px;
    }
    .pago-card {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 6px;
      border: 1.5px solid #ddd;
      border-radius: 8px;
      padding: 10px 6px;
      cursor: pointer;
      text-align: center;
      transition: border-color 0.15s, background 0.15s;
    }
    .pago-card:hover { border-color: #1259C3; background: #f5f9ff; }
    .pago-card.selected { border-color: #1259C3; background: #E3F2FD; box-shadow: 0 0 0 2px rgba(18,89,195,0.25); }
    .pago-card img { width: 28px; height: 28px; object-fit: contain; }
    .pago-card span { font-size: 0.72rem; font-weight: 700; color: #444; }
    .btn-promo { background:#1259C3; color:#fff; border:none; border-radius:8px; padding:9px 16px; font-weight:700; cursor:pointer; }
    .btn-promo:hover { background:#0d47a1; }
  </style>
</head>
<body>

  <a href="#contenido-principal" class="skip-link">Saltar al contenido principal</a>

  <!-- NAVBAR -->
  <nav class="navbar" aria-label="Navegación principal">
    <a href="index.jsp" class="logo">
      <img src="images/libro-logo.png" class="icon-img" style="width:32px;height:32px;" alt="">
      Librería Brenda
    </a>
    <div class="search-bar">
      <input type="text" placeholder="Buscar productos..." aria-label="Buscar productos">
      <button aria-label="Buscar">&#128269;</button>
    </div>
    <div class="navbar-links">
      <a href="index.jsp"><img src="images/inicio.png" class="icon-img" alt=""> Inicio</a>
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
        <a href="login.jsp"><img src="images/usuario.png" class="icon-img" alt=""> Mi cuenta</a>
      <% } %>
      <a href="carrito.jsp" class="btn-carrito" style="position:relative">
        <img src="images/carrito.png" class="icon-img" alt=""> 
        Carrito
        <span class="badge" id="carrito-badge" role="status" aria-live="polite" aria-label="Productos en el carrito">0</span>
      </a>
    </div>
  </nav>

  <main id="contenido-principal">

  <!-- BREADCRUMB -->
  <div style="padding:12px 20px; font-size:0.85rem; color:#666; background:white; border-bottom:1px solid #e0e0e0;">
    <a href="index.jsp" style="color:#1259C3; text-decoration:none;">Inicio</a>
    &nbsp;›&nbsp; Mi Carrito
  </div>

  <div class="carrito-container">

    <!-- Lista de ítems -->
    <div class="carrito-items">
      <h2 style="font-family:'Nunito',sans-serif; font-weight:800; margin-bottom:20px; font-size:1.3rem;">
        <img src="images/carrito.png" class="icon-img" style="width:32px;height:32px;" alt=""> 
        Mi Carrito de Compras
      </h2>
      <div id="carrito-lista" aria-live="polite">
        <!-- JS carga los productos -->
      </div>
    </div>

    <!-- Resumen de pago -->
    <div class="carrito-resumen" aria-live="polite" aria-atomic="true">
      <h3>Resumen del pedido</h3>

      <div class="resumen-fila">
        <span>Subtotal</span>
        <span id="resumen-items">S/ 0.00</span>
      </div>
      <div class="resumen-fila" id="fila-descuento" style="display:none; color:#00A650; font-weight:700;">
        <span>Descuento</span>
        <span id="resumen-descuento">- S/ 0.00</span>
      </div>
      <div class="resumen-fila">
        <span>Envío</span>
        <span id="resumen-envio" style="color:#00A650; font-weight:700;">¡Gratis!</span>
      </div>
      <div class="resumen-fila total">
        <span>Total</span>
        <span id="resumen-total">S/ 0.00</span>
      </div>

      <div class="promo-box" style="margin:16px 0;">
        <label for="input-promo" style="display:block; font-size:0.82rem; font-weight:700; color:#444; margin-bottom:5px;">Código promocional</label>
        <div style="display:flex; gap:8px;">
          <input type="text" id="input-promo" maxlength="30" autocomplete="off" autocapitalize="characters"
                 placeholder="Ej: BIENVENIDA10" aria-describedby="promo-msg"
                 style="flex:1; padding:9px 10px; border:1.5px solid #ccc; border-radius:8px; font-size:0.9rem; text-transform:uppercase;"
                 onkeydown="if(event.key==='Enter'){event.preventDefault();aplicarCodigoPromo();}">
          <button type="button" id="btn-aplicar-promo" class="btn-promo" onclick="aplicarCodigoPromo()">Aplicar</button>
          <button type="button" id="btn-quitar-promo" class="btn-promo" style="display:none" onclick="quitarCodigoPromo()" aria-label="Quitar código promocional">Quitar</button>
        </div>
        <p id="promo-msg" role="status" aria-live="polite" style="font-size:0.82rem; margin-top:6px; min-height:1.2em;"></p>
      </div>

      <!-- === DATOS DE ENTREGA === -->
      <div class="datos-entrega-box" style="margin:20px 0;">
        <h4 style="font-family:'Nunito',sans-serif; font-weight:800; font-size:1rem; margin-bottom:12px;">
          <img src="images/ubicacion.png" class="icon-img" alt=""> Datos de entrega
        </h4>

        <label for="input-direccion" style="display:block; font-size:0.82rem; font-weight:700; color:#444; margin-bottom:5px;">
          Dirección de entrega
        </label>
        <input type="text" id="input-direccion" placeholder="Ej: Av. Arequipa 1234, Miraflores"
          style="width:100%; box-sizing:border-box; padding:10px 12px; border:1.5px solid #ddd; border-radius:8px; font-family:'Lato',sans-serif; font-size:0.9rem; margin-bottom:14px;">

        <span id="lbl-pago" style="display:block; font-size:0.82rem; font-weight:700; color:#444; margin-bottom:8px;">
          Método de pago
        </span>
        <input type="hidden" id="input-pago" value="">
        <div class="pago-metodos" id="pago-metodos" role="radiogroup" aria-labelledby="lbl-pago">
          <div class="pago-card" data-valor="Tarjeta Visa" role="radio" aria-checked="false" tabindex="0"
               onclick="seleccionarPago(this)"
               onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();seleccionarPago(this)}">
            <img src="images/visa.png" alt=""><span>Visa</span>
          </div>
          <div class="pago-card" data-valor="Tarjeta Mastercard" role="radio" aria-checked="false" tabindex="0"
               onclick="seleccionarPago(this)"
               onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();seleccionarPago(this)}">
            <img src="images/mastercard.png" alt=""><span>Mastercard</span>
          </div>
          <div class="pago-card" data-valor="Yape" role="radio" aria-checked="false" tabindex="0"
               onclick="seleccionarPago(this)"
               onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();seleccionarPago(this)}">
            <img src="images/yape.png" alt=""><span>Yape</span>
          </div>
          <div class="pago-card" data-valor="Plin" role="radio" aria-checked="false" tabindex="0"
               onclick="seleccionarPago(this)"
               onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();seleccionarPago(this)}">
            <img src="images/plin.png" alt=""><span>Plin</span>
          </div>
          <div class="pago-card" data-valor="Transferencia BCP" role="radio" aria-checked="false" tabindex="0"
               onclick="seleccionarPago(this)"
               onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();seleccionarPago(this)}">
            <img src="images/bcp.png" alt=""><span>Transferencia BCP</span>
          </div>
          <div class="pago-card" data-valor="Efectivo contra entrega" role="radio" aria-checked="false" tabindex="0"
               onclick="seleccionarPago(this)"
               onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();seleccionarPago(this)}">
            <img src="images/efectivo.png" alt=""><span>Efectivo</span>
          </div>
        </div>
      </div>

      <button class="btn-comprar" onclick="realizarPedido()">
        <img src="images/check.png" class="icon-img" alt=""> 
        Realizar pedido
      </button>

      <a href="index.jsp" style="display:block;text-align:center;margin-top:12px;color:#1259C3;font-size:0.88rem;font-weight:700;text-decoration:none;">
        ← Seguir comprando
      </a>
    </div>

  </div>

  </main>

  <!-- FOOTER -->
  <footer class="footer">
    <p><strong>Librería Brenda</strong> | Lima, Perú &nbsp;|&nbsp; © 2026 
      <br><small>Comprometidos con la diversidad y la reducción de desigualdades</small>
    </p>
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

    function seleccionarPago(el) {
      document.querySelectorAll('.pago-card').forEach(c => {
        c.classList.remove('selected');
        c.setAttribute('aria-checked', 'false');
      });
      el.classList.add('selected');
      el.setAttribute('aria-checked', 'true');
      document.getElementById('input-pago').value = el.dataset.valor;
    }

    function realizarPedido() {
      const carrito = JSON.parse(localStorage.getItem('carritoBrend') || '[]');
      if (carrito.length === 0) {
        alert('Tu carrito está vacío.');
        return;
      }

      const direccion = document.getElementById('input-direccion').value.trim();
      const pago = document.getElementById('input-pago').value;

      if (!direccion) {
        alert('Por favor ingresa una dirección de entrega.');
        document.getElementById('input-direccion').focus();
        return;
      }
      if (!pago) {
        alert('Por favor selecciona un método de pago.');
        document.getElementById('pago-metodos').scrollIntoView({ behavior: 'smooth', block: 'center' });
        return;
      }

      guardarPedidoEnDB(carrito, direccion, pago)
        .then(data => {
          if (data.ok) {
            localStorage.removeItem('carritoBrend');

            alert('¡Pedido realizado con éxito!\n\nNúmero: ' + data.id);
            window.location.href = 'pedidos.jsp';
          } else {
            if (data.requiereLogin) {
              alert('Inicia sesión para registrar tu pedido. Te llevaremos al inicio de sesión.');
              window.location.href = 'login.jsp';
              return;
            }
            alert('No se pudo completar el pedido:\n' + (data.error || 'Error desconocido.'));
            if (btn) { btn.disabled = false; btn.innerHTML = btnHtmlOriginal; }
          }
        })
        .catch(err => {
          console.error(err);
          alert('No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.');
          if (btn) { btn.disabled = false; btn.innerHTML = btnHtmlOriginal; }
        });
    }

    // Envía el carrito al servidor para registrar el pedido de verdad.
    // Devuelve la Promise del fetch para que realizarPedido() espere la
    // respuesta antes de vaciar el carrito o avisar éxito.
    function guardarPedidoEnDB(carrito, direccion, pago) {
      const params = new URLSearchParams();
      params.append('accion', 'guardarDB');
      params.append('direccion', direccion || '');
      params.append('pago', pago || '');
      if (promoAplicada) params.append('codigoPromo', promoAplicada.codigo);
      carrito.forEach(it => {
        if (!it.id) return; // productos sin id conocido no se pueden ligar a la tabla productos
        params.append('item_id', it.id);
        params.append('item_qty', it.qty);
        params.append('item_precio', it.precio);
      });

      return fetch('PedidoServlet', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
      }).then(r => {
        // Sin sesion el servidor responde 401: no se registra nada.
        if (r.status === 401) {
          return { ok: false, requiereLogin: true, error: 'Inicia sesión para registrar tu pedido.' };
        }
        return r.json();
      });
    }
  </script>
<script src="js/accesibilidad.js"></script>
</body>
</html>