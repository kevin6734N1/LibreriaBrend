package libreria.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Pruebas de Caja Negra para {@link EvaluadorPrestamo}.
 *
 * Diseñadas a partir de la especificación funcional (Reglas R1 a R5)
 * utilizando las técnicas de Partición de Equivalencia (EP) y
 * Análisis de Valores Límite (BVA).
 */
public class EvaluadorPrestamoCajaNegraTest {

    @ParameterizedTest(name = "Caso {0} [{1}]: edad={2}, ingreso={3}, puntaje={4}, antiguedad={5}, deudas={6} -> esperado={7}")
    @CsvSource(delimiter = '|', textBlock = """
        1 | BVA: Frontera inferior valida (edad e ingreso) | 21 | 1500.0 | 601 | 1 | false | Aprobado
        2 | BVA: Frontera superior invalida (edad > 65)    | 66 | 2000.0 | 750 | 2 | false | Rechazado
        3 | EP invalida / BVA: Puntaje en frontera (<=600) | 35 | 1800.0 | 600 | 0 | false | Rechazado
        4 | BVA: Frontera inferior invalida (edad < 21)    | 20 | 2000.0 | 700 | 3 | false | Rechazado
        5 | BVA: Limite inferior de excepcion (R4)         | 40 | 1200.0 | 650 | 6 | false | Aprobado por antigüedad
        6 | EP invalida: Excepcion con deuda vencida (R4)  | 40 | 1200.0 | 650 | 6 | true  | Rechazado
        """)
    @DisplayName("Tabla de decisiones de Caja Negra: Equivalencia + Valores Límite")
    void testEvaluarPrestamoCajaNegra(
            int caso,
            String tecnica,
            int edad,
            double ingreso,
            int puntaje,
            int antiguedad,
            boolean tieneDeudas,
            String resultadoEsperado) {

        String resultadoObtenido = EvaluadorPrestamo.evaluar(edad, ingreso, puntaje, antiguedad, tieneDeudas);
        assertEquals(resultadoEsperado, resultadoObtenido,
                () -> "Discrepancia en Caso " + caso + " (" + tecnica + "): esperado='"
                        + resultadoEsperado + "', obtenido='" + resultadoObtenido + "'");
    }
}
