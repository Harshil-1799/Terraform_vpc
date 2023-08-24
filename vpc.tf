# Provider configuration
#terraform {
#    required_providers {
#        aws = {
#            source  = "hashicorp/aws"
#            version = "~> 4.0"
#        }
#    }
#}
provider   "aws" {
  region = "ap-south-1"
  access_key = "AKIAXBEBFT3D66J3RD2W"
  secret_key = "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"
}

# Create VPC
resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16" 

  tags = {
    Name = "test-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "test-igw"
  }
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "10.0.1.0/24" 
  availability_zone       = "ap-south-1a" 
  map_public_ip_on_launch = true  
  tags = {
    Name = "public-subnet"
  }
}

# Create Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "10.0.2.0/24"  
  availability_zone       = "ap-south-1a"  

  tags = {
    Name = "private-subnet"
  }
}
# Nat Gateway
resource "aws_nat_gateway" "test_ngw" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.private_subnet.id
}
# Create Route Table for Public Subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Create Route Table for Private Subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.test_vpc.id

  route  {
    cidr_block = "0.0.0.0/0"	
    gateway_id = aws_nat_gateway.test_ngw.id
  }	
  tags = {
    Name = "private-route-table"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# Create Security Group for EC2 Instances
resource "aws_security_group" "test_sg" {
  vpc_id = aws_vpc.test_vpc.id

  ingress {
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
    Name = "example-security-group"
  }
}
# Create Key
resource "aws_key_pair" "Newkey-vpc" {
  key_name   = "Newkey-vpc"
  public_key = file("./id_rsa.pub")
}

# Create EC2 Instance in Public Subnet
resource "aws_instance" "public_instance" {
  ami           = "ami-0f5ee92e2d63afc18" 
  instance_type = "t2.micro"              
  subnet_id     = aws_subnet.public_subnet.id

  key_name               = aws_key_pair.Newkey-vpc.key_name
  vpc_security_group_ids = [aws_security_group.test_sg.id]

  tags = {
    Name = "public-instance"
  }
}

# Create EC2 Instance in Private Subnet
resource "aws_instance" "private_instance" {
  ami           = "ami-0f5ee92e2d63afc18" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id

  key_name               = aws_key_pair.Newkey-vpc.key_name
  vpc_security_group_ids = [aws_security_group.test_sg.id]

  tags = {
    Name = "private-instance"
  }
}
