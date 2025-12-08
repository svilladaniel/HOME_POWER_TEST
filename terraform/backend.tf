# Se debe crear el bucket y Dynamo DB antes manualmente para el backend remoto

terraform {
  backend "s3" {
    bucket         = "terraform-state-devops-test-daniel"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
