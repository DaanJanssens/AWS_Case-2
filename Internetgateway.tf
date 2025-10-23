resource "aws_internet_gateway" "Innovatech-igw" {
  vpc_id = aws_vpc.Innovatech-VPC.id
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.Innovatech-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Innovatech-igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Subnet_Web01.id
  route_table_id = aws_route_table.public-rt.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.Subnet_Web02.id
  route_table_id = aws_route_table.public-rt.id
}