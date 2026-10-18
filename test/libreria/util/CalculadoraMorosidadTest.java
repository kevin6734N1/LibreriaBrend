package libreria.util;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Prueba RED de la función académica de morosidad (ejercicio TDD Sprint 3).
 *
 * Regla de negocio: un cliente/factura es moroso cuando el saldo pendiente
 * es mayor que cero Y la fecha de evaluación es posterior al vencimiento.
 *
 * Los datos son simulados (caso hipotético Águilas del Perú S.A.C.); no
 * pertenecen a clientes reales de Librería Brenda ni a los 17 RF del proyecto.
 */
class CalculadoraMorosidadTest {

    @Test
    void facturaVencidaConSaldoPendiente_esMoroso() {
        BigDecimal saldoPendiente = new BigDecimal("100.00");
        LocalDate fechaVencimiento = LocalDate.of(2026, 10, 10);
        LocalDate fechaEvaluacion = LocalDate.of(2026, 10, 17);

        assertTrue(
                CalculadoraMorosidad.esMoroso(saldoPendiente, fechaVencimiento, fechaEvaluacion),
                "Saldo S/ 100.00 vencido el 10/10/2026 y evaluado el 17/10/2026 debe clasificarse como Moroso");
    }
}