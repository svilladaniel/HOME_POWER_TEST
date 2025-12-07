# my-fastapi-app/main.py

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse

# 1. Inicializa la aplicación de FastAPI
app = FastAPI(title="Mi API Sencilla")

# 2. Montar el directorio estático
# Esto permite que el backend sirva los archivos HTML/JS/CSS del frontend
app.mount("/static", StaticFiles(directory="frontend"), name="static")

# 3. Endpoint de la API (Backend)
@app.get("/api/saludo")
def obtener_saludo():
    """
    Este endpoint será llamado por el frontend para obtener un mensaje.
    """
    return {"mensaje": "¡Datos recibidos con éxito desde el Backend de FastAPI!"}

# 4. Ruta Raíz para servir el Frontend

@app.get("/api", response_class=HTMLResponse)
async def servir_frontend():
    """
    Ruta raíz que lee y devuelve nuestro archivo index.html
    """
    try:
        with open("frontend/api.html", "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return HTMLResponse("<h1>Error: api.html no encontrado en la carpeta 'frontend'.</h1>", status_code=404)


@app.get("/", response_class=HTMLResponse)
async def servir_frontend():
    """
    Ruta raíz que lee y devuelve nuestro archivo index.html
    """
    try:
        with open("frontend/index.html", "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return HTMLResponse("<h1>Error: index.html no encontrado en la carpeta 'frontend'.</h1>", status_code=404)