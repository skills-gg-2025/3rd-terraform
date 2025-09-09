# VPC
resource "aws_vpc" "apdev_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "apdev-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "apdev_igw" {
  vpc_id = aws_vpc.apdev_vpc.id

  tags = {
    Name = "apdev-igw"
  }
}

# Public Subnets
resource "aws_subnet" "apdev_public_subnet_a" {
  vpc_id                  = aws_vpc.apdev_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "apdev-public-subnet-a"
  }
}

resource "aws_subnet" "apdev_public_subnet_b" {
  vpc_id                  = aws_vpc.apdev_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "apdev-public-subnet-b"
  }
}

# Private Subnets
resource "aws_subnet" "apdev_private_subnet_a" {
  vpc_id            = aws_vpc.apdev_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "apdev-private-subnet-a"
  }
}

resource "aws_subnet" "apdev_private_subnet_b" {
  vpc_id            = aws_vpc.apdev_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "apdev-private-subnet-b"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "apdev_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "apdev-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "apdev_nat" {
  allocation_id = aws_eip.apdev_nat_eip.id
  subnet_id     = aws_subnet.apdev_public_subnet_a.id

  tags = {
    Name = "apdev-nat"
  }

  depends_on = [aws_internet_gateway.apdev_igw]
}

# Public Route Table
resource "aws_route_table" "apdev_public_rt" {
  vpc_id = aws_vpc.apdev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.apdev_igw.id
  }

  tags = {
    Name = "apdev-public-rt"
  }
}

# Private Route Table
resource "aws_route_table" "apdev_private_rt" {
  vpc_id = aws_vpc.apdev_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.apdev_nat.id
  }

  tags = {
    Name = "apdev-private-rt"
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "apdev_public_rta_a" {
  subnet_id      = aws_subnet.apdev_public_subnet_a.id
  route_table_id = aws_route_table.apdev_public_rt.id
}

resource "aws_route_table_association" "apdev_public_rta_b" {
  subnet_id      = aws_subnet.apdev_public_subnet_b.id
  route_table_id = aws_route_table.apdev_public_rt.id
}

# Private Route Table Associations
resource "aws_route_table_association" "apdev_private_rta_a" {
  subnet_id      = aws_subnet.apdev_private_subnet_a.id
  route_table_id = aws_route_table.apdev_private_rt.id
}

resource "aws_route_table_association" "apdev_private_rta_b" {
  subnet_id      = aws_subnet.apdev_private_subnet_b.id
  route_table_id = aws_route_table.apdev_private_rt.id
}