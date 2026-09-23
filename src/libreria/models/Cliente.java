package libreria.models;

import java.util.Date;

/**
 * Modelo Cliente - Libreria Brenda
 * Coincide con la tabla "clientes" y con los campos de registro.jsp.
 */
public class Cliente {

    private int     id;
    private String  nombres;
    private String  apellidos;
    private String  dni;
    private String  email;
    private String  telefono;
    private String  direccion;
    private String  passwordHash;
    private boolean activo;
    private Date    fechaRegistro;

    // Campos calculados (vienen de vista_clientes_resumen, no de la tabla)
    private int    totalPedidos;
    private double totalGastado;

    public Cliente() {
        this.activo = true;
    }

    // ---- Getters ----
    public int     getId()            { return id; }
    public String  getNombres()       { return nombres; }
    public String  getApellidos()     { return apellidos; }
    public String  getNombreCompleto(){ return nombres + " " + apellidos; }
    public String  getDni()           { return dni; }
    public String  getEmail()         { return email; }
    public String  getTelefono()      { return telefono; }
    public String  getDireccion()     { return direccion; }
    public String  getPasswordHash()  { return passwordHash; }
    public boolean isActivo()         { return activo; }
    public Date    getFechaRegistro() { return fechaRegistro; }
    public int     getTotalPedidos()  { return totalPedidos; }
    public double  getTotalGastado()  { return totalGastado; }

    // ---- Setters ----
    public void setId(int id)                       { this.id = id; }
    public void setNombres(String nombres)           { this.nombres = nombres; }
    public void setApellidos(String apellidos)       { this.apellidos = apellidos; }
    public void setDni(String dni)                   { this.dni = dni; }
    public void setEmail(String email)               { this.email = email; }
    public void setTelefono(String telefono)         { this.telefono = telefono; }
    public void setDireccion(String direccion)       { this.direccion = direccion; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public void setActivo(boolean activo)            { this.activo = activo; }
    public void setFechaRegistro(Date fechaRegistro) { this.fechaRegistro = fechaRegistro; }
    public void setTotalPedidos(int totalPedidos)    { this.totalPedidos = totalPedidos; }
    public void setTotalGastado(double totalGastado) { this.totalGastado = totalGastado; }

    @Override
    public String toString() {
        return "Cliente{id=" + id + ", nombre=" + getNombreCompleto() + ", email=" + email + "}";
    }
}