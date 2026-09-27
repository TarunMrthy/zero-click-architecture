provider "aws" {
  region = "ap-south-1"
}

# Core Network (VPC)
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "zero-click-vpc"
  }
}

# Tier 1: Public Subnet (For Web Servers)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "public-presentation-tier"
  }
}

# Tier 2 & 3: Private Subnet (For App Logic & Database)
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "private-application-tier"
  }
}

# Internet Gateway (The door to the outside world)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "zero-click-igw"
  }
}

# Public Route Table (The map pointing to the door)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Link the Route Table to the Public Subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Web Server Firewall
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Incoming Web Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outgoing Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Find latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Tier 1 Web Server (EC2)
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Zero-Click Architecture: Tier 1 Web Server is Live!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "tier-1-web-server"
  }
}

# Output the Public IP so you can visit your website
output "web_server_public_ip" {
  value = aws_instance.web_server.public_ip
}



# Tier 2 Application Server Firewall
resource "aws_security_group" "app_sg" {
  name        = "app-server-sg"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description     = "Allow traffic ONLY from Tier 1 Web Server"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    description = "Outgoing Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Tier 2 Application Server (Private EC2)
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = false

  tags = {
    Name = "tier-2-app-server"
  }
}
