terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --- Lee tu llave pública local ---
# Cambia la ruta si tu llave no está en ~/.ssh/id_rsa.pub
resource "aws_key_pair" "local_key" {
  key_name   = "mi-llave-local"
  public_key = file("~/.ssh/id_rsa.pub")
}

# --- Grupo de seguridad para Spring Boot ---
resource "aws_security_group" "spring_sg" {
  name        = "ubuntu-spring-sg"
  description = "Allow SSH and app ports"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Spring Boot default port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Instancia Ubuntu con Java y Maven ---
resource "aws_instance" "ubuntu_spring" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.local_key.key_name
  vpc_security_group_ids = [aws_security_group.spring_sg.id]

  tags = {
    Name = "ubuntu-springboot"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y git 
    # agregar docker
    # clonar repo
    # inicializar docker-compose

    echo "✅ Entorno Spring Boot listo. Sube tu proyecto con SCP o Git."
  EOF
}

# --- Outputs ---
output "springboot_ip" {
  description = "IP pública de la instancia para Spring Boot"
  value       = aws_instance.ubuntu_spring.public_ip
}
