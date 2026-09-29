package libreria.util;

import libreria.models.Producto;
import org.junit.jupiter.api.Test;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class ValidadorProductoTest {

    /** Producto válido base: cada test cambia un solo campo para probar su regla. */
    private Producto productoValido() {
        return new Producto(1, "Cuaderno A4", "Cuaderno cuadriculado", 12.5, 10, "Cuadernos", "img.png");
    }

    // ---- Ciclo 1: nombre obligatorio ----

    @Test
    void nombreVacio_devuelveError() {
        Producto p = new Producto(0, "  ", "desc", 10.0, 5, "Libros", "img.png");

        List<String> errores = ValidadorProducto.validar(p);

        assertTrue(errores.contains("El nombre es obligatorio"));
    }

    // ---- Ciclo 2: precio mayor a 0 ----

    @Test
    void precioCero_devuelveError() {
        Producto p = productoValido();
        p.setPrecio(0);

        assertTrue(ValidadorProducto.validar(p).contains("El precio debe ser mayor a 0"));
    }

    @Test
    void precioNegativo_devuelveError() {
        Producto p = productoValido();
        p.setPrecio(-5.0);

        assertTrue(ValidadorProducto.validar(p).contains("El precio debe ser mayor a 0"));
    }

    // ---- Ciclo 3: stock no negativo ----

    @Test
    void stockNegativo_devuelveError() {
        Producto p = productoValido();
        p.setStock(-1);

        assertTrue(ValidadorProducto.validar(p).contains("El stock no puede ser negativo"));
    }

    /**
     * Test de borde: stock 0 es válido. Pasa desde el inicio (aún no hay regla
     * de stock) y queda para proteger contra el error clásico de usar <= 0
     * en vez de < 0.
     */
    @Test
    void stockCero_noDevuelveError() {
        Producto p = productoValido();
        p.setStock(0);

        assertFalse(ValidadorProducto.validar(p).contains("El stock no puede ser negativo"));
    }

    // ---- Ciclo 4: categoría obligatoria ----

    @Test
    void categoriaNula_devuelveError() {
        Producto p = productoValido();
        p.setCategoria(null);

        assertTrue(ValidadorProducto.validar(p).contains("La categoría es obligatoria"));
    }

    @Test
    void categoriaVacia_devuelveError() {
        Producto p = productoValido();
        p.setCategoria("   ");

        assertTrue(ValidadorProducto.validar(p).contains("La categoría es obligatoria"));
    }

    // ---- Ciclo 5: producto válido y acumulación (regresión, pasan de inmediato) ----

    @Test
    void productoValido_noDevuelveErrores() {
        List<String> errores = ValidadorProducto.validar(productoValido());

        assertTrue(errores.isEmpty());
    }

    @Test
    void variosCamposInvalidos_acumulaTodosLosErrores() {
        Producto p = productoValido();
        p.setNombre("");
        p.setPrecio(-1);
        p.setStock(-1);
        p.setCategoria(null);

        assertEquals(4, ValidadorProducto.validar(p).size());
    }
}
