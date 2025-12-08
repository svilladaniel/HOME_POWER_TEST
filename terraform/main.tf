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

resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function

resource "aws_lambda_function" "lambda" {
  function_name = "${var.lambda_function_name}-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.handler"
  runtime       = "python3.12"
  filename      = var.lambda_zip_path

  source_code_hash = filebase64sha256(var.lambda_zip_path)

  publish = true

  environment {
    variables = {
      ENV = var.environment
    }
  }
}

# Lambda Alias por ambiente

resource "aws_lambda_alias" "alias" {
  name             = var.environment
  function_name    = aws_lambda_function.lambda.function_name
  function_version = aws_lambda_function.lambda.version
}

# API Gateway HTTP API

resource "aws_apigatewayv2_api" "api" {
  name          = "powertest-api-${var.environment}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Cleanup versiones antiguas

resource "null_resource" "cleanup_old_versions" {
  provisioner "local-exec" {
    command = <<EOT
      aws lambda list-versions-by-function \
        --function-name ${aws_lambda_function.lambda.function_name} \
        --query 'Versions[?Version != "$LATEST"]' \
        --output json | \
      jq -r '.[] | select(.Version != "1") | .Version' | \
      xargs -r -I {} aws lambda delete-function \
        --function-name ${aws_lambda_function.lambda.function_name} --qualifier {}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [aws_lambda_alias.alias]
}
