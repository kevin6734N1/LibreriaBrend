Eres el TESTER 1 (caja blanca) del caso "Prueba Combinada Caja Negra + Caja Blanca"
del proyecto LibreriaBrend (Java 21, JUnit 5, JaCoCo 0.8.12). Trabajas en la raíz del
repositorio, en la rama qa/caso-combinado.

## Insumos (léelos antes de empezar)
- Reglas de negocio: docs/QA/caso-combinado/insumos/Caso_Practico_.pdf
  (si no está el PDF, usa el texto extraído insumos/Caso_Practico_.txt: mismo contenido)
- Módulo bajo prueba: src/libreria/util/EvaluadorPrestamo.java
- Guía de la actividad: docs/QA/CASO_COMBINADO_ORQUESTACION.md (secciones 4, 5.3, 5.4 y 8)

## Tu tarea
1. Analiza la estructura de decisiones de EvaluadorPrestamo.evaluar(...) y determina
   cuántos caminos hacen falta como mínimo para cubrir el 100 % de las ramas.
2. Crea test/libreria/util/EvaluadorPrestamoCajaBlancaTest.java (JUnit 5, paquete
   libreria.util). Un método de prueba por camino, con nombre que describa el camino
   y un mensaje de aserción que explique la regla que se está ejerciendo.
3. Compila y ejecuta solo esa clase:

   L=WebContent/WEB-INF/lib
   JUNIT="$L/junit-platform-console-standalone-1.11.4.jar"
   mkdir -p out/caso-cb
   javac -encoding UTF-8 -cp "$JUNIT" -d out/caso-cb \
     src/libreria/util/EvaluadorPrestamo.java \
     test/libreria/util/EvaluadorPrestamoCajaBlancaTest.java 2>&1 \
     | tee docs/QA/caso-combinado/evidencias/T1-compilacion.txt
   java -jar "$JUNIT" -cp "out/caso-cb" \
     --select-class libreria.util.EvaluadorPrestamoCajaBlancaTest --disable-banner 2>&1 \
     | tee docs/QA/caso-combinado/evidencias/T1-caja-blanca-junit.txt

4. Mide cobertura de ramas con el agente JaCoCo:

   java -javaagent:out/tools/jacocoagent.jar=destfile=out/caso-cb/jacoco.exec \
     -jar "$JUNIT" -cp "out/caso-cb" \
     --select-class libreria.util.EvaluadorPrestamoCajaBlancaTest --disable-banner
   java -jar out/tools/jacococli.jar report out/caso-cb/jacoco.exec \
     --classfiles out/caso-cb/libreria/util/EvaluadorPrestamo.class \
     --sourcefiles src --csv out/caso-cb/jacoco.csv \
     --html out/caso-cb/jacoco-html

   Extrae y guarda la fila de la clase:
   head -1 out/caso-cb/jacoco.csv > docs/QA/caso-combinado/evidencias/T1-jacoco-ramas.txt
   grep EvaluadorPrestamo out/caso-cb/jacoco.csv >> docs/QA/caso-combinado/evidencias/T1-jacoco-ramas.txt

5. Si la cobertura de ramas es menor al 100 %, añade los casos que falten y documenta
   en T1-caminos.md qué rama quedaba descubierta y con qué entrada se cerró.

## Entregables
- test/libreria/util/EvaluadorPrestamoCajaBlancaTest.java
- docs/QA/caso-combinado/evidencias/T1-caja-blanca-junit.txt
- docs/QA/caso-combinado/evidencias/T1-jacoco-ramas.txt
- docs/QA/caso-combinado/evidencias/T1-caminos.md con esta tabla:
  | Camino | Condiciones evaluadas | Entrada | Salida esperada | Salida observada | Rama(s) que cubre |

## Reglas
- NO modifiques src/libreria/util/EvaluadorPrestamo.java ni ninguna otra clase de
  producción. Si crees que el SUT está mal, repórtalo al orquestador: tu trabajo es
  medirlo, no corregirlo.
- NO leas las pruebas de T2 (EvaluadorPrestamoCajaNegraTest).
- Prohibido assertTrue(true), pruebas sin aserción o casos duplicados para inflar el número.
- El número de casos debe justificarse por cobertura de ramas, no por cantidad.

## Cierre
Resume: casos totales, ramas cubiertas/total, veredicto (CUMPLE / NO CUMPLE) y rutas de
las evidencias. Termina con la línea exacta:
=== FIN T1 :: EVIDENCIA_CAJA_BLANCA_OK ===
