package libreria.models;

/**
 * Modelo PreferenciaAccesibilidad - Libreria Brenda
 * Coincide con la tabla "preferencias_accesibilidad": una fila por cliente.
 */
public class PreferenciaAccesibilidad {

    private int     clienteId;
    private String  tipoDaltonismo;    // "ninguno" | "protanopia" | "deuteranopia" | "tritanopia"
    private boolean lecturaVozActiva;

    public int     getClienteId()           { return clienteId; }
    public String  getTipoDaltonismo()      { return tipoDaltonismo; }
    public boolean isLecturaVozActiva()     { return lecturaVozActiva; }

    public void setClienteId(int clienteId)                  { this.clienteId = clienteId; }
    public void setTipoDaltonismo(String tipoDaltonismo)     { this.tipoDaltonismo = tipoDaltonismo; }
    public void setLecturaVozActiva(boolean lecturaVozActiva){ this.lecturaVozActiva = lecturaVozActiva; }
}
