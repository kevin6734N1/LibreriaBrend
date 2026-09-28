package libreria.models;

/** Modelo CodigoPromo - Libreria Brenda. Coincide con la tabla "codigos_promo". */
public class CodigoPromo {
    private String codigo;
    private String tipo;   // "PORCENTAJE" | "MONTO_FIJO"
    private double valor;

    public String getCodigo() { return codigo; }
    public String getTipo()   { return tipo; }
    public double getValor()  { return valor; }

    public void setCodigo(String codigo) { this.codigo = codigo; }
    public void setTipo(String tipo)     { this.tipo = tipo; }
    public void setValor(double valor)   { this.valor = valor; }

    /**
     * Descuento en soles sobre el subtotal. Porcentaje: redondeado a centimos.
     * Monto fijo: nunca mayor que el subtotal. Misma formula que carrito.js.
     */
    public double calcularDescuento(double subtotal) {
        if ("PORCENTAJE".equals(tipo)) {
            return Math.round(subtotal * valor) / 100.0;
        }
        return Math.min(valor, subtotal);
    }
}
