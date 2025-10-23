resource "aws_vpc" "Innovatech-VPC" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "Innovatech-VPC"
  }
}

resource "aws_subnet" "Subnet_Web01" {
  vpc_id            = aws_vpc.Innovatech-VPC.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = var.zone1
  tags = {
    Name = "Subent_Web01"
  }
}

resource "aws_subnet" "Subnet_Web02" {
  vpc_id            = aws_vpc.Innovatech-VPC.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = var.zone2

  tags = {
    Name = "Subent_Web02"
  }
}


resource "aws_db_subnet_group" "db-subnet" {
  name       = "db-subnet"
  subnet_ids = [aws_subnet.Subnet_Web01.id, aws_subnet.Subnet_Web02.id]
}