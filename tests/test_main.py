# tests/test_main.py

from fastapi.testclient import TestClient
from my_fastapi_app.main import app

# Inicializar el cliente de pruebas
client = TestClient(app)

def test_read_root():
    """Prueba que la ruta raiz principal (/) devuelva un estado 200 OK."""
    # Como la ruta "/" sirve index.html, comprobamos la respuesta
    response = client.get("/")
    assert response.status_code == 200
    assert "Prueba para Power test" in response.text # Verifica contenido de index.html

def test_api_saludo_endpoint():
    """Prueba que el endpoint /api/saludo devuelva el mensaje esperado."""
    response = client.get("/api/saludo")
    assert response.status_code == 200
    assert response.json() == {"mensaje": "¡Datos recibidos con éxito desde el Backend de FastAPI!"}
    
def test_api_route_frontend():
    """Prueba que la ruta /api devuelva el frontend de la API."""
    response = client.get("/api")
    assert response.status_code == 200
    assert "Cliente Sencillo (Frontend)" in response.text # Verifica contenido de api.html