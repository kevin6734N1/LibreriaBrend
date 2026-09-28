// =============================
//  CARRITO - Librería Brenda
// =============================

let carrito = JSON.parse(localStorage.getItem('carritoBrend') || '[]');

function guardar() {
  localStorage.setItem('carritoBrend', JSON.stringify(carrito));
}

function agregarCarrito(id, nombre, precio) {
  const item = carrito.find(i => i.nombre === nombre);
  if (!item && carrito.length >= 10) {
    alert('Ya tienes 10 productos distintos en el carrito. Elimina alguno antes de agregar otro.');
    return;
  }
  if (item) {
    item.qty++;
  } else {
    carrito.push({ id, nombre, precio, qty: 1, icon: 'images/producto-generico.png' });
  }
  guardar();
  actualizarBadge();
  mostrarToast(nombre);
}

function actualizarBadge() {
  const total = carrito.reduce((s, i) => s + i.qty, 0);
  const b = document.getElementById('carrito-badge');
  if (b) b.textContent = total;
}

function mostrarToast(nombre) {
  let t = document.getElementById('toast-carrito');
  if (!t) {
    t = document.createElement('div');
    t.id = 'toast-carrito';
    t.setAttribute('role', 'status');
    t.setAttribute('aria-live', 'polite');
    t.style.cssText = `
      position:fixed; bottom:24px; right:24px; background:#1259C3;
      color:white; padding:14px 22px; border-radius:10px;
      font-weight:700; font-size:0.9rem; z-index:9999;
      box-shadow:0 4px 16px rgba(0,0,0,0.25); transition:opacity 0.3s;
    `;
    document.body.appendChild(t);
  }
  t.innerHTML = `<img src="images/check.png" alt="" style="width:16px;height:16px;vertical-align:middle;margin-right:6px;">"${nombre}" añadido al carrito`;
  t.style.opacity = '1';
  clearTimeout(window._toastTimer);
  window._toastTimer = setTimeout(() => { t.style.opacity = '0'; }, 2500);
}

function cambiarQty(idx, delta) {
  carrito[idx].qty += delta;
  if (carrito[idx].qty <= 0) carrito.splice(idx, 1);
  guardar();
  renderCarrito();
}

function eliminarItem(idx) {
  carrito.splice(idx, 1);
  guardar();
  renderCarrito();
}

// === ODS 10 - Inclusión y Equidad ===
// Calcula subtotal, descuento por estudiante universitario (-15%) y envío
// (gratis si el subtotal ya califica, o si la persona marca "discapacidad").
function calcularTotales() {
  const subtotal = carrito.reduce((s, i) => s + i.precio * i.qty, 0);

  const chkDiscapacidad = document.getElementById('chk-discapacidad');
  const chkEstudiante = document.getElementById('chk-estudiante');
  const esDiscapacidad = !!(chkDiscapacidad && chkDiscapacidad.checked);
  const esEstudiante = !!(chkEstudiante && chkEstudiante.checked);

  const descuento = esEstudiante ? subtotal * 0.15 : 0;
  const envio = (subtotal >= 30 || esDiscapacidad) ? 0 : 10;
  const total = subtotal - descuento + envio;

  return { subtotal, descuento, envio, total, esDiscapacidad, esEstudiante };
}

function renderCarrito() {
  const lista = document.getElementById('carrito-lista');
  const resumenItems = document.getElementById('resumen-items');
  const resumenTotal = document.getElementById('resumen-total');
  const resumenEnvio = document.getElementById('resumen-envio');
  const filaDescuento = document.getElementById('fila-descuento');
  const resumenDescuento = document.getElementById('resumen-descuento');
  if (!lista) return;

  if (carrito.length === 0) {
    lista.innerHTML = `
      <div style="text-align:center; padding:60px 20px; color:#666">
        <img src="images/empty.png" alt="" style="width:80px;height:80px;margin-bottom:16px;opacity:0.75">
        <h3 style="font-family:Nunito,sans-serif; font-size:1.2rem; margin-bottom:8px">Tu carrito está vacío</h3>
        <p style="font-size:0.9rem; margin-bottom:20px">¡Agrega productos desde nuestra tienda!</p>
        <a href="index.jsp" style="background:#1259C3;color:white;padding:12px 28px;border-radius:8px;font-weight:700;text-decoration:none">Ver productos</a>
      </div>`;
    if (resumenItems) resumenItems.textContent = 'S/ 0.00';
    if (resumenTotal) resumenTotal.textContent = 'S/ 0.00';
    if (resumenEnvio) resumenEnvio.textContent = '¡Gratis!';
    if (filaDescuento) filaDescuento.style.display = 'none';
    return;
  }

  let html = '';

  carrito.forEach((it, idx) => {
    const sub = it.precio * it.qty;
    html += `
      <div class="carrito-item">
        <div class="thumb"><img src="${it.icon || 'images/producto-generico.png'}" alt="" style="width:48px;height:48px;object-fit:contain;"></div>
        <div class="det">
          <h4>${it.nombre}</h4>
          <p class="precio-item">S/ ${it.precio.toFixed(2)} c/u</p>
          <div class="qty-ctrl">
            <button class="qty-btn" aria-label="Disminuir cantidad de ${it.nombre.replace(/"/g, '&quot;')}" onclick="cambiarQty(${idx},-1)">−</button>
            <span class="qty-num" aria-label="Cantidad">${it.qty}</span>
            <button class="qty-btn" aria-label="Aumentar cantidad de ${it.nombre.replace(/"/g, '&quot;')}" onclick="cambiarQty(${idx},1)">+</button>
          </div>
        </div>
        <div style="text-align:right">
          <div style="font-family:Nunito,sans-serif;font-weight:900;font-size:1.05rem;">S/ ${sub.toFixed(2)}</div>
          <button class="btn-eliminar" aria-label="Eliminar ${it.nombre.replace(/"/g, '&quot;')} del carrito" onclick="eliminarItem(${idx})"><img src="images/eliminar.png" alt="" style="width:14px;height:14px;vertical-align:middle;margin-right:4px;"> Eliminar</button>
        </div>
      </div>`;
  });

  lista.innerHTML = html;

  const { subtotal, descuento, envio, total, esDiscapacidad } = calcularTotales();

  if (resumenItems) resumenItems.textContent = 'S/ ' + subtotal.toFixed(2);

  if (filaDescuento && resumenDescuento) {
    if (descuento > 0) {
      filaDescuento.style.display = 'flex';
      resumenDescuento.textContent = '- S/ ' + descuento.toFixed(2);
    } else {
      filaDescuento.style.display = 'none';
    }
  }

  if (resumenEnvio) {
    if (envio === 0) {
      resumenEnvio.textContent = esDiscapacidad ? '¡Gratis! (ODS10)' : '¡Gratis!';
    } else {
      resumenEnvio.textContent = 'S/ ' + envio.toFixed(2);
    }
  }

  if (resumenTotal) resumenTotal.textContent = 'S/ ' + total.toFixed(2);

  actualizarBadge();
}

// Inicializar badge al cargar
document.addEventListener('DOMContentLoaded', () => {
  actualizarBadge();
  renderCarrito();
});