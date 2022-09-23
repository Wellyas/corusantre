resource "aws_instance" "wab" {
  ami           = "ami-0a279a1895fc6d09d"
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg_access.id]
  subnet_id = aws_subnet.sc_access.id
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = false

  tags = {
    Name  = "sidawswabadm01p"
  }
}


resource "aws_route53_record" "wab" {
  zone_id = aws_route53_zone.private.zone_id
  name    = aws_instance.wab.tags.Name
  type    = "A"
  ttl     = 300
  records = [aws_instance.wab.private_ip]
}

resource "aws_route53_record" "wabcname" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "wab"
  type    = "CNAME"
  ttl     = 300
  records = [
    aws_route53_record.wab.fqdn,
  ]
}