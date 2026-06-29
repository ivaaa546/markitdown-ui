# Convenciones — MarkItDown

> Estándares de código que **todo agente debe seguir** al modificar este repositorio.
> En caso de conflicto entre una spec y este documento, **las convenciones ganan**.

---

## Python

### Versión objetivo

- **Python ≥ 3.10**. CI prueba 3.10, 3.11, 3.12, 3.13.
- **No uses sintaxis exclusiva de Python >3.10** (ej. `match/case` de 3.10 está bien; `Self` de 3.11 requiere `from typing import Self` con guarda).
- Usa `from __future__ import annotations` si necesitas referencias adelantadas de tipos.

### Type hints

- **Todos** los parámetros de función y valores de retorno deben tener type hints.
- Usa `Optional[X]` o `X | None` (3.10+).
- Usa `Union[A, B]` o `A | B` (3.10+).
- Importa desde `typing`: `Any`, `BinaryIO`, `Optional`, `Union`, `List`, `Dict`.

```python
# ✔ Correcto
def convert(self, file_stream: BinaryIO, stream_info: StreamInfo, **kwargs: Any) -> DocumentConverterResult:

# ✘ Incorrecto (sin tipos)
def convert(self, file_stream, stream_info, **kwargs):
```

### Formato (black)

- El formateador es **black** con configuración por defecto.
- Se aplica automáticamente con `pre-commit run --all-files`.
- **No formatees manualmente**; deja que black lo haga.
- Longitud de línea: 88 caracteres (default de black).

---

## API pública

### `DocumentConverterResult`

| Atributo | Estado | Uso |
|---|---|---|
| `.markdown` | ✔ Activo | Usar en todo código nuevo |
| `.__str__()` | ✔ Activo | Equivalente a `.markdown` |
| `.text_content` | ⚠ Soft-deprecated | **No usar** en código nuevo |

```python
# ✔ Correcto
result = converter.convert(stream, stream_info)
text = result.markdown

# ✘ Incorrecto (deprecated)
text = result.text_content
```

### Métodos de conversión (de más estrecho a más amplio)

Preferir siempre la API más estrecha posible:

```python
md.convert_local(path)          # 1er — solo disco local
md.convert_response(response)   # 2do — desde requests.Response
md.convert_stream(stream)       # 3er — desde BinaryIO
md.convert(source)              # 4to — acepta cualquier cosa (menos seguro)
```

---

## Patrón de converters

### Estructura obligatoria

```python
# converters/_mi_converter.py

from typing import Any, BinaryIO
from .._base_converter import DocumentConverter, DocumentConverterResult
from .._stream_info import StreamInfo
from .._exceptions import MissingDependencyException, FileConversionException

class MiConverter(DocumentConverter):

    def accepts(
        self,
        file_stream: BinaryIO,
        stream_info: StreamInfo,
        **kwargs: Any,
    ) -> bool:
        # Decisión basada principalmente en stream_info
        mimetype = stream_info.mimetype or ""
        extension = stream_info.extension or ""
        return mimetype == "application/mi-formato" or extension == ".mif"

    def convert(
        self,
        file_stream: BinaryIO,
        stream_info: StreamInfo,
        **kwargs: Any,
    ) -> DocumentConverterResult:
        # Conversión efectiva
        ...
        return DocumentConverterResult(markdown=resultado, title=titulo)
```

### Registro en 3 sitios (obligatorio)

```python
# 1. converters/__init__.py
from ._mi_converter import MiConverter
__all__ = [..., "MiConverter"]

# 2. _markitdown.py — import al top del archivo
from .converters import (..., MiConverter)

# 3. _markitdown.py — dentro de MarkItDown.__init__()
self.register_converter(MiConverter(), priority=PRIORITY_SPECIFIC_FILE_FORMAT)
```

### Prioridades

```python
PRIORITY_SPECIFIC_FILE_FORMAT = 0.0   # Formatos concretos: .pdf, .docx, Wikipedia
PRIORITY_GENERIC_FILE_FORMAT  = 10.0  # Catch-all: PlainText, Html, Zip
```

Menor valor → se intenta **primero**. Entre misma prioridad, el último registrado gana.

### Dependencias opcionales

```python
# ✔ Correcto — dependencia opcional con fallback informativo
try:
    import mi_libreria
except ImportError:
    raise MissingDependencyException(
        "MiConverter",
        [mi-paquete-pip],
        "pip install 'markitdown[mi-extra]'",
    )
```

```toml
# En pyproject.toml — añadir el extra correspondiente
[project.optional-dependencies]
mi-extra = ["mi-paquete-pip"]
```

### Lectura del stream en `accepts()` (gotcha crítico)

Si necesitas leer bytes del stream para decidir si aceptas:

```python
def accepts(self, file_stream: BinaryIO, stream_info: StreamInfo, **kwargs: Any) -> bool:
    cur_pos = file_stream.tell()    # 1. Guardar posición
    header = file_stream.read(8)    # 2. Leer lo necesario
    file_stream.seek(cur_pos)       # 3. Restaurar SIEMPRE antes de retornar
    return header.startswith(b"MI_MAGIC")
```

---

## Tests

### Ubicación

```
packages/markitdown/tests/
├── test_<área>.py          # Un archivo por área funcional
└── test_files/             # Fixtures: archivos de prueba reales
```

### Convenciones

- Un test por criterio de aceptación (mínimo).
- Nombres descriptivos: `test_<converter>_<escenario>_<resultado_esperado>`.
- Tests deben fallar si se borra el código que testean ("mutation-resistant").
- Usa fixtures de `test_files/` para formatos binarios; no generes binarios inline.
- No uses `assert True` ni tests que siempre pasen.

```python
# ✔ Correcto
def test_pdf_converter_extracts_heading():
    result = markitdown.convert_local("tests/test_files/sample.pdf")
    assert "# Título Esperado" in result.markdown

# ✘ Incorrecto (test trivial)
def test_pdf_converter_exists():
    assert PdfConverter() is not None
```

### Comandos de verificación

```bash
cd packages/markitdown

hatch test                        # Suite completa
hatch test -- -k "test_pdf"       # Filtrar por nombre
hatch run types:check             # mypy
pre-commit run --all-files        # Formato
```

---

## Nombres de archivos y commits

### Archivos de converters

```
converters/_<nombre>_converter.py
```

El `<nombre>` en snake_case, minúsculas, singular: `_pdf_converter.py`, `_epub_converter.py`.

### Commits (Conventional Commits)

| Prefijo | Cuándo |
|---|---|
| `feat:` | Nueva funcionalidad |
| `fix:` | Corrección de bug |
| `docs:` | Solo cambios de documentación |
| `chore:` | Mantenimiento, deps, CI |
| `refactor:` | Refactoring sin cambio de comportamiento |
| `test:` | Solo tests |

### Branches

```
feat/<descripción-corta>
fix/<descripción-corta>
chore/<descripción-corta>
```

---

## Seguridad

- No pasar inputs no sanitizados a `convert()` en entornos no confiables.
- Usar la API más estrecha posible (ver sección API pública arriba).
- MarkItDown accede a recursos con los **privilegios del proceso actual**.
- Ver `SECURITY.md` para el proceso de reporte de vulnerabilidades.

---

## Lo que NO hacer

| ❌ No hacer | ✔ En su lugar |
|---|---|
| Usar `.text_content` | Usar `.markdown` |
| Añadir deps al core sin ser opcionales | Añadir a `[project.optional-dependencies]` |
| Leer stream en `accepts()` sin restaurar posición | `tell()` + `seek()` |
| Registrar converter en solo 1 o 2 sitios | Registrar en los 3 obligatoriamente |
| Commitear sin pasar `hatch test` | Siempre verificar antes |
| Usar sintaxis Python >3.10 | Verificar compatibilidad 3.10–3.13 |
| Tests que siempre pasan | Tests mutation-resistant |
