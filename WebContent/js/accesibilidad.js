// =========================================================
//  ACCESIBILIDAD VISUAL (ODS10 / Ley 29973) - Libreria Brenda
//  Filtro de correccion de color (algoritmo Daltonize, no una
//  simulacion) para protanopia/deuteranopia/tritanopia.
//  Matrices calculadas a partir de las formulas publicadas en
//  daltonize.org (conversion RGB->LMS, correccion en LMS,
//  reparto del error de vuelta a RGB), no inventadas.
// =========================================================

(function () {
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
    body.accesibilidad-protanopia    { filter: url(#filtro-protanopia); }
    body.accesibilidad-deuteranopia  { filter: url(#filtro-deuteranopia); }
    body.accesibilidad-tritanopia    { filter: url(#filtro-tritanopia); }

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
  `;

  function aplicarFiltro(tipo) {
    document.body.classList.remove(
      'accesibilidad-protanopia', 'accesibilidad-deuteranopia', 'accesibilidad-tritanopia'
    );
    if (tipo && tipo !== 'ninguno') {
      document.body.classList.add('accesibilidad-' + tipo);
    }
  }

  function guardarPreferencia(tipo, autenticado) {
    if (autenticado) {
      const params = new URLSearchParams();
      params.append('tipoDaltonismo', tipo);
      params.append('lecturaVozActiva', 'false');
      fetch('PreferenciaAccesibilidadServlet', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
      }).catch(err => console.error('No se pudo guardar la preferencia:', err));
    } else {
      localStorage.setItem('accesibilidad_tipoDaltonismo', tipo);
    }
  }

  function construirUI(tipoActual, autenticado) {
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
      const checked = valor === tipoActual ? 'checked' : '';
      radiosHtml += `
        <label>
          <input type="radio" name="tipo-daltonismo" value="${valor}" ${checked}>
          ${etiqueta}
        </label>`;
    });
    radiosHtml += '</fieldset>';
    radiosHtml += autenticado
      ? '<small>Tu preferencia se guarda en tu cuenta.</small>'
      : '<small>Inicia sesión para guardar tu preferencia.</small>';

    panel.innerHTML = radiosHtml;

    btn.addEventListener('click', () => {
      const abierto = panel.classList.toggle('show');
      btn.setAttribute('aria-expanded', abierto ? 'true' : 'false');
    });

    panel.addEventListener('change', (e) => {
      if (e.target.name === 'tipo-daltonismo') {
        aplicarFiltro(e.target.value);
        guardarPreferencia(e.target.value, autenticado);
      }
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
    fetch('PreferenciaAccesibilidadServlet')
      .then(r => r.json())
      .then(data => {
        let tipo = data.tipoDaltonismo || 'ninguno';
        if (!data.autenticado) {
          // Visitante sin sesion: usa lo guardado en este navegador, si existe.
          tipo = localStorage.getItem('accesibilidad_tipoDaltonismo') || 'ninguno';
        }
        aplicarFiltro(tipo);
        construirUI(tipo, data.autenticado);
      })
      .catch(err => {
        console.error('No se pudo cargar la preferencia de accesibilidad:', err);
        const tipo = localStorage.getItem('accesibilidad_tipoDaltonismo') || 'ninguno';
        aplicarFiltro(tipo);
        construirUI(tipo, false);
      });
  });
})();
