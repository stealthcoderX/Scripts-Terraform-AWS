provider "aws" {
  region = "us-east-1"
}

# Minimal SG that actually allows SSH in
resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh"
  description = "Allow SSH inbound"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # You can restrict later if you want
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Fetch default VPC (so we don’t create anything new)
data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "my_instance" {
  ami                         = "ami-0360c520857e3138f"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [aws_security_group.ssh_access.id]
  key_name                    = "sarah-key-acc"
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git maven docker.io nginx python3-pip
    sudo systemctl enable docker --now
    sudo systemctl enable nginx --now

    sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
      | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt update
    sudo apt install -y jenkins
  EOF

  tags = {
    Name = "MyEC2Instance"
  }
}

output "instance_public_ip" {
  value = aws_instance.my_instance.public_ip
}
