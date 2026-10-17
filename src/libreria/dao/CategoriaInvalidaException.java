package libreria.dao;

/**
 * Se lanza cuando se intenta crear o editar un producto con una categoria
 * que no existe. Antes ProductoDAO.obtenerCategoriaId() devolvia 1 como
 * "fallback", lo que asignaba silenciosamente la primera categoria.
 */
public class CategoriaInvalidaException extends RuntimeException {

    private final String categoria;

    public CategoriaInvalidaException(String categoria) {
        super("La categoría \"" + categoria + "\" no existe.");
        this.categoria = categoria;
    }

    public String getCategoria() {
        return categoria;
    }
}
