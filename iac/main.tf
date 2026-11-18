terraform {
  required_providers {
    aws   = { source = "hashicorp/aws", version = "~> 5.0" }
    local = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

variable "region" {
  default = "us-east-1"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "instance_type" {
  default = "t3.small"
}

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "avaliacao" {
  key_name   = "avaliacao-cursos"
  public_key = file(pathexpand(var.public_key_path))
}

resource "aws_security_group" "avaliacao" {
  name        = "avaliacao-cursos-sg"
  description = "SSH, HTTP e API"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP (VM1)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "API (VM2)"
    from_port   = 3000
    to_port     = 3000
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

resource "aws_instance" "vm1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.avaliacao.key_name
  vpc_security_group_ids = [aws_security_group.avaliacao.id]
  user_data              = file("${path.module}/cloud_init.yaml")
  tags                   = { Name = "vm1-app-web" }
}

resource "aws_instance" "vm2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.avaliacao.key_name
  vpc_security_group_ids = [aws_security_group.avaliacao.id]
  user_data              = file("${path.module}/cloud_init.yaml")
  tags                   = { Name = "vm2-api-banco" }
}

# Gera automaticamente o inventário do Ansible com os IPs criados
resource "local_file" "inventory" {
  filename = "${path.module}/../ansible/inventory"
  content  = <<-INV
    [vm1]
    vm1 ansible_host=${aws_instance.vm1.public_ip}

    [vm2]
    vm2 ansible_host=${aws_instance.vm2.public_ip}

    [all:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${var.private_key_path}
    ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  INV
}

output "vm1_ip" {
  value = aws_instance.vm1.public_ip
}

output "vm2_ip" {
  value = aws_instance.vm2.public_ip
}

output "url_aplicacao" {
  value = "http://${aws_instance.vm1.public_ip}"
}
