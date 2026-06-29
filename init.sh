#!/usr/bin/env bash
# =============================================================================
# init.sh — Script de verificación y arranque seguro para MarkItDown
#
# Propósito:
#   Actúa como filtro de seguridad obligatorio antes de que cualquier agente
#   de IA comience a trabajar. Verifica la estructura del repositorio, las
#   dependencias, los tipos y los tests para asegurar una base de código sana.
#
# Uso:
#   bash init.sh              # Verificación completa (recomendado)
#   bash init.sh --no-tests   # Omitir tests (solo estructura + tipos)
#   bash init.sh --no-types   # Omitir mypy
#   bash init.sh --quick      # Solo verificación de estructura
#
# Códigos de salida:
#   0  — Todo OK, el agente puede proceder
#   1  — Error crítico detectado, el agente NO debe continuar
# =============================================================================

set -euo pipefail

# ─── Colores y helpers ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

PASS="${GREEN}✔${RESET}"
FAIL="${RED}✘${RESET}"
WARN="${YELLOW}⚠${RESET}"
INFO="${CYAN}ℹ${RESET}"

log_section() { echo -e "\n${BOLD}${BLUE}══ $1 ══${RESET}"; }
log_pass()    { echo -e "  ${PASS} $1"; }
log_fail()    { echo -e "  ${FAIL} ${RED}$1${RESET}"; }
log_warn()    { echo -e "  ${WARN} ${YELLOW}$1${RESET}"; }
log_info()    { echo -e "  ${INFO} $1"; }

# Contador de errores críticos
ERRORS=0
WARNINGS=0

fail() {
    log_fail "$1"
    ERRORS=$((ERRORS + 1))
}

warn() {
    log_warn "$1"
    WARNINGS=$((WARNINGS + 1))
}

# ─── Flags de CLI ─────────────────────────────────────────────────────────────
RUN_TESTS=true
RUN_TYPES=true
RUN_LINT=true

for arg in "$@"; do
    case "$arg" in
        --no-tests) RUN_TESTS=false ;;
        --no-types) RUN_TYPES=false ;;
        --no-lint)  RUN_LINT=false  ;;
        --quick)
            RUN_TESTS=false
            RUN_TYPES=false
            RUN_LINT=false
            ;;
        --help|-h)
            echo "Uso: bash init.sh [--no-tests] [--no-types] [--no-lint] [--quick]"
            exit 0
            ;;
    esac
done

# ─── Cabecera ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║      MarkItDown — Verificación Pre-Agente            ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
echo -e "  Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"

# ─── Detectar raíz del repositorio ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
log_info "Raíz del repo: ${REPO_ROOT}"

# ─── SECCIÓN 1: Estructura del repositorio ────────────────────────────────────
log_section "1/5 · Estructura del repositorio"

# Archivos raíz críticos
REQUIRED_ROOT_FILES=(
    "README.md"
    "AGENTS.md"
    "LICENSE"
    "init.sh"
    ".github/workflows/tests.yml"
    ".pre-commit-config.yaml"
    "packages/markitdown/pyproject.toml"
)
for f in "${REQUIRED_ROOT_FILES[@]}"; do
    if [[ -e "${REPO_ROOT}/${f}" ]]; then
        log_pass "Archivo raíz presente: ${f}"
    else
        fail "Archivo raíz FALTANTE: ${f}"
    fi
done

# Paquetes del monorepo
REQUIRED_PACKAGES=(
    "packages/markitdown"
    "packages/markitdown-mcp"
    "packages/markitdown-ocr"
    "packages/markitdown-sample-plugin"
)
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if [[ -d "${REPO_ROOT}/${pkg}" ]]; then
        log_pass "Paquete presente: ${pkg}"
    else
        fail "Paquete FALTANTE: ${pkg}"
    fi
done

# Estructura interna del core
CORE_SRC="${REPO_ROOT}/packages/markitdown/src/markitdown"
REQUIRED_CORE_FILES=(
    "_markitdown.py"
    "_base_converter.py"
    "_stream_info.py"
    "_exceptions.py"
    "__init__.py"
    "converters/__init__.py"
)
for f in "${REQUIRED_CORE_FILES[@]}"; do
    if [[ -f "${CORE_SRC}/${f}" ]]; then
        log_pass "Archivo core presente: src/markitdown/${f}"
    else
        fail "Archivo core FALTANTE: src/markitdown/${f}"
    fi
done

# Directorio de tests
TESTS_DIR="${REPO_ROOT}/packages/markitdown/tests"
if [[ -d "$TESTS_DIR" ]]; then
    TEST_COUNT=$(find "$TESTS_DIR" -name "test_*.py" | wc -l | tr -d ' ')
    log_pass "Directorio de tests presente (${TEST_COUNT} archivos test_*.py)"
    if [[ "$TEST_COUNT" -eq 0 ]]; then
        warn "No se encontraron archivos test_*.py en ${TESTS_DIR}"
    fi
else
    fail "Directorio de tests FALTANTE: ${TESTS_DIR}"
fi

# ─── SECCIÓN 2: Entorno Python ────────────────────────────────────────────────
log_section "2/5 · Entorno Python"

# Verificar Python >= 3.10
if command -v python3 &>/dev/null; then
    PY_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
    if [[ "$PY_MAJOR" -ge 3 && "$PY_MINOR" -ge 10 ]]; then
        log_pass "Python ${PY_VERSION} (≥3.10 requerido)"
    else
        fail "Python ${PY_VERSION} es demasiado antiguo — se requiere ≥3.10"
    fi
else
    fail "python3 no encontrado en PATH"
fi

# Verificar pip
if command -v pip &>/dev/null || command -v pip3 &>/dev/null; then
    log_pass "pip disponible"
else
    warn "pip no encontrado — puede que estés usando uv o conda"
fi

# Verificar hatch (herramienta de build y tests)
if command -v hatch &>/dev/null; then
    HATCH_VERSION=$(hatch --version 2>/dev/null | head -1)
    log_pass "hatch disponible (${HATCH_VERSION})"
    HATCH_OK=true
else
    warn "hatch no encontrado — los comandos 'hatch test' y 'hatch run types:check' no estarán disponibles"
    log_info "Instala hatch con: pip install hatch"
    HATCH_OK=false
fi

# Verificar si el paquete markitdown está instalado (editable o normal)
if python3 -c "import markitdown" &>/dev/null; then
    log_pass "markitdown importable desde el entorno actual"
else
    warn "markitdown no está instalado en el entorno actual"
    log_info "Instala con: pip install -e 'packages/markitdown[all]'"
fi

# ─── SECCIÓN 3: pre-commit / Linter ───────────────────────────────────────────
log_section "3/5 · Linter (pre-commit / black)"

if [[ "$RUN_LINT" == true ]]; then
    if command -v pre-commit &>/dev/null; then
        log_info "Ejecutando pre-commit run --all-files ..."
        if pre-commit run --all-files 2>&1; then
            log_pass "pre-commit: sin problemas de formato"
        else
            fail "pre-commit: encontró problemas de formato. Ejecuta 'pre-commit run --all-files' para corregirlos."
        fi
    else
        warn "pre-commit no instalado — verificación de formato omitida"
        log_info "Instala con: pip install pre-commit && pre-commit install"
    fi
else
    log_info "Linter omitido (--no-lint o --quick)"
fi

# ─── SECCIÓN 4: Verificación de tipos (mypy) ──────────────────────────────────
log_section "4/5 · Verificación de tipos (mypy)"

if [[ "$RUN_TYPES" == true ]]; then
    if [[ "$HATCH_OK" == true ]]; then
        log_info "Ejecutando hatch run types:check (mypy) ..."
        cd "${REPO_ROOT}/packages/markitdown"
        if hatch run types:check 2>&1; then
            log_pass "mypy: sin errores de tipos"
        else
            fail "mypy: se encontraron errores de tipos. Corrígelos antes de continuar."
        fi
        cd "${REPO_ROOT}"
    elif command -v mypy &>/dev/null; then
        log_info "hatch no disponible, usando mypy directamente ..."
        if mypy "${CORE_SRC}" --ignore-missing-imports 2>&1; then
            log_pass "mypy: sin errores de tipos"
        else
            fail "mypy: se encontraron errores de tipos."
        fi
    else
        warn "Ni hatch ni mypy disponibles — verificación de tipos omitida"
    fi
else
    log_info "Verificación de tipos omitida (--no-types o --quick)"
fi

# ─── SECCIÓN 5: Tests ─────────────────────────────────────────────────────────
log_section "5/5 · Tests (hatch test)"

if [[ "$RUN_TESTS" == true ]]; then
    if [[ "$HATCH_OK" == true ]]; then
        log_info "Ejecutando hatch test en packages/markitdown ..."
        cd "${REPO_ROOT}/packages/markitdown"
        if hatch test 2>&1; then
            log_pass "Tests: todos pasaron"
        else
            fail "Tests: uno o más tests fallaron. El agente NO debe continuar."
        fi
        cd "${REPO_ROOT}"
    elif command -v pytest &>/dev/null; then
        log_info "hatch no disponible, usando pytest directamente ..."
        if pytest "${TESTS_DIR}" -q --tb=short 2>&1; then
            log_pass "Tests: todos pasaron (pytest)"
        else
            fail "Tests: uno o más tests fallaron. El agente NO debe continuar."
        fi
    else
        warn "Ni hatch ni pytest disponibles — tests omitidos"
        log_info "Instala con: pip install hatch"
    fi
else
    log_info "Tests omitidos (--no-tests o --quick)"
fi

# ─── Resumen final ────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${BLUE}══ Resumen de Verificación ══${RESET}"
echo -e "  Errores críticos : ${RED}${ERRORS}${RESET}"
echo -e "  Advertencias     : ${YELLOW}${WARNINGS}${RESET}"

if [[ "$ERRORS" -gt 0 ]]; then
    echo ""
    echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}${BOLD}║  ✘  VERIFICACIÓN FALLIDA — El agente debe detenerse  ║${RESET}"
    echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
    echo -e "  Se detectaron ${ERRORS} error(es) crítico(s)."
    echo -e "  Corrígelos antes de permitir que cualquier agente proceda."
    echo ""
    exit 1
else
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}║  ✔  VERIFICACIÓN EXITOSA — El agente puede proceder  ║${RESET}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
    if [[ "$WARNINGS" -gt 0 ]]; then
        echo -e "  ${YELLOW}Hay ${WARNINGS} advertencia(s) no crítica(s). Revísalas si es posible.${RESET}"
    fi
    echo ""
    exit 0
fi
