package libreria.models;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class CodigoPromoTest {

    private CodigoPromo promo(String tipo, double valor) {
        CodigoPromo c = new CodigoPromo();
        c.setCodigo("PROMO");
        c.setTipo(tipo);
        c.setValor(valor);
        return c;
    }

    @Test
    void porcentaje_calculaDescuentoSobreSubtotal() {
        assertEquals(5.0, promo("PORCENTAJE", 10).calcularDescuento(50.0), 0.001);
    }

    @Test
    void porcentaje_redondeaACentimos() {
        // 15% de 33.33 = 4.9995 -> 5.00
        assertEquals(5.0, promo("PORCENTAJE", 15).calcularDescuento(33.33), 0.001);
    }

    @Test
    void porcentaje_subtotalCero_descuentoCero() {
        assertEquals(0.0, promo("PORCENTAJE", 20).calcularDescuento(0), 0.001);
    }

    @Test
    void porcentaje_cien_descuentaTodoElSubtotal() {
        assertEquals(40.0, promo("PORCENTAJE", 100).calcularDescuento(40.0), 0.001);
    }

    @Test
    void montoFijo_menorAlSubtotal_descuentaElMonto() {
        assertEquals(8.0, promo("MONTO_FIJO", 8).calcularDescuento(50.0), 0.001);
    }

    @Test
    void montoFijo_mayorAlSubtotal_noExcedeElSubtotal() {
        assertEquals(20.0, promo("MONTO_FIJO", 50).calcularDescuento(20.0), 0.001);
    }

    @Test
    void montoFijo_igualAlSubtotal_descuentaElSubtotal() {
        assertEquals(15.0, promo("MONTO_FIJO", 15).calcularDescuento(15.0), 0.001);
    }
}
