<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Iniciar Sesión | Librería Brenda</title>
  <link rel="stylesheet" href="css/style.css">
  <style>
    .icon-img {
      width: 24px;
      height: 24px;
      vertical-align: middle;
    }
    .login-icon {
      width: 64px;
      height: 64px;
    }
  </style>
</head>
<body class="login-page">

  <a href="#contenido-principal" class="skip-link">Saltar al contenido principal</a>

  <main id="contenido-principal">

  <div class="login-box">

    <!-- Logo -->
    <div class="login-logo">
      <img src="images/libro-logo.png" class="login-icon" alt="Librería Brenda">
      <h2>Librería Brenda</h2>
      <p>Inicia sesión para gestionar tus pedidos</p>
    </div>

    <!-- Tabs Cliente / Admin -->
    <div class="login-tabs" role="tablist" aria-label="Tipo de cuenta">
      <button class="tab-btn active" id="tab-cliente" role="tab" aria-selected="true" onclick="cambiarTab('cliente')">
        <img src="images/usuario.png" class="icon-img" alt=""> Cliente
      </button>
      <button class="tab-btn" id="tab-admin" role="tab" aria-selected="false" onclick="cambiarTab('admin')">
        <img src="images/admin.png" class="icon-img" alt=""> Empleado / Admin
      </button>
    </div>

    <!-- Mensaje de error/éxito -->
    <div id="msg-login" style="display:none" class="alert" role="alert"></div>

    <!-- Formulario -->
    <div class="form-group">
      <label for="email">Correo electrónico</label>
      <input type="email" id="email" placeholder="tucorreo@email.com" required autocomplete="email">
    </div>

    <div class="form-group">
      <label for="password">Contraseña</label>
      <input type="password" id="password" placeholder="••••••••" required autocomplete="current-password">
    </div>

    <!-- Solo admin: campo de código -->
    <div class="form-group" id="campo-codigo" style="display:none">
      <label for="codigo">Código de empleado</label>
      <input type="text" id="codigo" placeholder="EMP-XXXX">
    </div>

    <div style="text-align:right; margin-bottom:8px;">
      <a href="#" style="font-size:0.82rem; color:#1259C3; font-weight:700; text-decoration:none;">
        ¿Olvidaste tu contraseña?
      </a>
    </div>

    <button class="btn-login" onclick="iniciarSesion()">
      <img src="images/check.png" class="icon-img" alt=""> Ingresar
    </button>

    <div class="login-links">
      ¿No tienes cuenta? <a href="registro.jsp">Regístrate aquí</a>
    </div>

    <div style="margin-top:18px; padding-top:16px; border-top:1px solid #e0e0e0; text-align:center;">
      <a href="index.jsp" style="font-size:0.85rem; color:#666; text-decoration:none;">
        ← Volver a la tienda
      </a>
    </div>

    <!-- Creds demo -->
    <div style="margin-top:16px; background:#F5F5F5; border-radius:8px; padding:12px; font-size:0.78rem; color:#666; text-align:center;">
      <strong>Demo local:</strong><br>
      Cliente: cliente01@example.com / Cliente#2026<br>
      Admin: admin@example.com / Admin#2026 + EMP-DEMO
    </div>

  </div>

  </main>

  <script>
    let rolActual = 'cliente';

    function cambiarTab(rol) {
      rolActual = rol;
      document.querySelectorAll('.tab-btn').forEach(b => {
        b.classList.remove('active');
        b.setAttribute('aria-selected', 'false');
      });
      const tabActivo = document.getElementById('tab-' + rol);
      tabActivo.classList.add('active');
      tabActivo.setAttribute('aria-selected', 'true');
      document.getElementById('campo-codigo').style.display = rol === 'admin' ? '' : 'none';
      document.getElementById('msg-login').style.display = 'none';
    }

    // Mismo patrón simple que valida el servidor: no busca ser 100% RFC 5322,
    // solo rechazar entradas obviamente inválidas antes de golpear el servidor.
    const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    function iniciarSesion() {
      const email    = document.getElementById('email').value.trim();
      const password = document.getElementById('password').value;

      if (!email || !password) {
        mostrarMsg('Por favor completa todos los campos.', 'error');
        return;
      }

      if (!EMAIL_REGEX.test(email)) {
        mostrarMsg('Ingresa un correo con formato válido.', 'error');
        return;
      }

      const datos = new URLSearchParams();
      datos.append('email', email);
      datos.append('password', password);
      datos.append('rol', rolActual);

      if (rolActual === 'admin') {
        const codigo = document.getElementById('codigo').value.trim();
        if (!codigo) {
          mostrarMsg('Ingresa tu código de empleado.', 'error');
          return;
        }
        datos.append('codigo', codigo);
      }

      fetch('LoginServlet', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: datos.toString()
      })
      .then(r => r.json())
      .then(data => {
        if (data.ok) {
          mostrarMsg('✅ ¡Bienvenido! Redirigiendo...', 'success');
          setTimeout(() => window.location.href = data.redirect, 900);
        } else {
          mostrarMsg('❌ ' + (data.error || 'No se pudo iniciar sesión.'), 'error');
        }
      })
      .catch(err => {
        console.error(err);
        mostrarMsg('Error de conexión con el servidor.', 'error');
      });
    }

    function mostrarMsg(texto, tipo) {
      const msg = document.getElementById('msg-login');
      msg.textContent = texto;
      msg.className   = 'alert alert-' + tipo;
      msg.style.display = '';
    }

    // Enter key
    document.addEventListener('keydown', e => {
      if (e.key === 'Enter') iniciarSesion();
    });

    // Si AuthFilter redirigio para aca por falta de sesion admin, avisar por que.
    if (new URLSearchParams(window.location.search).get('error') === 'sesion') {
      cambiarTab('admin');
      mostrarMsg('Debes iniciar sesión como administrador para ver esa página.', 'error');
    }
  </script>
<script src="js/accesibilidad.js"></script>
</body>
</html>
