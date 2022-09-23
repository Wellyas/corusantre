resource "aws_vpc" "sidera_cloud" {
  cidr_block = "10.137.0.0/16"

  enable_dns_hostnames = true

  tags = {
    Name  = "Sidera Cloud"
  }
}
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block = "10.201.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.sidera_cloud.id

  tags = {
    Name  = "SC Internet Gateway"
  }
}

resource "aws_subnet" "sc_portail" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block = "10.137.35.0/24"

  tags = {
    Name  = "Zone Portail"
  }
}


resource "aws_subnet" "sc_dmz" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block = "10.137.40.0/24"

  tags = {
    Name  = "Zone DMZ"
  }
}
resource "aws_route_table" "dmz" {
  vpc_id = aws_vpc.sidera_cloud.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Route to internet"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sc_dmz.id
  route_table_id = aws_route_table.dmz.id
}


resource "aws_subnet" "sc_siem" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block = "10.137.25.0/24"

  tags = {
    Name  = "Zone SIEM"
  }
}
resource "aws_subnet" "sc_access" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block        = cidrsubnet(aws_vpc.sidera_cloud.cidr_block, 12, 7)
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name  = "Zone Access"
  }
}
/* resource "aws_subnet" "sc_adm_portail" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block = "10.137.30.0/24"

  tags = {
    Name  = "Zone Portail ADM"
  }
} */
resource "aws_security_group" "sg_access" {
  name   = "ZoneAccess ACL"
  vpc_id = aws_vpc.sidera_cloud.id
  tags = {
    Name  = "Security Groupe - Access"
  }

  ingress {
    description = "TLS from Sidera"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpn_connection_route.admin.destination_cidr_block]
  }
  ingress {
    description = "TLS from Sidera"
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = [aws_vpn_connection_route.admin.destination_cidr_block]
  }
  ingress {
    description = "SSH from Sidera"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpn_connection_route.admin.destination_cidr_block]
  }
}

resource "aws_security_group" "sg_portail" {
  name   = "ZonePortail ACL"
  vpc_id = aws_vpc.sidera_cloud.id
  tags = {
    Name  = "Security Groupe - Portail"
  }

  ingress {
    description = "TLS from Sidera"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpn_connection_route.admin.destination_cidr_block]
  }
  ingress {
    description = "SSH from Sidera"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpn_connection_route.admin.destination_cidr_block]
  }
}
resource "aws_security_group" "sg_dmz" {
  name   = "ZoneDMZ ACL"
  vpc_id = aws_vpc.sidera_cloud.id
  tags = {
    Name  = "Security Groupe - DMZ"
  }

  ingress {
    description = "SSH from All"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 53
    to_port          = 53
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

/* resource "aws_security_group_rule" "sg_portail_ssh" {
  type              = "ingress"
  from_port         = 0
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.sg_portail.id

} */