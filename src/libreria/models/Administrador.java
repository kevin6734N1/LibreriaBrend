package libreria.models;

import java.util.Date;

/**
 * Modelo Administrador - Libreria Brenda
 * Coincide con la tabla "administradores". Antes esta tabla existia en la
 * BD pero el login de admin usaba credenciales fijas en el codigo; ahora
 * LoginServlet valida contra esta tabla de verdad (ver AdministradorDAO).
 */
public class Administrador {

    private int    id;
    private String nombre;
    private String email;
    private String codigoEmpleado;
    private Date   fechaRegistro;

    // ---- Getters ----
    public int     getId()             { return id; }
    public String  getNombre()         { return nombre; }
    public String  getEmail()          { return email; }
    public String  getCodigoEmpleado() { return codigoEmpleado; }
    public Date    getFechaRegistro()  { return fechaRegistro; }

    // ---- Setters ----
    public void setId(int id)                           { this.id = id; }
    public void setNombre(String nombre)                 { this.nombre = nombre; }
    public void setEmail(String email)                   { this.email = email; }
    public void setCodigoEmpleado(String codigoEmpleado) { this.codigoEmpleado = codigoEmpleado; }
    public void setFechaRegistro(Date fechaRegistro)     { this.fechaRegistro = fechaRegistro; }

    @Override
    public String toString() {
        return "Administrador{id=" + id + ", nombre=" + nombre + ", email=" + email + "}";
    }
}
