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
      {"name": "PORT", "value": "389"},
      {"name": "LDAPS_PORT", "value": "636"},
      {"name": "BASE_DN", "value": "dc=aws,dc=csoc,dc=thales"},
      {"name": "ROOT_PASSWORD", "value": "${random_password.ldaprootpassword.result}"}
    ],
    "portMappings": [
      {
        "containerPort": 389,
        "hostPort": 389
      },
      {
        "containerPort": 636,
        "hostPort": 636
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
          aws_subnet.sc_access.id
      ]
      security_groups = [
          aws_security_group.sg_ldap.id
      ]
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
    from_port   = 389
    to_port     = 389
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