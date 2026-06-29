# Guía de Specs — MarkItDown

> Cómo escribir, gestionar y cerrar specs de features en este proyecto.
> Las specs son el contrato entre el Leader y el Implementer.

---

## ¿Qué es una spec?

Una spec (especificación) es un documento corto que describe **exactamente qué
debe construirse** antes de que se escriba una sola línea de código. Es la única
fuente de verdad entre el Leader (qué se necesita) y el Implementer (cómo se hace).

Una buena spec responde:
1. **¿Por qué?** — el problema que resuelve
2. **¿Qué?** — criterios de aceptación verificables
3. **¿Cómo (a alto nivel)?** — diseño técnico suficiente para arrancar

---

## Convenciones de nombre y ubicación

```
specs/<YYYY-MM-DD>-<slug>.md
```

Ejemplos:
```
specs/2026-06-29-epub-converter.md
specs/2026-07-01-youtube-chapters.md
specs/2026-07-03-fix-pdf-tables.md
```

- `<YYYY-MM-DD>`: fecha de creación de la spec
- `<slug>`: kebab-case, descripción concisa, sin espacios

---

## Plantilla de spec

Copiar y rellenar al crear una nueva spec:

```markdown
# Spec: <Título descriptivo de la feature>

**Estado:** PENDING
**Fecha:** YYYY-MM-DD
**Autor:** leader
**Prioridad:** HIGH | MEDIUM | LOW

---

## Contexto

Por qué existe esta spec. Qué problema resuelve. Qué pasaría si no se implementa.
Incluye referencias a issues, conversaciones con el usuario, o comportamientos
actuales que se quieren mejorar.

## Criterios de aceptación

Lista verificable y concreta. Cada ítem debe ser demostrable con un test:

- [ ] CA-1: <comportamiento observable y verificable>
- [ ] CA-2: <comportamiento observable y verificable>
- [ ] CA-3: <...>

**Regla:** Si no puedes escribir un test para un CA, reescribe el CA.

## Criterios de no regresión

Features existentes que NO deben romperse:

- [ ] NR-1: <comportamiento existente que debe seguir funcionando>

## Diseño técnico

Descripción del enfoque de implementación. No necesita ser exhaustivo,
pero debe dar suficiente contexto para arrancar:

### Archivos a crear
- `packages/markitdown/src/markitdown/converters/_<nombre>_converter.py`

### Archivos a modificar
- `packages/markitdown/src/markitdown/converters/__init__.py` — export
- `packages/markitdown/src/markitdown/_markitdown.py` — registro

### Dependencias necesarias
- `<paquete-pip>` → extra `[<nombre-extra>]` en `pyproject.toml`

### Notas de implementación
- Gotchas conocidos
- Restricciones de la API
- Consideraciones de seguridad

## Archivos de prueba necesarios

Si la feature requiere fixtures:
- `tests/test_files/<nombre>.<ext>` — descripción de qué debe contener

## Historial de revisión

| Iteración | Agente | Resultado | Fecha | Notas |
|---|---|---|---|---|
| 1 | reviewer | PENDING | YYYY-MM-DD | — |
```

---

## Estados de una spec

| Estado | Significado | Quién lo cambia |
|---|---|---|
| `PENDING` | Spec creada, esperando implementación | Leader al crear |
| `IN_PROGRESS` | Implementer está trabajando en ella | Leader al asignar |
| `IN_REVIEW` | En revisión por el Reviewer | Leader al solicitar review |
| `DONE` | Aprobada por el Reviewer | Leader al recibir aprobación |
| `BLOCKED` | Bloqueada por dependencia o problema externo | Leader o Implementer |
| `CANCELLED` | Descartada (con motivo) | Leader con aprobación del usuario |

---

## Reglas para escribir buenos criterios de aceptación

### ✔ Criterios bien escritos

```markdown
- [ ] CA-1: Al convertir `tests/test_files/sample.epub`, el resultado contiene
            el título del libro como encabezado `# Título`.
- [ ] CA-2: Si `ebooklib` no está instalado, la conversión lanza
            `MissingDependencyException` con el mensaje de instalación correcto.
- [ ] CA-3: El converter acepta mimetype `application/epub+zip` y extensión `.epub`.
```

### ✘ Criterios mal escritos

```markdown
- [ ] El converter funciona bien.              ← no verificable
- [ ] El código es limpio.                     ← subjetivo
- [ ] Maneja todos los errores correctamente.  ← ambiguo
```

---

## Ciclo de vida completo de una spec

```
[Leader] Crea specs/YYYY-MM-DD-slug.md   → Estado: PENDING
    │
    ▼
[Leader] Asigna al Implementer           → Estado: IN_PROGRESS
    │
    ▼
[Implementer] Implementa y verifica
    │
    ▼
[Leader] Solicita review al Reviewer     → Estado: IN_REVIEW
    │
    ├─ RECHAZADO ──→ [Implementer] corrige
    │                    │
    │                    └──→ vuelve a IN_REVIEW
    │
    └─ APROBADO ──→ [Leader] actualiza spec → Estado: DONE
                         │
                         └──→ [Leader] actualiza progress/<slug>.md
```

---

## Relación con `progress/`

Cuando una spec pasa a `DONE`, el Leader crea o actualiza el archivo
correspondiente en `progress/`. Ver `docs/verification.md` para el formato
exacto del registro de progreso.
