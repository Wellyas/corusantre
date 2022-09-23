resource "aws_route53_zone" "private" {
  name = "aws.csoc.thales"

  vpc {
    vpc_id = aws_vpc.sidera_cloud.id
  }
}
resource "aws_subnet" "sc_dns1" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block        = cidrsubnet(aws_vpc.sidera_cloud.cidr_block, 12, 5)
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name  = "Zone DNS 1"
  }
}
resource "aws_subnet" "sc_dns2" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block        = cidrsubnet(aws_vpc.sidera_cloud.cidr_block, 12, 6)
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name  = "Zone DNS 2"
  }
}

resource "aws_route53_record" "ns" {
  zone_id = aws_route53_zone.private.zone_id
  count = length(aws_route53_resolver_endpoint.dns.ip_address)
  name    = "ns${count.index+1}.${aws_route53_zone.private.name}"
  type    = "A"
  ttl     = 30
  records = aws_route53_resolver_endpoint.dns.ip_address.*.ip
}

resource "aws_route53_record" "aws" {
  allow_overwrite = true
  name            = aws_route53_zone.private.name
  ttl             = 172800
  type            = "NS"
  zone_id      = aws_route53_zone.private.zone_id

  records = aws_route53_record.ns.*.name

}

resource "aws_security_group" "sg_dns" {
  name   = "ZoneDNS ACL"
  vpc_id = aws_vpc.sidera_cloud.id
  tags = {
    Name  = "Security Groupe - DNS"
  }

  ingress {
    description = "TLS from Sidera"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [aws_vpn_connection_route.admin.destination_cidr_block]
  }
  ingress {
    description = "TLS from Sidera"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [aws_vpn_connection_route.admin.destination_cidr_block]
  }
}
resource "aws_route53_resolver_endpoint" "dns" {
  name      = "sidera-aws-dns"
  direction = "INBOUND"

  security_group_ids = [
    aws_security_group.sg_dns.id,
  ]

  ip_address {
    subnet_id = aws_subnet.sc_dns1.id
  }
  ip_address {
    subnet_id = aws_subnet.sc_dns2.id
  }


}

output "dns_privates_ns" {
  value = aws_route53_resolver_endpoint.dns.ip_address.*.ip
  
}