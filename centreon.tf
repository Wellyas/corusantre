resource "aws_instance" "centreon" {
  ami                         = "ami-0eb3117f2ccc34ba6"
  instance_type               = "t3.small"
  vpc_security_group_ids      = [aws_security_group.sg_centreon.id,aws_security_group.sg_admin_from_wab.id]
  subnet_id                   = aws_subnet.sc_centreon.id
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = false

  tags = {
    Name = "sidawscencol01p"
  }
}


resource "aws_subnet" "sc_centreon" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block = cidrsubnet(data.aws_vpc.vpc.cidr_block, 12, 8)

  tags = {
    Name = "Zone Centreon"
  }
}


resource "aws_security_group" "sg_centreon" {
  name   = "Security Group Centreon"
  vpc_id = aws_vpc.sidera_cloud.id
  tags = {
    Name = "Security Groupe - Centreon "
  }

  
  ingress {
    description = "SSH from Sidera"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpn_connection_route.admin.destination_cidr_block]
  }
  egress {
    description = "TO SIDERA PORTAIL EXTERNE"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  egress {
    description = "TO SIDERA PORTAIL EXTERNE"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  egress {
    description = "TO SIDERA CENTREON MASTER"
    from_port   = 5669
    to_port     = 5669
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpn_connection_route.admin.destination_cidr_block
    ]
  }
}

resource "aws_route53_record" "centreon" {
  zone_id = aws_route53_zone.private.zone_id
  name    = aws_instance.centreon.tags.Name
  type    = "A"
  ttl     = 300
  records = [aws_instance.centreon.private_ip]
}


resource "aws_route53_record" "centreoncname" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "centreon"
  type    = "CNAME"
  ttl     = 300
  records = [
    aws_route53_record.centreon.fqdn,
  ]
}