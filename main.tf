###############################
#        Provider Block       #
###############################

# Provider Block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "local" {}

provider "tls" {}

###############################
#          Variables          #
###############################

# Change this to add a Prefix that explains whatever you're testing
variable "prefix" {
  default = "matt-eks-test"
}

variable "region" {
  default = "us-east-1"
}

variable "az" {
  default = "us-east-1a"
}

###############################
#        Local SSH Key        #
###############################

# Creates RSA 4096-encrypted key pair
resource "tls_private_key" "key" {
  algorithm   = "RSA"
  ecdsa_curve = "4096"
}

# Saves the private .pem file locally
resource "local_file" "key" {
  filename        = "${var.prefix}-key.pem"
  file_permission = 0400
  content         = tls_private_key.key.private_key_pem
}

# Provides Public key to the Web Server EC2 instance
resource "aws_key_pair" "key" {
  key_name   = "${var.prefix}-key"
  public_key = tls_private_key.key.public_key_openssh
}

###############################
#             VPC             #
###############################

# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = var.az

  tags = {
    Name = "${var.prefix}-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prefix}_igw"
  }
}

# Provides Route Table for Public Subnet
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.prefix}_pub_rt"
  }
}

# Associates Public Subnet with the Public Route Table
resource "aws_route_table_association" "pub_sub1_rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.pub_rt.id
}

# Provides Security Group for Public SSH Access
resource "aws_security_group" "pub_ssh_sg" {
  name        = "ssh_access_public"
  description = "Allows SSH access from the public internet"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "SSH port 22 from public internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description      = "SSH port 22 to public internet"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "public_ssh_access_sg"
  }
}

###############################
#             EC2             #
###############################

# EC2 Instance
resource "aws_instance" "web" {
  ami                         = "ami-0a22e6228541105a0"
  subnet_id                   = aws_subnet.public.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  key_name = aws_key_pair.web.key_name
  vpc_security_group_ids = [
    aws_security_group.pub_ssh_sg.id
  ]

  ebs_block_device {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = "25"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install vim -y
    EOF

  tags = {
    Name = "${var.prefix}-ec2"
  }
}

###############################
#           Outputs           #
###############################
output "ssh" {
  value = "ssh -i ${local_file.web.filename} ec2-user@${aws_instance.web.public_ip}"
}