resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.sc_dmz.id

  tags = {
    Name = "GW NAT sidera"
  }

}

resource "aws_eip" "nat_gateway_eip" {
  vpc = true
}

resource "aws_route_table" "natgw" {
  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }
}