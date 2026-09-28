package libreria.models;

import java.util.Date;
import java.util.List;

/**
 * Modelo Pedido - Librería Brenda
 */
public class Pedido {

    public enum Estado {
        PENDIENTE, CONFIRMADO, ENVIADO, ENTREGADO, CANCELADO
    }

    private String          id;
    private String          clienteEmail;
    private Date            fecha;
    private Estado          estado;
    private List<ItemPedido> items;
    private double          subtotal;
    private double          descuento;
    private double          envio;
    private double          total;
    private String          direccionEntrega;
    private String          metodoPago;

    public Pedido() {
        this.fecha  = new Date();
        this.estado = Estado.PENDIENTE;
        this.id     = "PED-" + System.currentTimeMillis();
    }

    // ---- Getters ----
    public String           getId()              { return id; }
    public String           getClienteEmail()    { return clienteEmail; }
    public Date             getFecha()           { return fecha; }
    public Estado           getEstado()          { return estado; }
    public List<ItemPedido> getItems()           { return items; }
    public double           getSubtotal()        { return subtotal; }
    public double           getDescuento()       { return descuento; }
    public double           getEnvio()           { return envio; }
    public double           getTotal()           { return total; }
    public String           getDireccionEntrega(){ return direccionEntrega; }
    public String           getMetodoPago()      { return metodoPago; }

    // ---- Setters ----
    public void setId(String id)                         { this.id = id; }
    public void setClienteEmail(String clienteEmail)     { this.clienteEmail = clienteEmail; }
    public void setFecha(Date fecha)                     { this.fecha = fecha; }
    public void setEstado(Estado estado)                 { this.estado = estado; }
    public void setItems(List<ItemPedido> items)         { this.items = items; }
    public void setSubtotal(double subtotal)             { this.subtotal = subtotal; }
    public void setDescuento(double descuento)           { this.descuento = descuento; }
    public void setEnvio(double envio)                   { this.envio = envio; }
    public void setTotal(double total)                   { this.total = total; }
    public void setDireccionEntrega(String dir)          { this.direccionEntrega = dir; }
    public void setMetodoPago(String metodoPago)         { this.metodoPago = metodoPago; }

    /** Calcula el subtotal sumando todos los ítems (sin descuentos ni envío). */
    public double calcularSubtotal() {
        if (items == null) return 0;
        this.subtotal = items.stream()
                .mapToDouble(i -> i.getPrecioUnitario() * i.getCantidad())
                .sum();
        return this.subtotal;
    }

    /**
     * Recalcula subtotal, envio y total.
     *  - Envio gratis si (subtotal - descuento) >= 30, sino S/10.
     *  - El descuento se conserva tal cual (0 por defecto); PedidoServlet lo
     *    asigna con setDescuento() cuando hay un codigo promocional valido.
     */
    public double calcularTotal() {
        calcularSubtotal();
        this.envio = (subtotal - descuento) >= 30 ? 0 : 10;
        this.total = subtotal - descuento + envio;
        return this.total;
    }

    // ---- Clase interna ItemPedido ----
    public static class ItemPedido {
        private Producto producto;
        private int      cantidad;
        private double   precioUnitario;

        public ItemPedido(Producto producto, int cantidad) {
            this.producto       = producto;
            this.cantidad       = cantidad;
            this.precioUnitario = producto.getPrecio();
        }

        public Producto getProducto()        { return producto; }
        public int      getCantidad()        { return cantidad; }
        public double   getPrecioUnitario()  { return precioUnitario; }
        public double   getSubtotal()        { return precioUnitario * cantidad; }

        public void setCantidad(int cantidad)            { this.cantidad = cantidad; }
        public void setPrecioUnitario(double precio)     { this.precioUnitario = precio; }
    }
}
