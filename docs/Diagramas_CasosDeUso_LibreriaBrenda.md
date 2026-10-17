# Diagramas de casos de uso – Librería Brenda (Sprint 1 y Sprint 2)

> Mermaid no tiene un tipo "use case" nativo, así que se dibuja con `flowchart`:
> actores = círculos, casos de uso = óvalos, frontera del sistema = recuadro.
> En VS Code: instala la extensión **Markdown Preview Mermaid Support** (o "Mermaid Chart"),
> abre este archivo y presiona `Ctrl+Shift+V`. Para exportar a imagen: https://mermaid.live
> (pegas el bloque de código) → Actions → PNG/SVG.

## 1. Sprint 1 – Login y seguridad (CU-LOG-001 a CU-LOG-004)

```mermaid
flowchart LR
    CLI(("Cliente"))
    ADM(("Administrador"))

    subgraph SIS["Sistema Web – Librería Brenda"]
        direction TB
        CU1(["CU-LOG-001<br/>Autenticación (Login)"])
        CU2(["CU-LOG-002<br/>Gestión de sesión<br/>y estado de cuenta"])
        CU3(["CU-LOG-003<br/>Registro de clientes"])
        CU4(["CU-LOG-004<br/>Validación de perfil y<br/>control de acceso por rol"])

        V1(["Validar formato de email<br/>y contraseña mínima 8"])
        V2(["Verificar contraseña<br/>con BCrypt"])
        V3(["Verificar cuenta activa"])
        V4(["Bloquear 2 min tras<br/>5 intentos fallidos"])
        V5(["Cerrar sesión<br/>(invalidar sesión)"])
        V6(["Acceder al panel admin"])
    end

    CLI --- CU3
    CLI --- CU1
    CLI --- CU2
    ADM --- CU1
    ADM --- CU2
    ADM --- CU4

    CU3 -. "«include»" .-> V1
    CU1 -. "«include»" .-> V2
    CU1 -. "«include»" .-> V3
    V4 -. "«extend»" .-> CU1
    CU2 -. "«include»" .-> V5
    CU4 -. "«include»" .-> V6
```

## 2. Sprint 2 – Catálogo de Productos (H0007 a H0013)

```mermaid
flowchart LR
    VIS(("Visitante /<br/>Cliente"))
    ADM(("Administrador"))

    subgraph SIS["Sistema Web – Librería Brenda"]
        direction TB
        P2(["H0008 Listar productos<br/>(catálogo público)"])
        P7(["H0013 Buscar y filtrar<br/>por categoría"])
        P1(["H0007 Registrar producto"])
        P3(["H0009 Listar productos<br/>(panel administrador)"])
        P4(["H0010 Editar producto"])
        P5(["H0011 Inactivar y<br/>activar producto"])
        P6(["H0012 Eliminar producto"])

        VAL(["Validar datos del producto<br/>(nombre, precio mayor a 0,<br/>stock no negativo, categoría)"])
        AUT(["Verificar sesión de admin<br/>(AuthFilter)"])
    end

    VIS --- P2
    VIS --- P7

    ADM --- P1
    ADM --- P3
    ADM --- P4
    ADM --- P5
    ADM --- P6

    P7 -. "«extend»" .-> P2
    P1 -. "«include»" .-> VAL
    P4 -. "«include»" .-> VAL
    P1 -. "«include»" .-> AUT
    P3 -. "«include»" .-> AUT
    P4 -. "«include»" .-> AUT
    P5 -. "«include»" .-> AUT
    P6 -. "«include»" .-> AUT
```

## Notas para verificar antes de entregar

- CU-LOG-001 a 004 y H0007 a H0013 salen de tu bitácora y del Informe del Sprint 2.
- Las relaciones «include» y «extend» son una interpretación del diseño (por ejemplo, el bloqueo tras 5 intentos como extensión del login). Ajusta si en su análisis lo modelaron distinto.
- El panel de administrador también tiene buscador y filtros (dentro de H0009), por eso no hay una historia aparte para el admin.
