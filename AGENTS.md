# AGENTS.md — MarkItDown

---

## ⚠️ PASO 0 OBLIGATORIO — Ejecutar `init.sh` antes de cualquier acción

> **Todo agente de IA DEBE ejecutar este comando como primer paso, antes de leer código, editar archivos, o ejecutar cualquier otro comando:**

```bash
bash init.sh
```

**Ubicación:** `init.sh` en la raíz del repositorio.

### ¿Qué hace `init.sh`?

| Verificación | Descripción |
|---|---|
| **Estructura del repositorio** | Confirma que todos los archivos y directorios críticos existen |
| **Entorno Python** | Valida Python ≥3.10 y las herramientas necesarias (`hatch`, `pip`) |
| **Linter (pre-commit / black)** | Asegura que el formato del código sea correcto |
| **Tipos (mypy)** | Detecta errores de tipado antes de que se conviertan en bugs |
| **Tests** | Corre la suite completa para confirmar que el sistema no está roto |

### Interpretación del resultado

- **`✔ VERIFICACIÓN EXITOSA`** → El agente puede proceder con su tarea normalmente.
- **`✘ VERIFICACIÓN FALLIDA`** → **El agente debe detenerse inmediatamente.** No editar código, no crear archivos. Reportar al usuario los errores encontrados y esperar instrucciones.

### Opciones disponibles

```bash
bash init.sh                # Verificación completa (recomendado)
bash init.sh --quick        # Solo estructura (sin tests ni tipos)
bash init.sh --no-tests     # Omitir tests (útil en iteración rápida)
bash init.sh --no-types     # Omitir mypy
```

> **Regla inquebrantable:** Si `init.sh` termina con código de salida `1`, el agente NO debe realizar ningún cambio en el código fuente hasta que el usuario resuelva los problemas reportados.

---

## Propósito

Convierte archivos (PDF, DOCX, XLSX, PPTX, HTML, imágenes, audio, EPUB, CSV, ZIP, YouTube, Wikipedia, RSS, etc.) a Markdown para LLMs. Monorepo Python ≥3.10, build con `hatchling`, entornos/tests con `hatch`.

## Layout del monorepo

```
packages/
  markitdown/                  # Librería core (src/markitdown/)
    src/markitdown/
      _markitdown.py           # MarkItDown class, registro de converters
      _base_converter.py       # DocumentConverter, DocumentConverterResult
      _stream_info.py          # StreamInfo (mimetype, extension, url, charset, filename)
      converters/              # Cada archivo es un converter
        __init__.py            # Exports + __all__ de todos los converters
        _pdf_converter.py
        _docx_converter.py
        _pptx_converter.py
        _image_converter.py
        ... (24 converters)
      converter_utils/         # Helpers compartidos
  markitdown-mcp/              # Servidor MCP, entry point `markitdown-mcp`
  markitdown-ocr/              # Plugin OCR, entry point group markitdown.plugin → ocr
  markitdown-sample-plugin/    # Plugin de ejemplo, entry point group markitdown.plugin → sample_plugin
  markitdown-ui/               # Interfaz Web construida con Streamlit
.github/workflows/
  tests.yml                    # hatch test en 3.10/3.11/3.12
  pre-commit.yml               # pre-commit run --all-files
```

## Comandos (literales)

Todos los comandos se ejecutan desde `packages/markitdown/` a menos que se indique otro `workdir`.

| Comando | Cuándo |
|---|---|
| `hatch test` | Antes de commit; CI lo exige en PR |
| `hatch run types:check` (mypy) | Antes de commit, o cuando cambias tipos |
| `pre-commit run --all-files` | Antes de commit (formato black) |
| `pip install -e 'packages/markitdown[all]'` | Instalación editable inicial |
| `cd packages/markitdown && hatch shell` | Entrar al entorno hatch para desarrollo |

CI (`.github/workflows/tests.yml`): corre `hatch test` en Python 3.10, 3.11, 3.12.

## Patrón converters (regla inquebrantable)

Cada converter vive en `converters/_<nombre>_converter.py` y sigue estrictamente:

1. **Clase**: extiende `DocumentConverter` (de `_base_converter.py`).
2. **`accepts(file_stream, stream_info, **kwargs) -> bool`**: decisión rápida basada en `stream_info.mimetype`, `stream_info.extension`, opcionalmente `stream_info.url`.
3. **`convert(file_stream, stream_info, **kwargs) -> DocumentConverterResult`**: devuelve el Markdown convertido. Excepciones: `FileConversionException`, `MissingDependencyException`.
4. **Registro en 3 sitios** (obligatorio):
   - `converters/__init__.py`: importar la clase y agregarla a `__all__`.
   - `_markitdown.py` (top-level): importar la clase.
   - `_markitdown.py` (método `__init__`): `self.register_converter(MiConverter(), priority=...)`.
5. **Prioridades**: `PRIORITY_SPECIFIC_FILE_FORMAT=0.0` (formatos concretos: .docx, .pdf, .pptx) vs `PRIORITY_GENERIC_FILE_FORMAT=10.0` (catch-all genéricos: PlainTextConverter, HtmlConverter, ZipConverter). Menor valor = se prueba primero. Orden estable; entre misma prioridad, el último registrado gana.

## Gotcha crítico

Si en `accepts()` lees del `file_stream` para inspeccionar contenido (ej. `OutlookMsgConverter`), **debes** guardar la posición con `file_stream.tell()` y restaurarla con `file_stream.seek(cur_pos)` antes de retornar. `convert()` se ejecuta inmediatamente después y espera el stream en la posición original.

## Hechos del proyecto

- **Python ≥3.10**. CI prueba 3.10, 3.11, 3.12. No usar sintaxis >3.10.
- **API pública estable**: `MarkItDown.convert()`, `DocumentConverterResult.markdown`. `DocumentConverterResult.text_content` es un alias soft-deprecated — en código nuevo usar `.markdown` o `__str__`.
- **Deps opcionales**: definidos como extras en `[project.optional-dependencies]` (`[pdf]`, `[docx]`, `[pptx]`, etc.). Los converters que los requieren deben importarlos con try/except ImportError → lanzar `MissingDependencyException`. No añadir dependencias core si son opcionales.
- **Plugins**: se descubren automáticamente por `entry_points(group="markitdown.plugin")`. Para habilitar: `MarkItDown(enable_plugins=True)` o CLI `--use-plugins`.

## Seguridad

Seguir las notas del README. No pasar inputs no confiables a `convert()`. Preferir la API más estrecha posible: `convert_local()` > `convert_response()` > `convert_stream()` > `convert()`. MarkItDown accede a recursos con los privilegios del proceso.

## Notas por paquete

### markitdown (core)
Foco principal. Casi todo cambio de converters, API o tests ocurre aquí.

### markitdown-mcp
Depende de `markitdown[all]`. Expone herramientas MCP sobre `convert()`. Entry point: `markitdown-mcp`.

### markitdown-ocr
Plugin que engancha PDF/DOCX/PPTX/XLSX vía `llm_client`/`llm_model` para extraer texto de imágenes con LLM Vision. Sin `llm_client` el plugin se carga pero OCR se omite silenciosamente. Entry point: `markitdown.plugin → ocr`.

### markitdown-sample-plugin
Referencia para crear plugins de terceros. Entry point: `markitdown.plugin → sample_plugin`.

### markitdown-ui
Interfaz Gráfica de Usuario (GUI) rápida usando Streamlit para usuarios no técnicos. Para iniciar: `cd packages/markitdown-ui && streamlit run app.py`.

## Política de commits/branches

- **No commitear/pushear salvo petición explícita del usuario.**
- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
- Branches: `feat/..., fix/..., chore/...`.
- **Antes de iniciar cualquier trabajo:** `bash init.sh` (ver Paso 0 arriba).
- Antes de commit: `pre-commit run --all-files` + `hatch test` + `hatch run types:check`.
- Si `bash init.sh` falla en cualquier momento durante el desarrollo, detener y reportar al usuario.
