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
      version = "4.39"
    }
    tls = {
      source = "hashicorp/tls"
      version = ">= 3.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = {
      Owner       = "Taleb E."
      Environment = "Preprod"
      Projet      = "Cloudification"
      DeployedBy  = "Terraform"
    }
  }
}

data "aws_region" "current" {}
