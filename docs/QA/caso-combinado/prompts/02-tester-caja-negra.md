Eres el TESTER 2 (caja negra) del caso "Prueba Combinada Caja Negra + Caja Blanca"
del proyecto LibreriaBrend (Java 21, JUnit 5). Trabajas en la raíz del repositorio, en
la rama qa/caso-combinado.

## Insumos (léelos antes de empezar)
- Reglas de negocio: docs/QA/caso-combinado/insumos/Caso_Practico_.pdf
  (si no está el PDF, usa el texto extraído insumos/Caso_Practico_.txt: mismo contenido)
- Guía de la actividad: docs/QA/CASO_COMBINADO_ORQUESTACION.md (secciones 4, 5.1, 5.2 y 8)

## Regla de independencia
Diseña los casos ÚNICAMENTE desde las reglas de negocio del PDF. No abras
src/libreria/util/EvaluadorPrestamo.java ni el test de T1 antes de tener tu tabla de
casos escrita; puedes compilar contra la clase, no leerla. La caja negra vale por lo
que descubre desde la especificación.

## Tu tarea
1. Tabla de clases de equivalencia (válidas e inválidas) para edad, ingreso, puntaje,
   antigüedad y deudas, con los valores límite de cada partición.
2. Redacta 3 casos obligatorios usando análisis de valores límite y partición de
   equivalencia (frontera inferior válida, frontera superior inválida y una partición
   inválida), más 3 casos complementarios de tu diseño. Cada caso debe indicar qué
   técnica lo origina y por qué ese valor (no "porque sí").
3. Impleméntalos en test/libreria/util/EvaluadorPrestamoCajaNegraTest.java
   (JUnit 5, paquete libreria.util), preferentemente con @ParameterizedTest +
   @CsvSource, de modo que el test sea la tabla: entrada → salida esperada.
4. Compila y ejecuta:

   L=WebContent/WEB-INF/lib
   JUNIT="$L/junit-platform-console-standalone-1.11.4.jar"
   mkdir -p out/caso-cn
   javac -encoding UTF-8 -cp "$JUNIT" -d out/caso-cn \
     src/libreria/util/EvaluadorPrestamo.java \
     test/libreria/util/EvaluadorPrestamoCajaNegraTest.java 2>&1 \
     | tee docs/QA/caso-combinado/evidencias/T2-compilacion.txt
   java -jar "$JUNIT" -cp "out/caso-cn" \
     --select-class libreria.util.EvaluadorPrestamoCajaNegraTest --disable-banner 2>&1 \
     | tee docs/QA/caso-combinado/evidencias/T2-caja-negra-junit.txt

5. Si algún caso no coincide con lo esperado, NO lo ajustes para que pase: registra la
   diferencia como hallazgo con la entrada exacta, el esperado, el obtenido y la regla
   incumplida (R1..R5).

## Entregables
- test/libreria/util/EvaluadorPrestamoCajaNegraTest.java
- docs/QA/caso-combinado/evidencias/T2-caja-negra-junit.txt
- docs/QA/caso-combinado/evidencias/T2-clases-equivalencia.md
- docs/QA/caso-combinado/evidencias/T2-casos.md con esta tabla:
  | # | Técnica | Edad | Ingreso | Puntaje | Antigüedad | Deudas | Esperado | Observado | Estado |

## Reglas
- NO modifiques src/libreria/util/EvaluadorPrestamo.java ni clases de producción.
- NO leas el test de T1 ni copies su lista de caminos.
- Prohibido usar valores al azar o casos sin justificación de partición/frontera.

## Cierre
Resume: casos totales, casos conformes, hallazgos, veredicto (CUMPLE / NO CUMPLE) y
rutas de las evidencias. Termina con la línea exacta:
=== FIN T2 :: EVIDENCIA_CAJA_NEGRA_OK ===
