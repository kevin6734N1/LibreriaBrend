# BITACORA — Caso Combinado (Caja Negra + Caja Blanca)

Proyecto: LibreriaBrend — Calidad y Pruebas de Software (UPN)
Orquestador: Vibe CLI (GLM 5.3) · Tester 1: MiniMax Code (`mcode`) · Tester 2: Antigravity (`agy`)
Rama: qa/caso-combinado

---

## 2026-11-16

### 19:40–19:47 — Preparacion (orquestador)
- Verificado entorno: `javac 21.0.12.1`, JUnit console 1.11.4, JaCoCo 0.8.12 en `out/tools/`, Edge, `hc 0.1.21`.
- Copiado `Caso_Practico_.pdf` a `docs/QA/caso-combinado/insumos/` (el texto extraido `.txt` ya estaba).
- Creada rama `qa/caso-combinado` desde `main` (36848b5).
- Creado SUT `src/libreria/util/EvaluadorPrestamo.java` (traduccion fiel del fragmento Python del enunciado) y compilado aislado a `out/caso-cb`.
- Evidencia: `evidencias/G0-preparacion.txt` — **G0 SUPERADA**.

### 19:49 — Lanzamiento de la malla (orquestador)
- Nota: `hc` rechaza nombres con forma de dirección autogenerada (`t1`/`t2`), así que las
  terminales se llaman `tester1` (T1) y `tester2` (T2). Equivalencia 1:1 con la sección 2.
- `hc run --bg --outlive-parent --name tester1 ... mcode` → terminal t28, live, rol=caja-blanca.
- `hc run --bg --outlive-parent --name tester2 ... agy` → terminal t29, live, rol=caja-negra.
- Ambos CLIs arrancaron sin onboarding pendiente (mcode v0.7.6 Ready; Antigravity 1.5.7 con sesión Google activa).

### 19:52 — Despacho de encargos (orquestador)
- Prompts materializados como archivos (contenido literal de las secciones 9.2 y 9.3 de la guía):
  - `prompts/01-tester-caja-blanca.md` → `hc put tester1` (aterrizó en files/t28/)
  - `prompts/02-tester-caja-negra.md` → `hc put tester2` (aterrizó en files/t29/)
- `hc send tester1 "Ejecuta el encargo... Empieza ahora."` → started, status working.
- `hc send tester2 "Ejecuta el encargo... Empieza ahora."` → started, status working.
- Reglas de independencia incluidas en ambos prompts: T2 no lee el fuente del SUT antes de
  diseñar; T1 no lee los casos de T2; nadie toca `src/` de producción.

### 19:55 — T2 (Antigravity) cierra su turno
- Resumen de T2: 6 casos (3 obligatorios + 3 complementarios), 6 conformes, 0 hallazgos,
  veredicto CUMPLE. Línea de cierre: `=== FIN T2 :: EVIDENCIA_CAJA_NEGRA_OK ===`.
- Entregables verificados en disco por el orquestador:
  `test/libreria/util/EvaluadorPrestamoCajaNegraTest.java`,
  `evidencias/T2-caja-negra-junit.txt` (6 tests found, 6 successful, 0 failed),
  `evidencias/T2-compilacion.txt`, `evidencias/T2-clases-equivalencia.md`,
  `evidencias/T2-casos.md`.
- Validacion G2: casos 1-3 identicos a 5.1 de la guia; casos 4-6 cubren 5.2; cada caso
  justificado por particion/frontera; `git diff --stat src/` vacio (SUT intacto).
  **G2 SUPERADA**.
- Nota tecnica: `T2-caja-negra-junit.txt` quedo en UTF-16LE con codigos ANSI (redireccion
  de PowerShell); contenido integro. El orquestador genera una copia legible en UTF-8
  para el anexo del informe sin alterar el archivo original.

### 19:57 — Incidencia T1 (mcode) y reasignacion del encargo de caja blanca
- mcode (tester1) no pudo procesar el encargo: el proveedor del modelo
  (deepseek-v4-1-flash-1017) responde error 50113 "model provider is temporarily
  unavailable" de forma persistente (~12 min, mas de 15 reintentos automaticos y manuales).
- Intentos de recuperacion: `/retry` (llego mangleado por la conversion de rutas de
  Git Bash), reenvio limpio del encargo, Enter sobre el prompt preservado y `/model`
  (sin efecto: cada envio se acumula al prompt preservado y reintenta contra el
  proveedor caido). La terminal nunca llego a pensar: 0 archivos producidos.
- Decision del orquestador: reasignar el encargo de caja blanca a un subagente Vibe
  (`tester1-caja-blanca`) con el mismo prompt versionado
  (`prompts/01-tester-caja-blanca.md`), contexto fresco y las mismas reglas de
  independencia (no leer el test de T2 ni sus evidencias; no tocar `src/`).
  La terminal mcode queda viva como registro de la incidencia.
- Las puertas de calidad y los entregables de T1 no cambian: mismos archivos,
  mismos criterios (G1: 0 fallos, BRANCH_MISSED = 0, >= 8 casos, tabla de caminos).

### 20:00 — T1 (subagente Vibe `tester1-caja-blanca`) cierra su turno
- Resumen de T1: 8 casos (minimo justificado por cobertura de ramas), 8/8 exitosos,
  14/14 ramas (BRANCH_COVERED = 14, BRANCH_MISSED = 0), veredicto CUMPLE.
  Linea de cierre: `=== FIN T1 :: EVIDENCIA_CAJA_BLANCA_OK ===`.
- Entregables verificados en disco por el orquestador:
  `test/libreria/util/EvaluadorPrestamoCajaBlancaTest.java`,
  `evidencias/T1-compilacion.txt`, `evidencias/T1-caja-blanca-junit.txt`
  (8 tests found, 8 successful, 0 failed), `evidencias/T1-jacoco-ramas.txt`,
  `evidencias/T1-caminos.md`.
- Validacion G1: evidencias con salida real; el orquestador REPRODUJO el CSV de JaCoCo
  desde `out/caso-cb/jacoco.exec` (fila identica: `...,0,28,0,14,0,6,0,8,0,1`); suite con
  8 metodos con nombre descriptivo y asercion que cita la regla. **G1 SUPERADA**.

### 20:05 — G3 coherencia cruzada (orquestador)
- Veredictos de T1 y T2 coinciden con los criterios 5.1-5.4 de la guia; los 4 caminos de
  la consigna estan cubiertos a nivel decision y los 8 casos cierran las 14 ramas;
  SUT intacto (`git diff --stat src/` vacio); ninguna prueba reescrita para pasar.
- Evidencia: `evidencias/G3-coherencia.txt`. **G3 SUPERADA**.

### 20:06 — G4 regresion del proyecto (orquestador)
- Corrida A (comando literal de la guia): 98 tests found, 94 successful, 4 failed. Los 4
  fallos son de `libreria.util.ConexionBDPoolTest` por `Connection refused` (no hay
  MariaDB escuchando en 3306/3307): condicion ambiental preexistente, ajena a la
  actividad (ningun archivo rastreado modificado).
- Corrida B (exclusion extendida: `libreria\.dao\..*|libreria\.util\.ConexionBDPoolTest`):
  94 tests found, 94 successful, 0 failed, incluyendo las 14 pruebas nuevas.
- Evidencias: `G4-regresion.txt`, `G4-regresion-sin-bd.txt`, `G4-veredicto.txt`.
  **G4 SUPERADA** (con la salvedad ambiental documentada).

### 20:02 — G5 informe y PDF (orquestador)
- Redactado `Informe_Caso_Combinado.md` con las 8 secciones obligatorias de la guia
  (11.1) y su version imprimible `Informe_Caso_Combinado.html` con el CSS de impresion
  de la seccion 11.3.
- PDF generado con Edge headless (`--headless=new --no-pdf-header-footer`):
  `Informe_Caso_Combinado.pdf`, 340905 bytes, 13 paginas (portada + 12 de contenido),
  encabezado `%PDF-1.4` valido, portada renderizada verificada con captura
  (`out/caso-cb/portada-check.png`, fuera del repositorio).
- Toda cifra del informe proviene de un archivo de evidencia listado en su seccion 6.
  **G5 SUPERADA**.

### 20:04 — Cierre de la malla
- `hc kill tester1` (mcode: terminal cerrada; la incidencia del proveedor 50113 quedo
  documentada arriba) y `hc kill tester2` (agy: turno T2 completado y validado).
- Checklist de entrega (seccion 12 de la guia): todos los items cumplidos;
  `git status` muestra solo archivos de la actividad (SUT, dos suites, guia y
  carpeta docs/QA/caso-combinado).
