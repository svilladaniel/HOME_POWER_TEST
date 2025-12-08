# IAM Role para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role_${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Adjuntar permisos básicos de ejecución de Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Función Lambda con versionado
resource "aws_lambda_function" "lambda" {
  function_name = "${var.lambda_function_name}-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.handler"
  runtime       = "python3.12"
  filename      = var.lambda_zip_path

  source_code_hash = filebase64sha256(var.lambda_zip_path)
  publish          = true

  environment {
    variables = {
      ENV = var.environment
    }
  }
}

# Alias para apuntar a la versión activa
resource "aws_lambda_alias" "alias" {
  name             = var.environment   # "dev" o "main"
  function_name    = aws_lambda_function.lambda.function_name
  function_version = aws_lambda_function.lambda.version
}

# Limpiar versiones viejas automáticamente
resource "null_resource" "cleanup_old_versions" {
  depends_on = [aws_lambda_alias.alias]

  provisioner "local-exec" {
    command = <<EOT
      aws lambda list-versions-by-function \
        --function-name ${aws_lambda_function.lambda.function_name} \
        --query 'Versions[?Version != "$LATEST"]' \
        --output json | \
      jq -r '.[] | select(.Version != "${aws_lambda_alias.alias.function_version}") | .Version' | \
      xargs -r -I {} aws lambda delete-function \
        --function-name ${aws_lambda_function.lambda.function_name} --qualifier {}
    EOT
    environment = {
      AWS_ACCESS_KEY_ID     = var.AWS_ACCESS_KEY_ID
      AWS_SECRET_ACCESS_KEY = var.AWS_SECRET_KEY
      AWS_REGION            = var.AWS_REGION
    }
  }
}

# Log group para Lambda con retención de 7 días
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.lambda_function_name}-${var.environment}"
  retention_in_days = 7
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.lambda_function_name}-api-${var.environment}"
  protocol_type = "HTTP"
}

# Integración Lambda → API Gateway
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.lambda.invoke_arn
}

# Ruta default (todas las rutas)
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Stage default (auto deploy)
resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Permiso para que API Gateway invoque Lambda
resource "aws_lambda_permission" "api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
