import os
import streamlit as st
from markitdown import MarkItDown, FileConversionException


def main() -> None:
    st.title("MarkItDown - Convert Files to Markdown")

    st.markdown(
        "Upload one or multiple files to convert them to Markdown using MarkItDown."
    )

    uploaded_files = st.file_uploader("Choose files", accept_multiple_files=True)

    if uploaded_files:
        md = MarkItDown()
        for uploaded_file in uploaded_files:
            st.subheader(f"File: {uploaded_file.name}")
            try:
                # Extraemos la extensión para ayudar a MarkItDown a inferir el tipo
                file_ext = os.path.splitext(uploaded_file.name)[1]

                # Convert directly from the uploaded stream
                result = md.convert_stream(
                    uploaded_file, extension=file_ext, filename=uploaded_file.name
                )
                # Manejar compatibilidad entre versiones de markitdown (.markdown vs .text_content)
                markdown_content = getattr(
                    result, "markdown", getattr(result, "text_content", str(result))
                )

                st.text_area(
                    "Markdown Output",
                    markdown_content,
                    height=300,
                    key=f"text_{uploaded_file.name}",
                )

                # Download button
                file_name_no_ext = os.path.splitext(uploaded_file.name)[0]
                download_name = f"{file_name_no_ext}.md"

                st.download_button(
                    label="Descargar Markdown",
                    data=markdown_content,
                    file_name=download_name,
                    mime="text/markdown",
                    key=f"btn_{uploaded_file.name}",
                )
            except FileConversionException as e:
                st.error(f"Error converting {uploaded_file.name}: {str(e)}")
            except Exception as e:
                st.error(
                    f"An unexpected error occurred with {uploaded_file.name}: {str(e)}"
                )


if __name__ == "__main__":
    main()
