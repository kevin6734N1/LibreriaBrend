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

  <div class="login-box registro-box" style="max-width:480px;">

    <div class="login-logo">
      <img src="images/libro-logo.png" class="registro-icon" alt="Librería Brenda">
      <h2>Crear cuenta</h2>
      <p>Regístrate y empieza a comprar</p>
    </div>

    <div id="msg-reg" class="alert" style="display:none;"></div>

    <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
      <div class="form-group">
        <label>Nombres</label>
        <input type="text" id="nombres" placeholder="Juan">
      </div>
      <div class="form-group">
        <label>Apellidos</label>
        <input type="text" id="apellidos" placeholder="Pérez">
      </div>
    </div>

    <div class="form-group">
      <label>DNI</label>
      <input type="text" id="dni" placeholder="12345678" maxlength="8">
    </div>

    <div class="form-group">
      <label>Correo electrónico</label>
      <input type="email" id="email" placeholder="tucorreo@email.com">
    </div>

    <div class="form-group">
      <label>Teléfono</label>
      <input type="tel" id="telefono" placeholder="9XX XXX XXX">
    </div>

    <div class="form-group">
      <label>Dirección de entrega</label>
      <input type="text" id="direccion" placeholder="Av. Lima 123, Miraflores">
    </div>

    <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
      <div class="form-group">
        <label>Contraseña</label>
        <input type="password" id="password" placeholder="••••••••">
      </div>
      <div class="form-group">
        <label>Confirmar contraseña</label>
        <input type="password" id="confirm" placeholder="••••••••">
      </div>
    </div>

    <div style="margin-bottom:16px; font-size:0.82rem; color:#555;">
      <input type="checkbox" id="terminos" style="margin-right:6px;">
      Acepto los <a href="#" style="color:#1259C3; font-weight:700;">Términos y condiciones</a> y
      la <a href="#" style="color:#1259C3; font-weight:700;">Política de privacidad</a>
    </div>

    <button type="button" class="btn-login" onclick="registrar()">
      <img src="images/check.png" class="icon-img" alt=""> Crear mi cuenta
    </button>

    <div class="login-links" style="margin-top:16px;">
      ¿Ya tienes cuenta? <a href="login.jsp">Inicia sesión</a>
    </div>

  </div>

  <script>
  const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  const PASSWORD_MIN_LENGTH = 8;

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
	        alert('Completa los campos requeridos');
	        return;
	    }

	    if (dni.length !== 8 || isNaN(dni)) {
	        alert('DNI inválido');
	        return;
	    }

	    if (!EMAIL_REGEX.test(email)) {
	        alert('Ingresa un correo con formato válido');
	        return;
	    }

	    if (pass.length < PASSWORD_MIN_LENGTH) {
	        alert('La contraseña debe tener al menos ' + PASSWORD_MIN_LENGTH + ' caracteres');
	        return;
	    }

	    if (pass !== confirm) {
	        alert('Las contraseñas no coinciden');
	        return;
	    }

	    if (!terminos) {
	        alert('Debes aceptar los términos');
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
	            alert("Cuenta creada correctamente. ¡Bienvenido!");

	            window.location.href = data.redirect;

	        } else {

	            alert(data.error || "No se pudo crear la cuenta.");
	        }
	    })
	    .catch(error => {

	        console.error(error);

	        alert("Error de conexión con el servidor");
	    });
	}
  </script>
<script src="js/accesibilidad.js"></script>
</body>
</html>
