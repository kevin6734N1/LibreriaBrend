package libreria.models;

/**
 * Modelo Producto - Librería Brenda
 */
public class Producto {

    private int     id;
    private String  nombre;
    private String  descripcion;
    private double  precio;
    private int     stock;
    private String  categoria;
    private String  imagen;
    private boolean activo;
    private String  etiqueta;

    public Producto() {}

    public Producto(int id, String nombre, String descripcion,
                    double precio, int stock, String categoria, String imagen) {
        this.id          = id;
        this.nombre      = nombre;
        this.descripcion = descripcion;
        this.precio      = precio;
        this.stock       = stock;
        this.categoria   = categoria;
        this.imagen      = imagen;
        this.activo      = true;
    }

    // ---- Getters ----
    public int     getId()          { return id; }
    public String  getNombre()      { return nombre; }
    public String  getDescripcion() { return descripcion; }
    public double  getPrecio()      { return precio; }
    public int     getStock()       { return stock; }
    public String  getCategoria()   { return categoria; }
    public String  getImagen()      { return imagen; }
    public boolean isActivo()       { return activo; }
    public String  getEtiqueta()    { return etiqueta; }

    // ---- Setters ----
    public void setId(int id)                   { this.id = id; }
    public void setNombre(String nombre)         { this.nombre = nombre; }
    public void setDescripcion(String desc)      { this.descripcion = desc; }
    public void setPrecio(double precio)         { this.precio = precio; }
    public void setStock(int stock)              { this.stock = stock; }
    public void setCategoria(String categoria)   { this.categoria = categoria; }
    public void setImagen(String imagen)         { this.imagen = imagen; }
    public void setActivo(boolean activo)        { this.activo = activo; }
    public void setEtiqueta(String etiqueta)     { this.etiqueta = etiqueta; }

    @Override
    public String toString() {
        return "Producto{id=" + id + ", nombre=" + nombre + ", precio=" + precio + "}";
    }
}
