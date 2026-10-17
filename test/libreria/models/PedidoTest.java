package libreria.models;

import libreria.models.Pedido.ItemPedido;
import org.junit.jupiter.api.Test;
import java.util.ArrayList;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class PedidoTest {

    private Producto producto(double precio) {
        return new Producto(1, "Cuaderno A4", "desc", precio, 100, "Cuadernos", "img.png");
    }

    private Pedido pedidoCon(double precio, int cantidad) {
        Pedido p = new Pedido();
        List<ItemPedido> items = new ArrayList<>();
        items.add(new ItemPedido(producto(precio), cantidad));
        p.setItems(items);
        return p;
    }

    // ---- Estado inicial ----

    @Test
    void pedidoNuevo_estadoPendiente() {
        assertEquals(Pedido.Estado.PENDIENTE, new Pedido().getEstado());
    }

    @Test
    void pedidoNuevo_idConPrefijoPED() {
        assertTrue(new Pedido().getId().startsWith("PED-"));
    }

    @Test
    void pedidoNuevo_tieneFecha() {
        assertNotNull(new Pedido().getFecha());
    }

    // ---- ItemPedido ----

    @Test
    void item_subtotalEsPrecioPorCantidad() {
        ItemPedido item = new ItemPedido(producto(12.5), 4);
        assertEquals(50.0, item.getSubtotal(), 0.001);
    }

    @Test
    void item_tomaElPrecioDelProductoAlCrearse() {
        Producto prod = producto(10.0);
        ItemPedido item = new ItemPedido(prod, 1);
        prod.setPrecio(99.0); // un cambio posterior de precio no altera el pedido
        assertEquals(10.0, item.getPrecioUnitario(), 0.001);
    }

    // ---- calcularSubtotal ----

    @Test
    void subtotal_sinItems_esCero() {
        assertEquals(0.0, new Pedido().calcularSubtotal(), 0.001);
    }

    @Test
    void subtotal_sumaTodosLosItems() {
        Pedido p = new Pedido();
        List<ItemPedido> items = new ArrayList<>();
        items.add(new ItemPedido(producto(10.0), 2));  // 20
        items.add(new ItemPedido(producto(5.5), 3));   // 16.5
        p.setItems(items);
        assertEquals(36.5, p.calcularSubtotal(), 0.001);
    }

    // ---- calcularTotal: regla de envío ----

    @Test
    void total_subtotalBajo30_cobraEnvio10() {
        Pedido p = pedidoCon(10.0, 2); // 20
        assertEquals(30.0, p.calcularTotal(), 0.001);
        assertEquals(10.0, p.getEnvio(), 0.001);
    }

    @Test
    void total_subtotalExactamente30_envioGratis() {
        Pedido p = pedidoCon(10.0, 3); // 30 (borde)
        assertEquals(30.0, p.calcularTotal(), 0.001);
        assertEquals(0.0, p.getEnvio(), 0.001);
    }

    @Test
    void total_subtotalJustoDebajoDe30_cobraEnvio() {
        Pedido p = pedidoCon(29.99, 1);
        p.calcularTotal();
        assertEquals(10.0, p.getEnvio(), 0.001);
    }

    @Test
    void total_subtotalSobre30_envioGratis() {
        Pedido p = pedidoCon(25.0, 2); // 50
        assertEquals(50.0, p.calcularTotal(), 0.001);
    }

    // ---- calcularTotal: descuento ----

    @Test
    void total_descuentoSeRestaDelSubtotal() {
        Pedido p = pedidoCon(25.0, 2); // 50
        p.setDescuento(5.0);
        assertEquals(45.0, p.calcularTotal(), 0.001);
    }

    @Test
    void total_descuentoQueBajaDe30_activaEnvio() {
        Pedido p = pedidoCon(35.0, 1); // 35 sin descuento = envío gratis
        p.setDescuento(10.0);          // 25 -> cobra envío
        assertEquals(35.0, p.calcularTotal(), 0.001); // 35 - 10 + 10
        assertEquals(10.0, p.getEnvio(), 0.001);
    }

    @Test
    void total_sinItems_cobraSoloEnvio() {
        assertEquals(10.0, new Pedido().calcularTotal(), 0.001);
    }

    @Test
    void total_recalcularDosVeces_daElMismoResultado() {
        Pedido p = pedidoCon(10.0, 2);
        double primero = p.calcularTotal();
        assertEquals(primero, p.calcularTotal(), 0.001);
    }
}
