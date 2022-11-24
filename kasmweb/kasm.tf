resource "aws_instance" "kasm-web-app" {
  ami                         = "${var.ec2_ami}"
  instance_type               = "${var.webapp_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.kasm-webapp-sg.id}"]
  subnet_id                   = aws_subnet.sc_kasm_web.id
  key_name                    = var.key_name
  associate_public_ip_address = false

  depends_on = [
    aws_rds_cluster.kasmdb
  ]

  root_block_device {
    volume_size = "40"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -x
              fallocate -l 4g /mnt/kasm.swap
              chmod 600 /mnt/kasm.swap
              mkswap /mnt/kasm.swap
              swapon /mnt/kasm.swap
              echo '/mnt/kasm.swap swap swap defaults 0 0' | tee -a /etc/fstab
              cd /tmp
              wget ${var.kasm_build}
              tar xvf kasm_*.tar.gz
              echo "Checking for Kasm DB..."
              while ! nc -w 1  -z ${aws_rds_cluster.kasmdb.endpoint} 5432; do
                echo "Not Ready..."
                sleep 5
              done
              echo "DB is alive"
              bash kasm_release/install.sh -O -t -S app -e -z ${var.zone_name} -q ${aws_rds_cluster.kasmdb.endpoint} -Q ${random_password.database.result} -R "" -o ${aws_elasticache_cluster.kasmredis.cache_nodes.0.address}
              EOF
  tags = {
    Name  = "sidawsksmweb01p"
  }
}

/* resource "aws_instance" "kasm-db" {
  ami           = var.ec2_ami
  instance_type = var.db_instance_type
  vpc_security_group_ids = [aws_security_group.kasm-db-sg.id]
  subnet_id = aws_subnet.sc_kasm_db2.id
  key_name                    = var.key_name
  associate_public_ip_address = false

  root_block_device {
    volume_size = "40"
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              fallocate -l 4g /mnt/kasm.swap
              chmod 600 /mnt/kasm.swap
              mkswap /mnt/kasm.swap
              swapon /mnt/kasm.swap
              echo '/mnt/kasm.swap swap swap defaults 0 0' | tee -a /etc/fstab
              cd /tmp
              wget ${var.kasm_build}
              tar xvf kasm_*.tar.gz
              bash kasm_release/install.sh -S db -e -Q ${random_password.database.result} -R ${random_password.redis.result} -U ${random_password.user.result} -P ${random_password.admin.result} -M ${random_password.manager.result}
              EOF
  tags = {
    Name  = "sidawsksmbdd01p"
  }
} */

resource "aws_instance" "kasm-agent" {
  count                       = "${var.num_agents}"
  #count                       = "0"
  ami                         = "${var.ec2_ami}"
  instance_type               = "${var.agent_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.kasm-agent-sg.id}"]
  subnet_id = aws_subnet.sc_kasm_agent.id
  key_name                    = var.key_name
  associate_public_ip_address = false

  depends_on = [
    aws_instance.kasm-web-app
  ]
  root_block_device {
    volume_size = "80"
  }

  user_data = <<-EOF
              #!/bin/bash
              fallocate -l 5g /mnt/kasm.swap
              chmod 600 /mnt/kasm.swap
              mkswap /mnt/kasm.swap
              swapon /mnt/kasm.swap
              echo '/mnt/kasm.swap swap swap defaults 0 0' | tee -a /etc/fstab
              cd /tmp
              wget ${var.kasm_build}
              tar xvf kasm_*.tar.gz
              PRIVATE_IP=(`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`)
              bash kasm_release/install.sh -S agent -e  -p $PRIVATE_IP -m ${aws_instance.kasm-web-app.private_ip} -M ${random_password.manager.result}
              EOF
  tags = {
    Name  = "${format("sidawsksmapp%02sp",count.index+1)}"
  }
}

resource "aws_instance" "kasm-agent-pub" {
  count                       = var.num_agents
  ami                         = var.ec2_ami
  instance_type               = var.agent_instance_type
  vpc_security_group_ids      = [aws_security_group.kasm-agent-sg.id,aws_seucirty_group.kasm-agent-internet-sg.id]
  subnet_id = aws_subnet.sc_kasm_agent_pub.id
  key_name                    = var.key_name
  associate_public_ip_address = false

  depends_on = [
    aws_instance.kasm-web-app
  ]
  root_block_device {
    volume_size = "80"
  }

  user_data = <<-EOF
              #!/bin/bash
              fallocate -l 5g /mnt/kasm.swap
              chmod 600 /mnt/kasm.swap
              mkswap /mnt/kasm.swap
              swapon /mnt/kasm.swap
              echo '/mnt/kasm.swap swap swap defaults 0 0' | tee -a /etc/fstab
              cd /tmp
              wget ${var.kasm_build}
              tar xvf kasm_*.tar.gz
              PRIVATE_IP=(`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`)
              bash kasm_release/install.sh -S agent -e  -p pub_$PRIVATE_IP -m ${aws_instance.kasm-web-app.private_ip} -M ${random_password.manager.result}
              EOF
  tags = {
    Name  = "${format("sidawsksmpub%02sp",count.index+1)}"
  }
}
/* resource "aws_route53_record" "kasm-db" {
  count = var.private_zone_id != "" ? 1 : 0 
  zone_id = var.private_zone_id
  name    = aws_instance.kasm-db.tags.Name
  type    = "A"
  ttl     = 300
  records = [aws_instance.kasm-db.private_ip]
} */
resource "aws_route53_record" "kasm-agent" {
  count = var.private_zone_id != "" ? length(aws_instance.kasm-agent) : 0 
  zone_id = var.private_zone_id
  name    = aws_instance.kasm-agent[count.index].tags.Name
  type    = "A"
  ttl     = 300
  records = [aws_instance.kasm-agent[count.index].private_ip]
}
resource "aws_route53_record" "kasm-agent-pub" {
  count = var.private_zone_id != "" ? length(aws_instance.kasm-agent-pub) : 0 
  zone_id = var.private_zone_id
  name    = aws_instance.kasm-agent-pub[count.index].tags.Name
  type    = "A"
  ttl     = 300
  records = [aws_instance.kasm-agent-pub[count.index].private_ip]
}

resource "aws_route53_record" "kasm-web-app" {
  count = var.private_zone_id != "" ? 1 : 0 
  zone_id = var.private_zone_id
  name    = aws_instance.kasm-web-app.tags.Name
  type    = "A"
  ttl     = 300
  records = [aws_instance.kasm-web-app.private_ip]
}

resource "aws_route53_record" "kasm-cname" {
  count = var.private_zone_id != "" ? 1 : 0 
  zone_id = var.private_zone_id
  name    = "vdi"
  type    = "CNAME"
  ttl     = 300
  records = [
    aws_route53_record.kasm-web-app[count.index].fqdn
  ]
}
output "install" {
  value = "kasm_release/install.sh -S db -e -Q ${random_password.database.result} -R ${random_password.redis.result} -U ${random_password.user.result} -P ${random_password.admin.result} -M ${random_password.manager.result}"
}
output "installdb" {
  value = "kasm_release/install.sh -S init_remote_db -e -Q ${random_password.database.result} -U ${random_password.user.result} -P ${random_password.admin.result} -M ${random_password.manager.result} -q ${aws_rds_cluster.kasmdb.endpoint} -g root -G ${random_password.databaseroot.result}"
}

resource "aws_rds_cluster" "kasmdb" {
  cluster_identifier = "kasmdb"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "14.3"
  database_name      = "kasmdbnotused"
  master_username    = "root"
  master_password    = random_password.databaseroot.result
  db_subnet_group_name = aws_db_subnet_group.kasmdb.name
  skip_final_snapshot = true
  final_snapshot_identifier = "kasmdb-snapshot"
  enabled_cloudwatch_logs_exports = ["postgresql"]

  network_type = "IPV4"
  apply_immediately = true

  serverlessv2_scaling_configuration {
    max_capacity = 2.0
    min_capacity = 0.5
  }

  vpc_security_group_ids = [
    aws_security_group.kasm-db-sg.id
  ]
}

resource "aws_db_instance" "kasmdb12" {
  count = 0 
  allocated_storage    = 10
  identifier = "kasmdb12"
  instance_class = "db.t3.micro"
  engine             = "postgres"
  engine_version     = "12.11"
  db_name      = "kasmdbnotused"
  username    = "root"
  password    = random_password.databaseroot.result
  db_subnet_group_name = aws_db_subnet_group.kasmdb.name
  skip_final_snapshot = true
  final_snapshot_identifier = "kasmdb-snapshot"
  enabled_cloudwatch_logs_exports = ["postgresql"]

  network_type = "IPV4"
  apply_immediately = true

  vpc_security_group_ids = [
    aws_security_group.kasm-db-sg.id
  ]
}

resource "aws_rds_cluster_instance" "kasmdb" {
  cluster_identifier = aws_rds_cluster.kasmdb.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.kasmdb.engine
  engine_version     = aws_rds_cluster.kasmdb.engine_version
}

resource "aws_elasticache_cluster" "kasmredis" {
  cluster_id           = "kasmweb-redis"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379

  subnet_group_name = aws_elasticache_subnet_group.kasm_subnet_group.name

  security_group_ids = [
    aws_security_group.kasm-db-sg.id
  ]
}

output "dbinfo" {
  value = aws_rds_cluster.kasmdb.endpoint
}

output "appinstall" {
  value = "kasm_release/install.sh -O -t -S app -e -z ${var.zone_name} -q ${aws_rds_cluster.kasmdb.endpoint} -Q ${random_password.database.result} -R '' -o ${aws_elasticache_cluster.kasmredis.cache_nodes.0.address}"
  sensitive = true
}

output "agentinstall" {
  value = "bash kasm_release/install.sh -S agent -e  -p $PRIVATE_IP -m ${aws_instance.kasm-web-app.private_ip} -M ${random_password.manager.result}"
  sensitive = true
}

output "web_userdata" { 
  value = aws_instance.kasm-web-app.user_data
  sensitive = true
}