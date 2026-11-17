package libreria.util;

/**
 * Evaluador de aprobación de préstamos personales.
 *
 * Ejercicio académico del caso práctico "Prueba Combinada (Caja Negra +
 * Caja Blanca)" de Calidad y Pruebas de Software (UPN): traducción fiel
 * a Java 21 del fragmento Python del enunciado. Función independiente:
 * no forma parte de los 17 requisitos funcionales implementados de
 * Librería Brenda ni se integra con Servlets, DAO, base de datos ni
 * interfaz.
 *
 * Reglas de negocio del enunciado:
 * R1: edad del solicitante entre 21 y 65 años, ambos inclusive.
 * R2: ingreso mensual neto >= 1500.
 * R3: puntaje crediticio > 600.
 * R4: excepción interna: antigüedad > 5 años y sin deudas vencidas
 *     aprueba aunque el ingreso sea >= 1200.
 * R5: cualquier otro caso: "Rechazado".
 */
public final class EvaluadorPrestamo {

    private EvaluadorPrestamo() {
        // clase utilitaria, no se instancia
    }

    /**
     * Evalúa si un solicitante califica para un préstamo personal.
     * Devuelve exactamente "Aprobado", "Aprobado por antigüedad" o
     * "Rechazado": sin validaciones extra, sin null y sin excepciones.
     */
    public static String evaluar(int edad, double ingreso, int puntaje, int antiguedad, boolean tieneDeudas) {
        if (edad >= 21 && edad <= 65 && puntaje > 600) {
            if (ingreso >= 1500) {
                return "Aprobado";
            } else if (antiguedad > 5 && !tieneDeudas && ingreso >= 1200) {
                return "Aprobado por antigüedad";
            }
        }
        return "Rechazado";
    }
}
