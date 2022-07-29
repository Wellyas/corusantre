terraform {
  cloud {
      organization = "eliasmtaleb"

      workspaces {
          name = "SideraCloud"
      }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-3"
}

data "aws_region" "current" {}
