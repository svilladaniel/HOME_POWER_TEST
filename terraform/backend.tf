terraform {
  backend "s3" {
    bucket         = "terraform-state-devops-test-daniel"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
