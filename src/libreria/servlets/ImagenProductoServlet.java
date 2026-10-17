package libreria.servlets;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

/**
 * ImagenProductoServlet - Libreria Brenda
 *
 * POST /ImagenProductoServlet  (multipart/form-data, campo "archivo")
 *   -> guarda la imagen dentro del proyecto y devuelve su ruta web:
 *      {"ok":true,"imagen":"images/productos/mi-foto-1a2b3c4d.png","bytes":12345}
 *
 * Sustituye el viejo flujo de "escribe a mano la ruta de la imagen": el
 * formulario de productos arrastra o elige un archivo y este servlet lo deja
 * en WebContent/images/productos, que es la misma carpeta que ya usaba el
 * catalogo (las rutas de la BD siguen siendo relativas al contexto).
 *
 * Seguridad / validaciones (en el servidor, no solo en el navegador):
 *  - Solo ADMIN con sesion (AuthFilter tambien protege esta ruta).
 *  - Extension y Content-Type tienen que estar en la lista blanca.
 *  - Se comprueban los bytes de cabecera (magic numbers) para que un .txt
 *    renombrado a .png no se guarde como imagen.
 *  - Tamano maximo 3 MB, nombre de archivo saneado + sufijo aleatorio.
 *  - SVG queda fuera a proposito: puede llevar <script> y se sirve desde
 *    el mismo origen que la tienda.
 *
 * La carpeta destino se puede cambiar con la propiedad/variable UPLOAD_DIR
 * (util si el WAR se despliega sin explotar o en un servidor de solo lectura).
 */
@WebServlet("/ImagenProductoServlet")
@MultipartConfig(fileSizeThreshold = 0, maxFileSize = ImagenProductoServlet.MAX_BYTES,
                 maxRequestSize = ImagenProductoServlet.MAX_BYTES + 1024 * 1024)
public class ImagenProductoServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    static final long MAX_BYTES = 3L * 1024 * 1024;   // 3 MB
    private static final String CARPETA = "images/productos";

    /** Content-Type aceptado -> extension con la que se guarda. */
    private static final Map<String, String> EXT_POR_TIPO = Map.of(
            "image/jpeg", "jpg",
            "image/png",  "png",
            "image/gif",  "gif",
            "image/webp", "webp");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();

        // Defensa en profundidad: el AuthFilter ya exige admin, pero este
        // servlet escribe archivos en disco y no debe depender de una sola capa.
        HttpSession sesion = request.getSession(false);
        if (sesion == null || !"admin".equals(sesion.getAttribute("rol"))) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"ok\":false,\"error\":\"No autorizado. Inicia sesion como administrador.\"}");
            return;
        }

        Part archivo;
        try {
            archivo = request.getPart("archivo");
        } catch (IllegalStateException exceso) {
            response.setStatus(413);
            out.print("{\"ok\":false,\"error\":\"La imagen supera el limite de 3 MB.\"}");
            return;
        } catch (ServletException noMultipart) {
            response.setStatus(400);
            out.print("{\"ok\":false,\"error\":\"El formulario no incluye una imagen valida.\"}");
            return;
        }

        if (archivo == null || archivo.getSize() == 0) {
            response.setStatus(400);
            out.print("{\"ok\":false,\"error\":\"Selecciona una imagen antes de guardar.\"}");
            return;
        }
        if (archivo.getSize() > MAX_BYTES) {
            response.setStatus(413);
            out.print("{\"ok\":false,\"error\":\"La imagen supera el limite de 3 MB.\"}");
            return;
        }

        String tipo = archivo.getContentType() == null ? "" : archivo.getContentType();
        int puntoYComa = tipo.indexOf(';');
        if (puntoYComa >= 0) tipo = tipo.substring(0, puntoYComa);
        tipo = tipo.trim().toLowerCase(Locale.ROOT);

        String extension = EXT_POR_TIPO.get(tipo);
        if (extension == null) {
            response.setStatus(400);
            out.print("{\"ok\":false,\"error\":\"Formato no permitido. Usa JPG, PNG, GIF o WEBP.\"}");
            return;
        }

        byte[] cabecera;
        try (InputStream entrada = archivo.getInputStream()) {
            cabecera = entrada.readNBytes(12);
        }
        if (!firmaValida(cabecera, extension)) {
            response.setStatus(400);
            out.print("{\"ok\":false,\"error\":\"El archivo no es una imagen valida del formato indicado.\"}");
            return;
        }

        Path destino;
        try {
            destino = carpetaDestino();
            Files.createDirectories(destino);
        } catch (IOException | IllegalStateException e) {
            e.printStackTrace();
            response.setStatus(500);
            out.print("{\"ok\":false,\"error\":\"No se pudo preparar la carpeta de imagenes en el servidor.\"}");
            return;
        }

        String nombreArchivo = nombreSeguro(archivo.getSubmittedFileName(), extension);
        Path archivoFinal = destino.resolve(nombreArchivo);

        try (InputStream entrada = archivo.getInputStream()) {
            Files.copy(entrada, archivoFinal, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            e.printStackTrace();
            response.setStatus(500);
            out.print("{\"ok\":false,\"error\":\"No se pudo guardar la imagen en el servidor.\"}");
            return;
        }

        out.print("{\"ok\":true,\"imagen\":\"" + esc(CARPETA + "/" + nombreArchivo)
                + "\",\"nombre\":\"" + esc(nombreArchivo)
                + "\",\"bytes\":" + Files.size(archivoFinal) + "}");
    }

    /** Carpeta destino: UPLOAD_DIR si esta definida; si no, la del proyecto desplegado. */
    private Path carpetaDestino() {
        String configurada = System.getProperty("UPLOAD_DIR");
        if (configurada == null || configurada.isBlank()) configurada = System.getenv("UPLOAD_DIR");

        if (configurada != null && !configurada.isBlank()) {
            Path base = Paths.get(configurada);
            // Si UPLOAD_DIR ya apunta a la carpeta de productos, se respeta tal cual.
            return base.getFileName() != null && CARPETA.endsWith(base.getFileName().toString())
                    ? base : base.resolve("productos");
        }

        String real = getServletContext().getRealPath("/" + CARPETA);
        if (real == null) {
            throw new IllegalStateException(
                    "El contexto no esta explotado en disco. Define UPLOAD_DIR para guardar imagenes.");
        }
        return Paths.get(real);
    }

    /** Comprueba la firma real del archivo (no confia en la extension ni en el Content-Type). */
    private boolean firmaValida(byte[] b, String extension) {
        if (b == null) return false;
        switch (extension) {
            case "jpg":
                return b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF;
            case "png":
                return b.length >= 8 && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G'
                        && (b[4] & 0xFF) == 0x0D && (b[5] & 0xFF) == 0x0A && (b[6] & 0xFF) == 0x1A && (b[7] & 0xFF) == 0x0A;
            case "gif":
                return b.length >= 6 && b[0] == 'G' && b[1] == 'I' && b[2] == 'F' && b[3] == '8'
                        && (b[4] == '7' || b[4] == '9') && b[5] == 'a';
            case "webp":
                return b.length >= 12
                        && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                        && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P';
            default:
                return false;
        }
    }

    /**
     * Nombre de archivo apto para URL: minusculas, sin acentos ni espacios,
     * con sufijo aleatorio para no pisar imagenes existentes ni permitir
     * rutas del estilo "../../web.xml".
     */
    private String nombreSeguro(String original, String extension) {
        String base = original == null ? "" : original;
        int barra = Math.max(base.lastIndexOf('/'), base.lastIndexOf('\\'));
        if (barra >= 0) base = base.substring(barra + 1);
        int punto = base.lastIndexOf('.');
        if (punto > 0) base = base.substring(0, punto);

        base = java.text.Normalizer.normalize(base, java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-+|-+$", "");

        if (base.isEmpty()) base = "producto";
        if (base.length() > 60) base = base.substring(0, 60).replaceAll("-+$", "");
        if (base.isEmpty()) base = "producto";

        return base + "-" + UUID.randomUUID().toString().substring(0, 8) + "." + extension;
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
