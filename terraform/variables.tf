variable "AWS_REGION" {
  type        = string
  description = "AWS region"
}

variable "AWS_ACCESS_KEY_ID" {
  type        = string
  sensitive   = true
}

variable "AWS_SECRET_KEY" {
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
