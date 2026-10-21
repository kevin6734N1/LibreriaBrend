# Exposición de datos en el repositorio público — acción requerida

**Fecha del hallazgo:** 2026-10-21
**Estado:** abierto. No se publicó ningún cambio nuevo mientras esté abierto.
**Repositorio:** `github.com/kevin6734N1/LibreriaBrend` (verificado público el 2026-10-21).

Este documento describe el riesgo **sin reproducir** nombres, correos, DNI,
teléfonos, direcciones, IDs de pedido ni hashes.

## 1. Qué se encontró

### Archivo de volcado completo

`libreria_brenda_backup.sql` está versionado y contiene:

| Tabla | Registros | Datos sensibles |
|---|---|---|
| `clientes` | 16 | nombres y apellidos, DNI, correo, teléfono, dirección, `password_hash` BCrypt |
| `pedidos` | 16 | IDs, fechas, montos, direcciones de entrega, método de pago |
| `pedido_items` | 31 | detalle de compra |
| `comprobantes` | 8 | series y montos |
| `administradores` | 1 | correo, código de empleado, `password_hash` BCrypt |

Señales que impiden tratarlo como ficticio:

- Los 16 DNI son distintos y tienen 8 dígitos; los teléfonos son distintos.
- Hay correos en dominios de uso personal, no en `test.local` ni `example.com`.
- No aparece ninguna marca de dato de prueba (`test.local`, `ficticio`, `dummy`).
- Los pedidos cubren varios meses de 2026 y los montos/direcciones son variados.
- Los hashes tienen formato BCrypt real (`$2a$10$...`), no texto plano.

No es posible demostrar que los datos sean inventados. Por tanto, se tratan
como **PII real hasta que el propietario confirme lo contrario**.

### Evidencias de auditoría con datos de pedidos

Además del volcado, estos archivos versionados contienen direcciones de
entrega e identificadores de pedidos (11 apariciones; algunos IDs se repiten
entre archivos):

- `docs/auditoria/evidencias/db/00_baseline_antes.txt`
- `docs/auditoria/evidencias/db/01_baseline_despues.txt`
- `docs/auditoria/evidencias/responses/B03_seguridad_lectura.txt`
- `docs/auditoria/evidencias/requests/B03_seguridad_lectura.sh` (1 ID)
- `docs/auditoria/FASE2_INFORME.md` (fragmento con un pedido)

No se detectaron correos ni DNI en esos cinco archivos, pero una dirección de
entrega junto con un ID de pedido sigue siendo información personal.

### Historial

- El volcado se incorporó en `7d93b00` (2026-10-17) y se actualizó en
  `2468111` (2026-10-17).
- Las evidencias de auditoría se incorporaron en `e72064a` (2026-09-28).
- `.gitignore` tiene reglas para algunos volcados (`*.dump`, `dump*.sql`),
  pero no cubre `*_backup.sql`; además, las reglas no aplican a archivos que
  ya estaban trackeados.

## 2. Por qué es grave

1. El repositorio es público: cualquier persona o crawler pudo descargar los
   datos, y pueden existir forks, clones o cachés aunque luego se borren.
2. Los hashes BCrypt de costo 10 permiten ataques de diccionario offline.
   Un hash no es equivalente a una contraseña, pero tampoco es inocuo.
3. La combinación nombre + DNI + teléfono + dirección + correo es PII de alto
   valor para fraude y phishing.
4. Si los datos son de clientes reales, aplica la Ley 29733 (Perú) de
   protección de datos personales y podría requerir notificación a los
   titulares.

## 3. Acciones necesarias (requieren autorización del propietario)

Ordenadas de mitigación más rápida a más profunda. **Ninguna se ejecutó.**

1. **Poner el repositorio en privado de inmediato** mientras se decide. Es la
   mitigación más rápida y no reescribe nada. Solo el propietario puede
   hacerlo desde *Settings → General → Danger Zone → Change visibility*.
2. **Retirar los archivos del árbol actual** (no del historial):

   ```bash
   git rm --cached libreria_brenda_backup.sql \
     docs/auditoria/evidencias/db/00_baseline_antes.txt \
     docs/auditoria/evidencias/db/01_baseline_despues.txt \
     docs/auditoria/evidencias/responses/B03_seguridad_lectura.txt \
     docs/auditoria/evidencias/requests/B03_seguridad_lectura.sh
   ```

   Esto reduce la exposición futura, pero los blobs siguen en el historial.
3. **Purgar el historial** con `git filter-repo` (o BFG), coordinando con
   cualquier colaborador, y forzar el push. Es una operación destructiva:
   cambia los hashes de todos los commits y requiere que los demás vuelvan a
   clonar. No debe hacerse sin respaldo y autorización expresa.
4. **Rotar credenciales** si alguna contraseña del volcado se usó en otro
   servicio. Forzar el cambio de las cuentas afectadas.
5. **Evaluar notificación** a los titulares si se confirma que los datos son
   reales, y revisar logs de acceso, forks y clones.
6. **Reemplazar las evidencias** de auditoría por versiones redactadas o
   sintéticas si se quieren conservar en el portafolio.

## 4. Qué se hizo en esta sesión

- Se verificó `git status` y el historial antes de tocar código.
- No se borró, reescribió ni publicó nada del historial.
- No se hizo push ni se abrió un Pull Request.
- Las pruebas nuevas usan exclusivamente `libreria_brenda_test` y datos
  ficticios creados y eliminados por ejecución.
- Los archivos con PII **siguen en el repositorio** y en `main`; este documento
  no los modifica.

## 5. Cómo verificar el alcance sin exponer los datos

```bash
git ls-files libreria_brenda_backup.sql
git log --follow --oneline -- libreria_brenda_backup.sql
git grep -lE "PED-[0-9]{6,}" -- docs ':!libreria_brenda_backup.sql'
git grep -lEi "jiron|avenida|calle|urbanizacion" -- docs
```

Los comandos listan archivos, no valores. No pegues su salida con datos en
issues, PRs o capturas.

## 6. Decisión pendiente

Antes de publicar la rama `qa/rf02-login` o abrir el PR, el propietario debe
elegir entre:

- **A.** Poner el repositorio en privado, retirar los archivos y purgar el
  historial antes de publicar.
- **B.** Retirar los archivos del árbol actual y publicar el PR, dejando el
  historial pendiente y documentado.
- **C.** No publicar nada todavía y resolver la exposición primero.

Recomendación: **A**, porque el repositorio ya fue público y la purga del
historial es la única forma de eliminar los blobs de la URL pública.
