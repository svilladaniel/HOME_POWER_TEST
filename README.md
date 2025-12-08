# HOME_POWER_TEST — Daniel Villa

Enlace al repositorio
- https://github.com/svilladaniel/HOME_POWER_TEST

Resumen del proyecto
--------------------
Prueba técnica para el puesto de Ingeniero/a DevOps. Aplicación mínima construida con FastAPI (Python) empaquetada para AWS Lambda (Mangum) y desplegada con Terraform. CI/CD implementado con GitHub Actions. Estado remoto en S3 usando lockfile. Infracost integrado para estimación de costos.

Decisiones principales
- Runtime y hosting: AWS Lambda + API Gateway (HTTP API).
- Framework de la app: FastAPI + Mangum.
- Frontend: archivo estático en `app/frontend/index.html`, servido por la Lambda.
- IaC: Terraform en `terraform/` (providers, variables, main.tf, outputs.tf, backend.tf).
- Backend de state: S3 con `use_lockfile = true`.
- CI/CD: GitHub Actions (workflows en `.github/workflows/`).
- Linter: flake8. Tests: pytest. Costos: Infracost en pipeline dev.

1) Estrategia de Git y su implementación
---------------------------------------
Ramas activas en el repositorio:
- `main`
  - Rama de producción / estable.
  - Despliegue continuo (workflow `.github/workflows/main.yml`) que construye el paquete y aplica la infraestructura para el entorno `main`.
  - La implementación publica una nueva versión de Lambda y mantiene alias por entorno.
- `dev`
  - Rama de integración / desarrollo compartido.
  - Despliegue continuo (workflow `.github/workflows/dev.yml`) que construye el paquete y aplica la infraestructura para el entorno `dev`.
  - Publica nueva versión de Lambda y actualiza el alias `dev`.
- `feature/*`
  - Ramas de desarrollo de funcionalidades.
  - No se despliegan automáticamente en CI; ejecutan checks de CI (lint/tests) cuando se crean PRs hacia `dev`.

Flujo de trabajo git (implementado):
- Desarrollo en `feature/*` → PR a `dev` → CI ejecuta linters y tests en PR → al hacer merge a `dev` se ejecuta pipeline `dev.yml` (build + terraform apply) → para pasar a producción se abre PR de `dev` a `main` y, tras merge, `main.yml` despliega a `main`.

2) Arquitectura de AWS y justificación (capa gratuita)
-------------------------------------------------------
Componentes:
- AWS Lambda (Python 3.12): ejecuta la aplicación FastAPI vía Mangum.
- API Gateway (HTTP API): expone la Lambda públicamente.
- IAM Role para la Lambda con la política básica de ejecución.
- S3 para almacenamiento del tfstate (backend).
- Artefacto (zip) de la Lambda en `terraform/lambda/lambda.zip` generado por los workflows.

Motivo de elección:
- Lambda + API Gateway permite mantener recursos dentro de la capa gratuita de AWS en escenarios de baja utilización (sin instancias EC2 permanentes).
- Arquitectura simple y tiempos de respuesta cortos adecuados para la prueba técnica.

3) Estrategia de pruebas unitarias
----------------------------------
- Framework: pytest.
- Archivo de pruebas: `tests/test_app.py`.
  - test_root_returns_html: valida que la ruta `/` responda HTML y contenga el texto del frontend.
  - test_api_info_returns_correct_json: valida el JSON exacto retornado por `/api/info`.
  - test_api_info_keys_exist: valida presencia de las claves principales en la respuesta.
- Ejecución:
  - Local:
    ```
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    pytest -q
    ```
  - CI: los workflows ejecutan `pytest` como paso en `dev.yml` y `main.yml`.

4) Análisis de código estático
-------------------------------
- Herramienta principal: flake8 (archivo de configuración `.flake8` en la raíz).
- Ejecución: `flake8 .` se ejecuta en el pipeline (`dev.yml`).
- Resultado: flake8 detecta issues de estilo y errores comunes; el pipeline falla si flake8 devuelve errores.

5) Lógica y flujo de los workflows de GitHub Actions
----------------------------------------------------
Workflows relevantes:
- `.github/workflows/dev.yml` (trigger: `push` en `dev`)
  - Pasos (resumido):
    - Checkout
    - Setup Python 3.12
    - Instalar dependencias y herramientas (pip, flake8, pytest, jq)
    - Ejecutar flake8
    - Ejecutar pytest
    - Construir ZIP de la Lambda (`terraform/lambda/lambda.zip`)
    - Setup Terraform (hashicorp/setup-terraform)
    - `terraform init` con backend-config apuntando al bucket S3
    - `terraform plan` (env vars: AWS credentials desde secrets)
    - Infracost setup y `infracost breakdown --path=terraform --format=table`
    - `terraform apply -auto-approve` para el entorno `dev`
- `.github/workflows/main.yml` (trigger: `push` en `main`)
  - Pasos (resumido):
    - Checkout
    - Setup Python 3.12
    - Construir ZIP de la Lambda
    - Setup Terraform
    - `terraform init` con backend-config apuntando al bucket S3 (key para `main`)
    - `terraform plan`
    - `terraform apply -auto-approve` para el entorno `main`

Observaciones sobre despliegue:
- El pipeline genera y publica una versión de Lambda (`publish = true` en Terraform).
- El alias por entorno (`aws_lambda_alias`) apunta a la versión publicada para `dev` o `main`, de modo que la integración de API Gateway invoca el alias correspondiente.

6) Análisis de costos con Infracost
-----------------------------------
- Infracost está integrado en `dev.yml` (paso `Setup Infracost CLI` y `Generate Infracost cost estimate`).
- El pipeline requiere la variable secreta `INFRACOST_API_KEY` en GitHub Secrets para poder generar el breakdown.
- El objetivo del análisis es verificar que la selección de recursos (Lambda + API Gateway y pocos recursos adicionales) se mantenga dentro o cerca de la capa gratuita para uso de baja intensidad.

7) Estrategia de gestión del state de Terraform
-----------------------------------------------
- Backend: S3 (bucket configurado en los workflows: `terraform-state-devops-test-daniel`).
- Ubicación del state por entorno (definida en `-backend-config` dentro de los workflows):
  - `dev` → key `dev/terraform.tfstate`
  - `main` → key `main/terraform.tfstate`
- Locking: `use_lockfile = true` (lockfile en S3; parámetro usado para evitar la advertencia deprecada sobre `dynamodb_table`).
- Acceso y seguridad del state:
  - El tfstate puede descargarse o inspeccionarse con `terraform state pull` tras inicializar backend con los mismos backend-config que usa CI.
  - El objeto en S3 puede consultarse con `aws s3 cp s3://terraform-state-devops-test-daniel/dev/terraform.tfstate ./dev.tfstate` siempre que las credenciales/roles permitan `s3:GetObject`.
  - El state puede contener información sensible; la política de acceso al bucket controla quién puede leer/editar el state.

Comandos utilizados para interactuar con el state (ejemplos informativos)
- Inicializar backend (ejemplo dev):
  ```
  terraform init \
    -backend-config="bucket=terraform-state-devops-test-daniel" \
    -backend-config="key=dev/terraform.tfstate" \
    -backend-config="region=us-east-1" \
    -reconfigure
  ```
- Extraer el state:
  ```
  terraform state pull > state-dev.json
  ```
- Descargar desde S3:
  ```
  aws s3 cp s3://terraform-state-devops-test-daniel/dev/terraform.tfstate ./dev.tfstate
  ```

8) Desafíos encontrados y resoluciones
--------------------------------------
- Deprecación `dynamodb_table` en backend S3:
  - Observación: al usar `dynamodb_table` en el backend S3 se mostró la advertencia: `The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile" instead.`
  - Resolución aplicada en este repositorio: backend S3 configurado con `use_lockfile = true` (lockfile en S3).
- Creación del bucket de backend:
  - Observación: el bucket S3 debe existir antes de ejecutar `terraform init` para el stack principal.
  - Resolución práctica: el flujo de CI sobrescribe backend-config en `terraform init` y asume que el bucket existe; el bucket puede crearse previamente con un paso/batch separado (no incluido aquí en el estado principal).
- Limpieza de versiones de Lambda:
  - Observación: la gestión automática de eliminación de versiones antiguas por `local-exec` requiere `awscli` disponible y permisos adecuados.
  - Resolución: empaquetado y publicación de versiones se realizan desde CI; manejo de versiones y alias está implementado en Terraform (cada apply publica versión y alias apunta a la versión activa).

9) Reproducción local (comandos)
--------------------------------
- Crear entorno y ejecutar tests:
  ```
  python -m venv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
  pytest
  ```
- Empaquetar Lambda (mismo proceso que el workflow):
  ```
  mkdir -p terraform/lambda
  mkdir -p package
  pip install -r requirements.txt -t package/
  cp -r app/* package/
  cd package
  zip -r ../terraform/lambda/lambda.zip .
  cd ..
  ```
- Inicializar terraform apuntando al backend S3 (ejemplo dev):
  ```
  terraform init \
    -backend-config="bucket=terraform-state-devops-test-daniel" \
    -backend-config="key=dev/terraform.tfstate" \
    -backend-config="region=us-east-1" \
    -reconfigure
  ```

10) Contacto del autor
-----------------------
- Daniel Villa — svilladaniel@gmail.com  
- LinkedIn: https://www.linkedin.com/in/danielvillasaldarriaga/

Entrega
-------
- Repositorio: https://github.com/svilladaniel/HOME_POWER_TEST
- Este documento (README.md) resume las decisiones, la implementación y los elementos solicitados en la prueba técnica.
