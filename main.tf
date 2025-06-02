# Terraform configuration for AWS infrastructure consisiting of a VPC, public and private subnets, NAT Gateway, Jumpbox, and a private instance.

terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
}

provider "aws" {
    region = var.aws_region
    default_tags {
        tags = {
            Project = "sdm-hwrk"
            Environment = "development"
        }
    } 
}

data "aws_ami" "linux_ami" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

# AWS VPC

resource "aws_vpc" "sdm-hwrk-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "sdm-hwrk-vpc"
    }
}

# Publc subnet and Internet Gateway configuration

resource "aws_internet_gateway" "sdm_hwrk_ig" {
  vpc_id = aws_vpc.sdm-hwrk-vpc.id
  tags = {
    Name = "sdm-hwrk-ig"
  }
}

resource "aws_subnet" "public_subnet" {
  cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.sdm-hwrk-vpc.id
  availability_zone = "us-east-1a"
  tags = {
    Name = "sdm-hwrk-public-subnet"
  }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.sdm-hwrk-vpc.id
    tags = {
        Name = "sdm-hwrk-public-route-table"
    }
}

resource "aws_route_table_association" "public_route_table_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route" "public_route" {
    route_table_id = aws_route_table.public_route_table.id
    # This route allows outbound internet access from the public subnet
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sdm_hwrk_ig.id
}

# Private subnet and NAT Gateway configuration

resource "aws_subnet" "private_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.sdm-hwrk-vpc.id
  availability_zone = "us-east-1a"
  tags = {
    Name = "sdm-hwrk-private-subnet"
  }
}

resource "aws_eip" "sdm_hwrk_eip_nat" {
    tags = {
        Name = "sdm-hwrk-eip-nat"
    }
}

resource "aws_nat_gateway" "sdm_hwrk_ng" {
    subnet_id = aws_subnet.private_subnet.id
    allocation_id = aws_eip.sdm_hwrk_eip_nat.id
    tags = {
        Name = "sdm-hwrk-ng"
    }
}

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.sdm-hwrk-vpc.id
    tags = {
        Name = "sdm-hwrk-private-route-table"
    }
}

resource "aws_route_table_association" "private_route_table_association" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route" "private_route" {
    route_table_id = aws_route_table.private_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sdm_hwrk_ng.id
}

# Jumpbox configuration

resource "aws_key_pair" "sdm-hwrk_key" {
    key_name   = "sdm-hwrk-key"
    public_key = file("~/.ssh/arpi.pub")
    tags = {
        Name = "sdm-hwrk-key"
    }
}

resource "aws_security_group" "jumpbox_sg" {
    vpc_id = aws_vpc.sdm-hwrk-vpc.id
    name = "sdm-hwrk-jumpbox-sg"
    description = "Security group for the jumpbox instance"
    
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow SSH access"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }
    tags = {
        Name = "sdm-hwrk-jumpbox-sg"
    }
}

resource "aws_eip" "jumpbox_eip" {
    tags = {
        Name = "sdm-hwrk-jumpbox-eip"
    } 
}

resource "aws_instance" "jumpbox" {
    ami =  data.aws_ami.linux_ami.id
    associate_public_ip_address = true
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet.id
    security_groups =  [aws_security_group.jumpbox_sg.id]
    key_name = aws_key_pair.sdm-hwrk_key.key_name
    tags = {
        Name = "sdm-hwrk-jumpbox"
    }
}

resource "aws_eip_association" "jumpbox_eip_association" {
    instance_id = aws_instance.jumpbox.id
    allocation_id = aws_eip.jumpbox_eip.id
}

# Private instance configuration

resource "aws_security_group" "private_sg" {
    vpc_id = aws_vpc.sdm-hwrk-vpc.id
    name = "sdm-hwrk-private-sg"
    description = "Security group for private instances"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.jumpbox_sg.id] # Allow SSH from the jumpbox
        description = "Allow SSH access from jumpbox"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }
    tags = {
        Name = "sdm-hwrk-private-sg"
    }
}

resource "aws_instance" "private_instance" {
    ami = data.aws_ami.linux_ami.id
    associate_public_ip_address = false
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private_subnet.id
    security_groups =  [aws_security_group.private_sg.id]
    key_name = aws_key_pair.sdm-hwrk_key.key_name

    tags = {
        Name = "sdm-hwrk-private-instance"
    }
}
