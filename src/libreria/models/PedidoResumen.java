package libreria.models;

import java.util.Date;

/**
 * Resumen de un pedido para el historial del modal de clientes.
 * No incluye ítems ni datos personales: solo lo que muestra la fila.
 */
public class PedidoResumen {

    private String id;
    private Date fecha;
    private double total;
    private String estado;

    public String getId()       { return id; }
    public Date   getFecha()    { return fecha; }
    public double getTotal()    { return total; }
    public String getEstado()   { return estado; }

    public void setId(String id)         { this.id = id; }
    public void setFecha(Date fecha)     { this.fecha = fecha; }
    public void setTotal(double total)   { this.total = total; }
    public void setEstado(String estado) { this.estado = estado; }
}
