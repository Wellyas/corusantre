data "aws_iam_policy_document" "iamtoken" {
  statement {
    effect = "Allow"
    actions = [
      "iam:DeleteAccessKey",
      "iam:UpdateAccessKey",
      "iam:CreateAccessKey"
    ]

    resources = [
      "arn:aws:iam::*:user/$${aws:username}",
    ]
  }
}

resource "aws_iam_group" "apitoken" {
  name = "CyberApiToken"
  path = "/cyber/"
  /*   tags = {
    Owner    = "Taleb E."
    DeployBy = "terraform"
  } */
}


resource "aws_iam_group_policy" "iamtoken" {
  name_prefix = "CyberIam"
  group       = aws_iam_group.apitoken.name

  policy = data.aws_iam_policy_document.iamtoken.json
}


data "aws_iam_policy_document" "ec2serialconsole" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:GetSerialConsoleAccessStatus",
      "ec2:EnableSerialConsoleAccess",
      "ec2:DisableSerialConsoleAccess"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_group" "ec2serialconsole" {
  name = "CyberEC2SerialConsole"
  path = "/cyber/"
}

resource "aws_iam_group_policy" "ec2serialconsole" {
  name_prefix = "CyberIam"
  group       = aws_iam_group.ec2serialconsole.name

  policy = data.aws_iam_policy_document.ec2serialconsole.json
}



data "aws_iam_policy_document" "marketplacesubs" {
  statement {
    effect = "Allow"
    actions = [
      "aws-marketplace:ViewSubscriptions",
      "aws-marketplace:Subscribe",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_group" "marketplacesubs" {
  name = "CyberMarketPlaceSubscribe"
  path = "/cyber/"
}

resource "aws_iam_group_policy" "marketplacesubs" {
  name_prefix = "CyberIam"
  group       = aws_iam_group.marketplacesubs.name

  policy = data.aws_iam_policy_document.marketplacesubs.json
}

/* data "aws_iam_policy_document" "watchlog" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"  
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "logflow" {
  name               = "instance_role"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.watchlog.json
} */