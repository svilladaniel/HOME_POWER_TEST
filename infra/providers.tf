terraform {

    # Declaración uso de proveedores

    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "6.17.0"
        }
    }
}

# AWS Provider configuration

provider "aws" {

    # Configuration options

    region= "${var.AWS_REGION}"
    access_key = "${var.AWS_ACCESS_KEY_ID}"
    secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
}