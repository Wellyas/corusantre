
resource "aws_ecs_task_definition" "ldap" {
  family = "ldapserver"
  requires_compatibilities = ["FARGATE"]
  network_mode= "awsvpc"
  cpu = 1024
  memory = 2048
  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn

  depends_on = [
    random_password.ldaprootpassword,
    aws_cloudwatch_log_group.ecs_ldap
  ]

  container_definitions = <<EOF
[
  {
    "name": "opendj",
    "image": "openidentityplatform/opendj:alpine",
    "cpu": 1024,
    "memory": 2048,
    "environment": [
      {"name": "PORT", "value": "1389"},
      {"name": "LDAPS_PORT", "value": "1636"},
      {"name": "BASE_DN", "value": "dc=aws,dc=csoc,dc=thales"},
      {"name": "ROOT_USER_DN", "value": "cn=idm"},
      {"name": "ROOT_PASSWORD", "value": "${random_password.ldaprootpassword.result}"}
    ],
    "portMappings": [
      {
        "containerPort": 1389,
        "hostPort": 1389
      },
      {
        "containerPort": 1636,
        "hostPort": 1636
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-create-group": "true",
        "awslogs-region": "eu-west-3",
        "awslogs-group": "${aws_cloudwatch_log_group.ecs_ldap.name}",
        "awslogs-stream-prefix": "ec2"
      }
    }
  }
]
EOF

  runtime_platform {
    operating_system_family = "LINUX"
  }
}
/* 
    "healthCheck" : {
      "command" : [ "CMD-SHELL", "opendj/bin/ldapsearch --hostname localhost --port 1636 --bindDN '$ROOT_USER_DN' --bindPassword '$ROOT_PASSWORD' --useSsl --trustAll --baseDN '$BASE_DN' --searchScope base '(objectClass=*)' 1.1 || exit 1" ],
      "timeout": 30
    },
 */
resource "aws_cloudwatch_log_group" "ecs_ldap" {
  name              = "/corusant/ecs/ldap"
  retention_in_days = 3
}

resource "aws_ecs_service" "ldap" {
  name            = "ldap"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.ldap.arn

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0


  network_configuration {
      subnets = [
          aws_subnet.sc_ldap.id
      ]
      security_groups = [
          aws_security_group.sg_ldap.id
      ]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ldap.arn
    container_name   = "opendj"
    container_port   = 1389
  }
}

data "dns_a_record_set" "registry_docker" {
  #host = module.url_build.host
  host = "registry-1.docker.io"
}
data "dns_a_record_set" "registry_docker_2" {
  #host = module.url_build.host
  host = "production.cloudflare.docker.com"
}

resource "aws_security_group" "sg_ldap" {
    name   = "LDAP ACL"
    vpc_id = aws_vpc.sidera_cloud.id
     tags = {
    Name = "Security Groupe - LDAP"
  }
  egress {
    description= "Docker"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    //cidr_blocks = concat([for x in data.dns_a_record_set.registry_docker.addrs : "${x}/32"],[for x in data.dns_a_record_set.registry_docker_2.addrs : "${x}/32"])
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description= "Docker"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    //cidr_blocks = concat([for x in data.dns_a_record_set.registry_docker.addrs : "${x}/32"],[for x in data.dns_a_record_set.registry_docker_2.addrs : "${x}/32"])
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS to LDAP"
    from_port   = 1389
    to_port     = 1389
    protocol    = "tcp"
    cidr_blocks = [aws_vpn_connection_route.admin.destination_cidr_block,aws_vpc.sidera_cloud.cidr_block]
  }
}

resource "random_password" "ldaprootpassword" {
  length           = 26
  special          = true
  override_special = "_,"
}

resource "aws_subnet" "sc_ldap" {
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block        = cidrsubnet(aws_vpc.sidera_cloud.cidr_block, 12, 13)

  tags = {
    Name  = "Zone LDAP"
  }
}

resource "aws_route_table_association" "nat" {
  subnet_id      = aws_subnet.sc_ldap.id
  route_table_id = aws_route_table.natgw.id
}

resource "aws_lb_target_group" "ldap" {
  name_prefix     = "ldap"
  port     = 1389
  target_type = "ip"
  protocol = "TCP"
  vpc_id   = aws_vpc.sidera_cloud.id

  lifecycle {
   create_before_destroy = true
  }
}

resource "aws_route53_record" "ldapcname" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "ldap"
  type    = "CNAME"
  ttl     = 300
  records = [
    aws_route53_record.ecs-route53-elb-record.fqdn,
  ]
}

resource "aws_lb_listener" "ecs_lb_ldap" {
  load_balancer_arn = aws_lb.ecs_lb.id
  protocol = "TCP"
  port = 389

  default_action {
    target_group_arn = aws_lb_target_group.ldap.id
    type             = "forward"
  }
  lifecycle {
   create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "ecs_lb_ldap" {
  network_acl_id = aws_network_acl.ecs_lb.id
  rule_number    = 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.135.190.0/24"
  from_port      = 389
  to_port        = 389
}
resource "aws_network_acl_rule" "ecs_lb_ldap_out" {
  network_acl_id = aws_network_acl.ecs_lb.id
  rule_number    = 101
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.sc_ldap.cidr_block
  from_port      = 1389
  to_port        = 1389
}

output "ldapdebug" {
  value = aws_ecs_service.ldap
  sensitive=true
  }