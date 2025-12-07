import os
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from mangum import Mangum

app = FastAPI(title="powertest_api")

# ruta absoluta del frontend
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FRONTEND_FILE = os.path.join(BASE_DIR, "frontend", "index.html")


@app.get("/", response_class=HTMLResponse)
async def root(): 
    try:
        with open(FRONTEND_FILE, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return HTMLResponse("<h1>Error: No se encontró index.html</h1>", status_code=404)


@app.get("/api/info")
def api_info():
    return {
        "nombre del participante": "Daniel Villa",
        "Edad del participante": "32",
        "cargo al que aspira": "DevOps",
        "Correo": "svilladaniel@gmail.com",
        "Linked-in": "https://www.linkedin.com/in/danielvillasaldarriaga/"
    }


# Handler para AWS Lambda
handler = Mangum(app)
