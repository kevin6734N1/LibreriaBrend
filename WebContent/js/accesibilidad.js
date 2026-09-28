// =========================================================
//  ACCESIBILIDAD VISUAL (ODS10 / Ley 29973) - Libreria Brenda
//  Filtro de correccion de color (algoritmo Daltonize, no una
//  simulacion) para protanopia/deuteranopia/tritanopia.
//  Matrices calculadas a partir de las formulas publicadas en
//  daltonize.org (conversion RGB->LMS, correccion en LMS,
//  reparto del error de vuelta a RGB), no inventadas.
//  Pieza 3: lectura en voz alta con Web Speech API.
// =========================================================

(function () {
  // ---------- Estado compartido del perfil ----------
  const estado = { tipoDaltonismo: 'ninguno', lecturaVozActiva: false, autenticado: false };

  // ---------- Lectura en voz alta (Web Speech API, complemento al lector de pantalla) ----------
  const SOPORTA_VOZ = 'speechSynthesis' in window && 'SpeechSynthesisUtterance' in window;
  let botonHablando = null;

  function detenerLectura() {
    if (!SOPORTA_VOZ) return;
    window.speechSynthesis.cancel();
    if (botonHablando) {
      botonHablando.setAttribute('aria-pressed', 'false');
      botonHablando = null;
    }
  }

  function leerTexto(texto, boton) {
    if (!SOPORTA_VOZ || !texto) return;
    const eraElMismo = (boton === botonHablando);
    detenerLectura();
    if (eraElMismo) return; // segundo clic sobre el mismo botón = detener

    const u = new SpeechSynthesisUtterance(texto);
    u.lang = 'es-PE';
    const voz = window.speechSynthesis.getVoices()
      .find(v => v.lang.toLowerCase().startsWith('es'));
    if (voz) u.voice = voz;
    u.rate = 0.95;
    u.onend = u.onerror = () => { if (botonHablando === boton) detenerLectura(); };

    botonHablando = boton;
    boton.setAttribute('aria-pressed', 'true');
    window.speechSynthesis.speak(u);
  }

  function aplicarLecturaVoz() {
    document.body.classList.toggle('lectura-voz-activa', estado.lecturaVozActiva && SOPORTA_VOZ);
  }

  // Un solo listener para todas las tarjetas (también las que se crean dinámicamente)
  document.addEventListener('click', (e) => {
    const boton = e.target.closest('.btn-leer-voz');
    if (!boton) return;
    const contenedor = boton.closest('[data-texto-voz]');
    leerTexto(contenedor ? contenedor.dataset.textoVoz : '', boton);
  });
  window.addEventListener('pagehide', detenerLectura);

  const FILTROS_SVG = `
    <svg width="0" height="0" style="position:absolute;overflow:hidden">
      <defs>
        <filter id="filtro-protanopia" color-interpolation-filters="sRGB">
          <feColorMatrix type="matrix" values="
            1.00000  0.00000  0.00000  0.00000  0.00000
            0.50895  0.49105  0.00000  0.00000  0.00000
            0.61733 -0.61732  1.00000  0.00000  0.00000
            0.00000  0.00000  0.00000  1.00000  0.00000" />
        </filter>
        <filter id="filtro-deuteranopia" color-interpolation-filters="sRGB">
          <feColorMatrix type="matrix" values="
            1.00000  0.00000  0.00000  0.00000  0.00000
            0.20232  0.79768  0.00000  0.00000  0.00000
            0.51741 -0.51741  1.00000  0.00000  0.00000
            0.00000  0.00000  0.00000  1.00000  0.00000" />
        </filter>
        <filter id="filtro-tritanopia" color-interpolation-filters="sRGB">
          <feColorMatrix type="matrix" values="
           -0.13854  1.13854  0.00000  0.00000  0.00000
            0.00000  1.00000  0.00000  0.00000  0.00000
            3.36558 -3.36563  1.00000  0.00000  0.00000
            0.00000  0.00000  0.00000  1.00000  0.00000" />
        </filter>
      </defs>
    </svg>`;

  const ESTILOS = `
    /* El filtro va sobre <html> y no sobre <body>: un "filter" convierte al
       elemento en containing block de los position:fixed descendientes, salvo
       cuando el elemento es la raiz del documento. Con el filtro en <body>, el
       boton flotante y el toast dejarian de quedarse fijos en pantalla. */
    html.accesibilidad-protanopia    { filter: url(#filtro-protanopia); }
    html.accesibilidad-deuteranopia  { filter: url(#filtro-deuteranopia); }
    html.accesibilidad-tritanopia    { filter: url(#filtro-tritanopia); }

    #btn-accesibilidad {
      position: fixed; bottom: 20px; left: 20px; z-index: 9999;
      width: 48px; height: 48px; border-radius: 50%; border: none;
      background: #1259C3; color: #fff; font-size: 1.3rem; cursor: pointer;
      box-shadow: 0 4px 14px rgba(0,0,0,0.25);
    }
    #panel-accesibilidad {
      display: none; position: fixed; bottom: 78px; left: 20px; z-index: 9999;
      background: #fff; border: 1px solid #ddd; border-radius: 10px;
      padding: 16px; width: 240px; box-shadow: 0 6px 20px rgba(0,0,0,0.18);
      font-family: 'Lato', sans-serif; font-size: 0.85rem;
    }
    #panel-accesibilidad.show { display: block; }
    #panel-accesibilidad legend { font-weight: 700; margin-bottom: 8px; padding: 0; }
    #panel-accesibilidad label { display: block; margin-bottom: 6px; cursor: pointer; }
    #panel-accesibilidad small { display: block; margin-top: 8px; color: #777; }

    .btn-leer-voz {
      display: none; align-items: center; justify-content: center; gap: 6px;
      width: 100%; margin-bottom: 8px; padding: 8px;
      border: 2px solid #1259C3; background: #fff; color: #1259C3;
      border-radius: 8px; font-weight: 700; cursor: pointer; font-family: inherit;
    }
    body.lectura-voz-activa .btn-leer-voz { display: flex; }
    .btn-leer-voz[aria-pressed="true"] { background: #1259C3; color: #fff; }
  `;

  function aplicarFiltro(tipo) {
    const raiz = document.documentElement;
    raiz.classList.remove('accesibilidad-protanopia', 'accesibilidad-deuteranopia', 'accesibilidad-tritanopia');
    if (tipo && tipo !== 'ninguno') raiz.classList.add('accesibilidad-' + tipo);
  }

  function guardarPreferencia() {
    if (estado.autenticado) {
      const params = new URLSearchParams();
      params.append('tipoDaltonismo', estado.tipoDaltonismo);
      params.append('lecturaVozActiva', String(estado.lecturaVozActiva));
      fetch('PreferenciaAccesibilidadServlet', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
      }).catch(err => console.error('No se pudo guardar la preferencia:', err));
    } else {
      localStorage.setItem('accesibilidad_tipoDaltonismo', estado.tipoDaltonismo);
      localStorage.setItem('accesibilidad_lecturaVoz', String(estado.lecturaVozActiva));
    }
  }

  function construirUI() {
    document.body.insertAdjacentHTML('beforeend', FILTROS_SVG);

    const style = document.createElement('style');
    style.textContent = ESTILOS;
    document.head.appendChild(style);

    const btn = document.createElement('button');
    btn.id = 'btn-accesibilidad';
    btn.setAttribute('aria-label', 'Opciones de accesibilidad visual');
    btn.setAttribute('aria-expanded', 'false');
    btn.textContent = '♿';

    const panel = document.createElement('div');
    panel.id = 'panel-accesibilidad';
    panel.setAttribute('role', 'dialog');
    panel.setAttribute('aria-label', 'Panel de accesibilidad visual');

    const opciones = [
      ['ninguno', 'Sin filtro'],
      ['protanopia', 'Protanopia'],
      ['deuteranopia', 'Deuteranopia'],
      ['tritanopia', 'Tritanopia'],
    ];

    let radiosHtml = '<fieldset style="border:none;padding:0;margin:0"><legend>Filtro de color</legend>';
    opciones.forEach(([valor, etiqueta]) => {
      const checked = valor === estado.tipoDaltonismo ? 'checked' : '';
      radiosHtml += `
        <label>
          <input type="radio" name="tipo-daltonismo" value="${valor}" ${checked}>
          ${etiqueta}
        </label>`;
    });
    radiosHtml += '</fieldset>';

    if (SOPORTA_VOZ) {
      radiosHtml += `
        <label style="margin-top:12px;border-top:1px solid #eee;padding-top:10px">
          <input type="checkbox" id="chk-lectura-voz" ${estado.lecturaVozActiva ? 'checked' : ''}>
          Lectura en voz alta
        </label>
        <small>Muestra un botón 🔊 en cada producto.</small>`;
    } else {
      radiosHtml += '<small>Tu navegador no soporta lectura en voz alta.</small>';
    }

    radiosHtml += estado.autenticado
      ? '<small>Tu preferencia se guarda en tu cuenta.</small>'
      : '<small>Inicia sesión para guardar tu preferencia.</small>';

    panel.innerHTML = radiosHtml;

    btn.addEventListener('click', () => {
      const abierto = panel.classList.toggle('show');
      btn.setAttribute('aria-expanded', abierto ? 'true' : 'false');
    });

    panel.addEventListener('change', (e) => {
      if (e.target.name === 'tipo-daltonismo') {
        estado.tipoDaltonismo = e.target.value;
        aplicarFiltro(estado.tipoDaltonismo);
      } else if (e.target.id === 'chk-lectura-voz') {
        estado.lecturaVozActiva = e.target.checked;
        aplicarLecturaVoz();
        if (!estado.lecturaVozActiva) detenerLectura();
      } else {
        return;
      }
      guardarPreferencia();
    });

    // Cierre del panel con Escape (devuelve el foco al boton).
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && panel.classList.contains('show')) {
        panel.classList.remove('show');
        btn.setAttribute('aria-expanded', 'false');
        btn.focus();
      }
    });

    document.body.appendChild(btn);
    document.body.appendChild(panel);
  }

  document.addEventListener('DOMContentLoaded', () => {
    function iniciar() {
      aplicarFiltro(estado.tipoDaltonismo);
      aplicarLecturaVoz();
      construirUI();
    }
    fetch('PreferenciaAccesibilidadServlet')
      .then(r => r.json())
      .then(data => {
        estado.autenticado = !!data.autenticado;
        if (estado.autenticado) {
          estado.tipoDaltonismo = data.tipoDaltonismo || 'ninguno';
          estado.lecturaVozActiva = !!data.lecturaVozActiva;
        } else {
          estado.tipoDaltonismo = localStorage.getItem('accesibilidad_tipoDaltonismo') || 'ninguno';
          estado.lecturaVozActiva = localStorage.getItem('accesibilidad_lecturaVoz') === 'true';
        }
        iniciar();
      })
      .catch(err => {
        console.error('No se pudo cargar la preferencia de accesibilidad:', err);
        estado.tipoDaltonismo = localStorage.getItem('accesibilidad_tipoDaltonismo') || 'ninguno';
        estado.lecturaVozActiva = localStorage.getItem('accesibilidad_lecturaVoz') === 'true';
        iniciar();
      });
  });
})();
