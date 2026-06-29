# Arquitectura — MarkItDown

> Documento de referencia para agentes de IA. Describe cómo está construido
> el sistema, dónde vive cada pieza y cómo fluye la ejecución.

---

## Visión general

MarkItDown es un **monorepo Python** que convierte cualquier tipo de archivo
a Markdown para ser consumido por LLMs. El diseño central es un **registro
de converters** con prioridades: dado un stream de bytes, el sistema prueba
cada converter en orden hasta encontrar uno que lo acepte y lo convierte.

```
Usuario / CLI / MCP
        │
        ▼
  MarkItDown.convert()          ← punto de entrada principal
        │
        ▼
  [Detección] magika + mimetype + extensión → StreamInfo
        │
        ▼
  [Registro de converters]
  Itera en orden de prioridad:
    converter.accepts(stream, stream_info) → bool
    Si True → converter.convert(stream, stream_info) → DocumentConverterResult
        │
        ▼
  DocumentConverterResult.markdown    ← string Markdown resultante
```

---

## Layout del monorepo

```
markitdown/
├── init.sh                          # Verificación pre-agente (ejecutar SIEMPRE primero)
├── AGENTS.md                        # Reglas globales para todos los agentes
├── .agents/                         # Definiciones de roles de agentes
│   ├── leader.md                    # Orquestador
│   ├── implementer.md               # Implementador
│   └── reviwer.md                   # Revisor de calidad
├── docs/                            # Documentación técnica (este directorio)
│   ├── architecture.md              # Este archivo
│   ├── conventions.md               # Estándares de código
│   ├── specs.md                     # Guía para escribir specs
│   └── verification.md              # Criterios de calidad y verificación
├── specs/                           # Specs de features (una por archivo)
├── progress/                        # Registro de avance por feature
└── packages/
    ├── markitdown/                  # Paquete CORE (aquí ocurre casi todo)
    │   ├── pyproject.toml           # Deps, extras, scripts, hatch config
    │   ├── src/markitdown/
    │   │   ├── __init__.py          # API pública exportada
    │   │   ├── __about__.py         # Versión del paquete
    │   │   ├── __main__.py          # CLI entry point
    │   │   ├── _markitdown.py       # Clase MarkItDown + registro de converters
    │   │   ├── _base_converter.py   # DocumentConverter + DocumentConverterResult
    │   │   ├── _stream_info.py      # StreamInfo (metadata del stream)
    │   │   ├── _exceptions.py       # FileConversionException, MissingDependencyException
    │   │   ├── _uri_utils.py        # Helpers para URIs y data URIs
    │   │   ├── converters/          # Un archivo por converter
    │   │   │   ├── __init__.py      # Exports + __all__
    │   │   │   ├── _pdf_converter.py
    │   │   │   ├── _docx_converter.py
    │   │   │   ├── _pptx_converter.py
    │   │   │   ├── _xlsx_converter.py
    │   │   │   ├── _xls_converter.py  (alias a xlsx vía xlrd)
    │   │   │   ├── _image_converter.py
    │   │   │   ├── _audio_converter.py
    │   │   │   ├── _html_converter.py
    │   │   │   ├── _plain_text_converter.py
    │   │   │   ├── _csv_converter.py
    │   │   │   ├── _epub_converter.py
    │   │   │   ├── _zip_converter.py
    │   │   │   ├── _ipynb_converter.py
    │   │   │   ├── _rss_converter.py
    │   │   │   ├── _youtube_converter.py
    │   │   │   ├── _wikipedia_converter.py
    │   │   │   ├── _bing_serp_converter.py
    │   │   │   ├── _outlook_msg_converter.py
    │   │   │   ├── _doc_intel_converter.py   (Azure Document Intelligence)
    │   │   │   ├── _cu_converter.py          (Azure Content Understanding)
    │   │   │   └── _markdownify.py           (helper HTML→Markdown)
    │   │   └── converter_utils/             # Helpers compartidos entre converters
    │   └── tests/                           # Suite de tests
    │       ├── _test_vectors.py             # Vectores de prueba compartidos
    │       ├── test_module_misc.py
    │       ├── test_module_vectors.py
    │       ├── test_cli_misc.py
    │       ├── test_cli_vectors.py
    │       ├── test_cu_converter.py
    │       ├── test_pdf_*.py                # Tests especializados de PDF
    │       └── test_files/                  # Archivos de prueba (fixtures)
    ├── markitdown-mcp/              # Servidor MCP
    ├── markitdown-ocr/              # Plugin OCR con LLM Vision
    └── markitdown-sample-plugin/    # Referencia para crear plugins
```

---

## Clases y contratos clave

### `StreamInfo` (`_stream_info.py`)

Objeto inmutable (frozen dataclass) que viaja junto al stream de bytes:

| Campo | Tipo | Descripción |
|---|---|---|
| `mimetype` | `str \| None` | MIME type detectado (ej. `"application/pdf"`) |
| `extension` | `str \| None` | Extensión del archivo (ej. `".pdf"`) |
| `charset` | `str \| None` | Codificación de caracteres |
| `filename` | `str \| None` | Nombre del archivo (de ruta, URL o Content-Disposition) |
| `local_path` | `str \| None` | Ruta local si se leyó de disco |
| `url` | `str \| None` | URL si se leyó de red |

Método útil: `stream_info.copy_and_update(**kwargs)` → nuevo `StreamInfo`.

### `DocumentConverter` (`_base_converter.py`)

Clase abstracta base de todos los converters:

```python
class DocumentConverter:
    def accepts(self, file_stream: BinaryIO, stream_info: StreamInfo, **kwargs) -> bool:
        ...  # Decisión rápida: ¿puedo convertir esto?

    def convert(self, file_stream: BinaryIO, stream_info: StreamInfo, **kwargs) -> DocumentConverterResult:
        ...  # Conversión efectiva → retorna Markdown
```

### `DocumentConverterResult` (`_base_converter.py`)

```python
result.markdown   # str — el Markdown resultante (usar esto)
result.title      # str | None — título del documento
str(result)       # equivalente a result.markdown
# result.text_content → DEPRECATED, no usar en código nuevo
```

### `MarkItDown` (`_markitdown.py`)

```python
md = MarkItDown(enable_plugins=False)

# Métodos de conversión (de más estrecho a más amplio):
md.convert_local(path)             # solo archivos locales
md.convert_response(response)      # desde requests.Response
md.convert_stream(stream, **kwargs)# desde un BinaryIO
md.convert(source, **kwargs)       # acepta cualquier cosa

# Registro de converters:
md.register_converter(converter, priority=0.0)
```

---

## Sistema de prioridades

Los converters se intentan en orden ascendente de prioridad (menor = primero):

| Constante | Valor | Usada para |
|---|---|---|
| `PRIORITY_SPECIFIC_FILE_FORMAT` | `0.0` | Formatos concretos: `.docx`, `.pdf`, `.pptx`, Wikipedia, YouTube |
| `PRIORITY_GENERIC_FILE_FORMAT` | `10.0` | Catch-all genéricos: PlainText, Html, Zip |

Entre converters de misma prioridad, el **último registrado** tiene precedencia.

---

## Sistema de plugins

Los plugins se descubren automáticamente mediante `entry_points`:

```toml
# En pyproject.toml del plugin:
[project.entry-points."markitdown.plugin"]
mi_plugin = "mi_paquete:MiConverter"
```

Se activan con `MarkItDown(enable_plugins=True)` o CLI `--use-plugins`.

Paquetes de plugins del monorepo:
- `markitdown-ocr`: OCR mediante LLM Vision para PDF/DOCX/PPTX/XLSX
- `markitdown-sample-plugin`: Referencia / punto de partida para plugins externos

---

## Flujo de detección de formato

Cuando se llama a `convert()`, el sistema determina el `StreamInfo` así:

1. **Extensión** del nombre de archivo (si disponible)
2. **`magika`** — detección de formato por contenido binario (ML-based)
3. **`python-magic`** / `mimetypes` — fallback
4. **URL** — para converters especializados (Wikipedia, YouTube, Bing)

El `StreamInfo` resultante se pasa a cada `accepts()` en orden de prioridad.

---

## CI/CD

| Workflow | Archivo | Qué hace |
|---|---|---|
| Tests | `.github/workflows/tests.yml` | `hatch test` en Python 3.10, 3.11, 3.12 |
| Pre-commit | `.github/workflows/pre-commit.yml` | `pre-commit run --all-files` (formato black) |

Los PRs **deben pasar ambos workflows** para ser mergeados.
