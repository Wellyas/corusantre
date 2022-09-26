data "aws_vpc" "vpc" {
 id = var.vpc_id 
}

data "aws_availability_zones" "zone" {
  state = "available"
}

resource "aws_subnet" "sc_kasm_db" {
  vpc_id     = data.aws_vpc.vpc.id
  count = 2
  private_dns_hostname_type_on_launch = "resource-name"
  availability_zone = data.aws_availability_zones.zone.names[count.index]
  cidr_block        = cidrsubnet(data.aws_vpc.vpc.cidr_block, 12, count.index+9)

  tags = {
    Name  = "Zone Kasmweb DB ${data.aws_availability_zones.zone.names[count.index]}"
  }
}
resource "aws_subnet" "sc_kasm_lb" {
  vpc_id     = data.aws_vpc.vpc.id
  count = 2
  private_dns_hostname_type_on_launch = "resource-name"
  availability_zone = data.aws_availability_zones.zone.names[count.index]
  cidr_block        = cidrsubnet(data.aws_vpc.vpc.cidr_block, 12, count.index+11)

  tags = {
    Name  = "Zone Kasmweb LB ${data.aws_availability_zones.zone.names[count.index]}"
  }
}
resource "aws_subnet" "sc_kasm_web" {
  vpc_id     = data.aws_vpc.vpc.id
  cidr_block        = cidrsubnet(data.aws_vpc.vpc.cidr_block, 12, 2)
  map_public_ip_on_launch = true

  tags = {
    Name  = "Zone Kasmweb Web"
  }
}
resource "aws_subnet" "sc_kasm_agent" {
  vpc_id     = data.aws_vpc.vpc.id
  cidr_block        = cidrsubnet(data.aws_vpc.vpc.cidr_block, 12, 3)

  tags = {
    Name  = "Zone Kaswmeb Agent"
  }
}
resource "aws_subnet" "sc_kasm_pub" {
  vpc_id     = data.aws_vpc.vpc.id
  cidr_block        = cidrsubnet(data.aws_vpc.vpc.cidr_block, 12, 4)

  tags = {
    Name  = "Zone Kaswmeb Public"
  }
}

resource "aws_route_table" "dmz" {
  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = {
    Name = "Kasmweb Route to internet"
  }
}
resource "aws_vpn_gateway_route_propagation" "vpnoam" {
  count = var.vpn_fw_oam != "" ? 1 : 0 
  vpn_gateway_id = var.vpn_fw_oam
  route_table_id = aws_route_table.dmz.id
}
resource "aws_vpn_gateway_route_propagation" "vpn" {
  count = var.vpn_fw_oam != "" ? 1 : 0 
  vpn_gateway_id = var.vpn_fw_oam
  route_table_id = aws_route_table.r.id
}

resource "aws_route_table_association" "ks_sagent" {
  subnet_id      = aws_subnet.sc_kasm_agent.id
  #route_table_id = aws_route_table.dmz.id
  route_table_id = aws_route_table.r.id
}
resource "aws_route_table_association" "ks_sweb" {
  subnet_id      = aws_subnet.sc_kasm_web.id
  route_table_id = aws_route_table.dmz.id
}

resource "aws_route_table_association" "ks_spub" {
  subnet_id      = aws_subnet.sc_kasm_pub.id
  route_table_id = aws_route_table.dmz.id
  //route_table_id = aws_route_table.r.id
}
resource "aws_route_table_association" "ks_lb" {
  count = length(aws_subnet.sc_kasm_lb)
  subnet_id      = aws_subnet.sc_kasm_lb.*.id
  route_table_id = aws_route_table.dmz.id
  //route_table_id = aws_route_table.r.id
}

resource "aws_db_subnet_group" "kasmdb" {
  name       = "kasmdb"
  subnet_ids = aws_subnet.sc_kasm_db.*.id

  tags = {
    Name = "DB Subnet Kasmweb"
  }
}

resource "aws_elasticache_subnet_group" "kasm_subnet_group" {
  name       = "tf-kasmweb-cache-subnet"
  subnet_ids = aws_subnet.sc_kasm_db.*.id
  tags = {
    Name = "Redis Subnet Kasmweb"
  }
}