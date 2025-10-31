provider "aws" {
  region = "us-east-1"
}

#create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}
# Create Subnet 
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "MySubnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "MyIGW"
  }
}

# Create  Route Table
resource "aws_route_table" "my_rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name = "MyRouteTable"
  }
}

# Route Table Association
resource "aws_route_table_association" "my_rta" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_rt.id
}

# Create a Security Group
resource "aws_security_group" "my_sg" {
  name        = "MySecurityGroup"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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

# EC2 Instance Creation
resource "aws_instance" "my_instance" {
  ami                         = "ami-0360c520857e3138f"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.my_subnet.id
  vpc_security_group_ids      = [aws_security_group.my_sg.id]
  key_name                    = "sarah-key-acc.pem"
  associate_public_ip_address = true
  user_data                   = <<-EOF
                #!/bin/bash
                sudo apt update && sudo apt upgrade -y
                sudo apt install git maven
                sudo apt install docker.io
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo apt install nginx -y
                sudo systemctl enable nginx
                sudo systemctl start nginx
                sudo apt install python3-pip -y
                
                openjdk 21.0.8 2025-07-15
                OpenJDK Runtime Environment (build 21.0.8+9-Debian-1)
                OpenJDK 64-Bit Server VM (build 21.0.8+9-Debian-1, mixed mode, sharing)
                
                sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
                https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
                echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
                https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null
                sudo apt update
                sudo apt install jenkins
                EOF
  tags = {
    Name = "MyEC2Instance"
  }

}
