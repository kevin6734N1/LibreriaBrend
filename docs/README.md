# Documentación — LibreriaBrend

Índice general de la documentación del repositorio. El punto de partida del proyecto
(puesta en marcha, stack, demo local, CI) es el [README principal](../README.md).

## Mapa de carpetas

| Carpeta | Contenido |
|---|---|
| [producto/](producto/) | Análisis y diseño del sistema: diagramas de casos de uso (Sprint 1 y 2) y reporte del panel administrativo con carga de imágenes. |
| [QA/](QA/) | Aseguramiento de calidad: sprints de pruebas (RF02, RF03, Sprint 4), caso combinado de caja negra + caja blanca (laboratorio 14), seguridad y saneamiento del repositorio, informe de validación, evidencias históricas y salidas crudas de ejecuciones. Su índice propio está en [QA/README.md](QA/README.md). |
| [auditoria/](auditoria/) | Auditoría de Fase 2: informe, cierre con limitaciones y evidencias (base de datos, logs, requests, responses). |
| [historial/](historial/) | Registro de cambios del proyecto y reporte de aplicación de cambios externos. |
| [academico/](academico/) | Entregables académicos del curso: laboratorio TDD (H0007 Registrar Producto) y plantilla de pruebas unitarias. |

## Documentos destacados

- [REGISTRO_CAMBIOS.md](historial/REGISTRO_CAMBIOS.md) — historia de cambios del proyecto, entrada por entrada.
- [SEGURIDAD_REPOSITORIO.md](QA/SEGURIDAD_REPOSITORIO.md) — saneamiento de datos del backup, verificación ejecutada y riesgo residual del historial público.
- [Informe del caso combinado (PDF)](QA/caso-combinado/Informe_Caso_Combinado.pdf) — laboratorio 14: prueba combinada caja negra + caja blanca con orquestación de agentes (14/14 ramas JaCoCo, 14 casos conformes).
- [Diagramas de casos de uso](producto/Diagramas_CasosDeUso_LibreriaBrenda.md) — casos de uso de los Sprint 1 y 2.

## Datos de base de datos

Los scripts SQL viven en [`database/`](../database/): la demo con datos sintéticos
(`demo/libreria_brenda_demo.sql`), el esquema y fixtures de pruebas (`schema_test.sql`,
`fixtures_test.sql`) y el respaldo saneado del historial del proyecto
(`backup/libreria_brenda_backup.sql`).
