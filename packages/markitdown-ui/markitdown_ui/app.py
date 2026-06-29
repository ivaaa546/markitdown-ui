__version__ = "0.1.0"

import streamlit as st
from markitdown import MarkItDown
import tempfile
import os

st.set_page_config(page_title="Markdowin UI", layout="wide")


# Inicializar conversor (habilitar plugins por si los requiere)
@st.cache_resource
def get_markitdown():
    import requests

    session = requests.Session()
    session.headers.update(
        {
            "Accept": "text/markdown, text/html;q=0.9, text/plain;q=0.8, */*;q=0.1",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        }
    )
    return MarkItDown(requests_session=session)


md = get_markitdown()

st.title("📝 Markdowin UI")
st.markdown("Convierte fácilmente cualquier documento, imagen o URL a Markdown.")

# Layout principal
col1, col2 = st.columns([1, 1])

with col1:
    st.subheader("Entrada de Datos")

    # Opción 1: Archivo local
    uploaded_file = st.file_uploader(
        "Sube un archivo (PDF, Word, Excel, PPT, Imágenes, HTML...)",
        type=None,  # Permitimos cualquier extensión, markitdown manejará el error si no es válido
    )

    st.markdown("---")

    # Opción 2: URL
    url_input = st.text_input(
        "O ingresa una URL (YouTube, Wikipedia, Bing...)",
        placeholder="https://es.wikipedia.org/wiki/Inteligencia_artificial",
    )

    convert_btn = st.button(
        "Convertir a Markdown", type="primary", use_container_width=True
    )

with col2:
    st.subheader("Resultado Markdown")

    if convert_btn:
        if not uploaded_file and not url_input:
            st.warning("⚠️ Por favor sube un archivo o ingresa una URL.")
        else:
            with st.spinner("⏳ Convirtiendo..."):
                try:
                    result = None
                    if uploaded_file is not None:
                        # Convertimos directamente el stream del archivo
                        result = md.convert_stream(
                            uploaded_file, filename=uploaded_file.name
                        )
                    elif url_input:
                        # Convertimos a partir de la URL
                        result = md.convert(url_input)

                    # Manejo de versiones antiguas de MarkItDown
                    markdown_content = (
                        getattr(
                            result,
                            "markdown",
                            getattr(result, "text_content", str(result)),
                        )
                        if result
                        else ""
                    )

                    if markdown_content:
                        st.success("✅ ¡Conversión exitosa!")

                        # Mostrar una vista previa controlada
                        st.text_area(
                            "Vista Previa (Primeros 5000 caracteres)",
                            markdown_content[:5000]
                            + (
                                "\n\n[... truncado ...]"
                                if len(markdown_content) > 5000
                                else ""
                            ),
                            height=400,
                        )

                        # Botón de descarga con el archivo original + .md
                        filename_out = "resultado.md"
                        if uploaded_file:
                            filename_out = (
                                f"{os.path.splitext(uploaded_file.name)[0]}.md"
                            )

                        st.download_button(
                            label="⬇️ Descargar Archivo Markdown",
                            data=markdown_content,
                            file_name=filename_out,
                            mime="text/markdown",
                            use_container_width=True,
                        )
                    else:
                        st.error("❌ No se pudo extraer contenido válido.")
                except Exception as e:
                    st.error(f"❌ Error durante la conversión: {str(e)}")
    else:
        st.info("El resultado de la conversión aparecerá aquí.")
