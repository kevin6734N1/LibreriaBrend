package libreria.models;

import java.util.Date;

/**
 * Modelo Comprobante - Libreria Brenda
 *
 * Un pedido representa la INTENCION de compra (lo que el cliente arma en su
 * carrito y confirma). Un comprobante representa la VENTA REALIZADA: solo
 * se emite cuando un administrador confirma que el pedido paso a
 * CONFIRMADO/ENVIADO/ENTREGADO (ver PedidoDAO.cambiarEstado). Los reportes
 * de ingresos (ReporteServlet/PedidoDAO) se calculan a partir de esta tabla,
 * no de "pedidos", para no contar como venta algo que quedo en PENDIENTE o
 * que se CANCELO.
 */
public class Comprobante {

    private int     id;
    private String  pedidoId;
    private String  tipoComprobante; // BOLETA | FACTURA
    private String  serie;
    private double  monto;
    private Date    fechaEmision;
    private Integer administradorId;      // quien confirmo la venta (puede ser null en datos historicos)
    private String  administradorNombre;  // solo para mostrar, viene de un JOIN

    // ---- Getters ----
    public int     getId()                  { return id; }
    public String  getPedidoId()            { return pedidoId; }
    public String  getTipoComprobante()     { return tipoComprobante; }
    public String  getSerie()               { return serie; }
    public double  getMonto()               { return monto; }
    public Date    getFechaEmision()        { return fechaEmision; }
    public Integer getAdministradorId()     { return administradorId; }
    public String  getAdministradorNombre() { return administradorNombre; }

    /** El correlativo es el mismo id autoincremental de la tabla (no se duplica en otra columna). */
    public String getNumeroCompleto() {
        return serie + "-" + String.format("%06d", id);
    }

    // ---- Setters ----
    public void setId(int id)                                 { this.id = id; }
    public void setPedidoId(String pedidoId)                  { this.pedidoId = pedidoId; }
    public void setTipoComprobante(String tipoComprobante)    { this.tipoComprobante = tipoComprobante; }
    public void setSerie(String serie)                         { this.serie = serie; }
    public void setMonto(double monto)                         { this.monto = monto; }
    public void setFechaEmision(Date fechaEmision)             { this.fechaEmision = fechaEmision; }
    public void setAdministradorId(Integer administradorId)   { this.administradorId = administradorId; }
    public void setAdministradorNombre(String nombre)         { this.administradorNombre = nombre; }
}
