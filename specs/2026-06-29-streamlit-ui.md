# Spec: Interfaz Web con Streamlit

**Estado:** DONE
**Fecha:** 2026-06-29
**Autor:** leader
**Prioridad:** HIGH

---

## Contexto

Actualmente, MarkItDown solo ofrece una interfaz de línea de comandos (CLI) o uso vía API programática. Para usuarios no técnicos o que buscan una interacción rápida sin usar la terminal, hace falta una Interfaz Gráfica de Usuario (GUI). Streamlit es la opción ideal para construir esta interfaz rápidamente, permitiendo subir archivos, ver la conversión a Markdown en tiempo real y descargar el resultado final.

## Criterios de aceptación

- [ ] CA-1: Existe un script `app.py` en la raíz (o un nuevo paquete `markitdown-ui`) que levanta una app de Streamlit.
- [ ] CA-2: La interfaz permite subir uno o varios archivos mediante un componente "File Uploader".
- [ ] CA-3: Para cada archivo subido, se invoca internamente `MarkItDown().convert_stream()` o similar, mostrando el resultado convertido por pantalla.
- [ ] CA-4: Se incluye un botón de "Descargar Markdown" por cada documento convertido, que permite guardar el resultado como un archivo `.md`.
- [ ] CA-5: Si ocurre un error de conversión (ej. `UnsupportedFormatException`), la UI captura la excepción y muestra un mensaje amigable al usuario (ej. `st.error`).

## Diseño técnico

### Archivos a crear
- `packages/markitdown-ui/app.py`: Contendrá el código de la interfaz de Streamlit.
- `packages/markitdown-ui/pyproject.toml` (o añadimos Streamlit como dependencia opcional `[ui]` en el paquete principal, dependiendo de la convención elegida. Como es una UI, separarlo en un paquete `markitdown-ui` o script raíz es mejor. En este caso, usaremos la convención de paquetes del monorepo, creando `packages/markitdown-ui` que dependa de `markitdown[all]` y `streamlit`).

### Archivos a modificar
- `AGENTS.md` (si es necesario para documentar cómo correr la UI).

### Dependencias necesarias
- `streamlit`

### Notas de implementación
- La subida de archivos en Streamlit (`st.file_uploader`) devuelve un objeto tipo stream (BytesIO) que es compatible directamente con `convert_stream()` de MarkItDown, lo cual es muy eficiente porque no necesitamos guardarlo temporalmente en disco.
- Para el nombre del archivo descargado, usaremos la extensión `.md` reemplazando la original.

## Historial de revisión

| Iteración | Agente | Resultado | Fecha | Notas |
|---|---|---|---|---|
| 1 | reviewer | PENDING | 2026-06-29 | Creada la spec inicial para revisión del usuario. |
