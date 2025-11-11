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

variable "jwt_secret_key" {
  description = "JWT Secret"
  type        = string
  sensitive   = true
}

variable "smtp_username" {
  description = "SMTP Username"
  type        = string
  sensitive   = true
}

variable "smtp_password" {
  description = "SMTP Password"
  type        = string
  sensitive   = true
}

variable "stripe_secret_key" {
  description = "Stripe Secret Key"
  type        = string
  sensitive   = true
}

variable "os_type" {
  type    = string
  default = "windows"
}


# --- Lee tu llave pública local ---
# Cambia la ruta si tu llave no está en ~/.ssh/id_rsa.pub
resource "aws_key_pair" "local_key" {
  key_name   = "mi-llave-local"
  public_key = file("~/.ssh/id_rsa.pub")
}

# --- Grupo de seguridad ---
resource "aws_security_group" "mysql_sg" {
  name        = "ubuntu-mysql-sg"
  description = "Allow SSH and MySQL"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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

# --- Instancia EC2 Ubuntu con MySQL ---
resource "aws_instance" "ubuntu_mysql" {
  ami                    = "ami-053b0d53c279acc90" # Ubuntu 22.04 LTS (us-east-1)
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.local_key.key_name
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]

  tags = {
    Name = "ubuntu-mysql"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Actualizar e instalar MySQL
    apt-get update -y
    apt-get install -y mysql-server

    systemctl enable mysql
    systemctl start mysql

    # Configurar MySQL
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES;"
    mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS hamar_db;"

    # Permitir conexión remota (usuario root accesible desde cualquier IP)
    mysql -u root -proot -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'root';"
    mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
    mysql -u root -proot -e "FLUSH PRIVILEGES;"

    # Permitir conexiones externas
    sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
    systemctl restart mysql
  EOF
}

# --- Grupo de seguridad para Nginx ---
resource "aws_security_group" "nginx_sg" {
  name        = "ubuntu-nginx-sg"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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

# --- Instancia EC2 con Nginx ---
resource "aws_instance" "ubuntu_nginx" {
  ami                    = "ami-053b0d53c279acc90" # Ubuntu 22.04 LTS (us-east-1)
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.local_key.key_name
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  tags = {
    Name = "ubuntu-nginx"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx

    echo "<h1>Servidor Nginx listo</h1>" > /var/www/html/index.html
  EOF
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Instancia Ubuntu con Java y Maven ---
resource "aws_instance" "ubuntu_spring" {
  ami                    = "ami-053b0d53c279acc90"
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
    apt-get install -y openjdk-21-jdk maven build-essential git

    java -version
    mvn -v

    echo "JWT_SECRET_KEY=${var.jwt_secret_key}" | sudo tee -a /etc/environment
    echo "SMTP_USERNAME=${var.smtp_username}" | sudo tee -a /etc/environment
    echo "SMTP_PASSWORD=${var.smtp_password}" | sudo tee -a /etc/environment
    echo "SPRING_DATASOURCE_URL=jdbc:mysql://${aws_instance.ubuntu_mysql.public_ip}:3306/hamar_db" | sudo tee -a /etc/environment
    echo "SPRING_DATASOURCE_USERNAME=root" | sudo tee -a /etc/environment
    echo "SPRING_DATASOURCE_PASSWORD=root" | sudo tee -a /etc/environment
    echo "STRIPE_SECRET_KEY=${var.stripe_secret_key}" | sudo tee -a /etc/environment

    echo "✅ Entorno Spring Boot listo. Sube tu proyecto con SCP o Git."
  EOF
}

# Scripts de deploy
resource "null_resource" "deploy_backend" {
  provisioner "local-exec" {
    command = var.os_type == "windows" ? "bash scripts/backend.sh ${aws_instance.ubuntu_nginx.public_ip} ${aws_instance.ubuntu_spring.public_ip} %USERPROFILE%\\.ssh\\id_rsa" : "bash scripts/backend.sh ${aws_instance.ubuntu_nginx.public_ip} ${aws_instance.ubuntu_spring.public_ip} ~/.ssh/id_rsa"
  }

  depends_on = [
    aws_instance.ubuntu_spring,
    aws_instance.ubuntu_nginx
  ]
}

resource "null_resource" "deploy_frontend" {
  provisioner "local-exec" {
    command = var.os_type == "windows" ? "bash scripts/frontend.sh ${aws_instance.ubuntu_nginx.public_ip} ${aws_instance.ubuntu_spring.public_ip} %USERPROFILE%\\.ssh\\id_rsa" : "bash scripts/frontend.sh ${aws_instance.ubuntu_nginx.public_ip} ${aws_instance.ubuntu_spring.public_ip} ~/.ssh/id_rsa"
  }

  depends_on = [
    aws_instance.ubuntu_spring,
    aws_instance.ubuntu_nginx
  ]
}

# --- Outputs ---
output "mysql_ip" {
  description = "IP pública de la instancia MySQL"
  value       = aws_instance.ubuntu_mysql.public_ip
}

output "nginx_ip" {
  description = "IP pública de la instancia Nginx"
  value       = aws_instance.ubuntu_nginx.public_ip
}

output "springboot_ip" {
  description = "IP pública de la instancia para Spring Boot"
  value       = aws_instance.ubuntu_spring.public_ip
}
