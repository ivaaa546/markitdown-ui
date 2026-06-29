import io
import pytest
from unittest.mock import patch

from streamlit.testing.v1 import AppTest


def test_app_starts():
    at = AppTest.from_file("app.py").run(timeout=15)
    assert not at.exception
    assert at.title[0].value == "MarkItDown - Convert Files to Markdown"


def test_file_uploader_exists():
    at = AppTest.from_file("app.py").run(timeout=15)
    assert len(at.file_uploader) == 1


@patch("streamlit.file_uploader")
def test_conversion_and_download(mock_file_uploader):
    # CA-3 y CA-4: Conversión y Botón de descarga
    class FakeUploadedFile(io.BytesIO):
        def __init__(self, name, content=b"# Dummy Content"):
            super().__init__(content)
            self.name = name

    mock_file_uploader.return_value = [FakeUploadedFile("test_doc.txt")]

    at = AppTest.from_file("app.py").run(timeout=15)

    # We should have one text area populated
    assert len(at.text_area) > 0
    assert "# Dummy Content" in at.text_area[0].value

    # We should have one download button
    assert len(at.download_button) > 0
    assert at.download_button[0].label == "Descargar Markdown"


@patch("streamlit.file_uploader")
def test_conversion_error_handling(mock_file_uploader):
    # CA-5: Manejo de errores
    class FakeUploadedFile(io.BytesIO):
        def __init__(self, name, content=b"fake"):
            super().__init__(content)
            self.name = name

    # Un archivo .xlsx corrupto lanzará un error porque openpyxl fallará al leerlo
    mock_file_uploader.return_value = [FakeUploadedFile("bad_doc.xlsx")]

    at = AppTest.from_file("app.py").run(timeout=15)

    # Debe haber un mensaje de error renderizado en la UI (CA-5)
    assert len(at.error) > 0
    # The error message should indicate that it failed to convert
    assert "Error converting bad_doc.xlsx" in at.error[0].value
