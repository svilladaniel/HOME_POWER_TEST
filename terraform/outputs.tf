output "api_url" {
  description = "Invoke URL of the API"
  value       = aws_apigatewayv2_stage.stage.invoke_url
}