# Terraform configuration for AWS infrastructure consisiting of a VPC, public and private subnets, NAT Gateway, Jumpbox, and a private instance.


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
    subnet_id = aws_subnet.public_subnet.id
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

