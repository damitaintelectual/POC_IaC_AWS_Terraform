## Initialize terraform provider and backed to terraform.tfstate file
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = "1.0.7"

  backend "s3" {
    encrypt = true
    bucket = "terraform-s3-backup"
    key    = "tfstate/terraform.tfstate"
    region = "us-east-1"
  }
}


provider "aws" {
  profile = "default"
  region  = "${var.region}"
}

## Resources
# Vpc
resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main_vpc"
    Environment = "${var.env_tag}"
  }
  enable_dns_hostnames = true
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone_id = "use1-az2" // us-east-1a

  tags = {
    Name = "public_subnet_1"
    Environment = "${var.env_tag}"
  }
  map_public_ip_on_launch = true
}

# Private subnet
resource "aws_subnet" "private_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.2.0/24"
  availability_zone_id = "use1-az4" // us-east-1b

  tags = {
    Name = "private_subnet_1"
    Environment = "${var.env_tag}"
  }
}

# Internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "internet_gateway_1"
    Environment = "${var.env_tag}"
  }
}

# Public route table with target as internet gateway
resource "aws_route_table" "rt_igw" {
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.internet_gateway,
  ]

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "route_table_igw_1"
    Environment = "${var.env_tag}"
  }
}

# Associate route table to public subnet
resource "aws_route_table_association" "associate_routetable_to_public_subnet" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_route_table.rt_igw,
  ]
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt_igw.id
}

# Elastic ip
resource "aws_eip" "elastic_ip" {
  vpc      = true

  tags = {
    Name = "elastic_ip_1"
    Environment = "${var.env_tag}"
  }
}

# NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_eip.elastic_ip,
  ]

  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat_gateway_1"
    Environment = "${var.env_tag}"
  }
}

# Bastion host security group
resource "aws_security_group" "bastion_sg" {
  depends_on = [
    aws_vpc.vpc,
  ]
  name        = "bastion-host-sg"
  description = "bastion host security group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "allow SSH"
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
}

# Bastion host ec2 instance
resource "aws_instance" "bastion_host" {
  depends_on = [
    aws_security_group.bastion_sg,
  ]
  ami = "ami-0747bdcabd34c712a"
  instance_type = "t2.micro"
  key_name = "bastionhost1"
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id = aws_subnet.public_subnet.id
  
  tags = {
    Name = "Bastion_Host_1"
    Environment = "${var.env_tag}"
  }
}

# Web host security group
resource "aws_security_group" "web_host_sg" {
  depends_on = [
    aws_vpc.vpc,
  ]

  name        = "web-host-sg"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] // only permit ssh connection fron bastion host
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Web server nginx instance
resource "aws_instance" "web-host" {
  depends_on = [
    aws_security_group.web_host_sg
  ]
  ami = "ami-0747bdcabd34c712a"
  instance_type = "t2.micro"
  key_name = "webhost1"
  vpc_security_group_ids = [aws_security_group.web_host_sg.id]
  subnet_id = aws_subnet.public_subnet.id
  user_data = "${file("install_nginx.sh")}"

  tags = {
    Name = "Web_Host_1"
    Environment = "${var.env_tag}"
  }
}