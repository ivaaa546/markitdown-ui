# Spec: Ejemplo — Plantilla de referencia

**Estado:** CANCELLED
**Fecha:** 2026-06-29
**Autor:** leader
**Prioridad:** LOW

> ⚠️ Este archivo es una **plantilla de referencia**, no una spec real.
> Cópialo y edítalo para crear nuevas specs. No implementar.

---

## Contexto

Describe aquí el problema que esta feature resuelve. Por ejemplo:

> MarkItDown actualmente no soporta archivos `.xyz`. Los usuarios que
> trabajan con pipelines de datos que generan este formato tienen que
> convertirlos manualmente antes de poder usar MarkItDown. Esta spec
> añade soporte nativo para `.xyz`.

## Criterios de aceptación

- [ ] CA-1: Al llamar `md.convert_local("archivo.xyz")`, el resultado
            contiene el contenido del archivo formateado como Markdown.
- [ ] CA-2: El converter acepta `mimetype = "application/x-xyz"` y
            extensión `".xyz"`.
- [ ] CA-3: Si la dependencia `xyzlib` no está instalada, la conversión
            lanza `MissingDependencyException` con el mensaje:
            `pip install 'markitdown[xyz]'`.
- [ ] CA-4: Instalando `markitdown[xyz]` se instala `xyzlib`.

## Criterios de no regresión

- [ ] NR-1: `hatch test` pasa al 100% (ningún test pre-existente falla).
- [ ] NR-2: El resto de converters siguen funcionando con sus fixtures.

## Diseño técnico

### Archivos a crear

- `packages/markitdown/src/markitdown/converters/_xyz_converter.py`
- `packages/markitdown/tests/test_xyz_converter.py`
- `packages/markitdown/tests/test_files/sample.xyz`

### Archivos a modificar

- `packages/markitdown/src/markitdown/converters/__init__.py` — añadir import y `__all__`
- `packages/markitdown/src/markitdown/_markitdown.py` — import + `register_converter()`
- `packages/markitdown/pyproject.toml` — añadir extra `xyz = ["xyzlib"]` y en `all`

### Prioridad del converter

`PRIORITY_SPECIFIC_FILE_FORMAT = 0.0` (formato concreto, no catch-all)

### Notas de implementación

- `xyzlib` no tiene soporte para Python 3.10 en Windows; documentarlo en el README.
- El formato `.xyz` puede contener metadatos en la cabecera; extraerlos como frontmatter.

## Archivos de prueba necesarios

- `tests/test_files/sample.xyz` — archivo minimal válido con al menos 1 sección de texto
- `tests/test_files/sample_complex.xyz` — archivo con múltiples secciones y metadatos

## Historial de revisión

| Iteración | Agente | Resultado | Fecha | Notas |
|---|---|---|---|---|
| — | — | CANCELLED | 2026-06-29 | Es solo una plantilla de ejemplo |
