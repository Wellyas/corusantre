data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_network_interface" "xsoar_net0" {
  subnet_id = aws_subnet.sc_dmz.id

  security_groups = [aws_security_group.sg_dmz.id]

  tags = {
    Name  = "ProdInterface"
  }
}

/* resource "aws_network_interface" "xsoar_net1" {
  subnet_id   = aws_subnet.sc_adm_portail.id

  tags = {
    Name = "AdmInterface"
  }
} */

/* resource "aws_eip" "xsoar_eip" {
  vpc               = true
  network_interface = aws_network_interface.xsoar_net0.id
  depends_on = [
    aws_network_interface.xsoar_net0
  ]
} */

resource "aws_instance" "xsoar" {
  #Ubuntu 20.04
  ami           = "ami-0f7559f51d3a22167"
  instance_type = "t3.micro"

  #Amazon Linux
  #ami           = "ami-0f5094faf16f004eb"
  #Xsoar MarketPlace
  /*   ami           = "ami-03d1e9fd22550631b"
  instance_type = "c5.2xlarge" */

  network_interface {
    network_interface_id = aws_network_interface.xsoar_net0.id
    device_index         = 0
  }
  /*   network_interface {
    network_interface_id = aws_network_interface.xsoar_net1.id
    device_index         = 1
  } */

  key_name = aws_key_pair.ssh.key_name


  tags = {
    Name  = "sidazudemmst01t"
  }
}

resource "aws_network_interface" "squid_net0" {
  subnet_id = aws_subnet.sc_portail.id

  security_groups = [aws_security_group.sg_portail.id]

  tags = {
    Name  = "ProdInterfaceSquid"
  }
}
resource "aws_instance" "squid" {
  #Ubuntu 20.04
  ami           = "ami-0f7559f51d3a22167"
  instance_type = "t3.nano"


  network_interface {
    network_interface_id = aws_network_interface.squid_net0.id
    device_index         = 0
  }

  key_name = aws_key_pair.ssh.key_name


  tags = {
    Name  = "sidazuboxsqd01t"
  }
}
resource "aws_route53_record" "squid" {
  zone_id = aws_route53_zone.private.zone_id
  name    = aws_instance.squid.tags.Name
  type    = "A"
  ttl     = 300
  records = [aws_instance.squid.private_ip]
}

output "soar_url" {
  value       = "https://${aws_instance.xsoar.public_ip}"
  description = "Url d'acces pour le SOAR"
  depends_on = [
    aws_instance.xsoar
  ]
}