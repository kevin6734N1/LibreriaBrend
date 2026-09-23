<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
    .inclusion-box {
      background: linear-gradient(135deg, #E3F2FD, #F0F4FF);
      border: 2px solid #1259C3;
      border-radius: 12px;
      padding: 18px;
      margin: 25px 0;
      font-size: 1.02rem;
      color: #0d47a1;
      box-shadow: 0 4px 12px rgba(18, 89, 195, 0.15);
    }
    .inclusion-box strong { color: #1259C3; }
    .ods10-check {
      display: flex;
      align-items: flex-start;
      gap: 10px;
      background: rgba(255,255,255,0.6);
      border: 1.5px solid #bcd6f7;
      border-radius: 8px;
      padding: 10px 12px;
      margin-top: 10px;
      cursor: pointer;
      transition: background 0.15s, border-color 0.15s;
    }
    .ods10-check:hover { background: rgba(255,255,255,0.9); border-color: #1259C3; }
    .ods10-check input[type="checkbox"] {
      width: 18px;
      height: 18px;
      margin-top: 1px;
      accent-color: #1259C3;
      cursor: pointer;
      flex-shrink: 0;
    }
    .ods10-check span { line-height: 1.35; }
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
  </style>
</head>
<body>

  <!-- NAVBAR -->
  <nav class="navbar">
    <a href="index.jsp" class="logo">
      <img src="images/libro-logo.png" class="icon-img" style="width:32px;height:32px;" alt="Logo">
      Librería Brenda
    </a>
    <div class="search-bar">
      <input type="text" placeholder="Buscar productos...">
      <button>&#128269;</button>
    </div>
    <div class="navbar-links">
      <a href="index.jsp"><img src="images/inicio.png" class="icon-img" alt=""> Inicio</a>
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
        <img src="images/carrito.png" class="icon-img" alt="Carrito"> 
        Carrito
        <span class="badge" id="carrito-badge">0</span>
      </a>
    </div>
  </nav>

  <!-- BREADCRUMB -->
  <div style="padding:12px 20px; font-size:0.85rem; color:#666; background:white; border-bottom:1px solid #e0e0e0;">
    <a href="index.jsp" style="color:#1259C3; text-decoration:none;">Inicio</a>
    &nbsp;›&nbsp; Mi Carrito
  </div>

  <div class="carrito-container">

    <!-- Lista de ítems -->
    <div class="carrito-items">
      <h2 style="font-family:'Nunito',sans-serif; font-weight:800; margin-bottom:20px; font-size:1.3rem;">
        <img src="images/carrito.png" class="icon-img" style="width:32px;height:32px;" alt="Carrito"> 
        Mi Carrito de Compras
      </h2>
      <div id="carrito-lista">
        <!-- JS carga los productos -->
      </div>
    </div>

    <!-- Resumen de pago -->
    <div class="carrito-resumen">
      <h3>Resumen del pedido</h3>

      <div class="resumen-fila">
        <span>Subtotal</span>
        <span id="resumen-items">S/ 0.00</span>
      </div>
      <div class="resumen-fila" id="fila-descuento" style="display:none; color:#00A650; font-weight:700;">
        <span>Descuento estudiante (ODS10, -15%)</span>
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

        <label style="display:block; font-size:0.82rem; font-weight:700; color:#444; margin-bottom:8px;">
          Método de pago
        </label>
        <input type="hidden" id="input-pago" value="">
        <div class="pago-metodos" id="pago-metodos">
          <div class="pago-card" data-valor="Tarjeta Visa" onclick="seleccionarPago(this)">
            <img src="images/visa.png" alt="Visa"><span>Visa</span>
          </div>
          <div class="pago-card" data-valor="Tarjeta Mastercard" onclick="seleccionarPago(this)">
            <img src="images/mastercard.png" alt="Mastercard"><span>Mastercard</span>
          </div>
          <div class="pago-card" data-valor="Yape" onclick="seleccionarPago(this)">
            <img src="images/yape.png" alt="Yape"><span>Yape</span>
          </div>
          <div class="pago-card" data-valor="Plin" onclick="seleccionarPago(this)">
            <img src="images/plin.png" alt="Plin"><span>Plin</span>
          </div>
          <div class="pago-card" data-valor="Transferencia BCP" onclick="seleccionarPago(this)">
            <img src="images/bcp.png" alt="BCP"><span>Transferencia BCP</span>
          </div>
          <div class="pago-card" data-valor="Efectivo contra entrega" onclick="seleccionarPago(this)">
            <img src="images/efectivo.png" alt="Efectivo"><span>Efectivo</span>
          </div>
        </div>
      </div>

      <!-- === NUEVA SECCIÓN ODS 10 - INCLUSIÓN === -->
      <div class="inclusion-box">
        <strong><img src="images/planeta.png" class="icon-img" alt=""> Inclusión y Equidad (ODS 10)</strong><br>
        En Librería Brenda creemos en la <strong>reducción de las desigualdades</strong>.

        <label class="ods10-check">
          <input type="checkbox" id="chk-discapacidad" onchange="renderCarrito()">
          <span><img src="images/check.png" class="icon-img" alt=""> <strong>Envío gratis</strong> para personas con discapacidad</span>
        </label>

        <label class="ods10-check">
          <input type="checkbox" id="chk-estudiante" onchange="renderCarrito()">
          <span><img src="images/check.png" class="icon-img" alt=""> <strong>15% de descuento</strong> para estudiantes universitarios</span>
        </label>

        <small>Marca la(s) condición(es) que correspondan para aplicar el beneficio a tu pedido.</small>
      </div>

      <button class="btn-comprar" onclick="realizarPedido()">
        <img src="images/check.png" class="icon-img" alt="Confirmar"> 
        Realizar pedido
      </button>

      <a href="index.jsp" style="display:block;text-align:center;margin-top:12px;color:#1259C3;font-size:0.88rem;font-weight:700;text-decoration:none;">
        ← Seguir comprando
      </a>
    </div>

  </div>

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
      if (menu) menu.classList.toggle('show');
    }
    document.addEventListener('click', function() {
      var menu = document.getElementById('cuenta-dropdown-menu');
      if (menu) menu.classList.remove('show');
    });

    function seleccionarPago(el) {
      document.querySelectorAll('.pago-card').forEach(c => c.classList.remove('selected'));
      el.classList.add('selected');
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

      // Totales con el descuento/envío ODS10 ya aplicados (mismo cálculo que el resumen)
      const totales = calcularTotales();

      const btn = document.querySelector('.btn-comprar');
      const btnHtmlOriginal = btn ? btn.innerHTML : null;
      if (btn) { btn.disabled = true; btn.innerHTML = 'Procesando...'; }

      // El pedido solo se confirma si el servidor lo guarda de verdad (puede
      // rechazarlo, por ejemplo si algún producto ya no tiene stock suficiente).
      guardarPedidoEnDB(carrito, direccion, pago, totales)
        .then(data => {
          if (data.ok) {
            localStorage.removeItem('carritoBrend');

            let mensajeBeneficios = '';
            if (totales.esEstudiante) mensajeBeneficios += '\nDescuento estudiante aplicado (-15%)';
            if (totales.esDiscapacidad) mensajeBeneficios += '\nEnvío gratis por discapacidad aplicado';

            alert('¡Pedido realizado con éxito!\n\nNúmero: ' + data.id + mensajeBeneficios);
            window.location.href = 'pedidos.jsp';
          } else {
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
    function guardarPedidoEnDB(carrito, direccion, pago, totales) {
      const params = new URLSearchParams();
      params.append('accion', 'guardarDB');
      params.append('direccion', direccion || '');
      params.append('pago', pago || '');
      params.append('beneficioEstudiante', totales.esEstudiante ? 'true' : 'false');
      params.append('beneficioDiscapacidad', totales.esDiscapacidad ? 'true' : 'false');
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
      }).then(r => r.json());
    }
  </script>
</body>
</html>