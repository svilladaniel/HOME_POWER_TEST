# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Copiar el archivo de dependencias
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación (asumiendo que main.py está dentro de my-fastapi-app/)
# Copiamos la carpeta completa que contiene main.py y frontend/
COPY my-fastapi-app/ .

EXPOSE 8000

# Comando para iniciar la aplicación con Uvicorn
# El módulo ahora es 'main:app' dentro del WORKDIR /app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]