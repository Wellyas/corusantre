
data "dns_a_record_set" "kasmweb_site" {
  #host = module.url_build.host
  host = "kasm-static-content.s3.amazonaws.com" 
}

data "dns_a_record_set" "kasmweb_filter" {
  #host = module.url_build.host
  host = "filter.kasmweb.com" 
}

data "dns_a_record_set" "registry_docker" {
  #host = module.url_build.host
  host = "registry.docker.io"
}
data "dns_a_record_set" "registry_docker_2" {
  #host = module.url_build.host
  host = "production.cloudflare.docker.com"
}

resource "aws_security_group" "kasm-webapp-sg" {
  name        = "ACL kasm-webapp"
  description = "Allow access to webapps"
  vpc_id = data.aws_vpc.vpc.id

  depends_on = [
    aws_subnet.sc_kasm_db
  ]

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_access_cidr]
  }
  ingress {
    description = "TLS from Sidera"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.ssh_access_cidr]
  }
  ingress {
    description = "TLS from Allowed source"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.https_access_cidr
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #security_groups = aws_security_group.kasm-agent-sg
    self  = true
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.sc_kasm_agent.cidr_block]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.sc_kasm_agent.cidr_block]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.kasmweb_site.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.kasmweb_site.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.registry_docker.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.registry_docker_2.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #security_groups = aws_security_group.sc_kasm_web
    self = true
  }
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = aws_subnet.sc_kasm_db.*.cidr_block
    //cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    //cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = aws_subnet.sc_kasm_db.*.cidr_block
    //cidr_blocks = [aws_subnet.sc_kasm_db.*.cidr_block]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    //cidr_blocks = [for x in data.dns_a_record_set.kasmweb_filter.addrs : "${x}/32"] 
    //description = "filter.kasmweb.com"
    cidr_blocks = [
      "52.222.149.0/24",
      "52.84.174.0/24"
    ]
  }
  #egress {
  #  from_port   = 0
  #  to_port     = 0
  #  protocol    = -1
  #  cidr_blocks = ["0.0.0.0/0"] 
  #}

}

resource "aws_security_group" "kasm-agent-internet-sg" {
  name        = "ACL kasm-agent-access Internet"
  description = "Allow access to agents"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_access_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.sc_kasm_web.cidr_block}"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.kasmweb_site.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.kasmweb_site.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.sc_kasm_web.cidr_block}"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.registry_docker.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.registry_docker_2.addrs : "${x}/32"] 
  }

}
resource "aws_security_group" "kasm-agent-sg" {
  name        = "ACL kasm-agent-access"
  description = "Allow access to agents"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_access_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.sc_kasm_web.cidr_block}"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.registry_docker.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.registry_docker_2.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.kasmweb_site.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.kasmweb_site.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.sc_kasm_web.cidr_block}"]
  }
  egress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = var.proxies_servers_cidr
  }
  #egress {
  #  from_port   = 0
  #  to_port     = 0
  #  protocol    = -1
  #  cidr_blocks = ["0.0.0.0/0"] 
  #}
}



resource "aws_security_group" "kasm-db-sg" {
  name        = "ACL kasm-db-access"
  description = "Allow access to database"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_access_cidr]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.sc_kasm_web.cidr_block}"]
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.sc_kasm_web.cidr_block}"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.kasmweb_site.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.kasmweb_site.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.registry_docker.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for x in data.dns_a_record_set.registry_docker_2.addrs : "${x}/32"] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

output "debug" {
  value = aws_subnet.sc_kasm_db.*.cidr_block
}
