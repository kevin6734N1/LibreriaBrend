package libreria.util;

import libreria.models.Producto;
import java.util.ArrayList;
import java.util.List;

/**
 * ValidadorProducto - Libreria Brenda
 *
 * Reglas de validación del módulo de Catálogo de Productos (historia H0007,
 * tarea 5 del Sprint 2). Construido test-first (TDD) en el laboratorio de
 * calidad: cada regla entró con un ciclo Rojo -> Verde y esta versión final
 * es el refactor posterior al verde (helper vacio() + constantes ERR_*).
 *
 * Los errores se acumulan: una sola pasada reporta todas las reglas
 * incumplidas, no solo la primera.
 */
public class ValidadorProducto {

    static final String ERR_NOMBRE    = "El nombre es obligatorio";
    static final String ERR_PRECIO    = "El precio debe ser mayor a 0";
    static final String ERR_STOCK     = "El stock no puede ser negativo";
    static final String ERR_CATEGORIA = "La categoría es obligatoria";

    public static List<String> validar(Producto p) {
        List<String> errores = new ArrayList<>();

        if (vacio(p.getNombre()))    errores.add(ERR_NOMBRE);
        if (p.getPrecio() <= 0)      errores.add(ERR_PRECIO);
        if (p.getStock() < 0)        errores.add(ERR_STOCK);
        if (vacio(p.getCategoria())) errores.add(ERR_CATEGORIA);

        return errores;
    }

    private static boolean vacio(String s) {
        return s == null || s.trim().isEmpty();
    }
}
