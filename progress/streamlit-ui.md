# Progress: Interfaz Web con Streamlit

**Spec:** [specs/2026-06-29-streamlit-ui.md](../specs/2026-06-29-streamlit-ui.md)
**Estado final:** DONE
**Fecha de cierre:** 2026-06-29

## Resumen

Se ha implementado una Interfaz Web utilizando Streamlit. Esta UI permite a usuarios no técnicos cargar múltiples archivos y ver en tiempo real la conversión a Markdown proporcionada por `MarkItDown`. Además, permite descargar el resultado convertido en formato `.md`. La implementación se ha aislado en el paquete `markitdown-ui`.

## Archivos modificados

| Archivo | Tipo de cambio |
|---|---|
| `packages/markitdown-ui/app.py` | NUEVO |
| `packages/markitdown-ui/pyproject.toml` | NUEVO |
| `packages/markitdown-ui/tests/test_app.py` | NUEVO |
| `AGENTS.md` | MODIFICADO |
| `specs/2026-06-29-streamlit-ui.md` | MODIFICADO |

## Historial de revisiones

| Iteración | Resultado | Fecha | Problemas reportados |
|---|---|---|---|
| 1 | APROBADO | 2026-06-29 | — |

## Notas técnicas

- La interfaz utiliza el método `convert_stream` extrayendo la extensión del archivo subido con `os.path.splitext` para pasársela a MarkItDown, lo cual evita tener que guardar el documento en disco.
- Se ha actualizado la configuración en `pyproject.toml` para que el paquete `markitdown-ui` dependa explícitamente de `markitdown[all]` y `streamlit`.
