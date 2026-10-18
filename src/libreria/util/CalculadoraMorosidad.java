package libreria.util;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Implementación REFACTOR — regla de negocio de morosidad.
 *
 * Ejercicio académico TDD Sprint 3 (Calidad y Pruebas de Software, UPN),
 * inspirado en el caso hipotético de facturas por cobrar de Águilas del Perú
 * S.A.C. Función independiente: no forma parte de los 17 requisitos
 * funcionales implementados de Librería Brenda ni se integra con Servlets,
 * DAO, base de datos ni interfaz en esta etapa.
 *
 * Regla de negocio: es moroso si saldoPendiente > 0 Y fechaEvaluacion > fechaVencimiento.
 */
public final class CalculadoraMorosidad {

    private CalculadoraMorosidad() {
        // clase utilitaria, no se instancia
    }

    /**
     * Determina si una factura está en estado moroso.
     * Preserva el cortocircuito evaluando las fechas únicamente si existe deuda.
     */
    public static boolean esMoroso(BigDecimal saldoPendiente, LocalDate fechaVencimiento, LocalDate fechaEvaluacion) {
        boolean tieneDeuda = saldoPendiente.compareTo(BigDecimal.ZERO) > 0;
        if (!tieneDeuda) {
            return false;
        }

        boolean plazoVencido = fechaEvaluacion.isAfter(fechaVencimiento);
        return plazoVencido;
    }
}