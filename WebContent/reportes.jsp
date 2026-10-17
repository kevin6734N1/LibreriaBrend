<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reportes | Libreria Brenda Admin</title>
  <link rel="stylesheet" href="css/style.css">
  <link rel="stylesheet" href="css/admin.css">
  <style>
    /* ===== Estilos propios de Reportes ===== */
    .periodo-selector { display: flex; gap: 8px; margin-bottom: 22px; flex-wrap: wrap; }
    .periodo-btn {
      padding: 8px 18px; border-radius: 20px; border: 1.5px solid var(--gris-borde);
      background: #fff; cursor: pointer; font-family: 'Lato', sans-serif;
      font-weight: 700; font-size: 0.85rem; color: #333; transition: all 0.18s;
    }
    .periodo-btn:hover { border-color: var(--azul); color: var(--azul); }
    .periodo-btn.active { background: var(--azul); color: #fff; border-color: var(--azul); }

    .stat-delta { font-size: 0.76rem; font-weight: 700; margin-top: 6px; display: inline-block; padding: 2px 8px; border-radius: 10px; }
    .delta-up { background: #D4EDDA; color: #155724; }
    .delta-down { background: #F8D7DA; color: #721c24; }

    .charts-grid { display: grid; grid-template-columns: 1.3fr 1fr; gap: 18px; margin-bottom: 18px; }
    .charts-grid-3 { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; margin-bottom: 18px; }
    .chart-card { background: #fff; border-radius: var(--radio); padding: 20px; box-shadow: var(--sombra); }
    .chart-card h3 { font-family: 'Nunito', sans-serif; font-weight: 800; font-size: 1rem; margin-bottom: 4px; display: flex; align-items: center; gap: 8px; }
    .chart-card .chart-sub { font-size: 0.78rem; color: #888; margin-bottom: 14px; }
    .chart-wrap { position: relative; height: 280px; }
    .chart-wrap.short { height: 230px; }

    .ranking-list { list-style: none; padding: 0; margin: 0; }
    .ranking-item { display: flex; align-items: center; gap: 12px; padding: 10px 0; border-bottom: 1px solid #f0f0f0; }
    .ranking-item:last-child { border-bottom: none; }
    .ranking-pos { width: 26px; height: 26px; border-radius: 50%; background: #EEF2FF; color: var(--azul); display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 0.8rem; flex-shrink: 0; }
    .ranking-pos.top1 { background: #FFE600; color: #5a4a00; }
    .ranking-pos.top2 { background: #E0E0E0; color: #444; }
    .ranking-pos.top3 { background: #FFD8B0; color: #7a3e00; }
    .ranking-info { flex: 1; }
    .ranking-nombre { font-weight: 700; font-size: 0.87rem; }
    .ranking-meta { font-size: 0.76rem; color: #888; }
    .ranking-valor { font-family: 'Nunito', sans-serif; font-weight: 900; color: var(--azul); font-size: 0.92rem; white-space: nowrap; }
  </style>
</head>
<body>
<div class="admin-layout">

  <!-- ===== SIDEBAR ===== -->
  <%@ include file="/WEB-INF/jspf/admin-sidebar.jspf" %>

  <!-- ===== MAIN ===== -->
  <main class="admin-main">

    <div class="topbar">
      <h2>
        <img src="images/reportes.png" style="width:28px;height:28px;vertical-align:middle;margin-right:8px;" alt="">
        Reportes y Estadisticas
      </h2>
      <div class="topbar-right">
        <button class="btn-exportar" onclick="exportarResumenCSV()">&#128190; Exportar resumen</button>
        <img src="images/usuario.png" style="width:28px;height:28px;" alt="">
        <span><%= session.getAttribute("adminNombre") != null ? session.getAttribute("adminNombre") : "Admin" %></span>
        <span class="badge-admin">ADMIN</span>
      </div>
    </div>

    <!-- Selector de periodo -->
    <div class="periodo-selector">
      <button class="periodo-btn" onclick="setPeriodo('semana', this)">Esta semana</button>
      <button class="periodo-btn active" onclick="setPeriodo('mes', this)">Este mes</button>
      <button class="periodo-btn" onclick="setPeriodo('trimestre', this)">Trimestre</button>
      <button class="periodo-btn" onclick="setPeriodo('anio', this)">Este anio</button>
    </div>

    <!-- Stats -->
    <div class="stats-grid">
      <div class="stat-card">
        <img src="images/pedidos.png" alt="">
        <div class="stat-num" id="stat-pedidos">186</div>
        <div class="stat-label">Pedidos del periodo</div>
        <span class="stat-delta delta-up" id="delta-pedidos">&#9650; 12.5%</span>
      </div>
      <div class="stat-card">
        <img src="images/ventas.png" alt="">
        <div class="stat-num" id="stat-ingresos" style="color:#00A650;">S/14,280</div>
        <div class="stat-label">Ingresos del periodo</div>
        <span class="stat-delta delta-up" id="delta-ingresos">&#9650; 8.2%</span>
      </div>
      <div class="stat-card">
        <img src="images/clientes.png" alt="">
        <div class="stat-num" id="stat-clientes-nuevos">23</div>
        <div class="stat-label">Clientes nuevos</div>
        <span class="stat-delta delta-down" id="delta-clientes">&#9660; 3.1%</span>
      </div>
      <div class="stat-card">
        <img src="images/check.png" alt="">
        <div class="stat-num" id="stat-ticket" style="color:#1259C3;">S/76.78</div>
        <div class="stat-label">Ticket promedio</div>
        <span class="stat-delta delta-up" id="delta-ticket">&#9650; 5.4%</span>
      </div>
    </div>

    <!-- Fila 1: Ventas en el tiempo + Estado de pedidos -->
    <div class="charts-grid">
      <div class="chart-card">
        <h3><img src="images/ventas.png" style="width:22px;height:22px;" alt=""> Ventas en el tiempo</h3>
        <div class="chart-sub">Ingresos diarios del periodo seleccionado (S/)</div>
        <div class="chart-wrap"><canvas id="chartVentas"></canvas></div>
      </div>
      <div class="chart-card">
        <h3><img src="images/pedidos.png" style="width:22px;height:22px;" alt=""> Estado de pedidos</h3>
        <div class="chart-sub">Distribucion segun estado actual</div>
        <div class="chart-wrap"><canvas id="chartEstados"></canvas></div>
      </div>
    </div>

    <!-- Fila 2: Categorias + Top productos -->
    <div class="charts-grid-3">
      <div class="chart-card">
        <h3><img src="images/productos.png" style="width:22px;height:22px;" alt=""> Ventas por categoria</h3>
        <div class="chart-sub">Porcentaje de ingresos por tipo de producto</div>
        <div class="chart-wrap short"><canvas id="chartCategorias"></canvas></div>
      </div>
      <div class="chart-card">
        <h3>&#127942; Top 5 productos mas vendidos</h3>
        <div class="chart-sub">Por unidades vendidas en el periodo</div>
        <ul class="ranking-list" id="ranking-productos"></ul>
      </div>
    </div>

    <!-- Fila 3: Clientes nuevos por mes -->
    <div class="charts-grid">
      <div class="chart-card">
        <h3><img src="images/clientes.png" style="width:22px;height:22px;" alt=""> Clientes nuevos por mes</h3>
        <div class="chart-sub">Crecimiento de la base de clientes en 2026</div>
        <div class="chart-wrap"><canvas id="chartClientes"></canvas></div>
      </div>
      <div class="chart-card">
        <h3>&#11088; Top 5 clientes</h3>
        <div class="chart-sub">Por total gastado en el periodo</div>
        <ul class="ranking-list" id="ranking-clientes"></ul>
      </div>
    </div>

  </main>
</div>

<script>
  // ================================================================
  //  REPORTES - Conectado a la base de datos via ReporteServlet
  //  El servlet devuelve JSON con: stats, ventasPorDia, pedidosPorEstado,
  //  ventasPorCategoria, topProductos, topClientes, clientesNuevosPorMes
  // ================================================================
  var periodoActual = 'mes';
  var chartVentas, chartEstados, chartCategorias, chartClientes;

  var COLOR_AZUL     = '#1259C3';
  var COLOR_VERDE    = '#00A650';
  var COLORES_PIE    = ['#1259C3', '#4C8DFF', '#00A650', '#FFC107', '#FF6B6B', '#9C6ADE'];
  var COLORES_ESTADO = { 'PENDIENTE':'#FFC107', 'CONFIRMADO':'#17a2b8', 'ENVIADO':'#007bff', 'ENTREGADO':'#28a745', 'CANCELADO':'#dc3545' };

  // Guarda el ultimo dato cargado para evitar pedir 2 veces si solo cambia el chart de ventas
  var ultimoDato = null;

  // ================================================================
  //  CARGA PRINCIPAL — llama al servlet y pinta todo
  // ================================================================
  function cargarReporte(periodo) {
    mostrarCargando(true);
    fetch('ReporteServlet?periodo=' + periodo)
      .then(function(resp) {
        if (!resp.ok) throw new Error('Respuesta no OK del servidor: ' + resp.status);
        return resp.json();
      })
      .then(function(data) {
        ultimoDato = data;
        pintarStats(data.stats);
        pintarChartVentas(data.ventasPorDia);
        pintarChartEstados(data.pedidosPorEstado);
        pintarChartCategorias(data.ventasPorCategoria);
        pintarChartClientesNuevos(data.clientesNuevosPorMes);
        pintarRankingProductos(data.topProductos);
        pintarRankingClientes(data.topClientes);
        mostrarCargando(false);
      })
      .catch(function(err) {
        mostrarCargando(false);
        mostrarErrorCarga(err);
        console.error('Error cargando reportes:', err);
      });
  }

  function mostrarCargando(activo) {
    var nums = document.querySelectorAll('.stat-num');
    if (activo) {
      for (var i = 0; i < nums.length; i++) nums[i].textContent = '...';
    }
  }

  function mostrarErrorCarga(err) {
    // Ignorar errores de Chart no inicializado aun
    if (err && err.message && err.message.indexOf('Chart') >= 0) return;
    var main = document.querySelector('.admin-main');
    var aviso = document.getElementById('aviso-error-bd');
    if (!aviso) {
      aviso = document.createElement('div');
      aviso.id = 'aviso-error-bd';
      aviso.style.background = '#F8D7DA';
      aviso.style.color = '#721c24';
      aviso.style.padding = '14px 18px';
      aviso.style.borderRadius = '8px';
      aviso.style.marginBottom = '18px';
      aviso.style.fontSize = '0.88rem';
      aviso.style.fontWeight = '600';
      main.insertBefore(aviso, main.children[1]);
    }
    aviso.innerHTML = '&#9888; No se pudo conectar a la base de datos. Verifica que XAMPP (Apache + MySQL) este corriendo y que ReporteServlet este desplegado. Detalle: ' + err.message;
  }

  // ================================================================
  //  CAMBIO DE PERIODO
  // ================================================================
  function setPeriodo(p, btn) {
    periodoActual = p;
    var btns = document.querySelectorAll('.periodo-btn');
    for (var i = 0; i < btns.length; i++) btns[i].classList.remove('active');
    btn.classList.add('active');
    cargarReporte(periodoActual);
  }

  // ================================================================
  //  STATS (tarjetas superiores)
  // ================================================================
  function pintarStats(stats) {
    if (!stats) return;
    var pedidos        = stats.pedidos || 0;
    var ingresos        = stats.ingresos || 0;
    var clientesNuevos  = stats.clientesNuevos || 0;
    var ticket          = stats.ticket || 0;

    document.getElementById('stat-pedidos').textContent = pedidos;
    document.getElementById('stat-ingresos').textContent = 'S/' + Number(ingresos).toLocaleString('es-PE', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    document.getElementById('stat-clientes-nuevos').textContent = clientesNuevos;
    document.getElementById('stat-ticket').textContent = 'S/' + Number(ticket).toFixed(2);

    // Los deltas (variacion vs periodo anterior) requieren una segunda
    // consulta historica; por ahora se ocultan si no hay dato.
    ocultarDelta('delta-pedidos');
    ocultarDelta('delta-ingresos');
    ocultarDelta('delta-clientes');
    ocultarDelta('delta-ticket');
  }

  function ocultarDelta(id) {
    var el = document.getElementById(id);
    if (el) el.style.display = 'none';
  }

  // ================================================================
  //  GRAFICO 1: VENTAS EN EL TIEMPO (linea)
  // ================================================================
  function pintarChartVentas(filas) {
    var labels = [];
    var datos = [];
    if (filas) {
      for (var i = 0; i < filas.length; i++) {
        labels.push(formatearFechaCorta(filas[i].label));
        datos.push(filas[i].valor);
      }
    }

    if (chartVentas) {
      chartVentas.data.labels = labels;
      chartVentas.data.datasets[0].data = datos;
      chartVentas.update();
      return;
    }

    var ctx = document.getElementById('chartVentas').getContext('2d');
    chartVentas = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Ventas (S/)',
          data: datos,
          borderColor: COLOR_AZUL,
          backgroundColor: 'rgba(18,89,195,0.10)',
          tension: 0.35,
          fill: true,
          pointBackgroundColor: COLOR_AZUL,
          pointRadius: 4
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { callback: function(v){ return 'S/' + v; } } } }
      }
    });
  }

  function formatearFechaCorta(fechaIso) {
    // Si viene como yyyy-MM-dd la acortamos a dd/MM, si es un mes yyyy-MM la dejamos igual
    if (!fechaIso) return '';
    var partes = fechaIso.split('-');
    if (partes.length === 3) return partes[2] + '/' + partes[1];
    if (partes.length === 2) return partes[1] + '/' + partes[0];
    return fechaIso;
  }

  // ================================================================
  //  GRAFICO 2: ESTADO DE PEDIDOS (doughnut)
  // ================================================================
  function pintarChartEstados(filas) {
    var labels = [];
    var datos = [];
    var colores = [];
    if (filas) {
      for (var i = 0; i < filas.length; i++) {
        labels.push(capitalizar(filas[i].label));
        datos.push(filas[i].valor);
        colores.push(COLORES_ESTADO[filas[i].label] || '#999');
      }
    }

    if (chartEstados) {
      chartEstados.data.labels = labels;
      chartEstados.data.datasets[0].data = datos;
      chartEstados.data.datasets[0].backgroundColor = colores;
      chartEstados.update();
      return;
    }

    var ctx = document.getElementById('chartEstados').getContext('2d');
    chartEstados = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: labels,
        datasets: [{ data: datos, backgroundColor: colores, borderWidth: 0 }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 11 } } } }
      }
    });
  }

  function capitalizar(s) {
    if (!s) return '';
    return s.charAt(0).toUpperCase() + s.slice(1).toLowerCase();
  }

  // ================================================================
  //  GRAFICO 3: VENTAS POR CATEGORIA (barra horizontal)
  // ================================================================
  function pintarChartCategorias(filas) {
    var labels = [];
    var datos = [];
    if (filas) {
      for (var i = 0; i < filas.length; i++) {
        labels.push(filas[i].label);
        datos.push(filas[i].valor);
      }
    }

    if (chartCategorias) {
      chartCategorias.data.labels = labels;
      chartCategorias.data.datasets[0].data = datos;
      chartCategorias.update();
      return;
    }

    var ctx = document.getElementById('chartCategorias').getContext('2d');
    chartCategorias = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{ label: 'Ingresos (S/)', data: datos, backgroundColor: COLORES_PIE, borderRadius: 6 }]
      },
      options: {
        indexAxis: 'y',
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { x: { beginAtZero: true, ticks: { callback: function(v){ return 'S/' + v; } } } }
      }
    });
  }

  // ================================================================
  //  GRAFICO 4: CLIENTES NUEVOS POR MES (barra vertical)
  // ================================================================
  function pintarChartClientesNuevos(filas) {
    var labels = [];
    var datos = [];
    if (filas) {
      for (var i = 0; i < filas.length; i++) {
        labels.push(formatearMes(filas[i].label));
        datos.push(filas[i].valor);
      }
    }

    if (chartClientes) {
      chartClientes.data.labels = labels;
      chartClientes.data.datasets[0].data = datos;
      chartClientes.update();
      return;
    }

    var ctx = document.getElementById('chartClientes').getContext('2d');
    chartClientes = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{ label: 'Clientes nuevos', data: datos, backgroundColor: COLOR_VERDE, borderRadius: 6, maxBarThickness: 40 }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true } }
      }
    });
  }

  function formatearMes(mesIso) {
    // mesIso viene como "2026-06" -> lo convertimos a "Jun 2026"
    if (!mesIso) return '';
    var nombres = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    var partes = mesIso.split('-');
    var idx = parseInt(partes[1], 10) - 1;
    return (nombres[idx] || mesIso) + ' ' + partes[0];
  }

  // ================================================================
  //  RANKINGS (listas, no charts)
  // ================================================================
  function pintarRankingProductos(lista) {
    var ul = document.getElementById('ranking-productos');
    if (!lista || lista.length === 0) {
      ul.innerHTML = '<li style="padding:14px 0;color:#999;font-size:0.85rem;">Aun no hay ventas registradas en este periodo.</li>';
      return;
    }
    var html = '';
    for (var i = 0; i < lista.length; i++) {
      var p = lista[i];
      var posClass = i === 0 ? 'top1' : (i === 1 ? 'top2' : (i === 2 ? 'top3' : ''));
      html +=
        '<li class="ranking-item">' +
          '<div class="ranking-pos ' + posClass + '">' + (i + 1) + '</div>' +
          '<div class="ranking-info">' +
            '<div class="ranking-nombre">' + p.nombre + '</div>' +
            '<div class="ranking-meta">' + p.unidades + ' unidades vendidas</div>' +
          '</div>' +
          '<div class="ranking-valor">S/ ' + Number(p.ingresos).toFixed(2) + '</div>' +
        '</li>';
    }
    ul.innerHTML = html;
  }

  function pintarRankingClientes(lista) {
    var ul = document.getElementById('ranking-clientes');
    if (!lista || lista.length === 0) {
      ul.innerHTML = '<li style="padding:14px 0;color:#999;font-size:0.85rem;">Aun no hay clientes con compras en este periodo.</li>';
      return;
    }
    var html = '';
    for (var i = 0; i < lista.length; i++) {
      var c = lista[i];
      var posClass = i === 0 ? 'top1' : (i === 1 ? 'top2' : (i === 2 ? 'top3' : ''));
      html +=
        '<li class="ranking-item">' +
          '<div class="ranking-pos ' + posClass + '">' + (i + 1) + '</div>' +
          '<div class="ranking-info">' +
            '<div class="ranking-nombre">' + c.nombre + '</div>' +
            '<div class="ranking-meta">' + c.pedidos + ' pedidos realizados</div>' +
          '</div>' +
          '<div class="ranking-valor">S/ ' + Number(c.gastado).toFixed(2) + '</div>' +
        '</li>';
    }
    ul.innerHTML = html;
  }

  // ================================================================
  //  EXPORTAR RESUMEN CSV (usa el ultimo dato cargado del servlet)
  // ================================================================
  function exportarResumenCSV() {
    if (!ultimoDato) { alert('Espera a que carguen los datos antes de exportar.'); return; }
    var s = ultimoDato.stats || {};
    var filas = [
      'Reporte Libreria Brenda - Periodo: ' + periodoActual,
      '',
      'Metrica,Valor',
      'Pedidos,' + (s.pedidos || 0),
      'Ingresos,S/' + (s.ingresos || 0),
      'Clientes nuevos,' + (s.clientesNuevos || 0),
      'Ticket promedio,S/' + Number(s.ticket || 0).toFixed(2),
      '',
      'Top productos,Unidades,Ingresos'
    ];
    var topProd = ultimoDato.topProductos || [];
    for (var i = 0; i < topProd.length; i++) {
      var p = topProd[i];
      filas.push('"' + p.nombre + '",' + p.unidades + ',S/' + Number(p.ingresos).toFixed(2));
    }
    var csv = filas.join('\n');
    var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = 'reporte_libreria_brenda_' + periodoActual + '.csv';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  // ================================================================
  //  INIT — carga Chart.js dinamicamente y espera a que este listo
  //  antes de llamar cargarReporte(), evitando "Chart is not defined"
  // ================================================================
  function iniciarConChartJS() {
    var script = document.createElement('script');
    // Intentamos primero con cdnjs, si falla usamos jsdelivr como fallback
    script.src = 'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.4/chart.umd.min.js';
    script.onload = function() {
      cargarReporte(periodoActual);
    };
    script.onerror = function() {
      // Fallback a jsdelivr si cdnjs no responde
      var fallback = document.createElement('script');
      fallback.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js';
      fallback.onload = function() {
        cargarReporte(periodoActual);
      };
      fallback.onerror = function() {
        mostrarErrorCarga(new Error('No se pudo cargar Chart.js. Verifica tu conexion a internet.'));
      };
      document.head.appendChild(fallback);
    };
    document.head.appendChild(script);
  }

  // Esperar a que el DOM este completamente cargado
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', iniciarConChartJS);
  } else {
    iniciarConChartJS();
  }
</script>
</body>
</html>
