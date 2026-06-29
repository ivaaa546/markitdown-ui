# Verificación — MarkItDown

> Criterios de calidad y procesos de verificación que el Reviewer usa para
> emitir su veredicto y que el Implementer usa para auto-verificarse.

---

## Filosofía

Una entrega es **verificada** cuando puede demostrarse objetivamente que:

1. **Funciona**: todos los tests pasan.
2. **Es correcto**: no hay errores de tipos (mypy).
3. **Es limpio**: cumple el formato del proyecto (black via pre-commit).
4. **Cumple la spec**: cada criterio de aceptación tiene un test que lo demuestra.
5. **No rompe nada**: los tests de no regresión también pasan.

---

## Comandos de verificación (referencia rápida)

Todos los comandos se ejecutan desde `packages/markitdown/`:

```bash
cd packages/markitdown

# 1. Verificación de tipos (mypy)
hatch run types:check

# 2. Suite completa de tests
hatch test

# 3. Tests con detalle de fallos
hatch test -- -v --tb=short

# 4. Filtrar tests por nombre (para iteración rápida)
hatch test -- -k "test_epub"

# 5. Formato y linting (desde raíz del repo)
cd ../..
pre-commit run --all-files
```

### Umbral mínimo de aprobación

| Check | Umbral para APROBAR |
|---|---|
| `hatch run types:check` | **0 errores** mypy |
| `hatch test` | **100% de tests pasan** (0 fallos, 0 errores) |
| `pre-commit run --all-files` | **0 errores** de formato |

---

## Checklist del Reviewer (completo)

### Bloque 1: Ejecución mecánica

```
[ ] bash init.sh → exit 0 (verificación pre-agente)
[ ] hatch run types:check → 0 errores
[ ] hatch test → 0 fallos
[ ] pre-commit run --all-files → 0 errores
```

### Bloque 2: Cobertura de la spec

Por cada criterio de aceptación (CA-N) de la spec:

```
[ ] CA está implementado en el código
[ ] Existe un test que verifica ese CA explícitamente
[ ] El test falla si se comenta/borra el código que implementa el CA
[ ] El nombre del test deja claro qué CA verifica
```

### Bloque 3: Patrón de converters (si aplica)

```
[ ] Clase hereda de DocumentConverter
[ ] accepts() → bool basado en stream_info (no en lógica de negocio)
[ ] accepts() restaura posición del stream si lo lee (tell/seek)
[ ] convert() retorna DocumentConverterResult(markdown=..., title=...)
[ ] Registrado en converters/__init__.py (import + __all__)
[ ] Registrado en _markitdown.py (import al top + register_converter en __init__)
[ ] Prioridad correcta: 0.0 (específico) o 10.0 (genérico)
[ ] Deps opcionales: try/except ImportError → MissingDependencyException
[ ] Extra añadido a pyproject.toml [project.optional-dependencies]
```

### Bloque 4: Convenciones de código

```
[ ] Python ≥3.10 compatible (sin sintaxis >3.10)
[ ] Todos los parámetros y retornos con type hints
[ ] Usa .markdown (no .text_content deprecated)
[ ] No añade deps al core que deberían ser opcionales
```

### Bloque 5: Seguridad

```
[ ] No se expone input no sanitizado a convert() en flujos no confiables
[ ] Se usa la API más estrecha posible (convert_local > convert_response > ...)
```

---

## Formato de veredicto del Reviewer

### ✔ APROBADO

```
VEREDICTO: APROBADO
Spec: specs/<fecha>-<slug>.md
Fecha de revisión: YYYY-MM-DD
Iteración: N

Resumen de checks:
  mypy         : ✔ 0 errores
  hatch test   : ✔ <N> tests pasaron, 0 fallaron
  pre-commit   : ✔ limpio

Criterios de aceptación:
  CA-1 : ✔ implementado y testeado (test_<nombre>)
  CA-2 : ✔ implementado y testeado (test_<nombre>)

Notas (no bloqueantes):
  - <observación opcional de mejora futura>
```

### ✘ RECHAZADO

```
VEREDICTO: RECHAZADO
Spec: specs/<fecha>-<slug>.md
Fecha de revisión: YYYY-MM-DD
Iteración: N

Problemas BLOQUEANTES (deben resolverse antes de aprobar):

  [P1] <Descripción concreta>
       Archivo: packages/markitdown/src/markitdown/converters/_mi_converter.py
       Línea: ~42
       Cómo corregir: <instrucción accionable>

  [P2] <...>

Problemas NO BLOQUEANTES (recomendaciones):
  - <sugerencia de mejora>
```

---

## Registro de progreso en `progress/`

Cuando una feature queda `DONE`, el Leader crea o actualiza:

```
progress/<slug>.md
```

### Formato del archivo de progreso

```markdown
# Progress: <Título de la feature>

**Spec:** [specs/<fecha>-<slug>.md](../specs/<fecha>-<slug>.md)
**Estado final:** DONE
**Fecha de cierre:** YYYY-MM-DD

## Resumen

Descripción breve de lo que se implementó.

## Archivos modificados

| Archivo | Tipo de cambio |
|---|---|
| `packages/markitdown/src/markitdown/converters/_mi_converter.py` | NUEVO |
| `packages/markitdown/src/markitdown/converters/__init__.py` | MODIFICADO |
| `packages/markitdown/src/markitdown/_markitdown.py` | MODIFICADO |
| `packages/markitdown/tests/test_mi_converter.py` | NUEVO |

## Historial de revisiones

| Iteración | Resultado | Fecha | Problemas reportados |
|---|---|---|---|
| 1 | RECHAZADO | YYYY-MM-DD | P1: faltaba registro en __init__.py |
| 2 | APROBADO | YYYY-MM-DD | — |

## Notas técnicas

Observaciones relevantes para el futuro (gotchas, decisiones de diseño, etc.)
```

---

## Verificación de no regresión

Antes de aprobar cualquier cambio, el Reviewer verifica que los converters
existentes no se han roto. La suite completa de tests cubre esto, pero
en casos de duda, ejecutar:

```bash
# Desde packages/markitdown/
hatch test -- -v --tb=long 2>&1 | tail -50
```

Si un test pre-existente falla con el nuevo código → **RECHAZADO**.
El Implementer no puede modificar tests existentes para que pasen
(a menos que la spec lo indique explícitamente y el Leader lo apruebe).

---

## Verificación de la instalación de dependencias opcionales

Para features que añaden dependencias opcionales, verificar:

```bash
# Instalar sin el extra → debe lanzar MissingDependencyException (no crash)
pip install -e 'packages/markitdown'
python -c "from markitdown import MarkItDown; md = MarkItDown(); md.convert('test.mi')"

# Instalar con el extra → debe funcionar correctamente
pip install -e 'packages/markitdown[mi-extra]'
python -c "from markitdown import MarkItDown; md = MarkItDown(); md.convert('test.mi')"
```
