package libreria.dao;

/**
 * Se lanza cuando el codigo promocional ya no se puede aplicar al momento de
 * confirmar el pedido (ej. otra pestana lo uso primero). PedidoDAO.crear()
 * hace rollback antes de lanzarla; PedidoServlet la atrapa y devuelve el motivo.
 */
public class CodigoPromoInvalidoException extends RuntimeException {
    private static final long serialVersionUID = 1L;

    public CodigoPromoInvalidoException(String mensaje) {
        super(mensaje);
    }
}
