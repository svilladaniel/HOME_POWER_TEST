import sys
import os
from fastapi.testclient import TestClient
from app.main import app

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

client = TestClient(app)


def test_root_returns_html():
    """
    Verifica que la ruta raíz (/) responde con HTML.
    """
    response = client.get("/")
    assert response.status_code == 200
    assert "<html" in response.text.lower()   # HTML básico
    assert "Prueba para Powertest".lower() in response.text.lower()


def test_api_info_returns_correct_json():
    """
    Verifica que la API devuelva el JSON exacto esperado.
    """
    response = client.get("/api/info")
    assert response.status_code == 200

    expected = {
        "nombre del participante": "Daniel Villa",
        "Edad del participante": "32",
        "cargo al que aspira": "DevOps",
        "Correo": "svilladaniel@gmail.com",
        "Linked-in": "https://www.linkedin.com/in/danielvillasaldarriaga/"
    }

    assert response.json() == expected


def test_api_info_keys_exist():
    """
    Verifica que el JSON tenga las llaves principales.
    """
    response = client.get("/api/info")
    data = response.json()

    assert "nombre del participante" in data
    assert "Edad del participante" in data
    assert "cargo al que aspira" in data
    assert "Correo" in data
    assert "Linked-in" in data
