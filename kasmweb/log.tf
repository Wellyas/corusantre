resource "aws_flow_log" "kaslog" {
  iam_role_arn    = aws_iam_role.kasmlog.arn
  log_destination = aws_cloudwatch_log_group.kasmlog.arn
  traffic_type    = "ALL"
  vpc_id          = data.aws_vpc.vpc.id

  max_aggregation_interval = 60

  //subnet_id = aws_subnet.sc_kasm_db2.id
}

resource "aws_cloudwatch_log_group" "kasmlog" {
  name = "kasmlog"
}

resource "aws_iam_role" "kasmlog" {
  name = "kasmlog"

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

resource "aws_iam_role_policy" "kasmlog" {
  name = "kasmlog"
  role = aws_iam_role.kasmlog.id

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
}