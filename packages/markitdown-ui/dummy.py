from streamlit.testing.v1 import AppTest


def test_upload():
    at = AppTest.from_file("app.py").run()
    # Let's inspect what at.file_uploader[0].set_value expects.
