package libreria.dao;

/**
 * Se lanza cuando un pedido pide más unidades de un producto de las que
 * hay en stock. PedidoDAO.crear() la lanza dentro de su transacción (y
 * hace rollback antes de lanzarla); PedidoServlet la atrapa para devolver
 * un mensaje claro al carrito en vez de un genérico "error del servidor".
 */
public class StockInsuficienteException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    private final int productoId;
    private final int cantidadSolicitada;

    public StockInsuficienteException(String nombreProducto, int productoId, int cantidadSolicitada) {
        super("Stock insuficiente para \"" + nombreProducto + "\" (pediste " + cantidadSolicitada + ").");
        this.productoId = productoId;
        this.cantidadSolicitada = cantidadSolicitada;
    }

    public int getProductoId() { return productoId; }
    public int getCantidadSolicitada() { return cantidadSolicitada; }
}
