/* resource "aws_flow_log" "corusant" {
  iam_role_arn    = aws_iam_role.corusant.arn
  log_destination = aws_cloudwatch_log_group.corusant.arn
  traffic_type    = "ALL"
  //vpc_id          = aws_vpc.sidera_cloud.id
  subnet_id = aws_subnet.sc_ldap.id
  max_aggregation_interval = 60

  //subnet_id = aws_subnet.sc_kasm_db2.id
}

resource "aws_cloudwatch_log_group" "corusant" {
  name = "corusant"
  retention_in_days= 7
}

resource "aws_iam_role" "corusant" {
  name = "corusant"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "corusant" {
  name = "corusant"
  role = aws_iam_role.corusant.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
} */