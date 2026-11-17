package libreria.util;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Pruebas de CAJA BLANCA (Tester 1) para
 * {@link EvaluadorPrestamo#evaluar(int, double, int, int, boolean)}.
 *
 * <p>Objetivo: 100 % de cobertura de ramas medida con JaCoCo 0.8.12 sobre la clase
 * {@code libreria.util.EvaluadorPrestamo}.</p>
 *
 * <p><b>Estructura de decisiones del SUT</b> (7 saltos condicionales = 14 ramas):</p>
 * <ul>
 *   <li>D1: {@code if (edad >= 21 && edad <= 65 && puntaje > 600)} &rarr; 3 condiciones &rarr; 6 ramas</li>
 *   <li>D2: {@code if (ingreso >= 1500)} &rarr; 1 condici&oacute;n &rarr; 2 ramas</li>
 *   <li>D3: {@code else if (antiguedad > 5 && !tieneDeudas && ingreso >= 1200)} &rarr; 3 condiciones &rarr; 6 ramas</li>
 * </ul>
 *
 * <p><b>Caminos a nivel de decisi&oacute;n</b> (los 4 de la consigna):</p>
 * <ol>
 *   <li>C1: D1 falso &rarr; "Rechazado"</li>
 *   <li>C2: D1 verdadero + D2 verdadero &rarr; "Aprobado"</li>
 *   <li>C3: D1 verdadero + D2 falso + D3 verdadero &rarr; "Aprobado por antig&uuml;edad"</li>
 *   <li>C4: D1 verdadero + D2 falso + D3 falso &rarr; "Rechazado"</li>
 * </ol>
 *
 * <p><b>Por qu&eacute; 4 no bastan y hacen falta 8 casos:</b> JaCoCo mide ramas de
 * subexpresi&oacute;n, no solo el resultado de la decisi&oacute;n. Cada una de las 7 condiciones
 * debe evaluarse verdadera en al menos un caso y falsa en al menos otro. Las tres salidas
 * falsas de D1 son mutuamente excluyentes (3 casos), las cuatro salidas de D3 tambi&eacute;n
 * lo son (4 casos, todos con D2 falso) y D2 verdadero exige un caso propio: m&iacute;nimo
 * 3 + 4 + 1 = 8 casos para cerrar las 14 ramas. Cada m&eacute;todo de esta clase es un
 * camino distinto, sin duplicados, y su aserci&oacute;n cita la regla de negocio (R1&ndash;R5)
 * que ejercita.</p>
 */
class EvaluadorPrestamoCajaBlancaTest {

    /**
     * Camino 1: D1 falso por edad inferior a 21.
     * Cierra la rama "edad &gt;= 21 falsa" (cortocircuito: el resto de D1 no se eval&uacute;a).
     */
    @Test
    @DisplayName("Camino 1: primer if falso por edad < 21 -> Rechazado (R1)")
    void camino1_primerIfFalsoPorEdadInferior_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(18, 2000.0, 700, 6, false);
        assertEquals("Rechazado", resultado,
                "R1: con edad=18 (< 21) la primera condicion del if externo es falsa"
                        + " y el modulo debe rechazar sin evaluar ingreso ni puntaje");
    }

    /**
     * Camino 2: D1 falso por edad superior a 65 (edad &gt;= 21 verdadera, edad &lt;= 65 falsa).
     * Cierra las ramas "edad &gt;= 21 verdadera" y "edad &lt;= 65 falsa".
     */
    @Test
    @DisplayName("Camino 2: primer if falso por edad > 65 -> Rechazado (R1)")
    void camino2_primerIfFalsoPorEdadSuperior_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(66, 2000.0, 750, 2, false);
        assertEquals("Rechazado", resultado,
                "R1: con edad=66 (> 65) la segunda condicion del if externo es falsa"
                        + " y el modulo debe rechazar aunque ingreso y puntaje sean validos");
    }

    /**
     * Camino 3: D1 falso por puntaje en la frontera (edad v&aacute;lida, puntaje &gt; 600 falso).
     * Cierra las ramas "edad &lt;= 65 verdadera" y "puntaje &gt; 600 falsa".
     */
    @Test
    @DisplayName("Camino 3: primer if falso por puntaje = 600 -> Rechazado (R3)")
    void camino3_primerIfFalsoPorPuntaje_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(35, 1800.0, 600, 0, false);
        assertEquals("Rechazado", resultado,
                "R3: con puntaje=600 (no > 600) la tercera condicion del if externo es falsa"
                        + " y el modulo debe rechazar aunque la edad y el ingreso sean validos");
    }

    /**
     * Camino 4: D1 verdadero + D2 verdadero (ingreso &ge; 1500).
     * Cierra las ramas "puntaje &gt; 600 verdadera" e "ingreso &ge; 1500 verdadera".
     */
    @Test
    @DisplayName("Camino 4: if externo verdadero + ingreso >= 1500 -> Aprobado (R1+R2+R3)")
    void camino4_ingresoSuficiente_retornaAprobado() {
        String resultado = EvaluadorPrestamo.evaluar(30, 1600.0, 650, 1, false);
        assertEquals("Aprobado", resultado,
                "R1+R2+R3: edad=30 en [21,65], ingreso=1600 >= 1500 y puntaje=650 > 600"
                        + " cumplen las tres reglas y el modulo debe aprobar");
    }

    /**
     * Camino 5: D1 verdadero + D2 falso + D3 falso por antig&uuml;edad insuficiente.
     * Cierra las ramas "ingreso &ge; 1500 falsa" y "antig&uuml;edad &gt; 5 falsa".
     */
    @Test
    @DisplayName("Camino 5: ingreso < 1500 + antigüedad <= 5 -> Rechazado (R4 no aplica)")
    void camino5_ingresoBajoAntiguedadCorta_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(40, 1300.0, 650, 2, false);
        assertEquals("Rechazado", resultado,
                "R4/R5: con ingreso=1300 (< 1500) y antigüedad=2 (<= 5) la excepcion interna"
                        + " no aplica y el modulo debe rechazar");
    }

    /**
     * Camino 6: D1 verdadero + D2 falso + D3 falso por deudas vencidas
     * (antig&uuml;edad &gt; 5 verdadera, sin deudas falso).
     * Cierra las ramas "antig&uuml;edad &gt; 5 verdadera" y "sin deudas vencidas falsa".
     */
    @Test
    @DisplayName("Camino 6: ingreso < 1500 + deudas vencidas -> Rechazado (R4 bloqueada por deudas)")
    void camino6_conDeudasVencidas_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(40, 1300.0, 650, 6, true);
        assertEquals("Rechazado", resultado,
                "R4: con antigüedad=6 (> 5) pero tieneDeudas=true la segunda condicion"
                        + " del elif es falsa y el modulo debe rechazar");
    }

    /**
     * Camino 7: D1 verdadero + D2 falso + D3 falso por ingreso debajo del umbral
     * de la excepci&oacute;n (sin deudas verdadera, ingreso &ge; 1200 falso).
     * Cierra las ramas "sin deudas vencidas verdadera" y "ingreso &ge; 1200 falsa".
     */
    @Test
    @DisplayName("Camino 7: ingreso < 1200 con antigüedad suficiente -> Rechazado (R4 exige >= 1200)")
    void camino7_ingresoDebajoDe1200_retornaRechazado() {
        String resultado = EvaluadorPrestamo.evaluar(40, 1100.0, 650, 6, false);
        assertEquals("Rechazado", resultado,
                "R4: con antigüedad=6 y sin deudas pero ingreso=1100 (< 1200) la tercera"
                        + " condicion del elif es falsa y el modulo debe rechazar");
    }

    /**
     * Camino 8: D1 verdadero + D2 falso + D3 verdadero (excepci&oacute;n interna completa).
     * Cierra la rama "ingreso &ge; 1200 verdadera" y completa las 14 ramas de la clase.
     */
    @Test
    @DisplayName("Camino 8: excepción interna (antigüedad > 5, sin deudas, ingreso >= 1200) -> Aprobado por antigüedad (R4)")
    void camino8_excepcionAntiguedad_retornaAprobadoPorAntiguedad() {
        String resultado = EvaluadorPrestamo.evaluar(40, 1300.0, 650, 6, false);
        assertEquals("Aprobado por antigüedad", resultado,
                "R4: con antigüedad=6 (> 5), sin deudas vencidas e ingreso=1300 (>= 1200)"
                        + " la excepcion interna aprueba aunque el ingreso no llegue a 1500");
    }
}
