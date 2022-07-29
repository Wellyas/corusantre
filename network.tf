resource "aws_vpc" "sidera_cloud" {
  cidr_block = "10.137.0.0/16"

  enable_dns_hostnames = true

  tags = {
    Name  = "Sidera Cloud"
    Owner = "Taleb E."
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.sidera_cloud.id

  tags = {
    Name = "SC Internet Gateway"
    Owner = "Taleb E."
  }
}

resource "aws_subnet" "sc_portail" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block = "10.137.30.0/24"

  tags = {
    Name  = "Zone Portail"
    Owner = "Taleb E."
  }
}

resource "aws_subnet" "sc_dmz" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block = "10.137.40.0/24"

  tags = {
    Name  = "Zone DMZ"
    Owner = "Taleb E."
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
    Owner = "Taleb E."
  }
}

/* resource "aws_subnet" "sc_adm_portail" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block = "10.137.30.0/24"

  tags = {
    Name  = "Zone Portail ADM"
    Owner = "Taleb E."
  }
} */

resource "aws_security_group" "sg_portail" {
  name = "ZonePortail ACL"
  vpc_id = aws_vpc.sidera_cloud.id
  tags = {
    Name  = "Security Groupe - Portail"
    Owner = "Taleb E."
  }

  ingress {
    description      = "TLS from Sidera"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpn_connection_route.admin.destination_cidr_block]
  }
  ingress {
    description      = "SSH from Sidera"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpn_connection_route.admin.destination_cidr_block]
  }

}
resource "aws_security_group" "sg_dmz" {
  name = "ZoneDMZ ACL"
  vpc_id = aws_vpc.sidera_cloud.id
  tags = {
    Name  = "Security Groupe - DMZ"
    Owner = "Taleb E."
  }

  ingress {
    description      = "SSH from All"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
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