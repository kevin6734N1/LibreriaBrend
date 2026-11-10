package libreria.models;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * QA-S4-01: el identificador de pedido debe ser unico incluso cuando varios
 * hilos crean pedidos en el mismo instante.
 *
 * Antes de la correccion, el identificador se construia con
 * "PED-" + System.currentTimeMillis(), de modo que dos pedidos creados en el
 * mismo milisegundo obtenian el mismo id y el INSERT del pedido era rechazado
 * por la clave primaria (Duplicate entry 'PED-...' for key 'PRIMARY').
 */
class PedidoIdentificadorUnicoTest {

    @Test
    @DisplayName("QA-S4-01: identificadores de pedido unicos bajo creacion concurrente")
    void identificadoresUnicosBajoConcurrencia() throws Exception {
        final int hilos = 64;
        final int porHilo = 25;
        final int total = hilos * porHilo;

        ExecutorService pool = Executors.newFixedThreadPool(hilos);
        CountDownLatch listo = new CountDownLatch(hilos);
        CountDownLatch arranque = new CountDownLatch(1);
        Set<String> ids = Collections.synchronizedSet(new HashSet<>());

        for (int h = 0; h < hilos; h++) {
            pool.submit(() -> {
                listo.countDown();
                try {
                    arranque.await();
                    for (int i = 0; i < porHilo; i++) {
                        ids.add(new Pedido().getId());
                    }
                } catch (InterruptedException interrumpido) {
                    Thread.currentThread().interrupt();
                }
            });
        }

        assertTrue(listo.await(10, TimeUnit.SECONDS), "Los hilos no llegaron a arrancar");
        arranque.countDown();
        pool.shutdown();
        assertTrue(pool.awaitTermination(30, TimeUnit.SECONDS), "El pool no termino a tiempo");

        assertEquals(total, ids.size(),
                "Se generaron identificadores repetidos: colision de clave primaria en pedidos");
    }

    @Test
    @DisplayName("QA-S4-01: el identificador conserva el formato esperado")
    void formatoDelIdentificador() {
        Pedido pedido = new Pedido();
        String id = pedido.getId();

        assertTrue(id.startsWith("PED-"), "El identificador debe conservar el prefijo PED-: " + id);
        assertTrue(id.length() <= 30,
                "El identificador debe caber en la columna varchar(30): " + id);
        assertTrue(id.substring(4).matches("\\d+"),
                "El identificador debe llevar una secuencia numerica: " + id);
    }
}
