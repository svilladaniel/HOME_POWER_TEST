variable "region" {
  type        = string
  description = "AWS region"
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda function name"
  default     = "powertest_api"
}

variable "lambda_zip_path" {
  type        = string
  description = "Path to lambda zip file"
}

variable "environment" {
  type        = string
  description = "Environment name: dev or main"
}
