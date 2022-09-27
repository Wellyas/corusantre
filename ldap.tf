resource "aws_ecs_task_definition" "ldap" {
  family = "ldapserver"

  depends_on = [
    random_password.ldaprootpassword,
    aws_cloudwatch_log_group.ecs_loggroup
  ]

  container_definitions = <<EOF
[
  {
    "name": "opendj",
    "image": "openidentityplatform/opendj:alpine",
    "cpu": 0,
    "memory": 128,
    "network_mode": "awsvpc",
    "environment": [
      {"name": "PORT", "value": 389},
      {"name": "LDAPS_PORT", "value": 636},
      {"name": "BASE_DN", "value": "dc=aws,dc=csoc,dc=thales"},
      {"name": "ROOT_PASSWORD", "value": "${random_password.ldaprootpassword.result}"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "eu-west-3",
        "awslogs-group": "${aws_cloudwatch_log_group.ecs_loggroup.name}",
        "awslogs-stream-prefix": "ec2"
      }
    }
  }
]
EOF
}

resource "aws_ecs_service" "ldap" {
  name            = "ldap"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.ldap.arn

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0


  network_configuration = {
      subnets = [
          aws_subnet.sc_access.id
      ]
      security_groups = [
          aws_security_group.sg_ldap.id
      ]
  }
}

resource "aws_security_group" "sg_ldap" {
    name   = "LDAP ACL"
    vpc_id = aws_vpc.sidera_cloud.id
     tags = {
    Name = "Security Groupe - LDAP"
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