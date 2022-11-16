resource "aws_instance" "centreon" {
  ami                         = "ami-0eb3117f2ccc34ba6"
  instance_type               = "t3.small"
  vpc_security_group_ids      = [aws_security_group.sg_centreon.id,aws_security_group.sg_admin_from_wab.id]
  subnet_id                   = aws_subnet.sc_centreon.id
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = false


  user_data_replace_on_change = true
  user_data = <<-EOF
#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
  yum install -y http://yum.centreon.com/standard/19.10/el7/stable/noarch/RPMS/centreon-release-19.10-1.el7.centos.noarch.rpm 
  yum install -y centreon-poller-centreon-engine
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxk6So6/0jIQ/pnq38lyXF9PZ7QKAW9RJCk5OA60ERYJlqIdDN5NhPQibHTCbO8b8BnV/6giVfnRPhGL3WZyw3GZ+KRDHTmocnlt9LfBnMNIP8gB7TPx3T90hfeLzUYFfZ3vlWyBScHTiTpaGpxFkwJ/d3LU0xY2QQ8v7L1ge/KhfvbGRykjcRa4FExi98WrPmEHrjdtVtG0R0h2SRVP9Gpb/KRURFdLDpwReNqF0m0zHe1nJt9tr0+gHIJZYzTl1YOJc370tapMg/n1Ih6ar/WccfxKnWyTymJAbMTVecbOy/FZ9EGo1FW612Ae9VhWVoVHvrukRmtXwRnYQZ30noVZvzdy7wfLMqeLpjicm05XVVULmvcDni1eBhhpNc+zdaIulVKHFdy2Usz0cBBj3FZomHBdKk9XCfNZdHYdVZ4tU8eN9K//2fW5SHJYBr89ekpLCpoKBoYAeteAtEWAW0bK0ZbKUEtCEXTRJEgIW4Je7NRgWH3vG6KZHvp932LHUFLnpW5dgpoA7qx+qMv1dtgYGIZpnUU797wguDyuSD+lmILpozQzc0ulJd8uiaEwG90ugZONYBYK8X6oulOMzARah/20XNPU3rPJy8PWCvQBY7NI9TchcdvMVab1+6KGw37XRfDlNRiHDH1fmB+jQGqOccYPIu4WLPuIRY5fNDAQ== centreon@siddc1cenadm01p" > /var/spool/centreon/.ssh/authorized_keys
  systemctl enable centengine
  systemctl start centengine
  echo "Installation completed"
EOF

  tags = {
    Name = "sidawscencol01p"
  }
}


resource "aws_subnet" "sc_centreon" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block = cidrsubnet(aws_vpc.sidera_cloud.cidr_block, 12, 8)

  tags = {
    Name = "Zone Centreon"
  }
}

resource "aws_route_table" "route_centreon" {
  vpc_id = aws_vpc.sidera_cloud.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }
}
resource "aws_vpn_gateway_route_propagation" "sideraOAM-cent" {
  vpn_gateway_id = aws_vpn_gateway.sideracloud_vpngw.id
  route_table_id = aws_route_table.route_centreon.id
}

resource "aws_route_table_association" "nat_sc_centreon" {
  subnet_id      = aws_subnet.sc_centreon.id
  route_table_id = aws_route_table.route_centreon.id
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