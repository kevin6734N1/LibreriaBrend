<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Registro | Librería Brenda</title>
  <link rel="stylesheet" href="css/style.css">
  <style>
    .icon-img {
      width: 24px;
      height: 24px;
      vertical-align: middle;
    }
    .registro-icon {
      width: 64px;
      height: 64px;
    }
  </style>
</head>
<body class="login-page">

  <a href="#contenido-principal" class="skip-link">Saltar al contenido principal</a>

  <main id="contenido-principal">

  <div class="login-box registro-box" style="max-width:480px;">

    <div class="login-logo">
      <img src="images/libro-logo.png" class="registro-icon" alt="Librería Brenda">
      <h2>Crear cuenta</h2>
      <p>Regístrate y empieza a comprar</p>
    </div>

    <div id="msg-reg" class="alert" role="alert" style="display:none;"></div>

    <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
      <div class="form-group">
        <label for="nombres">Nombres</label>
        <input type="text" id="nombres" placeholder="Juan" autocomplete="given-name">
      </div>
      <div class="form-group">
        <label for="apellidos">Apellidos</label>
        <input type="text" id="apellidos" placeholder="Pérez" autocomplete="family-name">
      </div>
    </div>

    <div class="form-group">
      <label for="dni">DNI</label>
      <input type="text" id="dni" placeholder="12345678" maxlength="8" inputmode="numeric">
    </div>

    <div class="form-group">
      <label for="email">Correo electrónico</label>
      <input type="email" id="email" placeholder="tucorreo@email.com" autocomplete="email">
    </div>

    <div class="form-group">
      <label for="telefono">Teléfono</label>
      <input type="tel" id="telefono" placeholder="9XX XXX XXX" autocomplete="tel">
    </div>

    <div class="form-group">
      <label for="direccion">Dirección de entrega</label>
      <input type="text" id="direccion" placeholder="Av. Lima 123, Miraflores" autocomplete="street-address">
    </div>

    <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
      <div class="form-group">
        <label for="password">Contraseña</label>
        <input type="password" id="password" placeholder="••••••••" autocomplete="new-password">
      </div>
      <div class="form-group">
        <label for="confirm">Confirmar contraseña</label>
        <input type="password" id="confirm" placeholder="••••••••" autocomplete="new-password">
      </div>
    </div>

    <label for="terminos" style="display:block; margin-bottom:16px; font-size:0.82rem; color:#555; cursor:pointer;">
      <input type="checkbox" id="terminos" style="margin-right:6px;">
      Acepto los <a href="#" style="color:#1259C3; font-weight:700;">Términos y condiciones</a> y
      la <a href="#" style="color:#1259C3; font-weight:700;">Política de privacidad</a>
    </label>

    <button type="button" class="btn-login" onclick="registrar()">
      <img src="images/check.png" class="icon-img" alt=""> Crear mi cuenta
    </button>

    <div class="login-links" style="margin-top:16px;">
      ¿Ya tienes cuenta? <a href="login.jsp">Inicia sesión</a>
    </div>

  </div>

  </main>

  <script>
  const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  const PASSWORD_MIN_LENGTH = 8;

  // Muestra el mensaje en #msg-reg (role="alert", lo anuncia el lector de
  // pantalla) en lugar de alert(), que interrumpe y varia entre lectores.
  function mostrarMensaje(texto, tipo) {
    const msg = document.getElementById('msg-reg');
    msg.textContent = texto;
    msg.className   = 'alert alert-' + (tipo || 'error');
    msg.style.display = '';
    msg.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }

  function registrar() {

	    const nombres   = document.getElementById('nombres').value.trim();
	    const apellidos = document.getElementById('apellidos').value.trim();
	    const dni       = document.getElementById('dni').value.trim();
	    const email     = document.getElementById('email').value.trim();
	    const telefono  = document.getElementById('telefono').value.trim();
	    const direccion = document.getElementById('direccion').value.trim();
	    const pass      = document.getElementById('password').value;
	    const confirm   = document.getElementById('confirm').value;
	    const terminos  = document.getElementById('terminos').checked;

	    if (!nombres || !apellidos || !dni || !email || !pass) {
	        mostrarMensaje('Completa los campos requeridos');
	        return;
	    }

	    if (dni.length !== 8 || isNaN(dni)) {
	        mostrarMensaje('DNI inválido');
	        return;
	    }

	    if (!EMAIL_REGEX.test(email)) {
	        mostrarMensaje('Ingresa un correo con formato válido');
	        return;
	    }

	    if (pass.length < PASSWORD_MIN_LENGTH) {
	        mostrarMensaje('La contraseña debe tener al menos ' + PASSWORD_MIN_LENGTH + ' caracteres');
	        return;
	    }

	    if (pass !== confirm) {
	        mostrarMensaje('Las contraseñas no coinciden');
	        return;
	    }

	    if (!terminos) {
	        mostrarMensaje('Debes aceptar los términos');
	        return;
	    }

	    const datos =
	        "nombres=" + encodeURIComponent(nombres) +
	        "&apellidos=" + encodeURIComponent(apellidos) +
	        "&dni=" + encodeURIComponent(dni) +
	        "&email=" + encodeURIComponent(email) +
	        "&telefono=" + encodeURIComponent(telefono) +
	        "&direccion=" + encodeURIComponent(direccion) +
	        "&password=" + encodeURIComponent(pass);

	    fetch("RegistroServlet", {
	        method: "POST",
	        headers: {
	            "Content-Type": "application/x-www-form-urlencoded"
	        },
	        body: datos
	    })
	    .then(response => response.json())
	    .then(data => {

	        if (data.ok) {

	            // La cuenta ya queda logueada (RegistroServlet crea la sesion),
	            // no hace falta mandarlo de nuevo a login.jsp.
	            mostrarMensaje('✅ Cuenta creada correctamente. ¡Bienvenido!', 'success');

	            setTimeout(() => { window.location.href = data.redirect; }, 900);

	        } else {

	            mostrarMensaje(data.error || "No se pudo crear la cuenta.");
	        }
	    })
	    .catch(error => {

	        console.error(error);

	        mostrarMensaje("Error de conexión con el servidor");
	    });
	}
  </script>
<script src="js/accesibilidad.js"></script>
</body>
</html>
