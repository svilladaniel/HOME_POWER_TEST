# VPC
resource "aws_vpc" "app_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  instance_tenancy = "default"
  enable_dns_support = true
  tags = {
    Name = "DevOps-Test-VPC"
  }
}

# Subred Pública
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Importante para asignar IP pública a la EC2
  availability_zone       = "us-east-1a"
  tags = {
    Name = "DevOps-Test-Public-Subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "DevOps-Test-IGW"
  }
}

# Tabla de Rutas para acceso a Internet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Asociación de la Tabla de Rutas a la Subred
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Creacion de las reglas del grupo de seguridad
resource "aws_security_group" "app_sg" {
  name        = "devops_app_sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  # Regla Inbound: Permitir tráfico HTTP (Puerto 80) desde cualquier lugar
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla Inbound: Permitir tráfico SSH (Puerto 22) - Opcional, para debug
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla Outbound: Permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "DevOps-Test-SG"
  }
}

# AMI de Amazon Linux 2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Script de User Data para instalar Docker y ejecutar el contenedor
locals {
  app_docker_image = "tu-repo-ecr/fastapi-app:latest" # Necesitas reemplazar esto con tu ECR
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro" # Capa gratuita
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

