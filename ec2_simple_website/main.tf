provider "aws" {
  region = "us-east-1"  # Change to your preferred AWS region
}

# Create a custom VPC:
resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
  tags = {
    Name = "CustomVPC"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Enable public IP for instances in this subnet
}

# Create an Internet Gateway for public access
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "InternetGateway"
  }
}

# Create a route table for the VPC
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate the subnet with the route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a security group for the web server
resource "aws_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Allow HTTP, SSH, and custom ports"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH (change this for security)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP
  }
  # Allow HTTPS access from anywhere
   ingress {
      from_port   = 443
      to_port     = 443
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

# Create an EC2 instance in the new VPC and subnet
resource "aws_instance" "web" {
  ami             = "ami-05b10e08d247fb927"  # Amazon Linux 2 AMI (change as needed)
  instance_type   = "t2.micro"
  key_name        = "my-new-key"  # Change to your key pair name
  subnet_id       = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = file("setup.sh")

  tags = {
    Name = "TerraformWebServer"
  }
}

# Output the instance public IP
output "public_ip" {
  value = aws_instance.web.public_ip

}
output "public_dns" {
  value = aws_instance.web.public_dns

}