# AWS SP - São Paulo
variable "aws_sp" {
  type        = string
  description = "AWS SP"
  default     = "sa-east-1a"
}

# Variáveis da VPC
variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
  default     = "10.1.64.0/18"
}

# Variáveis da Sub rede
variable "public_subnet_cidr" {
  type        = string
  description = "CIDR for the public subnet"
  default     = "10.1.64.0/24"
}

# Criando a VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
}

# Definindo a rede pública
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.aws_sp
}

# Definindo o gateway de internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}

# Defininco a tabela de rota pública
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Atribuir a tabela de rotas públicas à sub-rede pública
resource "aws_route_table_association" "public-rt-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

# Debian 11 Bullseye
data "aws_ami" "debian-11" {
  most_recent = true
  owners = ["136693071363"]
  filter {
    name   = "name"
    values = ["debian-11-amd64-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

variable "key_name" {
    default = "" # copiar da aws console
}

resource "aws_security_group" "permitir_ssh" {
  name        = "enable-ssh"
  description = "Permite SSH na instancia EC2"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH to EC2"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "enable-ssh"
  }
}

resource "aws_instance" "webserver1" {
  ami           = data.aws_ami.debian-11.id
  instance_type = "t2.micro"
  key_name      = var.key_name
  subnet_id     = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.permitir_ssh.id]
  associate_public_ip_address = true

  tags = {
    Name = "webserver1"
  }
}

resource "aws_instance" "webserver2" {
  ami           = data.aws_ami.debian-11.id
  instance_type = "t2.micro"
  key_name      = var.key_name
  subnet_id     = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.permitir_ssh.id]
  associate_public_ip_address = true

  tags = {
    Name = "webserver2"
  }
}