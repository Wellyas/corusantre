resource "aws_instance" "centreon" {
  ami                         = "ami-0eb3117f2ccc34ba6"
  instance_type               = "t3.small"
  vpc_security_group_ids      = [aws_security_group.sg_centreon.id,aws_security_group.sg_admin_from_wab.id]
  subnet_id                   = aws_subnet.sc_centreon.id
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
              yum install -y http://yum.centreon.com/standard/19.10/el7/stable/noarch/RPMS/centreon-release-19.10-1.el7.centos.noarch.rpm 
              yum install centreon-poller-centreon-engine
              echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3T0lKdGKw22hTZaTLjoMC/srz0+KVSOLo0NcqC8voeoOxD8/Sv+DhvV6JN/vWV8EISEval2mgUtl91e0TaAT1vuEK6gS6ttt9ph2YcPc7ycJ3QlZmXgvGjZAgzZd4iJ185jN05UUVr7e9seJmkwDDCLnZe7pKC+kPQYRp+tyl0/Cti/V057XlgDprLoCR2YXfKCp7WfpDyRE8W6NE7RL276NR9viN0sC+MDDZWkwdRiBD1BjyLRTEP8ST2dmRgRxiv81UGw855WdFokDvYwIac1OfkHYSDuhm4xayMpbKr1Iar9rM3B0auIJZuuyUHN1W559MrmfPcGxvOoOt+sCcSuKoTnBSu6OIo4gEIBSHTHJGl61Oxnxg5qR/HF82OppT/7GrgSAAMlkAEOnG5czzdwBwS9XaONSrb4S4wFq4JZxfcXfF3kLdTJ00q/o0NkMdDzUCi/DhR7Jh5owNLrkxQ2b+nrbZ7kFjeGe0wtLT6WJ873R+H9U3/pac4qf/03+kCbv38ozrD3sIE6O4SQ9fmwpqjDgxk0W9A8o7MAOlmV7I4LlT5dnXTJmDBIylE+8VI0ufoyz+wBGGk7Q94pHfzQFlMoeM4US6nIC/jZoefDmas1cQ/dSFS+9JW9srIjttDo5z4/ENaFfyWGbCAmIqRlZVZw/r/vz9I0Dr1OTHlQ== centreon@siddc1cenadm01p
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCakoYQVz7QrDTCRlNIoJkf5itv+0oZnBcJr9gvTuQxZOxioxFhx2hooBprNmn1LizWs5VVnx6qNRMSgAvVB/le1s+a/gNSK4szbzYKSPx/VESfW2umP0r6NWVcdCUKsqUdv6YKzd9RKpk3i0B2fDPz17xwhwOThZ98jCKUGdHFkHYS/+x7AOhuugT2+sKTUX2oB7AfLBYKfZpHHUcj8IVUd31w0NGVtCfeUq2pOA/O5Tc3to/D3rsPwNoEQQY3UhIbs0T3xnZ3deUCGPSjCpKkgNo/7PuYs+AiLC1WVVrmuvE/qjdhqkgkdgGN8fFqfdyIOjwkfkWiUC8aeXxZRE+SUJRkfB1HFRgsLzTpaCy6VxNk/EDht7uvHWgGkjEIxv3+QgK1vU6i4ph2vDWJiWpuuzR/+yLAQXZf5Li/GDpksuRM0vzLuM7rjIfqf2VXRY0gY/XrJyUj1WxfpkAFQe6dnPy03vWzuFiU2rxNh1TAhDmHEL0N77AqhBVJwz39S8tCrAhFdzAhlCkuC1Vw1nqGF5CafHy1QHs1/QNHKc0qqR001AgEVonYYK++nnRxOL+gUcvP0GnPv3emi7ekXG1o8ec4UP8JM/WpMXhSADv1/iZWqWjWazu5uGLWTjK+EqJx2FpsRqgVWLvvTsXUPd42fyuiMYmwcNXILTSaXxRCZw== centreon@siddc1cenadm01p
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxk6So6/0jIQ/pnq38lyXF9PZ7QKAW9RJCk5OA60ERYJlqIdDN5NhPQibHTCbO8b8BnV/6giVfnRPhGL3WZyw3GZ+KRDHTmocnlt9LfBnMNIP8gB7TPx3T90hfeLzUYFfZ3vlWyBScHTiTpaGpxFkwJ/d3LU0xY2QQ8v7L1ge/KhfvbGRykjcRa4FExi98WrPmEHrjdtVtG0R0h2SRVP9Gpb/KRURFdLDpwReNqF0m0zHe1nJt9tr0+gHIJZYzTl1YOJc370tapMg/n1Ih6ar/WccfxKnWyTymJAbMTVecbOy/FZ9EGo1FW612Ae9VhWVoVHvrukRmtXwRnYQZ30noVZvzdy7wfLMqeLpjicm05XVVULmvcDni1eBhhpNc+zdaIulVKHFdy2Usz0cBBj3FZomHBdKk9XCfNZdHYdVZ4tU8eN9K//2fW5SHJYBr89ekpLCpoKBoYAeteAtEWAW0bK0ZbKUEtCEXTRJEgIW4Je7NRgWH3vG6KZHvp932LHUFLnpW5dgpoA7qx+qMv1dtgYGIZpnUU797wguDyuSD+lmILpozQzc0ulJd8uiaEwG90ugZONYBYK8X6oulOMzARah/20XNPU3rPJy8PWCvQBY7NI9TchcdvMVab1+6KGw37XRfDlNRiHDH1fmB+jQGqOccYPIu4WLPuIRY5fNDAQ== centreon@siddc1cenadm01p" > /var/spool/centreon/.ssh/authorized_keys
              systemctl enable centengine
              systemctl start centengine
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