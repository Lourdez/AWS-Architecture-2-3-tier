terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My-VPC"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "My-VPC-PU-SUB"
  }
}

resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "My-VPC-PRI-SUB"
  }
}

resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "MY-VPC-IGN"
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tigw.id
  }

  tags = {
    Name = "MY-VPC-PUB-RT"
  }
}

resource "aws_route_table_association" "pubrtasso" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}
# create an elastic ip for NAT 
resource "aws_eip" "myeip" {
  domain  = "vpc"
}
# create a NAT gaterway
resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "MY-VPC-NAT"
  }
}

resource "aws_route_table" "prirt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tnat.id
  }

  tags = {
    Name = "MY-VPC-Pri-RT"
  }
}

resource "aws_route_table_association" "prirtasso" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.prirt.id
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

    ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "MY-VPC-SG"
  } 
}
resource "aws_instance" "PublicInstance" {
  ami                         = "ami-02a2af70a66af6dfb"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.pubsub.id
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  key_name                    = "zenclass"
  associate_public_ip_address  = true
}

resource "aws_instance" "privateinstance" {
  ami                         = "ami-02a2af70a66af6dfb"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.prisub.id
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  key_name                    = "zenclass"
}
